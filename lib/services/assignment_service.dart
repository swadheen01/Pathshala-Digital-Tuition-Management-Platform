import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../models/assignment_model.dart';

/// Handles assignments and submissions (spec §2.6).
class AssignmentService {
  AssignmentService({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  Future<AssignmentModel> createAssignment({
    required String roomId,
    required String title,
    required DateTime dueDate,
    String? description,
  }) async {
    final teacherId = _client.auth.currentUser?.id;
    if (teacherId == null) throw StateError('Not signed in.');

    final response = await _client
        .from('assignments')
        .insert({
          'room_id': roomId,
          'title': title,
          'due_date': dueDate.toIso8601String(),
          'description': description,
          'created_by': teacherId,
        })
        .select()
        .single();

    return AssignmentModel.fromJson(response);
  }

  Future<List<AssignmentModel>> fetchRoomAssignments(String roomId) async {
    final response = await _client
        .from('assignments')
        .select()
        .eq('room_id', roomId)
        .order('due_date', ascending: false);

    return (response as List)
        .map((row) => AssignmentModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<AssignmentModel> fetchAssignment(String assignmentId) async {
    final response = await _client
        .from('assignments')
        .select()
        .eq('id', assignmentId)
        .single();
    return AssignmentModel.fromJson(response);
  }

  /// Student submits or updates their own submission (upsert since
  /// there's a unique constraint on assignment_id+student_id).
  Future<SubmissionModel> submitAssignment({
    required String assignmentId,
    required SubmissionType type,
    String? textContent,
    String? fileUrl,
  }) async {
    final studentId = _client.auth.currentUser?.id;
    if (studentId == null) throw StateError('Not signed in.');

    final response = await _client
        .from('submissions')
        .upsert({
          'assignment_id': assignmentId,
          'student_id': studentId,
          'type': type.name,
          'text_content': textContent,
          'file_url': fileUrl,
        }, onConflict: 'assignment_id,student_id')
        .select()
        .single();

    return SubmissionModel.fromJson(response);
  }

  /// The current student's own submission for an assignment, if any.
  Future<SubmissionModel?> fetchMySubmission(String assignmentId) async {
    final studentId = _client.auth.currentUser?.id;
    if (studentId == null) return null;

    final response = await _client
        .from('submissions')
        .select()
        .eq('assignment_id', assignmentId)
        .eq('student_id', studentId)
        .maybeSingle();

    if (response == null) return null;
    return SubmissionModel.fromJson(response);
  }

  /// All submissions for an assignment, joined with student profile
  /// (spec §2.6: teacher reviews submissions).
  Future<List<SubmissionModel>> fetchSubmissionsForAssignment(
      String assignmentId) async {
    final response = await _client
        .from('submissions')
        .select('*, profiles(full_name)')
        .eq('assignment_id', assignmentId)
        .order('submitted_at');

    return (response as List)
        .map((row) => SubmissionModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Teacher grades a submission (spec §2.6).
  Future<void> gradeSubmission({
    required String submissionId,
    required String grade,
    String? feedback,
  }) async {
    await _client.from('submissions').update({
      'grade': grade,
      'feedback': feedback,
      'graded_at': DateTime.now().toIso8601String(),
    }).eq('id', submissionId);
  }
}
