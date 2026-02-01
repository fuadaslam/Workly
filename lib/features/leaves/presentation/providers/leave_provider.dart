
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/leave_request.dart';
import '../../data/models/holiday.dart';
import '../../data/repositories/leave_repository.dart';

final leaveRepositoryProvider = Provider((ref) => LeaveRepository(Supabase.instance.client));

final upcomingHolidaysProvider = Provider<List<Holiday>>((ref) {
  return [
    Holiday(id: '1', name: 'Eid Al-Fitr', date: DateTime.now().add(const Duration(days: 15))),
    Holiday(id: '2', name: 'National Day', date: DateTime.now().add(const Duration(days: 45))),
    Holiday(id: '3', name: 'New Year', date: DateTime(DateTime.now().year + 1, 1, 1)),
  ];
});

class LeaveState {
  final List<LeaveRequest> requests;
  final bool isLoading;
  final String? error;

  LeaveState({
    this.requests = const [],
    this.isLoading = false,
    this.error,
  });

  LeaveState copyWith({
    List<LeaveRequest>? requests,
    bool? isLoading,
    String? error,
  }) {
    return LeaveState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LeaveNotifier extends StateNotifier<LeaveState> {
  final LeaveRepository _repository;

  LeaveNotifier(this._repository) : super(LeaveState()) {
    loadLeaves();
  }

  Future<void> loadLeaves() async {
    state = state.copyWith(isLoading: true);
    try {
      final leaves = await _repository.getMyLeaves();
      state = state.copyWith(isLoading: false, requests: leaves);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> submitLeaveRequest(LeaveRequest request) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.submitLeave(request);
      await loadLeaves();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

class AdminLeaveNotifier extends StateNotifier<LeaveState> {
  final LeaveRepository _repository;

  AdminLeaveNotifier(this._repository) : super(LeaveState()) {
    loadAllLeaves();
  }

  Future<void> loadAllLeaves() async {
    state = state.copyWith(isLoading: true);
    try {
      final leaves = await _repository.getAllLeaves();
      state = state.copyWith(isLoading: false, requests: leaves);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateStatus(String id, LeaveStatus status) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.updateLeaveStatus(id, status.name);
      await loadAllLeaves();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final leaveProvider = StateNotifierProvider<LeaveNotifier, LeaveState>((ref) {
  return LeaveNotifier(ref.watch(leaveRepositoryProvider));
});

final adminLeaveProvider = StateNotifierProvider<AdminLeaveNotifier, LeaveState>((ref) {
  return AdminLeaveNotifier(ref.watch(leaveRepositoryProvider));
});

final leaveBalanceProvider = Provider<int>((ref) {
  final state = ref.watch(leaveProvider);
  const totalAllowance = 21; // Standard allowance
  final usedDays = state.requests
      .where((r) => r.status == LeaveStatus.approved)
      .fold(0, (sum, r) => sum + r.durationDays);
  return totalAllowance - usedDays;
});
