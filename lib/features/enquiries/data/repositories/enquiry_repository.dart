import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/supabase_org_utils.dart';
import '../../domain/models/enquiry.dart';

class EnquiryRepository {
  final SupabaseClient _client;

  EnquiryRepository(this._client);

  Future<List<Enquiry>> getAllEnquiries() async {
    final response = await _client
        .from('enquiries')
        .select('*, profiles:responsible_staff_id(name), offices:assigned_office_id(name)')
        .order('created_at', ascending: false)
        .limit(200);
    return (response as List).map((j) => Enquiry.fromJson(j)).toList();
  }

  Future<List<Enquiry>> getPaginatedEnquiries({
    required int offset,
    required int limit,
    String? status,
    String? service,
    String searchQuery = '',
    bool? converted,
  }) async {
    var query = _client.from('enquiries').select('*, profiles:responsible_staff_id(name), offices:assigned_office_id(name)');

    if (status != null && status.isNotEmpty) {
      query = query.eq('final_status', status);
    }
    if (service != null && service.isNotEmpty) {
      query = query.eq('nature_of_enquiry', service);
    }
    if (converted == true) {
      query = query.not('work_order_id', 'is', null);
    } else if (converted == false) {
      query = query.isFilter('work_order_id', null);
    }
    if (searchQuery.isNotEmpty) {
      // ',' and '(' / ')' are structural in PostgREST's or() filter grammar —
      // strip them so a search term containing one can't break the filter
      // (or silently change which conditions get OR'd together).
      final safeQuery = searchQuery.replaceAll(RegExp(r'[,()]'), '');
      if (safeQuery.isNotEmpty) {
        query = query.or('client_name.ilike.%$safeQuery%,enquiry_code.ilike.%$safeQuery%,contact_number.ilike.%$safeQuery%');
      }
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List).map((j) => Enquiry.fromJson(j)).toList();
  }

  Future<List<Enquiry>> getEnquiriesByStaff(String staffId) async {
    final response = await _client
        .from('enquiries')
        .select('*, profiles:responsible_staff_id(name), offices:assigned_office_id(name)')
        .eq('responsible_staff_id', staffId)
        .order('created_at', ascending: false);
    return (response as List).map((j) => Enquiry.fromJson(j)).toList();
  }

  Future<Enquiry> createEnquiry(Map<String, dynamic> data) async {
    final orgId = await fetchCallerOrgId(_client);
    final response = await _client
        .from('enquiries')
        .insert({...data, 'org_id': orgId})
        .select('*, profiles:responsible_staff_id(name), offices:assigned_office_id(name)')
        .single();
    return Enquiry.fromJson(response);
  }

  Future<Enquiry> updateEnquiry(String id, Map<String, dynamic> data) async {
    final response = await _client
        .from('enquiries')
        .update(data)
        .eq('id', id)
        .select('*, profiles:responsible_staff_id(name), offices:assigned_office_id(name)')
        .single();
    return Enquiry.fromJson(response);
  }

  Future<void> deleteEnquiry(String id) async {
    await _client.from('enquiries').delete().eq('id', id);
  }

  /// Converts an accepted enquiry into a work order (server-enforced) and
  /// returns the new work order's id. Carries over client/service/office/staff
  /// and the agreed amount, and links both records.
  Future<String> convertToWorkOrder(String enquiryId) async {
    final res = await _client.rpc('convert_enquiry_to_work_order', params: {
      'p_enquiry_id': enquiryId,
    });
    return res as String;
  }

  /// Assignment / transfer update that intentionally does NOT read the row
  /// back. When a staff member transfers an enquiry away from themselves they
  /// can no longer SELECT it (RLS), so a `.select().single()` would throw even
  /// though the write committed. The caller updates local state optimistically.
  Future<void> assignEnquiry(String id, Map<String, dynamic> data) async {
    await _client.from('enquiries').update(data).eq('id', id);
  }

  /// Fetches every enquiry in batches, for stats aggregation. Unlike
  /// [getAllEnquiries] (capped at 200 for the list view), this must see the
  /// whole table or totals/rates silently become wrong once the org has
  /// more than one page of enquiries.
  Future<List<Enquiry>> _getAllEnquiriesForStats() async {
    const batchSize = 1000;
    final all = <Enquiry>[];
    var offset = 0;
    while (true) {
      final response = await _client
          .from('enquiries')
          .select('*, profiles:responsible_staff_id(name), offices:assigned_office_id(name)')
          .order('created_at', ascending: false)
          .range(offset, offset + batchSize - 1);
      final batch = (response as List).map((j) => Enquiry.fromJson(j)).toList();
      all.addAll(batch);
      if (batch.length < batchSize) break;
      offset += batchSize;
    }
    return all;
  }

  Future<Map<String, dynamic>> getSummaryStats() async {
    final all = await _getAllEnquiriesForStats();
    final total = all.length;
    final accepted = all.where((e) => e.clientStatus == ClientStatus.accepted).length;
    final rejected = all.where((e) => e.clientStatus == ClientStatus.rejected).length;
    final settled = all.where((e) =>
        e.finalStatus == EnquiryFinalStatus.settled ||
        e.finalStatus == EnquiryFinalStatus.executed).length;
    final inProgress = all.where((e) => e.finalStatus == EnquiryFinalStatus.inProgress).length;

    final settledEnquiries = all.where((e) =>
        e.finalStatus == EnquiryFinalStatus.settled ||
        e.finalStatus == EnquiryFinalStatus.executed);
    final avgDays = settledEnquiries.isEmpty
        ? 0.0
        : settledEnquiries.map((e) => e.daysOpen).reduce((a, b) => a + b) / settledEnquiries.length;
    final totalRevenue = settledEnquiries.fold<double>(
        0, (sum, e) => sum + (e.finalAgreedServiceCharge ?? e.totalOffered));

    // By service type
    final Map<String, int> byService = {};
    for (final e in all) {
      if (e.natureOfEnquiry != null) {
        byService[e.natureOfEnquiry!] = (byService[e.natureOfEnquiry!] ?? 0) + 1;
      }
    }

    // By staff
    final Map<String, Map<String, dynamic>> byStaff = {};
    for (final e in all) {
      if (e.responsibleStaffName != null) {
        final name = e.responsibleStaffName!;
        byStaff[name] ??= {'count': 0, 'totalDays': 0, 'settled': 0};
        byStaff[name]!['count'] = (byStaff[name]!['count'] as int) + 1;
        if (e.finalStatus == EnquiryFinalStatus.settled ||
            e.finalStatus == EnquiryFinalStatus.executed) {
          byStaff[name]!['settled'] = (byStaff[name]!['settled'] as int) + 1;
          byStaff[name]!['totalDays'] = (byStaff[name]!['totalDays'] as int) + e.daysOpen;
        }
      }
    }

    return {
      'total': total,
      'accepted': accepted,
      'rejected': rejected,
      'settled': settled,
      'inProgress': inProgress,
      'conversionRate': total > 0 ? accepted / total : 0.0,
      'avgDaysToSettle': avgDays,
      'totalRevenue': totalRevenue,
      'byService': byService,
      'byStaff': byStaff,
    };
  }
}
