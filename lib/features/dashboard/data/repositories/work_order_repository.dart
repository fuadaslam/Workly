import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/work_order.dart';
import '../../domain/models/task_history.dart';
import '../../domain/models/task_document.dart';
import '../../../../core/utils/supabase_org_utils.dart';

class WorkOrderRepository {
  final SupabaseClient _client;

  WorkOrderRepository(this._client);

  Future<List<WorkOrder>> getMyWorkOrders() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    // Scalability Fix: Limit to last 50 by default to prevent massive initial load
    final response = await _client
        .from('work_orders')
        .select('*, offices(name), profiles:assigned_staff_id(name, offices(name)), agent_profiles:agent_id(name)')
        .eq('assigned_staff_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    
    return (response as List).map((json) => WorkOrder.fromJson(json)).toList();
  }

  Future<List<WorkOrder>> getPaginatedWorkOrders({
    int page = 0, 
    int pageSize = 20, 
    String? status,
    String? staffId,
    String? clientName,
  }) async {
    var query = _client
        .from('work_orders')
        .select('*, offices(name), profiles:assigned_staff_id(name, offices(name)), agent_profiles:agent_id(name)');

    if (staffId != null) {
      query = query.eq('assigned_staff_id', staffId);
    }
    
    if (status != null) {
      query = query.eq('status', status);
    }

    if (clientName != null) {
      query = query.eq('client_name', clientName);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);
    
    return (response as List).map((json) => WorkOrder.fromJson(json)).toList();
  }

  Future<Map<String, int>> getWorkOrderStats({String? staffId}) async {
    // Scalability Fix: Use count() instead of fetching all rows
    
    // Helper to run count query
    Future<int> getCount(String? status) async {
      var query = _client.from('work_orders').select('id');
      
      if (staffId != null) {
        query = query.eq('assigned_staff_id', staffId);
      }
      if (status != null) {
        query = query.eq('status', status);
      }
      
      final response = await query.count(CountOption.exact);
      return response.count;
    }

    // Run in parallel
    final results = await Future.wait([
      getCount(null), // Total
      getCount('Completed'),
      getCount('Pending'),
      getCount('In-Progress'),
    ]);

    return {
      'total': results[0],
      'completed': results[1],
      'pending': results[2],
      'inProgress': results[3],
    };
  }

  Future<List<WorkOrder>> getWorkOrdersByStaff(String staffId) async {
    // Scalability Fix: Limit to last 50
    final response = await _client
        .from('work_orders')
        .select('*, offices(name), profiles:assigned_staff_id(name, offices(name)), agent_profiles:agent_id(name)')
        .eq('assigned_staff_id', staffId)
        .order('created_at', ascending: false)
        .limit(50);
    
    return (response as List).map((json) => WorkOrder.fromJson(json)).toList();
  }

  Future<List<WorkOrder>> getAllWorkOrders() async {
    // Scalability Fix: Limit to last 100
    final response = await _client
        .from('work_orders')
        .select('*, offices(name), profiles:assigned_staff_id(name, offices(name)), agent_profiles:agent_id(name)')
        .order('created_at', ascending: false)
        .limit(100);
    
    return (response as List).map((json) => WorkOrder.fromJson(json)).toList();
  }

  Future<void> createWorkOrder({
    required String? clientName,
    required String? clientPhoneNumber,
    required String? serviceType,
    required String priority,
    String? nationality,
    String? clientId,
    String? serviceId,
    String? assignedStaffId,
    String? assignedOfficeId,
  }) async {
    final orgId = await fetchCallerOrgId(_client);
    final response = await _client.from('work_orders').insert({
      'client_name': clientName,
      'client_phone_number': clientPhoneNumber,
      'nationality': nationality,
      'service_type': serviceType,
      'priority': priority,
      'client_id': clientId,
      'service_id': serviceId,
      'assigned_staff_id': assignedStaffId ?? (assignedOfficeId == null ? _client.auth.currentUser?.id : null),
      'assigned_office_id': assignedOfficeId,
      'status': 'Pending',
      'org_id': orgId,
    }).select().single();

    final orderId = response['id'];
    await addTaskHistory(
      orderId, 
      'Task Created / تم إنشاء المهمة', 
      description: 'Initial task setup for $serviceType / إعداد المهمة الأولي لـ $serviceType'
    );
  }

