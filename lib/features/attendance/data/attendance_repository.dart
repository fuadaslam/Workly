import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceRepository {
  final SupabaseClient _client;

  AttendanceRepository(this._client);

  Future<Map<String, dynamic>?> getCurrentSession(String userId) async {
    try {
      final response = await _client
          .from('attendance')
          .select()
          .eq('user_id', userId)
          .filter('check_out_time', 'is', null)
          .maybeSingle(); // Returns null if no match found
      return response;
    } catch (e) {
      // Handle error or return null
      return null;
    }
  }

  Future<void> checkIn(String userId, String? gpsLocation) async {
    await _client.from('attendance').insert({
      'user_id': userId,
      'check_in_time': DateTime.now().toIso8601String(),
      'location_gps': gpsLocation,
    });
  }

  Future<void> checkOut(String attendanceId) async {
    await _client.from('attendance').update({
      'check_out_time': DateTime.now().toIso8601String(),
    }).eq('id', attendanceId);
  }

  Future<int> getActiveSessionsCount() async {
    try {
      final response = await _client
          .from('attendance')
          .select('id')
          .filter('check_out_time', 'is', null);
      if (response is List) return response.length;
      return 0;
    } catch (e) {
      return 0;
    }
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
