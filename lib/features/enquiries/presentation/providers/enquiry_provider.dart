import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/enquiry_repository.dart';
import '../../domain/models/enquiry.dart';
import '../../../../features/dashboard/presentation/providers/dashboard_provider.dart';

final enquiryRepositoryProvider = Provider((ref) {
  return EnquiryRepository(ref.watch(supabaseClientProvider));
});

final allEnquiriesProvider = FutureProvider<List<Enquiry>>((ref) async {
  return ref.watch(enquiryRepositoryProvider).getAllEnquiries();
});

final enquirySummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(enquiryRepositoryProvider).getSummaryStats();
});

// Filter state
class EnquiryFilter {
  final String? status;
  final String? staffId;
  final String? service;
  final String searchQuery;

  const EnquiryFilter({this.status, this.staffId, this.service, this.searchQuery = ''});

  EnquiryFilter copyWith({String? status, String? staffId, String? service, String? searchQuery}) {
    return EnquiryFilter(
      status: status ?? this.status,
      staffId: staffId ?? this.staffId,
      service: service ?? this.service,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final enquiryFilterProvider = StateProvider<EnquiryFilter>((ref) => const EnquiryFilter());

final filteredEnquiriesProvider = Provider<AsyncValue<List<Enquiry>>>((ref) {
  final all = ref.watch(allEnquiriesProvider);
  final filter = ref.watch(enquiryFilterProvider);

  return all.whenData((list) {
    return list.where((e) {
      if (filter.status != null && filter.status!.isNotEmpty) {
        final statusStr = e.finalStatus.name;
        if (!statusStr.toLowerCase().contains(filter.status!.toLowerCase())) return false;
      }
      if (filter.service != null && filter.service!.isNotEmpty) {
        if (e.natureOfEnquiry != filter.service) return false;
      }
      if (filter.searchQuery.isNotEmpty) {
        final q = filter.searchQuery.toLowerCase();
        return (e.clientName?.toLowerCase().contains(q) ?? false) ||
            (e.contactNumber?.contains(q) ?? false) ||
            (e.enquiryCode.toLowerCase().contains(q));
      }
      return true;
    }).toList();
  });
});
