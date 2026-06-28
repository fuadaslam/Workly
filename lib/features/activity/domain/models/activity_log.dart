/// A single audit-trail entry recording who performed an operation
/// (create / update / delete) on a core entity, and what changed.
///
/// Rows are written automatically by Postgres triggers (see the
/// `log_activity()` function), so this model is read-only on the client.
class ActivityLog {
  final String id;
  final String? orgId;
  final String? actorId;
  final String actorName;
  final String? actorRole;
  final String action; // created | updated | deleted | deactivated | reactivated
  final String entityType; // office | staff | work_order | client | ...
  final String? entityId;
  final String? entityLabel;
  final String? summary;
  final Map<String, dynamic>? changes; // {field: {old, new}}
  final DateTime createdAt;

  ActivityLog({
    required this.id,
    this.orgId,
    this.actorId,
    required this.actorName,
    this.actorRole,
    required this.action,
    required this.entityType,
    this.entityId,
    this.entityLabel,
    this.summary,
    this.changes,
    required this.createdAt,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] as String,
      orgId: json['org_id'] as String?,
      actorId: json['actor_id'] as String?,
      actorName: (json['actor_name'] as String?) ?? 'System',
      actorRole: json['actor_role'] as String?,
      action: (json['action'] as String?) ?? 'updated',
      entityType: (json['entity_type'] as String?) ?? 'record',
      entityId: json['entity_id'] as String?,
      entityLabel: json['entity_label'] as String?,
      summary: json['summary'] as String?,
      changes: json['changes'] is Map
          ? Map<String, dynamic>.from(json['changes'] as Map)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Human-friendly entity label, e.g. "work_order" -> "Work Order".
  String get entityTypeLabel => entityType
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
