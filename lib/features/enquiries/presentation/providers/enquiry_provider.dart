import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/enquiry_repository.dart';
import '../../domain/models/enquiry.dart';
import '../../../../features/dashboard/presentation/providers/dashboard_provider.dart';
import '../../../../core/pagination/pagination_state.dart';
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
  final bool? converted; // null = all, true = converted, false = not converted

  const EnquiryFilter({this.status, this.staffId, this.service, this.searchQuery = '', this.converted});

  EnquiryFilter copyWith({String? status, String? staffId, String? service, String? searchQuery}) {
    return EnquiryFilter(
      status: status ?? this.status,
      staffId: staffId ?? this.staffId,
      service: service ?? this.service,
      searchQuery: searchQuery ?? this.searchQuery,
      converted: converted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnquiryFilter &&
          status == other.status &&
          staffId == other.staffId &&
          service == other.service &&
          searchQuery == other.searchQuery &&
          converted == other.converted;

  @override
  int get hashCode => Object.hash(status, staffId, service, searchQuery, converted);
}

final enquiryFilterProvider = StateProvider<EnquiryFilter>((ref) => const EnquiryFilter());

final paginatedEnquiriesProvider = StateNotifierProvider<PaginationNotifier<Enquiry>, PaginationState<Enquiry>>((ref) {
  final repository = ref.watch(enquiryRepositoryProvider);
  final filter = ref.watch(enquiryFilterProvider);

  return PaginationNotifier<Enquiry>(
    fetchItems: (offset, limit) async {
      return await repository.getPaginatedEnquiries(
        offset: offset,
        limit: limit,
        status: filter.status,
        service: filter.service,
        searchQuery: filter.searchQuery,
        converted: filter.converted,
      );
    },
    limit: 20,
  );
});
