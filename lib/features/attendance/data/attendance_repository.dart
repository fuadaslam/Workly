import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/supabase_org_utils.dart';

class AttendanceRepository {
  final SupabaseClient _client;

  AttendanceRepository(this._client);

  Future<Map<String, dynamic>?> getCurrentSession(String userId) async {
    // maybeSingle() already returns null when there's no open session;
    // letting real failures (network/RLS) propagate lets the caller's
    // AsyncValue.error distinguish "no session" from "fetch failed".
    return await _client
        .from('attendance')
        .select()
        .eq('user_id', userId)
        .filter('check_out_time', 'is', null)
        .maybeSingle();
  }

  Future<void> checkIn(String userId, String? gpsLocation) async {
    final orgId = await fetchCallerOrgId(_client);
    await _client.from('attendance').insert({
      'user_id': userId,
      'check_in_time': DateTime.now().toIso8601String(),
      'location_gps': gpsLocation,
      'org_id': orgId,
    });
  }

  Future<void> checkOut(String attendanceId) async {
    await _client.from('attendance').update({
      'check_out_time': DateTime.now().toIso8601String(),
    }).eq('id', attendanceId);
  }

  Future<int> getActiveSessionsCount() async {
    final response = await _client
        .from('attendance')
        .select('id')
        .filter('check_out_time', 'is', null);
    return response.length;
  }

  Future<List<Map<String, dynamic>>> getDailyAttendance(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final response = await _client
        .from('attendance')
        .select('*, profiles(name, role)')
        .gte('check_in_time', startOfDay.toIso8601String())
        .lt('check_in_time', endOfDay.toIso8601String());
    
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAttendanceHistory({String? userId, DateTime? start, DateTime? end}) async {
    var query = _client.from('attendance').select('*, profiles(name, role)');
    
    if (userId != null) {
      query = query.eq('user_id', userId);
    }
    
    if (start != null) {
      query = query.gte('check_in_time', start.toIso8601String());
    }
    
    if (end != null) {
      query = query.lt('check_in_time', end.toIso8601String());
    }
    
    final response = await query.order('check_in_time', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}
