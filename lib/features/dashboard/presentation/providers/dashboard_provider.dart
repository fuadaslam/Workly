import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/work_order_repository.dart';
import '../../data/repositories/office_repository.dart';
import '../../domain/models/work_order.dart';
import '../../domain/models/task_history.dart';
import '../../domain/models/task_document.dart';
import '../../../attendance/data/attendance_repository.dart';

import '../../data/repositories/profile_repository.dart';
import '../../../../core/pagination/pagination_state.dart';

final supabaseClientProvider = Provider((ref) => Supabase.instance.client);

// Dashboard date range filter — null means "all time"
final dashboardDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

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

final paginatedClientWorkOrdersProvider = StateNotifierProvider.family<PaginationNotifier<WorkOrder>, PaginationState<WorkOrder>, String>((ref, clientName) {
  final repository = ref.watch(workOrderRepositoryProvider);
  return PaginationNotifier<WorkOrder>(
    fetchItems: (offset, limit) async {
      return await repository.getPaginatedWorkOrders(
        page: offset ~/ limit,
        pageSize: limit,
        clientName: clientName,
      );
    },
    limit: 20,
  );
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
  final dateRange = ref.watch(dashboardDateRangeProvider);

  var query = client.from('payments').select('total_amount, paid_amount, status, created_at, work_orders(client_name, service_type)');
  if (dateRange != null) {
    query = query
        .gte('created_at', dateRange.start.toIso8601String())
        .lt('created_at', dateRange.end.add(const Duration(days: 1)).toIso8601String());
  }
  final response = await query;
  
  double totalReceivables = 0;
  double cashCollected = 0;
  List<Map<String, dynamic>> logs = [];
  
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

  Map<String, List<Duration>> staffDurations = {};
  Map<String, String> staffNames = {};

  for (var order in response) {
    if (order['assigned_staff_id'] == null) continue;
    final staffId = order['assigned_staff_id'] as String;
    staffNames[staffId] = order['profiles']?['name'] ?? 'Unknown';

    if (order['created_at'] == null || order['updated_at'] == null) continue;
    final created = DateTime.parse(order['created_at'] as String);
    final updated = DateTime.parse(order['updated_at'] as String);
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

final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(workOrderRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  
  // Fetch counts efficiently from the server
  final stats = await repo.getWorkOrderStats(staffId: userId);

  // Note: For 'completedThisWeek' and 'avgResponseTime', we still calculate based on recent orders
  // as a 'Recent Performance' metric. In a full production app, this should be an RPC call.
  // For now, we take from the paginated list which gives us the 'latest' trends.
  final recentOrders = await ref.watch(myWorkOrdersProvider.future);
  
  // Calculate completed this week from recent orders
  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final completedThisWeek = recentOrders.where((o) {
    return o.status == WorkStatus.completed && 
           o.updatedAt != null && 
           o.updatedAt!.isAfter(startOfWeek);
  }).length;

  // Avg completion time for recently completed orders
  String avgTime = '---';
  final completedOrders = recentOrders.where((o) => o.status == WorkStatus.completed && o.updatedAt != null && o.createdAt != null);
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
    'total': stats['total'] ?? 0,
    'completed': stats['completed'] ?? 0,
    'pending': stats['pending'] ?? 0,
    'inProgress': stats['inProgress'] ?? 0,
    'completedThisWeek': completedThisWeek,
    'avgResponseTime': avgTime,
  };
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
      filtered.sort((a, b) => ((b['revenue'] as num?) ?? 0).compareTo((a['revenue'] as num?) ?? 0));
    } else if (sort == 'Workload') {
      filtered.sort((a, b) => ((b['workload_percentage'] as num?) ?? 0).compareTo((a['workload_percentage'] as num?) ?? 0));
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

final agentSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredAgentsProvider = Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final profilesAsync = ref.watch(allProfilesProvider);
  final query = ref.watch(agentSearchQueryProvider).toLowerCase();

  return profilesAsync.whenData((profiles) {
    return profiles.where((p) {
      if ((p['role'] as String? ?? '').toLowerCase() != 'agent') return false; 
      if (!(p['is_active'] as bool? ?? true)) return false; 
      
      final name = (p['name'] as String? ?? '').toLowerCase();
      final email = (p['email'] as String? ?? '').toLowerCase();
      final phoneNumber = (p['phone_number'] as String? ?? '').toLowerCase();
      
      return name.contains(query) || email.contains(query) || phoneNumber.contains(query);
    }).toList();
  });
});


final taskHistoryProvider = FutureProvider.family<List<TaskHistory>, String>((ref, taskId) async {
  final repo = ref.watch(workOrderRepositoryProvider);
  return repo.getTaskHistory(taskId);
});

final taskDocumentsProvider = FutureProvider.family<List<TaskDocument>, String>((ref, taskId) async {
  final repo = ref.watch(workOrderRepositoryProvider);
  return repo.getTaskDocuments(taskId);
});

final activeWorkOrdersProvider = FutureProvider<List<WorkOrder>>((ref) async {
  final client = Supabase.instance.client;
  final response = await client
      .from('work_orders')
      .select('*, offices(name), profiles:assigned_staff_id(name, offices(name)), agent_profiles:agent_id(name)')
      .inFilter('status', ['Pending', 'In-Progress'])
      .order('created_at', ascending: false);
  return (response as List).map((json) => WorkOrder.fromJson(json)).toList();
});

final activeCasesCountProvider = FutureProvider<int>((ref) async {
  final client = Supabase.instance.client;
  final response = await client
      .from('work_orders')
      .select('id')
      .inFilter('status', ['Pending', 'In-Progress'])
      .count(CountOption.exact);
  return response.count;
});

final pendingApprovalsCountProvider = FutureProvider<int>((ref) async {
  final client = Supabase.instance.client;
  final response = await client
      .from('work_orders')
      .select('id')
      .eq('status', 'Pending')
      .count(CountOption.exact);
  return response.count;
});

/// Work order counts per month for the last 6 months (index 0 = oldest, 5 = current).
final monthlyWorkOrderTrendProvider = FutureProvider<List<double>>((ref) async {
  final client = Supabase.instance.client;
  final now = DateTime.now();
  final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
  final response = await client
      .from('work_orders')
      .select('created_at')
      .gte('created_at', sixMonthsAgo.toIso8601String());
  final counts = List.filled(6, 0.0);
  for (final order in response) {
    final created = DateTime.tryParse(order['created_at'] as String? ?? '');
    if (created == null) continue;
    final monthsAgo = (now.year - created.year) * 12 + (now.month - created.month);
    if (monthsAgo >= 0 && monthsAgo < 6) counts[5 - monthsAgo]++;
  }
  return counts;
});

/// Completion rate per service type (top 4 by volume).
final serviceTypeKpiProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = Supabase.instance.client;
  final response = await client.from('work_orders').select('service_type, status');
  final Map<String, Map<String, int>> byType = {};
  for (final order in response) {
    final raw = (order['service_type'] as String?)?.trim() ?? '';
    final type = raw.isEmpty ? 'Other' : raw;
    byType.putIfAbsent(type, () => {'total': 0, 'completed': 0});
    byType[type]!['total'] = (byType[type]!['total'] ?? 0) + 1;
    if ((order['status'] as String? ?? '') == 'Completed') {
      byType[type]!['completed'] = (byType[type]!['completed'] ?? 0) + 1;
    }
  }
  final result = byType.entries.map((e) {
    final label = e.key.length > 7 ? e.key.substring(0, 7).toUpperCase() : e.key.toUpperCase();
    final percent = e.value['total']! > 0
        ? (e.value['completed']! / e.value['total']!).clamp(0.0, 1.0)
        : 0.0;
    return {'label': label, 'fullLabel': e.key, 'percent': percent, 'total': e.value['total']!};
  }).toList()
    ..sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));
  return result.take(4).toList();
});

