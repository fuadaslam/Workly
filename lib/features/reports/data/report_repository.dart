import 'package:supabase_flutter/supabase_flutter.dart';

class ReportFilters {
  // Work Order filters
  final List<String> woStatuses;
  final List<String> woPriorities;
  final List<String> woServiceTypes;
  final List<String> woStaffIds;

  // Enquiry filters
  final List<String> eqFinalStatuses;
  final List<String> eqClientStatuses;
  final List<String> eqServiceTypes;
  final List<String> eqNationalities;
  final List<String> eqStaffIds;

  const ReportFilters({
    this.woStatuses = const [],
    this.woPriorities = const [],
    this.woServiceTypes = const [],
    this.woStaffIds = const [],
    this.eqFinalStatuses = const [],
    this.eqClientStatuses = const [],
    this.eqServiceTypes = const [],
    this.eqNationalities = const [],
    this.eqStaffIds = const [],
  });

  bool get hasWorkOrderFilters =>
      woStatuses.isNotEmpty || woPriorities.isNotEmpty ||
      woServiceTypes.isNotEmpty || woStaffIds.isNotEmpty;

  bool get hasEnquiryFilters =>
      eqFinalStatuses.isNotEmpty || eqClientStatuses.isNotEmpty ||
      eqServiceTypes.isNotEmpty || eqNationalities.isNotEmpty || eqStaffIds.isNotEmpty;

  int get activeCount =>
      woStatuses.length + woPriorities.length + woServiceTypes.length + woStaffIds.length +
      eqFinalStatuses.length + eqClientStatuses.length + eqServiceTypes.length +
      eqNationalities.length + eqStaffIds.length;

  ReportFilters copyWith({
    List<String>? woStatuses, List<String>? woPriorities,
    List<String>? woServiceTypes, List<String>? woStaffIds,
    List<String>? eqFinalStatuses, List<String>? eqClientStatuses,
    List<String>? eqServiceTypes, List<String>? eqNationalities,
    List<String>? eqStaffIds,
  }) => ReportFilters(
    woStatuses: woStatuses ?? this.woStatuses,
    woPriorities: woPriorities ?? this.woPriorities,
    woServiceTypes: woServiceTypes ?? this.woServiceTypes,
    woStaffIds: woStaffIds ?? this.woStaffIds,
    eqFinalStatuses: eqFinalStatuses ?? this.eqFinalStatuses,
    eqClientStatuses: eqClientStatuses ?? this.eqClientStatuses,
    eqServiceTypes: eqServiceTypes ?? this.eqServiceTypes,
    eqNationalities: eqNationalities ?? this.eqNationalities,
    eqStaffIds: eqStaffIds ?? this.eqStaffIds,
  );

  ReportFilters clearAll() => const ReportFilters();
}

class ReportRepository {
  final SupabaseClient _client;
  ReportRepository(this._client);

  Future<List<Map<String, dynamic>>> getWorkOrdersInRange(
    DateTime from, DateTime to, {
    ReportFilters filters = const ReportFilters(),
  }) async {
    var query = _client
        .from('work_orders')
        .select('*, offices(name), profiles:assigned_staff_id(name,id), agent_profiles:agent_id(name), payments(total_amount,paid_amount,status)')
        .gte('created_at', from.toIso8601String())
        .lte('created_at', to.toIso8601String());

    if (filters.woStatuses.isNotEmpty) {
      query = query.inFilter('status', filters.woStatuses);
    }
    if (filters.woPriorities.isNotEmpty) {
      query = query.inFilter('priority', filters.woPriorities);
    }
    if (filters.woServiceTypes.isNotEmpty) {
      query = query.inFilter('service_type', filters.woServiceTypes);
    }
    if (filters.woStaffIds.isNotEmpty) {
      query = query.inFilter('assigned_staff_id', filters.woStaffIds);
    }

    final response = await query.order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<List<Map<String, dynamic>>> getEnquiriesInRange(
    DateTime from, DateTime to, {
    ReportFilters filters = const ReportFilters(),
  }) async {
    var query = _client
        .from('enquiries')
        .select('*, profiles:responsible_staff_id(name,id)')
        .gte('created_at', from.toIso8601String())
        .lte('created_at', to.toIso8601String());

    if (filters.eqFinalStatuses.isNotEmpty) {
      query = query.inFilter('final_status', filters.eqFinalStatuses);
    }
    if (filters.eqClientStatuses.isNotEmpty) {
      query = query.inFilter('client_status', filters.eqClientStatuses);
    }
    if (filters.eqServiceTypes.isNotEmpty) {
      query = query.inFilter('nature_of_enquiry', filters.eqServiceTypes);
    }
    if (filters.eqNationalities.isNotEmpty) {
      query = query.inFilter('nationality', filters.eqNationalities);
    }
    if (filters.eqStaffIds.isNotEmpty) {
      query = query.inFilter('responsible_staff_id', filters.eqStaffIds);
    }

    final response = await query.order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<List<Map<String, dynamic>>> getAttendanceInRange(
      DateTime from, DateTime to) async {
    try {
      final response = await _client
          .from('attendance')
          .select('*, profiles(name, role)')
          .gte('date', from.toIso8601String().split('T').first)
          .lte('date', to.toIso8601String().split('T').first)
          .order('date', ascending: true);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (_) {
      return [];
    }
  }

  // Fetch live filter option lists from DB
  Future<Map<String, List<Map<String, String>>>> getFilterOptions() async {
    final results = await Future.wait([
      _client.from('work_orders').select('status').order('status'),
      _client.from('work_orders').select('priority').order('priority'),
      _client.from('work_orders').select('service_type').not('service_type', 'is', null).order('service_type'),
      _client.from('enquiries').select('final_status').order('final_status'),
      _client.from('enquiries').select('nature_of_enquiry').not('nature_of_enquiry', 'is', null).order('nature_of_enquiry'),
      _client.from('enquiries').select('nationality').not('nationality', 'is', null).order('nationality'),
      _client.from('profiles').select('id, name').inFilter('role', ['staff', 'admin', 'super_admin']).order('name'),
    ]);

    Set<String> distinct(List<dynamic> rows, String key) =>
        rows.map((r) => r[key]?.toString() ?? '').where((v) => v.isNotEmpty).toSet();

    final woStatuses = distinct(results[0] as List, 'status').map((v) => {'label': v, 'value': v}).toList();
    final woPriorities = distinct(results[1] as List, 'priority').map((v) => {'label': v, 'value': v}).toList();
    final woServices = distinct(results[2] as List, 'service_type').map((v) => {'label': v, 'value': v}).toList();
    final eqStatuses = distinct(results[3] as List, 'final_status').map((v) => {'label': v, 'value': v}).toList();
    final eqServices = distinct(results[4] as List, 'nature_of_enquiry').map((v) => {'label': v, 'value': v}).toList();
    final eqNationalities = distinct(results[5] as List, 'nationality').map((v) => {'label': v, 'value': v}).toList();
    final staff = (results[6] as List).map((r) => {'label': r['name']?.toString() ?? '', 'value': r['id']?.toString() ?? ''}).where((r) => r['label']!.isNotEmpty).toList();

    return {
      'woStatuses': woStatuses,
      'woPriorities': woPriorities,
      'woServices': woServices,
      'eqStatuses': eqStatuses,
      'eqServices': eqServices,
      'eqNationalities': eqNationalities,
      'staff': staff,
    };
  }
}
