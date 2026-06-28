import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/activity_repository.dart';
import '../../domain/models/activity_log.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';

final activityRepositoryProvider = Provider((ref) {
  return ActivityRepository(ref.watch(supabaseClientProvider));
});

/// Active entity-type filter for the activity log screen (null = all).
final activityFilterProvider = StateProvider<String?>((ref) => null);

/// Recent activity-log entries, scoped by the current filter.
final activityLogsProvider = FutureProvider<List<ActivityLog>>((ref) async {
  final filter = ref.watch(activityFilterProvider);
  return ref.watch(activityRepositoryProvider).getActivityLogs(
        pageSize: 100,
        entityType: filter,
      );
});
