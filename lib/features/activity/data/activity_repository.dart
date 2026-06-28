import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/activity_log.dart';

class ActivityRepository {
  final SupabaseClient _client;

  ActivityRepository(this._client);

  /// Fetches the most recent activity-log entries for the caller's org.
  /// RLS restricts visibility to org admins, so non-admins get an empty list.
  Future<List<ActivityLog>> getActivityLogs({
    int page = 0,
    int pageSize = 30,
    String? entityType,
    String? actorId,
  }) async {
    var query = _client.from('activity_logs').select();

    if (entityType != null) {
      query = query.eq('entity_type', entityType);
    }
    if (actorId != null) {
      query = query.eq('actor_id', actorId);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);

    return (response as List)
        .map((json) => ActivityLog.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
