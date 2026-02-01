import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/work_order_repository.dart';
import '../../data/repositories/office_repository.dart';
import '../../domain/models/work_order.dart';
import '../../domain/models/task_history.dart';
import '../../../attendance/data/attendance_repository.dart';

import '../../data/repositories/profile_repository.dart';

final supabaseClientProvider = Provider((ref) => Supabase.instance.client);

final workOrderRepositoryProvider = Provider((ref) {
  return WorkOrderRepository(ref.watch(supabaseClientProvider));
});

final profileRepositoryProvider = Provider((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

final myWorkOrdersProvider = FutureProvider<List<WorkOrder>>((ref) async {
  final repo = ref.watch(workOrderRepositoryProvider);
  return repo.getMyWorkOrders();
});

final allWorkOrdersProvider = FutureProvider<List<WorkOrder>>((ref) async {
  final repo = ref.watch(workOrderRepositoryProvider);
  return repo.getAllWorkOrders();
});
final staffWorkOrdersProvider = FutureProvider.family<List<WorkOrder>, String>((ref, staffId) async {
  final repo = ref.watch(workOrderRepositoryProvider);
  return repo.getWorkOrdersByStaff(staffId);
});

final staffProfilesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  final profiles = await repo.getProfiles();
  return profiles.where((p) {
    final role = (p['role'] as String? ?? '').toLowerCase();
    final isActive = p['is_active'] as bool? ?? true;
    return role == 'staff' && isActive;
  }).toList();
});

final allProfilesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getProfiles();
});

final financialStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final client = Supabase.instance.client;
  
  final response = await client.from('payments').select('total_amount, paid_amount, status, created_at, work_orders(client_name, service_type)');
  
  double totalReceivables = 0;
  double cashCollected = 0;
  List<Map<String, dynamic>> logs = [];
  
  if (response is List) {
    for (var payment in response) {
      totalReceivables += (payment['total_amount'] as num? ?? 0).toDouble();
      cashCollected += (payment['paid_amount'] as num? ?? 0).toDouble();
      
      if (payment['status'] == 'Paid') {
        logs.add({
          'user': 'Finance System',
          'action': 'Approved payment for ${payment['work_orders']?['client_name'] ?? 'Unknown'}',
          'detail': '${payment['work_orders']?['service_type'] ?? ''}',
          'time': payment['created_at'],
        });
      }
    }
  }
  
  return {
    'totalReceivables': totalReceivables,
    'cashCollected': cashCollected,
    'auditLogs': logs,
  };
});

final attendanceRepositoryProvider = Provider((ref) {
  return AttendanceRepository(Supabase.instance.client);
});

final securityStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final attendanceRepo = ref.watch(attendanceRepositoryProvider);
  final activeSessions = await attendanceRepo.getActiveSessionsCount();

  // Security Alerts: Count users without name as placeholders for "incomplete profiles"
  final client = Supabase.instance.client;
  final profilesRes = await client.from('profiles').select('id, name');
  final profiles = profilesRes as List;
  final incompleteProfiles = profiles.where((p) => p['name'] == null || p['name'] == '').length;

  return {
    'activeSessions': activeSessions,
    'securityAlerts': incompleteProfiles,
  };
});

final staffPerformanceProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = Supabase.instance.client;
  
  // Fetch completed work orders with their staff and timestamps
  final response = await client.from('work_orders').select('*, profiles!assigned_staff_id(name)').eq('status', 'Completed');
  
  if (response is! List) return [];

  Map<String, List<Duration>> staffDurations = {};
  Map<String, String> staffNames = {};

  for (var order in response) {
    if (order['assigned_staff_id'] == null) continue;
    final staffId = order['assigned_staff_id'] as String;
    staffNames[staffId] = order['profiles']['name'] ?? 'Unknown';
    
    final created = DateTime.parse(order['created_at']);
    final updated = DateTime.parse(order['updated_at']);
    final duration = updated.difference(created);
    
    staffDurations.putIfAbsent(staffId, () => []).add(duration);
  }

  return staffDurations.entries.map((e) {
    final avgHours = e.value.isEmpty 
        ? 0 
        : e.value.fold(0, (prev, element) => prev + element.inHours) / e.value.length;
    
    return {
      'staffId': e.key,
      'name': staffNames[e.key],
      'avgCompletionTime': '${avgHours.toStringAsFixed(1)} hrs',
      'completedCount': e.value.length,
    };
  }).toList();
});

