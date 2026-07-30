import 'package:supabase_flutter/supabase_flutter.dart';

// Every insert/update across the app calls fetchCallerOrgId, which used to
// hit `profiles` fresh every time. Memoize per user and clear on any auth
// state change (sign-out/sign-in) so a stale org_id can never survive a
// session switch.
String? _cachedUserId;
String? _cachedOrgId;
bool _authListenerRegistered = false;

/// Fetches the org_id of the currently authenticated user from their profile.
/// Throws if the user is not authenticated or has no organisation assigned.
Future<String> fetchCallerOrgId(SupabaseClient client) async {
  final userId = client.auth.currentUser?.id;
  if (userId == null) throw Exception('Not authenticated');

  if (!_authListenerRegistered) {
    _authListenerRegistered = true;
    client.auth.onAuthStateChange.listen((_) {
      _cachedUserId = null;
      _cachedOrgId = null;
    });
  }

  if (_cachedUserId == userId && _cachedOrgId != null) {
    return _cachedOrgId!;
  }

  final profile = await client
      .from('profiles')
      .select('org_id')
      .eq('id', userId)
      .single();
  final orgId = profile['org_id'] as String?;
  if (orgId == null) {
    throw Exception('Your account is not linked to an organisation.');
  }
  _cachedUserId = userId;
  _cachedOrgId = orgId;
  return orgId;
}

/// Clears the cached caller organization ID.
/// Call this when a user updates their profile or switches workspace context.
void clearCallerOrgIdCache() {
  _cachedUserId = null;
  _cachedOrgId = null;
}