  Future<void> updateWorkOrderStatus(String id, String status) async {
    await _client.from('work_orders').update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> updateWorkOrderFinalStatus(
    String id, {
    String? finalStatus,
    String? rejectionReason,
  }) async {
    await _client.from('work_orders').update({
      'final_status': finalStatus,
      'rejection_reason': rejectionReason,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> updateWorkOrderAgent(String id, {String? agentId, double? agentFee}) async {
    final Map<String, dynamic> updates = {
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (agentId != null) updates['agent_id'] = agentId;
    if (agentFee != null) updates['agent_fee'] = agentFee;

    await _client.from('work_orders').update(updates).eq('id', id);
    
    if (agentId != null) {
      await addTaskHistory(
        id, 
        'Transferred to Agent / تم التحويل إلى وكيل', 
        description: 'Work transferred to agent for processing.'
      );
    }
  }

  Future<Map<String, dynamic>?> getPaymentForWorkOrder(String workOrderId) async {
    try {
      final response = await _client
          .from('payments')
          .select()
          .eq('work_order_id', workOrderId)
          .maybeSingle(); 
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<void> updatePayment(String workOrderId, double total, double paid) async {
    final existing = await getPaymentForWorkOrder(workOrderId);
    
    String status = 'Pending';
    if (paid >= total && total > 0) {
      status = 'Paid';
    } else if (paid > 0) {
      status = 'Advance'; 
    }

    if (existing != null) {
      await _client.from('payments').update({
        'total_amount': total,
        'paid_amount': paid,
        'status': status,
      }).eq('id', existing['id']);
    } else {
      await _client.from('payments').insert({
        'work_order_id': workOrderId,
        'total_amount': total,
        'paid_amount': paid,
        'status': status,
      });
    }
  }

  Future<List<TaskHistory>> getTaskHistory(String workOrderId) async {
    final response = await _client
        .from('task_history')
        .select()
        .eq('work_order_id', workOrderId)
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => TaskHistory.fromJson(json)).toList();
  }

  Future<void> addTaskHistory(String workOrderId, String title, {String? description, String? status}) async {
    await _client.from('task_history').insert({
      'work_order_id': workOrderId,
      'title': title,
      'description': description,
      'status_at_time': status,
    });
  }

  Future<List<TaskDocument>> getTaskDocuments(String workOrderId) async {
    final response = await _client
        .from('task_documents')
        .select()
        .eq('work_order_id', workOrderId)
        .order('created_at', ascending: true);
    return (response as List).map((json) => TaskDocument.fromJson(json)).toList();
  }

  Future<TaskDocument> addTaskDocument({
    required String workOrderId,
    required String title,
    required String fileUrl,
    required String iconName,
  }) async {
    final response = await _client.from('task_documents').insert({
      'work_order_id': workOrderId,
      'title': title,
      'file_url': fileUrl,
      'icon_name': iconName,
      'is_verified': false,
    }).select().single();
    return TaskDocument.fromJson(response);
  }

  Future<void> deleteTaskDocument(String docId, {String? storagePath}) async {
    await _client.from('task_documents').delete().eq('id', docId);
    if (storagePath != null && storagePath.isNotEmpty) {
      await _client.storage.from('task-files').remove([storagePath]);
    }
  }

  Future<void> toggleDocumentVerified(String docId, {required bool verified}) async {
    await _client.from('task_documents').update({'is_verified': verified}).eq('id', docId);
  }
}
