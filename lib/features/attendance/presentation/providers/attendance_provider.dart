import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/attendance_repository.dart';

final attendanceRepositoryProvider = Provider((ref) {
  return AttendanceRepository(Supabase.instance.client);
});

final currentAttendanceProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;
  return repo.getCurrentSession(user.id);
});

class AttendanceController extends StateNotifier<AsyncValue<void>> {
  final AttendanceRepository _repo;
  final Ref _ref;

  AttendanceController(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<void> checkIn() async {
    state = const AsyncValue.loading();
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // In a real app, we would get the actual location here using geolocator
        // For now, we mock it or pass null
        await _repo.checkIn(user.id, "24.7136, 46.6753"); 
        _ref.invalidate(currentAttendanceProvider);
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> checkOut(String attendanceId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.checkOut(attendanceId);
      _ref.invalidate(currentAttendanceProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final attendanceControllerProvider = StateNotifierProvider<AttendanceController, AsyncValue<void>>((ref) {
  return AttendanceController(ref.watch(attendanceRepositoryProvider), ref);
});

final dailyAttendanceProvider = FutureProvider.family.autoDispose<List<Map<String, dynamic>>, DateTime>((ref, date) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.getDailyAttendance(date);
});

final attendanceHistoryProvider = FutureProvider.family.autoDispose<List<Map<String, dynamic>>, ({String? userId, DateTime? start, DateTime? end})>((ref, params) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.getAttendanceHistory(userId: params.userId, start: params.start, end: params.end);
});
