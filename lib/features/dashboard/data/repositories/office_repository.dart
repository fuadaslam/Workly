import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/supabase_org_utils.dart';

class OfficeRepository {
  final SupabaseClient _client;

  OfficeRepository(this._client);

  Future<List<Map<String, dynamic>>> getOffices() async {
    // staff_count / revenue / workload_percentage are stale stored columns
    // (only ever set to 0 at creation). Derive them live via the
    // get_office_metrics RPC: staff from profiles.office_id, revenue from
    // collected payments, workload% from active vs. total work orders.
    final response = await _client.from('offices').select().order('created_at');
    final offices = List<Map<String, dynamic>>.from(response);

    Map<String, Map<String, dynamic>> metrics = {};
    try {
      final rows = await _client.rpc('get_office_metrics') as List;
      metrics = {
        for (final r in rows)
          (r as Map)['office_id'] as String: Map<String, dynamic>.from(r),
      };
    } catch (_) {
      // If the RPC is unavailable, fall back to whatever the table holds
      // rather than failing the whole offices screen.
    }

    for (final office in offices) {
      final m = metrics[office['id']];
      office['staff_count'] = (m?['staff_count'] as num?)?.toInt() ?? 0;
      office['revenue'] = (m?['revenue'] as num?) ?? office['revenue'] ?? 0;
      office['workload_percentage'] =
          (m?['workload_percentage'] as num?)?.toInt() ?? 0;
      office['active_work_orders'] = (m?['active_work_orders'] as num?)?.toInt() ?? 0;
    }
    return offices;
  }

  Future<void> addOffice(Map<String, dynamic> officeData) async {
    final orgId = await fetchCallerOrgId(_client);
    await _client.from('offices').insert({...officeData, 'org_id': orgId});
  }

  Future<void> updateOffice(String id, Map<String, dynamic> updates) async {
    await _client.from('offices').update(updates).eq('id', id);
  }

  Future<void> deleteOffice(String id) async {
    await _client.from('offices').delete().eq('id', id);
  }
}
