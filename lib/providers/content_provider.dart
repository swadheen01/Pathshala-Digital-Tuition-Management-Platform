import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/content_model.dart';
import '../providers/auth_provider.dart';
import '../services/content_service.dart';

final contentServiceProvider =
    Provider<ContentService>((ref) => ContentService());

/// Full content list — admin management screen (spec §4).
final allContentProvider = FutureProvider<List<ContentModel>>((ref) {
  return ref.watch(contentServiceProvider).fetchAllContent();
});

/// Student's home feed: general content + content targeted to their
/// own class/grade (spec §3). Reads class_grade from their profile.
final studentContentFeedProvider = FutureProvider<List<ContentModel>>((ref) async {
  final profile = await ref.watch(currentProfileProvider.future);
  return ref
      .watch(contentServiceProvider)
      .fetchFeedForStudent(profile?.classGrade);
});

/// Search/filter, keyed by a simple query object so results are cached
/// per unique (keyword, subject) pair.
final contentSearchProvider = FutureProvider.family<List<ContentModel>,
    ({String? keyword, String? subject})>((ref, query) {
  return ref
      .watch(contentServiceProvider)
      .search(keyword: query.keyword, subject: query.subject);
});

class ContentController extends StateNotifier<AsyncValue<void>> {
  ContentController(this._service) : super(const AsyncData(null));

  final ContentService _service;

  Future<bool> createContent({
    required String title,
    required String url,
    String? description,
    String? targetClassGrade,
    String? subject,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _service.createContent(
          title: title,
          url: url,
          description: description,
          targetClassGrade: targetClassGrade,
          subject: subject,
        ));
    state = result.hasError
        ? AsyncError(result.error!, result.stackTrace!)
        : const AsyncData(null);
    return !result.hasError;
  }

  Future<bool> deleteContent(String contentId) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _service.deleteContent(contentId));
    state = result.hasError
        ? AsyncError(result.error!, result.stackTrace!)
        : const AsyncData(null);
    return !result.hasError;
  }

  Future<void> logView(String contentId) async {
    await _service.logView(contentId);
  }
}

final contentControllerProvider =
    StateNotifierProvider<ContentController, AsyncValue<void>>((ref) {
  return ContentController(ref.watch(contentServiceProvider));
});
