import 'package:supabase_flutter/supabase_flutter.dart';

/// Fetches the org_id of the currently authenticated user from their profile.
/// Throws if the user is not authenticated or has no organisation assigned.
Future<String> fetchCallerOrgId(SupabaseClient client) async {
  final userId = client.auth.currentUser?.id;
  if (userId == null) throw Exception('Not authenticated');
  final profile = await client
      .from('profiles')
      .select('org_id')
      .eq('id', userId)
      .single();
  final orgId = profile['org_id'] as String?;
  if (orgId == null) {
    throw Exception('Your account is not linked to an organisation.');
  }
  return orgId;
}
