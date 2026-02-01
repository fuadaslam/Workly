import 'package:supabase_flutter/supabase_flutter.dart';

class OfficeRepository {
  final SupabaseClient _client;

  OfficeRepository(this._client);

  Future<List<Map<String, dynamic>>> getOffices() async {
    final response = await _client.from('offices').select().order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addOffice(Map<String, dynamic> officeData) async {
    await _client.from('offices').insert(officeData);
  }

  Future<void> updateOffice(String id, Map<String, dynamic> updates) async {
    await _client.from('offices').update(updates).eq('id', id);
  }

  Future<void> deleteOffice(String id) async {
    await _client.from('offices').delete().eq('id', id);
  }
}