/// Last 5 recently updated work orders for the activity feed.
final recentActivityProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = Supabase.instance.client;
  final response = await client
      .from('work_orders')
      .select('client_name, service_type, status, updated_at, profiles!assigned_staff_id(name)')
      .order('updated_at', ascending: false)
      .limit(5);
  return (response as List).map<Map<String, dynamic>>((order) {
    final staffName = (order['profiles'] as Map?)?['name'] as String? ?? 'Staff';
    final service = (order['service_type'] as String?) ?? 'task';
    final clientName = (order['client_name'] as String?) ?? '';
    final status = (order['status'] as String?) ?? '';
    final action = clientName.isNotEmpty
        ? 'updated "$service" for $clientName → $status'
        : 'updated "$service" → $status';
    return {'name': staffName, 'action': action, 'time': order['updated_at'] as String?};
  }).toList();
});

/// Active task count per staff member: Map<staffId, count>
final staffActiveTaskCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  final client = Supabase.instance.client;
  final response = await client
      .from('work_orders')
      .select('assigned_staff_id')
      .inFilter('status', ['Pending', 'In-Progress']);
  final Map<String, int> counts = {};
  for (final row in response) {
    final id = row['assigned_staff_id'] as String?;
    if (id != null) counts[id] = (counts[id] ?? 0) + 1;
  }
  return counts;
});

final workOrderByIdProvider = FutureProvider.family<WorkOrder?, String>((ref, id) async {
  final client = Supabase.instance.client;
  final response = await client
      .from('work_orders')
      .select('*, offices(name), profiles:assigned_staff_id(name, offices(name)), agent_profiles:agent_id(name)')
      .eq('id', id)
      .maybeSingle();
      
  if (response == null) return null;
  return WorkOrder.fromJson(response);
});
