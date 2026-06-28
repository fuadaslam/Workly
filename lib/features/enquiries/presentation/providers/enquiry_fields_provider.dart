import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/enquiry_fields_repository.dart';
import '../../../../features/dashboard/presentation/providers/dashboard_provider.dart';

final enquiryFieldsRepositoryProvider = Provider((ref) {
  return EnquiryFieldsRepository(ref.watch(supabaseClientProvider));
});

/// All custom field definitions (admin editor uses this).
final enquiryFieldRowsProvider = FutureProvider<List<EnquiryField>>((ref) async {
  return ref.watch(enquiryFieldsRepositoryProvider).getFields();
});

/// Only the active fields, for rendering the enquiry form.
final activeEnquiryFieldsProvider = FutureProvider<List<EnquiryField>>((ref) async {
  final all = await ref.watch(enquiryFieldsRepositoryProvider).getFields();
  return all.where((f) => f.isActive).toList();
});
