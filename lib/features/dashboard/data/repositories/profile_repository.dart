import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  Future<List<Map<String, dynamic>>> getProfiles() async {
    final response = await _client
        .from('profiles')
        .select('*, offices(name)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateProfile(String id, Map<String, dynamic> updates) async {
    await _client.from('profiles').update(updates).eq('id', id);
  }

  Future<void> deleteProfile(String id) async {
    // Perform soft delete
    await _client.from('profiles').update({'is_active': false}).eq('id', id);
  }

  Future<void> reactivateProfile(String id) async {
    await _client.from('profiles').update({'is_active': true}).eq('id', id);
  }
}
