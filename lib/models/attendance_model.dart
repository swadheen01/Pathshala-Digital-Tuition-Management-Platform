import 'package:equatable/equatable.dart';

/// A single attendance record: one student, one room, one date (spec §2.3).
/// Dates are restricted (in the UI layer) to the room's configured
/// class_days (spec §2.5) — enforced client-side and via a CHECK-adjacent
/// trigger server-side (see 0003_attendance.sql).
class AttendanceModel extends Equatable {
  const AttendanceModel({
    required this.id,
    required this.roomId,
    required this.studentId,
    required this.date,
    required this.present,
    this.markedBy,
    this.syncedAt,
    this.createdAt,
  });

  final String id;
  final String roomId;
  final String studentId;
  final DateTime date; // date-only, no time component
  final bool present;
  final String? markedBy; // teacher's profile id
  final DateTime? syncedAt; // null until offline-queued record syncs (§2.3)
  final DateTime? createdAt;

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      studentId: json['student_id'] as String,
      date: DateTime.parse(json['date'] as String),
      present: json['present'] as bool,
      markedBy: json['marked_by'] as String?,
      syncedAt: json['synced_at'] != null
          ? DateTime.tryParse(json['synced_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'student_id': studentId,
      'date': _dateOnly(date),
      'present': present,
      'marked_by': markedBy,
    };
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  List<Object?> get props => [id, roomId, studentId, date, present, markedBy];
}

/// Attendance percentage summary for one student in one room (spec §2.3).
class AttendanceSummary extends Equatable {
  const AttendanceSummary({
    required this.studentId,
    required this.studentName,
    required this.totalDays,
    required this.presentDays,
  });

  final String studentId;
  final String studentName;
  final int totalDays;
  final int presentDays;

  double get percentage => totalDays == 0 ? 0 : (presentDays / totalDays) * 100;

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String? ?? 'Unknown',
      totalDays: json['total_days'] as int? ?? 0,
      presentDays: json['present_days'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [studentId, studentName, totalDays, presentDays];
}

/// One student's attendance standing in one of their rooms — powers the
/// student home screen (spec §3).
class RoomAttendanceStat extends Equatable {
  const RoomAttendanceStat({
    required this.roomId,
    required this.roomName,
    this.subject,
    this.present = 0,
    this.total = 0,
  });

  final String roomId;
  final String roomName;
  final String? subject;
  final int present;
  final int total;

  double get percentage => total == 0 ? 0 : (present / total) * 100;

  factory RoomAttendanceStat.fromJson(Map<String, dynamic> json) {
    return RoomAttendanceStat(
      roomId: json['room_id'] as String,
      roomName: json['room_name'] as String? ?? 'Room',
      subject: json['subject'] as String?,
      present: (json['present'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [roomId, present, total];
}
