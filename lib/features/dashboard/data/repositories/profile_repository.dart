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

  Future<void> createProfile(Map<String, dynamic> data) async {
    // Note: This assumes the auth user is already created or we are just creating a profile record.
    // In a real app, you would create the auth user first.
    // If we just insert into profiles, it might fail if there's a foreign key constraint to auth.users.
    // However, we will try to insert. If 'id' is required and must match auth.users, this will fail without a valid UUID.
    // For this task, we will try to let the database handle it or assuming a trigger.
    // If not, we might need to use a random UUID if the constraint is not enforced (unlikely).
    await _client.from('profiles').insert(data);
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
