import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../models/content_model.dart';

/// Handles curated content: admin CRUD, student search/filter/view
/// (spec §3, §4).
class ContentService {
  ContentService({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  Future<ContentModel> createContent({
    required String title,
    required String url,
    String? description,
    String? thumbnailUrl,
    String? targetClassGrade,
    String? subject,
  }) async {
    final adminId = _client.auth.currentUser?.id;
    if (adminId == null) throw StateError('Not signed in.');

    final response = await _client
        .from('content')
        .insert({
          'title': title,
          'url': url,
          'description': description,
          'thumbnail_url': thumbnailUrl,
          'target_class_grade': targetClassGrade,
          'subject': subject,
          'created_by': adminId,
        })
        .select()
        .single();

    return ContentModel.fromJson(response);
  }

  Future<void> deleteContent(String contentId) async {
    await _client.from('content').delete().eq('id', contentId);
  }

  Future<List<ContentModel>> fetchAllContent() async {
    final response = await _client
        .from('content')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => ContentModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Content feed for a student's home page (spec §3): general content
  /// (target_class_grade is null) plus anything targeted to their class.
  Future<List<ContentModel>> fetchFeedForStudent(String? classGrade) async {
    final response = classGrade == null
        ? await _client
            .from('content')
            .select()
            .filter('target_class_grade', 'is', null)
            .order('created_at', ascending: false)
        : await _client
            .from('content')
            .select()
            .or('target_class_grade.is.null,target_class_grade.eq.$classGrade')
            .order('created_at', ascending: false);

    return (response as List)
        .map((row) => ContentModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Search/filter by keyword and/or subject (spec §4: available to all users).
  Future<List<ContentModel>> search({String? keyword, String? subject}) async {
    var query = _client.from('content').select();

    if (keyword != null && keyword.trim().isNotEmpty) {
      query = query.ilike('title', '%${keyword.trim()}%');
    }
    if (subject != null && subject.trim().isNotEmpty) {
      query = query.eq('subject', subject.trim());
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map((row) => ContentModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Logs a view for analytics (spec §4: most-used content, engagement).
  Future<void> logView(String contentId) async {
    final studentId = _client.auth.currentUser?.id;
    if (studentId == null) return;

    await _client.from('content_views').insert({
      'content_id': contentId,
      'student_id': studentId,
    });
  }
}
