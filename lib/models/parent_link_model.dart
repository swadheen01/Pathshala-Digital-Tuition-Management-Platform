import 'package:equatable/equatable.dart';

/// Links a parent account to a student, granted by the teacher
/// (spec §2.8: "Teacher can grant a read-only parent account/view
/// linked to a student").
class ParentLinkModel extends Equatable {
  const ParentLinkModel({
    required this.id,
    required this.parentId,
    required this.studentId,
    this.studentName,
    this.grantedBy,
    this.createdAt,
  });

  final String id;
  final String parentId;
  final String studentId;
  final String? studentName; // joined from profiles, for display
  final String? grantedBy; // teacher's profile id
  final DateTime? createdAt;

  factory ParentLinkModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return ParentLinkModel(
      id: json['id'] as String,
      parentId: json['parent_id'] as String,
      studentId: json['student_id'] as String,
      studentName: profile?['full_name'] as String?,
      grantedBy: json['granted_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parent_id': parentId,
      'student_id': studentId,
      'granted_by': grantedBy,
    };
  }

  @override
  List<Object?> get props => [id, parentId, studentId, studentName];
}