final dashboardStatsProvider = Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final workOrdersAsync = ref.watch(myWorkOrdersProvider);

  return workOrdersAsync.whenData((orders) {
    final total = orders.length;
    final completed = orders.where((o) => o.status == WorkStatus.completed).length;
    final pending = orders.where((o) => o.status == WorkStatus.pending).length;
    final inProgress = orders.where((o) => o.status == WorkStatus.inProgress).length;
    
    // Calculate completed this week
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final completedThisWeek = orders.where((o) {
      return o.status == WorkStatus.completed && 
             o.updatedAt != null && 
             o.updatedAt!.isAfter(startOfWeek);
    }).length;

    // Avg completion time for completed orders
    String avgTime = '---';
    final completedOrders = orders.where((o) => o.status == WorkStatus.completed && o.updatedAt != null && o.createdAt != null);
    if (completedOrders.isNotEmpty) {
      final totalMinutes = completedOrders.fold(0, (sum, o) => sum + o.updatedAt!.difference(o.createdAt!).inMinutes);
      final avgMinutes = totalMinutes / completedOrders.length;
      if (avgMinutes > 60) {
        avgTime = '${(avgMinutes / 60).toStringAsFixed(1)} Hrs';
      } else {
        avgTime = '${avgMinutes.toStringAsFixed(0)} Mins';
      }
    }
    
    return {
      'total': total,
      'completed': completed,
      'pending': pending,
      'inProgress': inProgress,
      'completedThisWeek': completedThisWeek,
      'avgResponseTime': avgTime,
    };
  });
});

final officeRepositoryProvider = Provider((ref) {
  return OfficeRepository(Supabase.instance.client);
});

final officesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(officeRepositoryProvider);
  return repo.getOffices();
});

final officeSearchQueryProvider = StateProvider<String>((ref) => '');
final officeSortProvider = StateProvider<String>((ref) => 'Default'); // Default, Revenue, Workload

final filteredOfficesProvider = Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final officesAsync = ref.watch(officesProvider);
  final query = ref.watch(officeSearchQueryProvider).toLowerCase();
  final sort = ref.watch(officeSortProvider);

  return officesAsync.whenData((offices) {
    var filtered = offices.where((office) {
      final name = (office['name'] as String? ?? '').toLowerCase();
      final location = (office['location'] as String? ?? '').toLowerCase();
      return name.contains(query) || location.contains(query);
    }).toList();

    if (sort == 'Revenue') {
      filtered.sort((a, b) => (b['revenue'] as num).compareTo(a['revenue'] as num));
    } else if (sort == 'Workload') {
      filtered.sort((a, b) => (b['workload_percentage'] as num).compareTo(a['workload_percentage'] as num));
    }

    return filtered;
  });
});

final adminSearchQueryProvider = StateProvider<String>((ref) => '');
final adminRoleFilterProvider = StateProvider<String>((ref) => 'All'); // All, Admin, Manager
final adminOfficeFilterProvider = StateProvider<String>((ref) => 'All Offices');

final filteredAdminsProvider = Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final profilesAsync = ref.watch(allProfilesProvider);
  final query = ref.watch(adminSearchQueryProvider).toLowerCase();
  final roleFilter = ref.watch(adminRoleFilterProvider);

  return profilesAsync.whenData((profiles) {
    return profiles.where((p) {
      if ((p['role'] as String? ?? '').toLowerCase() == 'staff') return false; // Only admins
      if (!(p['is_active'] as bool? ?? true)) return false; // Only active
      
      final name = (p['name'] as String? ?? '').toLowerCase();
      final email = (p['email'] as String? ?? '').toLowerCase();
      final matchesSearch = name.contains(query) || email.contains(query);
      
      final role = (p['role'] as String? ?? '').toLowerCase();
      
      final matchesRole = roleFilter == 'All' || 
                          (roleFilter == 'Super Admin' && role == 'super_admin') ||
                          (roleFilter == 'Admin' && role == 'admin');

      return matchesSearch && matchesRole;
    }).toList();
  });
});

final staffSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredStaffProvider = Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final profilesAsync = ref.watch(allProfilesProvider);
  final query = ref.watch(staffSearchQueryProvider).toLowerCase();

  return profilesAsync.whenData((profiles) {
    return profiles.where((p) {
      if ((p['role'] as String? ?? '').toLowerCase() != 'staff') return false; // Only staff
      if (!(p['is_active'] as bool? ?? true)) return false; // Only active
      
      final name = (p['name'] as String? ?? '').toLowerCase();
      final email = (p['email'] as String? ?? '').toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  });
});


final taskHistoryProvider = FutureProvider.family<List<TaskHistory>, String>((ref, taskId) async {
  final repo = ref.watch(workOrderRepositoryProvider);
  return repo.getTaskHistory(taskId);
});
