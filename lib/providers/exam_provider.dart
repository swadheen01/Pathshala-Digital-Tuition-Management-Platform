import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/exam_model.dart';
import '../services/exam_service.dart';

final examServiceProvider = Provider<ExamService>((ref) => ExamService());

final roomExamsProvider =
    FutureProvider.family<List<ExamModel>, String>((ref, roomId) {
  return ref.watch(examServiceProvider).fetchRoomExams(roomId);
});

final examScoresProvider =
    FutureProvider.family<List<ExamScoreModel>, String>((ref, examId) {
  return ref.watch(examServiceProvider).fetchScoresForExam(examId);
});

/// The current student's own performance across all exams in a room.
final myPerformanceProvider =
    FutureProvider.family<List<PerformancePoint>, String>((ref, roomId) {
  final studentId = Supabase.instance.client.auth.currentUser?.id ?? '';
  return ref
      .watch(examServiceProvider)
      .fetchStudentPerformance(roomId: roomId, studentId: studentId);
});

final leaderboardProvider =
    FutureProvider.family<List<LeaderboardEntry>, String>((ref, roomId) {
  return ref.watch(examServiceProvider).fetchLeaderboard(roomId);
});

class ExamController extends StateNotifier<AsyncValue<void>> {
  ExamController(this._service) : super(const AsyncData(null));

  final ExamService _service;

  Future<bool> createExam({
    required String roomId,
    required String title,
    required double maxMarks,
    DateTime? examDate,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _service.createExam(
          roomId: roomId,
          title: title,
          maxMarks: maxMarks,
          examDate: examDate,
        ));
    state = result.hasError
        ? AsyncError(result.error!, result.stackTrace!)
        : const AsyncData(null);
    return !result.hasError;
  }

  Future<bool> recordScores({
    required String examId,
    required Map<String, double> marksByStudent,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _service.recordScoresBulk(
          examId: examId,
          marksByStudent: marksByStudent,
        ));
    state = result.hasError
        ? AsyncError(result.error!, result.stackTrace!)
        : const AsyncData(null);
    return !result.hasError;
  }
}

final examControllerProvider =
    StateNotifierProvider<ExamController, AsyncValue<void>>((ref) {
  return ExamController(ref.watch(examServiceProvider));
});
