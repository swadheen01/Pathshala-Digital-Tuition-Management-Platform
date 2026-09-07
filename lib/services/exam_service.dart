import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../models/exam_model.dart';

/// Handles exams, scores, performance graphs, and leaderboard (spec §2.7).
class ExamService {
  ExamService({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  Future<ExamModel> createExam({
    required String roomId,
    required String title,
    required double maxMarks,
    DateTime? examDate,
  }) async {
    final teacherId = _client.auth.currentUser?.id;
    if (teacherId == null) throw StateError('Not signed in.');

    final response = await _client
        .from('exams')
        .insert({
          'room_id': roomId,
          'title': title,
          'max_marks': maxMarks,
          'exam_date': examDate?.toIso8601String().split('T').first,
          'created_by': teacherId,
        })
        .select()
        .single();

    return ExamModel.fromJson(response);
  }

  Future<List<ExamModel>> fetchRoomExams(String roomId) async {
    final response = await _client
        .from('exams')
        .select()
        .eq('room_id', roomId)
        .order('exam_date', ascending: false);

    return (response as List)
        .map((row) => ExamModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Bulk-records scores for every student in one exam (upsert).
  Future<void> recordScoresBulk({
    required String examId,
    required Map<String, double> marksByStudent,
  }) async {
    final rows = marksByStudent.entries
        .map((e) => {
              'exam_id': examId,
              'student_id': e.key,
              'marks_obtained': e.value,
            })
        .toList();

    if (rows.isEmpty) return;

    await _client
        .from('exam_scores')
        .upsert(rows, onConflict: 'exam_id,student_id');
  }

  Future<List<ExamScoreModel>> fetchScoresForExam(String examId) async {
    final response = await _client
        .from('exam_scores')
        .select('*, profiles(full_name)')
        .eq('exam_id', examId);

    return (response as List)
        .map((row) => ExamScoreModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// A single student's performance across every exam in a room —
  /// feeds the performance graph (spec §2.7, §3).
  Future<List<PerformancePoint>> fetchStudentPerformance({
    required String roomId,
    required String studentId,
  }) async {
    final response = await _client
        .from('exam_scores')
        .select('marks_obtained, exams!inner(title, exam_date, max_marks, room_id)')
        .eq('student_id', studentId)
        .eq('exams.room_id', roomId);

    return (response as List).map((row) {
      final exam = row['exams'] as Map<String, dynamic>;
      return PerformancePoint(
        examTitle: exam['title'] as String,
        examDate: exam['exam_date'] != null
            ? DateTime.tryParse(exam['exam_date'] as String)
            : null,
        marksObtained: (row['marks_obtained'] as num).toDouble(),
        maxMarks: (exam['max_marks'] as num).toDouble(),
      );
    }).toList();
  }

  /// Leaderboard for a room. Caller should check room.leaderboardEnabled
  /// before showing this to students (spec §2.7 — teacher-controlled).
  Future<List<LeaderboardEntry>> fetchLeaderboard(String roomId) async {
    final response = await _client.rpc(
      'get_leaderboard',
      params: {'p_room_id': roomId},
    );

    return (response as List)
        .map((row) => LeaderboardEntry.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
