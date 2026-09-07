import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import '../services/offline_sync_service.dart';

final attendanceServiceProvider =
    Provider<AttendanceService>((ref) => AttendanceService());

/// Exposed separately so screens can prefill from existing attendance
/// without going through the offline queue (a read, not a write).
final attendanceServiceProviderForPrefill = attendanceServiceProvider;

final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  return OfflineSyncService(attendanceService: ref.watch(attendanceServiceProvider));
});

/// Percentage summary for every student in a room (spec §2.3).
final roomSummaryProvider =
    FutureProvider.family<List<AttendanceSummary>, String>((ref, roomId) {
  return ref.watch(attendanceServiceProvider).fetchRoomSummary(roomId);
});

/// The signed-in student's attendance % per room — student home screen.
final myRoomAttendanceProvider =
    FutureProvider<List<RoomAttendanceStat>>((ref) {
  return ref.watch(attendanceServiceProvider).fetchMyRoomAttendance();
});

/// A single student's attendance history in a room.
final studentAttendanceHistoryProvider = FutureProvider.family<
    List<AttendanceModel>, ({String roomId, String studentId})>((ref, args) {
  return ref.watch(attendanceServiceProvider).fetchStudentHistory(
        roomId: args.roomId,
        studentId: args.studentId,
      );
});

/// Controller for marking attendance. Routes through the offline sync
/// service so teachers can mark attendance without internet (spec §2.3).
/// Returns true if it synced immediately, false if it was queued locally.
class AttendanceController extends StateNotifier<AsyncValue<void>> {
  AttendanceController(this._offlineSyncService) : super(const AsyncData(null));

  final OfflineSyncService _offlineSyncService;

  Future<bool> markAttendance({
    required String roomId,
    required DateTime date,
    required Map<String, bool> presentMap,
  }) async {
    state = const AsyncLoading();

    final pendingBefore = await _offlineSyncService.pendingCount();

    final result = await AsyncValue.guard(() => _offlineSyncService.queueOrSend(
          roomId: roomId,
          date: date,
          presentMap: presentMap,
        ));

    state = result.hasError
        ? AsyncError(result.error!, result.stackTrace!)
        : const AsyncData(null);

    if (result.hasError) return false;

    final pendingAfter = await _offlineSyncService.pendingCount();
    // If pending count grew, this batch was queued rather than sent live.
    return pendingAfter <= pendingBefore;
  }
}

final attendanceControllerProvider =
    StateNotifierProvider<AttendanceController, AsyncValue<void>>((ref) {
  return AttendanceController(ref.watch(offlineSyncServiceProvider));
});
