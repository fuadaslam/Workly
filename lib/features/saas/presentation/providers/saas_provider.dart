import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/saas_repository.dart';
import '../../domain/models/organization.dart';
import '../../../../features/dashboard/presentation/providers/dashboard_provider.dart';

final saasRepositoryProvider = Provider((ref) {
  return SaasRepository(ref.watch(supabaseClientProvider));
});

final allOrganizationsProvider = FutureProvider<List<Organization>>((ref) async {
  return ref.watch(saasRepositoryProvider).getAllOrganizations();
});

final platformStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(saasRepositoryProvider).getPlatformStats();
});

final orgPlansProvider = FutureProvider<List<OrgPlan>>((ref) async {
  return ref.watch(saasRepositoryProvider).getPlans();
});

final orgMembersProvider = FutureProvider.family<List<OrgMember>, String>((ref, orgId) async {
  return ref.watch(saasRepositoryProvider).getOrgMembers(orgId);
});

final orgInvitationsProvider = FutureProvider.family<List<OrgInvitation>, String>((ref, orgId) async {
  return ref.watch(saasRepositoryProvider).getInvitations(orgId);
});
