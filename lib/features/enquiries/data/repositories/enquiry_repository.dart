import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/enquiry.dart';

class EnquiryRepository {
  final SupabaseClient _client;

  EnquiryRepository(this._client);

  Future<List<Enquiry>> getAllEnquiries() async {
    final response = await _client
        .from('enquiries')
        .select('*, profiles:responsible_staff_id(name)')
        .order('created_at', ascending: false)
        .limit(200);
    return (response as List).map((j) => Enquiry.fromJson(j)).toList();
  }

  Future<List<Enquiry>> getEnquiriesByStaff(String staffId) async {
    final response = await _client
        .from('enquiries')
        .select('*, profiles:responsible_staff_id(name)')
        .eq('responsible_staff_id', staffId)
        .order('created_at', ascending: false);
    return (response as List).map((j) => Enquiry.fromJson(j)).toList();
  }

  Future<Enquiry> createEnquiry(Map<String, dynamic> data) async {
    final response = await _client
        .from('enquiries')
        .insert(data)
        .select('*, profiles:responsible_staff_id(name)')
        .single();
    return Enquiry.fromJson(response);
  }

  Future<Enquiry> updateEnquiry(String id, Map<String, dynamic> data) async {
    final response = await _client
        .from('enquiries')
        .update(data)
        .eq('id', id)
        .select('*, profiles:responsible_staff_id(name)')
        .single();
    return Enquiry.fromJson(response);
  }

  Future<void> deleteEnquiry(String id) async {
    await _client.from('enquiries').delete().eq('id', id);
  }

  Future<Map<String, dynamic>> getSummaryStats() async {
    final all = await getAllEnquiries();
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
