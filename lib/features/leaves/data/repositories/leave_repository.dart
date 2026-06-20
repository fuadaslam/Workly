
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/leave_request.dart';
import '../../../../core/utils/supabase_org_utils.dart';

class LeaveRepository {
  final SupabaseClient _client;

  LeaveRepository(this._client);

  Future<List<LeaveRequest>> getMyLeaves() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('leaves')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => LeaveRequest.fromJson(json)).toList();
  }

  Future<void> submitLeave(LeaveRequest request) async {
    final orgId = await fetchCallerOrgId(_client);
    await _client.from('leaves').insert({
      'user_id': _client.auth.currentUser?.id,
      'leave_type': request.type.name,
      'start_date': request.startDate.toIso8601String(),
      'end_date': request.endDate.toIso8601String(),
      'reason': request.reason,
      'status': 'Pending',
      'org_id': orgId,
    });
  }

  Future<List<LeaveRequest>> getAllLeaves() async {
    final response = await _client
        .from('leaves')
        .select('*, profiles(name)')
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => LeaveRequest.fromJson(json)).toList();
  }

  Future<void> updateLeaveStatus(String id, String status) async {
    final capitalizedStatus = status[0].toUpperCase() + status.substring(1).toLowerCase();
    await _client.from('leaves').update({
      'status': capitalizedStatus,
    }).eq('id', id);
  }
}
