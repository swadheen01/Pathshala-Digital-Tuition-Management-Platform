import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../models/payment_model.dart';

/// Handles payment recording and dues tracking (spec §2.4, teacher-only).
class PaymentService {
  PaymentService({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  Future<PaymentModel> recordPayment({
    required String roomId,
    required String studentId,
    required double amount,
    required DateTime paidOn,
    String? forMonth,
    String? note,
  }) async {
    final teacherId = _client.auth.currentUser?.id;

    final response = await _client
        .from('payments')
        .insert({
          'room_id': roomId,
          'student_id': studentId,
          'amount': amount,
          'paid_on':
              '${paidOn.year.toString().padLeft(4, '0')}-${paidOn.month.toString().padLeft(2, '0')}-${paidOn.day.toString().padLeft(2, '0')}',
          'for_month': forMonth,
          'note': note,
          'recorded_by': teacherId,
        })
        .select()
        .single();

    return PaymentModel.fromJson(response);
  }

  Future<List<PaymentModel>> fetchStudentPayments({
    required String roomId,
    required String studentId,
  }) async {
    final response = await _client
        .from('payments')
        .select()
        .eq('room_id', roomId)
        .eq('student_id', studentId)
        .order('paid_on', ascending: false);

    return (response as List)
        .map((row) => PaymentModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<PaymentModel>> fetchRoomPayments(String roomId) async {
    final response = await _client
        .from('payments')
        .select()
        .eq('room_id', roomId)
        .order('paid_on', ascending: false);

    return (response as List)
        .map((row) => PaymentModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Dues summary per student in a room — amount paid, outstanding,
  /// months overdue (spec §2.4).
  Future<List<DuesSummary>> fetchDuesSummary(String roomId) async {
    final response = await _client.rpc(
      'get_dues_summary',
      params: {'p_room_id': roomId},
    );

    return (response as List)
        .map((row) => DuesSummary.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// One-glance payment snapshot across every room the teacher owns
  /// (get_teacher_payment_overview RPC, 0016) — for the home screen.
  Future<TeacherPaymentOverview> fetchTeacherOverview() async {
    final rows = await _client.rpc('get_teacher_payment_overview') as List;
    if (rows.isEmpty) return const TeacherPaymentOverview();
    return TeacherPaymentOverview.fromJson(rows.first as Map<String, dynamic>);
  }

  /// Sets/updates a student's monthly fee for a room. `refId` is the
  /// member ref id (works for name-only students too).
  Future<void> setMonthlyFee({
    required String roomId,
    required String refId,
    required double monthlyFee,
  }) async {
    await _client
        .from('room_members')
        .update({'monthly_fee': monthlyFee})
        .eq('room_id', roomId)
        .eq('ref_id', refId);
  }

  Future<void> deletePayment(String paymentId) async {
    await _client.from('payments').delete().eq('id', paymentId);
  }
}
