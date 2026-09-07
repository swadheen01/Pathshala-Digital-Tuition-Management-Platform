import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/assignment_model.dart';
import '../services/assignment_service.dart';

final assignmentServiceProvider =
    Provider<AssignmentService>((ref) => AssignmentService());

final roomAssignmentsProvider =
    FutureProvider.family<List<AssignmentModel>, String>((ref, roomId) {
  return ref.watch(assignmentServiceProvider).fetchRoomAssignments(roomId);
});

final assignmentByIdProvider =
    FutureProvider.family<AssignmentModel, String>((ref, assignmentId) {
  return ref.watch(assignmentServiceProvider).fetchAssignment(assignmentId);
});

/// Current student's own submission for an assignment — null if not
/// submitted yet.
final mySubmissionProvider =
    FutureProvider.family<SubmissionModel?, String>((ref, assignmentId) {
  return ref.watch(assignmentServiceProvider).fetchMySubmission(assignmentId);
});

/// All submissions for an assignment — teacher review screen (spec §2.6).
final assignmentSubmissionsProvider =
    FutureProvider.family<List<SubmissionModel>, String>((ref, assignmentId) {
  return ref
      .watch(assignmentServiceProvider)
      .fetchSubmissionsForAssignment(assignmentId);
});

class AssignmentController extends StateNotifier<AsyncValue<void>> {
  AssignmentController(this._service) : super(const AsyncData(null));

  final AssignmentService _service;

  Future<bool> createAssignment({
    required String roomId,
    required String title,
    required DateTime dueDate,
    String? description,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _service.createAssignment(
          roomId: roomId,
          title: title,
          dueDate: dueDate,
          description: description,
        ));
    state = result.hasError
        ? AsyncError(result.error!, result.stackTrace!)
        : const AsyncData(null);
    return !result.hasError;
  }

  Future<bool> submit({
    required String assignmentId,
    required SubmissionType type,
    String? textContent,
    String? fileUrl,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _service.submitAssignment(
          assignmentId: assignmentId,
          type: type,
          textContent: textContent,
          fileUrl: fileUrl,
        ));
    state = result.hasError
        ? AsyncError(result.error!, result.stackTrace!)
        : const AsyncData(null);
    return !result.hasError;
  }

  Future<bool> gradeSubmission({
    required String submissionId,
    required String grade,
    String? feedback,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _service.gradeSubmission(
          submissionId: submissionId,
          grade: grade,
          feedback: feedback,
        ));
    state = result.hasError
        ? AsyncError(result.error!, result.stackTrace!)
        : const AsyncData(null);
    return !result.hasError;
  }
}

final assignmentControllerProvider =
    StateNotifierProvider<AssignmentController, AsyncValue<void>>((ref) {
  return AssignmentController(ref.watch(assignmentServiceProvider));
});
