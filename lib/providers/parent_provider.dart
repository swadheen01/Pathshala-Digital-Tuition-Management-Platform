import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attendance_model.dart';
import '../models/parent_link_model.dart';
import '../models/payment_model.dart';
import '../models/exam_model.dart';
import '../models/room_model.dart';
import '../services/attendance_service.dart';
import '../services/exam_service.dart';
import '../services/parent_service.dart';
import '../services/payment_service.dart';

final parentServiceProvider = Provider<ParentService>((ref) => ParentService());

/// Children linked to the current parent (spec §2.8).
final myChildrenProvider = FutureProvider<List<ParentLinkModel>>((ref) {
  return ref.watch(parentServiceProvider).fetchMyChildren();
});

/// Parent links for students in a room — teacher's management screen.
final roomParentLinksProvider =
    FutureProvider.family<List<ParentLinkModel>, String>((ref, roomId) {
  return ref.watch(parentServiceProvider).fetchLinksForRoom(roomId);
});

/// Rooms a linked child belongs to — lets the parent pick a room before
/// drilling into attendance/payments/performance (spec §2.8).
final childRoomsProvider =
    FutureProvider.family<List<RoomModel>, String>((ref, studentId) {
  return ref.watch(parentServiceProvider).fetchChildRooms(studentId);
});

/// A linked child's attendance across a room — reuses AttendanceService;
/// RLS (0009_parent.sql) restricts this to rows the parent is actually
/// linked to, so no extra client-side filtering is needed.
final childAttendanceProvider = FutureProvider.family<List<AttendanceModel>,
    ({String roomId, String studentId})>((ref, args) {
  return AttendanceService().fetchStudentHistory(
    roomId: args.roomId,
    studentId: args.studentId,
  );
});

/// A linked child's payment/dues history — reuses PaymentService.
final childPaymentsProvider =
    FutureProvider.family<List<PaymentModel>, ({String roomId, String studentId})>(
        (ref, args) {
  return PaymentService().fetchStudentPayments(
    roomId: args.roomId,
    studentId: args.studentId,
  );
});

/// A linked child's exam performance — reuses ExamService.
final childPerformanceProvider = FutureProvider.family<List<PerformancePoint>,
    ({String roomId, String studentId})>((ref, args) {
  return ExamService().fetchStudentPerformance(
    roomId: args.roomId,
    studentId: args.studentId,
  );
});

class ParentController extends StateNotifier<AsyncValue<void>> {
  ParentController(this._service) : super(const AsyncData(null));

  final ParentService _service;

  Future<bool> grantAccess({
    required String parentEmail,
    required String studentId,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _service.grantParentAccess(
          parentEmail: parentEmail,
          studentId: studentId,
        ));
    state = result.hasError
        ? AsyncError(result.error!, result.stackTrace!)
        : const AsyncData(null);
    return !result.hasError;
  }

  Future<bool> revokeAccess(String linkId) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _service.revokeParentAccess(linkId));
    state = result.hasError
        ? AsyncError(result.error!, result.stackTrace!)
        : const AsyncData(null);
    return !result.hasError;
  }
}

final parentControllerProvider =
    StateNotifierProvider<ParentController, AsyncValue<void>>((ref) {
  return ParentController(ref.watch(parentServiceProvider));
});
