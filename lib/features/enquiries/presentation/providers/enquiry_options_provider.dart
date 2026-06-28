import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/enquiry_options_repository.dart';
import '../../domain/models/enquiry.dart';
import '../../../../features/dashboard/presentation/providers/dashboard_provider.dart';

final enquiryOptionsRepositoryProvider = Provider((ref) {
  return EnquiryOptionsRepository(ref.watch(supabaseClientProvider));
});

/// Built-in defaults used as a fallback when an org has not configured a list.
List<String> defaultEnquiryOptions(String category) {
  switch (category) {
    case EnquiryOptionCategory.nature:
      return kNatureOfEnquiry;
    case EnquiryOptionCategory.nationality:
      return kNationalities;
    case EnquiryOptionCategory.rejectionReason:
      return kRejectionReasons;
    default:
      return const [];
  }
}

/// Active option VALUES for a category (what forms display), with a fallback to
/// the built-in defaults if the org hasn't configured any active options.
final enquiryOptionValuesProvider =
    FutureProvider.family<List<String>, String>((ref, category) async {
  final rows = await ref.watch(enquiryOptionsRepositoryProvider).getOptions(category);
  final active = rows.where((r) => r.isActive).map((r) => r.value).toList();
  return active.isNotEmpty ? active : defaultEnquiryOptions(category);
});

/// Full rows (including inactive) for the admin setup screen.
final enquiryOptionRowsProvider =
    FutureProvider.family<List<EnquiryOption>, String>((ref, category) async {
  return ref.watch(enquiryOptionsRepositoryProvider).getOptions(category);
});

/// Active option objects (value + subtitle) for the form, with a fallback to
/// built-in defaults (no subtitle) when the org hasn't configured any.
final activeEnquiryOptionsProvider =
    FutureProvider.family<List<EnquiryOption>, String>((ref, category) async {
  final rows = await ref.watch(enquiryOptionsRepositoryProvider).getOptions(category);
  final active = rows.where((r) => r.isActive).toList();
  if (active.isNotEmpty) return active;
  return defaultEnquiryOptions(category)
      .asMap()
      .entries
      .map((e) => EnquiryOption(id: 'default_${e.key}', value: e.value, isActive: true, sortOrder: e.key))
      .toList();
});

/// Whether a dropdown field (nature / nationality / …) is required in the
/// New Enquiry form for this org.
final enquiryFieldRequiredProvider =
    FutureProvider.family<bool, String>((ref, category) async {
  return ref.watch(enquiryOptionsRepositoryProvider).getFieldRequired(category);
});
