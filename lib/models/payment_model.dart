import 'package:equatable/equatable.dart';

/// A single payment record against a student (spec §2.4, teacher-only).
class PaymentModel extends Equatable {
  const PaymentModel({
    required this.id,
    required this.roomId,
    required this.studentId,
    required this.amount,
    required this.paidOn,
    this.forMonth,
    this.note,
    this.recordedBy,
    this.createdAt,
  });

  final String id;
  final String roomId;
  final String studentId;
  final double amount;
  final DateTime paidOn;
  final String? forMonth; // e.g. "2026-07" — which month's fee this covers
  final String? note;
  final String? recordedBy; // teacher's profile id
  final DateTime? createdAt;

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      studentId: json['student_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      paidOn: DateTime.parse(json['paid_on'] as String),
      forMonth: json['for_month'] as String?,
      note: json['note'] as String?,
      recordedBy: json['recorded_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'student_id': studentId,
      'amount': amount,
      'paid_on': '${paidOn.year.toString().padLeft(4, '0')}-${paidOn.month.toString().padLeft(2, '0')}-${paidOn.day.toString().padLeft(2, '0')}',
      'for_month': forMonth,
      'note': note,
      'recorded_by': recordedBy,
    };
  }

  @override
  List<Object?> get props =>
      [id, roomId, studentId, amount, paidOn, forMonth, note];
}

/// Per-student dues summary for a room (spec §2.4: amount paid,
/// outstanding/due amount, months overdue).
class DuesSummary extends Equatable {
  const DuesSummary({
    required this.studentId,
    required this.studentName,
    required this.monthlyFee,
    required this.totalPaid,
    required this.monthsSinceJoining,
  });

  final String studentId;
  final String studentName;
  final double monthlyFee;
  final double totalPaid;
  final int monthsSinceJoining;

  double get totalExpected => monthlyFee * monthsSinceJoining;
  double get outstanding =>
      (totalExpected - totalPaid).clamp(0, double.infinity);
  int get monthsOverdue =>
      monthlyFee == 0 ? 0 : (outstanding / monthlyFee).floor();

  factory DuesSummary.fromJson(Map<String, dynamic> json) {
    return DuesSummary(
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String? ?? 'Unknown',
      monthlyFee: (json['monthly_fee'] as num?)?.toDouble() ?? 0,
      totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0,
      monthsSinceJoining: json['months_since_joining'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props =>
      [studentId, studentName, monthlyFee, totalPaid, monthsSinceJoining];
}

/// One-glance payment snapshot across all of a teacher's rooms — powers
/// the teacher home screen "Payments" section (spec §2.4).
class TeacherPaymentOverview extends Equatable {
  const TeacherPaymentOverview({
    this.studentCount = 0,
    this.paidUp = 0,
    this.due = 0,
    this.overdue = 0,
    this.outstanding = 0,
    this.collected30 = 0,
  });

  final int studentCount;
  final int paidUp;
  final int due;
  final int overdue;
  final double outstanding;
  final double collected30;

  factory TeacherPaymentOverview.fromJson(Map<String, dynamic> json) {
    return TeacherPaymentOverview(
      studentCount: (json['student_count'] as num?)?.toInt() ?? 0,
      paidUp: (json['paid_up'] as num?)?.toInt() ?? 0,
      due: (json['due'] as num?)?.toInt() ?? 0,
      overdue: (json['overdue'] as num?)?.toInt() ?? 0,
      outstanding: (json['outstanding'] as num?)?.toDouble() ?? 0,
      collected30: (json['collected_30'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props =>
      [studentCount, paidUp, due, overdue, outstanding, collected30];
}
