import 'package:equatable/equatable.dart';

/// Homework/assignment posted by a teacher to a room (spec §2.6).
class AssignmentModel extends Equatable {
  const AssignmentModel({
    required this.id,
    required this.roomId,
    required this.title,
    required this.dueDate,
    this.description,
    this.createdBy,
    this.createdAt,
  });

  final String id;
  final String roomId;
  final String title;
  final DateTime dueDate;
  final String? description;
  final String? createdBy;
  final DateTime? createdAt;

  bool get isOverdue => DateTime.now().isAfter(dueDate);

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      title: json['title'] as String,
      dueDate: DateTime.parse(json['due_date'] as String),
      description: json['description'] as String?,
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
      'due_date': dueDate.toIso8601String(),
      'description': description,
      'created_by': createdBy,
    };
  }

  @override
  List<Object?> get props => [id, roomId, title, dueDate, description];
}

enum SubmissionType { text, file, image }

SubmissionType _typeFromString(String v) => SubmissionType.values
    .firstWhere((e) => e.name == v, orElse: () => SubmissionType.text);

/// A student's submission for an assignment (spec §2.6: text, file, or image).
class SubmissionModel extends Equatable {
  const SubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.type,
    this.studentName,
    this.textContent,
    this.fileUrl,
    this.grade,
    this.feedback,
    this.submittedAt,
    this.gradedAt,
  });

  final String id;
  final String assignmentId;
  final String studentId;
  final SubmissionType type;
  final String? studentName; // joined from profiles, for teacher review UI
  final String? textContent;
  final String? fileUrl; // used for both 'file' and 'image' types
  final String? grade; // teacher-assigned grade/marks (spec §2.6)
  final String? feedback;
  final DateTime? submittedAt;
  final DateTime? gradedAt;

  bool get isGraded => grade != null;

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return SubmissionModel(
      id: json['id'] as String,
      assignmentId: json['assignment_id'] as String,
      studentId: json['student_id'] as String,
      type: _typeFromString(json['type'] as String? ?? 'text'),
      studentName: profile?['full_name'] as String?,
      textContent: json['text_content'] as String?,
      fileUrl: json['file_url'] as String?,
      grade: json['grade'] as String?,
      feedback: json['feedback'] as String?,
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'] as String)
          : null,
      gradedAt: json['graded_at'] != null
          ? DateTime.tryParse(json['graded_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assignment_id': assignmentId,
      'student_id': studentId,
      'type': type.name,
      'text_content': textContent,
      'file_url': fileUrl,
    };
  }

  @override
  List<Object?> get props =>
      [id, assignmentId, studentId, type, textContent, fileUrl, grade];
}
