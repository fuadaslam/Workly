import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/activity_log.dart';
import '../providers/activity_provider.dart';

/// Read-only audit trail of every create / update / delete across the
/// org's core records (offices, staff, work orders, clients, services,
/// leaves, payments, enquiries, documents). Visible to org admins only
/// (enforced by RLS on the `activity_logs` table).
class ActivityLogScreen extends ConsumerWidget {
  const ActivityLogScreen({super.key});

  static const _filters = <String, String?>{
    'All': null,
    'Work Orders': 'work_order',
    'Staff': 'staff',
    'Offices': 'office',
    'Clients': 'client',
    'Services': 'service',
    'Leaves': 'leave',
    'Payments': 'payment',
    'Enquiries': 'enquiry',
    'Documents': 'document',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logsAsync = ref.watch(activityLogsProvider);
    final activeFilter = ref.watch(activityFilterProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Activity Log'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(activityLogsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(activeFilter: activeFilter, ref: ref),
          Expanded(
            child: logsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorState(message: '$e'),
              data: (logs) {
                if (logs.isEmpty) return const _EmptyState();
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(activityLogsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _ActivityCard(log: logs[i], isDark: isDark),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String? activeFilter;
  final WidgetRef ref;
  const _FilterBar({required this.activeFilter, required this.ref});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: ActivityLogScreen._filters.entries.map((e) {
          final selected = activeFilter == e.value;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(e.key),
              selected: selected,
              onSelected: (_) =>
                  ref.read(activityFilterProvider.notifier).state = e.value,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final ActivityLog log;
  final bool isDark;
  const _ActivityCard({required this.log, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final changes = log.changes;
    final hasChanges = changes != null && changes.isNotEmpty;
    final color = _actionColor(log.action);

    final tile = Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_entityIcon(log.entityType), color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _ActionBadge(action: log.action, color: color),
                        const SizedBox(width: 6),
                        Text(
                          log.entityTypeLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppTheme.darkSubtext : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      log.entityLabel?.isNotEmpty == true
                          ? log.entityLabel!
                          : (log.summary ?? '—'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppTheme.darkBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.person_outline,
                  size: 14, color: isDark ? AppTheme.darkSubtext : Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  log.actorRole != null && log.actorRole!.isNotEmpty
                      ? '${log.actorName} · ${_roleLabel(log.actorRole!)}'
                      : log.actorName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkSubtext : Colors.grey.shade700,
                  ),
                ),
              ),
              Text(
                _formatTime(log.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppTheme.darkSubtext : Colors.grey,
                ),
              ),
            ],
          ),
          if (hasChanges) ...[
            const SizedBox(height: 6),
            _ChangesView(changes: changes, isDark: isDark),
          ],
        ],
      ),
    );

    return tile;
  }

  static Color _actionColor(String action) {
    switch (action) {
      case 'created':
        return AppTheme.successGreen;
      case 'deleted':
      case 'deactivated':
        return AppTheme.statusDanger;
      case 'reactivated':
        return AppTheme.successGreen;
      default:
        return AppTheme.statusProgress; // updated
    }
  }

  static IconData _entityIcon(String entityType) {
    switch (entityType) {
      case 'office':
        return Icons.business_outlined;
      case 'staff':
        return Icons.badge_outlined;
      case 'work_order':
        return Icons.assignment_outlined;
      case 'client':
        return Icons.person_outline;
      case 'service':
        return Icons.design_services_outlined;
      case 'leave':
        return Icons.event_busy_outlined;
      case 'attendance':
        return Icons.how_to_reg_outlined;
      case 'payment':
        return Icons.payments_outlined;
      case 'enquiry':
        return Icons.track_changes_outlined;
      case 'document':
        return Icons.description_outlined;
      default:
        return Icons.history;
    }
  }

  static String _roleLabel(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      case 'staff':
        return 'Staff';
      case 'agent':
        return 'Agent';
      default:
        return role;
    }
  }

  static String _formatTime(DateTime utc) {
    final dt = utc.toLocal();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM, h:mm a').format(dt);
  }
}

class _ActionBadge extends StatelessWidget {
  final String action;
  final Color color;
  const _ActionBadge({required this.action, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        action.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: color,
        ),
      ),
    );
  }
}

class _ChangesView extends StatelessWidget {
  final Map<String, dynamic> changes;
  final bool isDark;
  const _ChangesView({required this.changes, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 4, bottom: 6),
        dense: true,
        visualDensity: VisualDensity.compact,
        title: Text(
          '${changes.length} field${changes.length == 1 ? '' : 's'} changed',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.electricBlue,
          ),
        ),
        children: changes.entries.map((e) {
          final detail = e.value is Map ? e.value as Map : const {};
          final oldV = _fmt(detail['old']);
          final newV = _fmt(detail['new']);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fieldLabel(e.key),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkSubtext : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        oldV,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.statusDanger,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward, size: 12, color: Colors.grey),
                    ),
                    Expanded(
                      child: Text(
                        newV,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.successGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  static String _fmt(dynamic v) {
    if (v == null) return '—';
    final s = v.toString();
    return s.isEmpty ? '—' : s;
  }

  static String _fieldLabel(String key) => key
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_toggle_off, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('No activity yet',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text('Actions across the app will appear here',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.statusDanger),
            const SizedBox(height: 12),
            Text('Could not load activity',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}
