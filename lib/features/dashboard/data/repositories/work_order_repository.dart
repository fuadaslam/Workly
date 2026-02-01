import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/work_order.dart';
import '../../domain/models/task_history.dart';

class WorkOrderRepository {
  final SupabaseClient _client;

  WorkOrderRepository(this._client);

  Future<List<WorkOrder>> getMyWorkOrders() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('work_orders')
        .select('*, offices(name), profiles:assigned_staff_id(name, offices(name))')
        .eq('assigned_staff_id', userId)
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => WorkOrder.fromJson(json)).toList();
  }
  Future<List<WorkOrder>> getWorkOrdersByStaff(String staffId) async {
    final response = await _client
        .from('work_orders')
        .select('*, offices(name), profiles:assigned_staff_id(name, offices(name))')
        .eq('assigned_staff_id', staffId)
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => WorkOrder.fromJson(json)).toList();
  }

  Future<List<WorkOrder>> getAllWorkOrders() async {
    final response = await _client
        .from('work_orders')
        .select('*, offices(name), profiles:assigned_staff_id(name, offices(name))')
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => WorkOrder.fromJson(json)).toList();
  }

  Future<void> createWorkOrder({
    required String? clientName,
    required String? clientPhoneNumber,
    required String? serviceType,
    required String priority,
    String? clientId,
    String? serviceId,
    String? assignedStaffId,
    String? assignedOfficeId,
  }) async {
    final response = await _client.from('work_orders').insert({
      'client_name': clientName,
      'client_phone_number': clientPhoneNumber,
      'service_type': serviceType,
      'priority': priority,
      'client_id': clientId,
      'service_id': serviceId,
      'assigned_staff_id': assignedStaffId ?? (assignedOfficeId == null ? _client.auth.currentUser?.id : null),
      'assigned_office_id': assignedOfficeId,
      'status': 'Pending',
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
}
