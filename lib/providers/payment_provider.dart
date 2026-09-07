import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment_model.dart';
import '../services/payment_service.dart';

final paymentServiceProvider =
    Provider<PaymentService>((ref) => PaymentService());

final roomPaymentsProvider =
    FutureProvider.family<List<PaymentModel>, String>((ref, roomId) {
  return ref.watch(paymentServiceProvider).fetchRoomPayments(roomId);
});

final studentPaymentsProvider = FutureProvider.family<List<PaymentModel>,
    ({String roomId, String studentId})>((ref, args) {
  return ref.watch(paymentServiceProvider).fetchStudentPayments(
        roomId: args.roomId,
        studentId: args.studentId,
      );
});

/// Dues summary per student — amount paid, outstanding, months overdue
/// (spec §2.4).
final duesSummaryProvider =
    FutureProvider.family<List<DuesSummary>, String>((ref, roomId) {
  return ref.watch(paymentServiceProvider).fetchDuesSummary(roomId);
});

/// Payment snapshot across all of the teacher's rooms — home screen.
final teacherPaymentOverviewProvider =
    FutureProvider<TeacherPaymentOverview>((ref) {
  return ref.watch(paymentServiceProvider).fetchTeacherOverview();
});

class PaymentController extends StateNotifier<AsyncValue<void>> {
  PaymentController(this._service) : super(const AsyncData(null));

  final PaymentService _service;

  Future<bool> recordPayment({
    required String roomId,
    required String studentId,
    required double amount,
    required DateTime paidOn,
    String? forMonth,
    String? note,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _service.recordPayment(
          roomId: roomId,
          studentId: studentId,
          amount: amount,
          paidOn: paidOn,
          forMonth: forMonth,
          note: note,
        ));
    state = result.hasError
        ? AsyncError(result.error!, result.stackTrace!)
        : const AsyncData(null);
    return !result.hasError;
  }

  Future<bool> setMonthlyFee({
    required String roomId,
    required String refId,
    required double monthlyFee,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _service.setMonthlyFee(
          roomId: roomId,
          refId: refId,
          monthlyFee: monthlyFee,
        ));
    state = result.hasError
        ? AsyncError(result.error!, result.stackTrace!)
        : const AsyncData(null);
    return !result.hasError;
  }
}

final paymentControllerProvider =
    StateNotifierProvider<PaymentController, AsyncValue<void>>((ref) {
  return PaymentController(ref.watch(paymentServiceProvider));
});
