import 'package:equatable/equatable.dart';

/// An exam/test defined by the teacher for a room (spec §2.7).
class ExamModel extends Equatable {
  const ExamModel({
    required this.id,
    required this.roomId,
    required this.title,
    required this.maxMarks,
    this.examDate,
    this.createdBy,
    this.createdAt,
  });

  final String id;
  final String roomId;
  final String title;
  final double maxMarks;
  final DateTime? examDate;
  final String? createdBy;
  final DateTime? createdAt;

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      title: json['title'] as String,
      maxMarks: (json['max_marks'] as num).toDouble(),
      examDate: json['exam_date'] != null
          ? DateTime.tryParse(json['exam_date'] as String)
          : null,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'title': title,
      'max_marks': maxMarks,
      'exam_date': examDate?.toIso8601String(),
      'created_by': createdBy,
    };
  }

  @override
  List<Object?> get props => [id, roomId, title, maxMarks, examDate];
}

/// One student's score on one exam (spec §2.7).
class ExamScoreModel extends Equatable {
  const ExamScoreModel({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.marksObtained,
    this.studentName,
  });

  final String id;
  final String examId;
  final String studentId;
  final double marksObtained;
  final String? studentName; // joined from profiles

  factory ExamScoreModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return ExamScoreModel(
      id: json['id'] as String,
      examId: json['exam_id'] as String,
      studentId: json['student_id'] as String,
      marksObtained: (json['marks_obtained'] as num).toDouble(),
      studentName: profile?['full_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exam_id': examId,
      'student_id': studentId,
      'marks_obtained': marksObtained,
    };
  }

  @override
  List<Object?> get props => [id, examId, studentId, marksObtained];
}

/// A single student's overall performance across exams in a room —
/// used for the performance graph (spec §2.7, §3).
class PerformancePoint extends Equatable {
  const PerformancePoint({
    required this.examTitle,
    required this.examDate,
    required this.marksObtained,
    required this.maxMarks,
  });

  final String examTitle;
  final DateTime? examDate;
  final double marksObtained;
  final double maxMarks;

  double get percentage => maxMarks == 0 ? 0 : (marksObtained / maxMarks) * 100;

  @override
  List<Object?> get props => [examTitle, examDate, marksObtained, maxMarks];
}

/// One row on the leaderboard — aggregate performance across all exams
/// in a room, only shown if teacher enables it (spec §2.7).
class LeaderboardEntry extends Equatable {
  const LeaderboardEntry({
    required this.studentId,
    required this.studentName,
    required this.totalMarksObtained,
    required this.totalMaxMarks,
  });

  final String studentId;
  final String studentName;
  final double totalMarksObtained;
  final double totalMaxMarks;

  double get percentage =>
      totalMaxMarks == 0 ? 0 : (totalMarksObtained / totalMaxMarks) * 100;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String? ?? 'Unknown',
      totalMarksObtained: (json['total_marks_obtained'] as num?)?.toDouble() ?? 0,
      totalMaxMarks: (json['total_max_marks'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props =>
      [studentId, studentName, totalMarksObtained, totalMaxMarks];
}
