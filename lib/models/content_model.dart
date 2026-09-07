import 'package:equatable/equatable.dart';

/// Curated content (YouTube/external links) managed by Admin (spec §4).
/// Visible to all students, or targeted by class/grade.
class ContentModel extends Equatable {
  const ContentModel({
    required this.id,
    required this.title,
    required this.url,
    this.description,
    this.thumbnailUrl,
    this.targetClassGrade, // null = visible to all students (spec §4)
    this.subject,
    this.createdBy,
    this.createdAt,
  });

  final String id;
  final String title;
  final String url; // YouTube or other external link
  final String? description;
  final String? thumbnailUrl;
  final String? targetClassGrade;
  final String? subject;
  final String? createdBy;
  final DateTime? createdAt;

  bool get isGeneral => targetClassGrade == null;

  factory ContentModel.fromJson(Map<String, dynamic> json) {
    return ContentModel(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      targetClassGrade: json['target_class_grade'] as String?,
      subject: json['subject'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'description': description,
      'thumbnail_url': thumbnailUrl,
      'target_class_grade': targetClassGrade,
      'subject': subject,
      'created_by': createdBy,
    };
  }

  @override
  List<Object?> get props =>
      [id, title, url, description, targetClassGrade, subject];
}

/// Aggregate platform stats for the admin analytics dashboard (spec §4).
class PlatformAnalytics extends Equatable {
  const PlatformAnalytics({
    required this.activeTeachers,
    required this.activeStudents,
    required this.totalRooms,
    required this.totalContent,
    required this.mostViewedContent,
  });

  final int activeTeachers;
  final int activeStudents;
  final int totalRooms;
  final int totalContent;
  final List<ContentEngagement> mostViewedContent;

  factory PlatformAnalytics.fromJson(Map<String, dynamic> json) {
    return PlatformAnalytics(
      activeTeachers: json['active_teachers'] as int? ?? 0,
      activeStudents: json['active_students'] as int? ?? 0,
      totalRooms: json['total_rooms'] as int? ?? 0,
      totalContent: json['total_content'] as int? ?? 0,
      mostViewedContent: (json['most_viewed_content'] as List<dynamic>? ?? [])
          .map((e) => ContentEngagement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        activeTeachers,
        activeStudents,
        totalRooms,
        totalContent,
        mostViewedContent,
      ];
}

class ContentEngagement extends Equatable {
  const ContentEngagement({
    required this.contentId,
    required this.title,
    required this.viewCount,
  });

  final String contentId;
  final String title;
  final int viewCount;

  factory ContentEngagement.fromJson(Map<String, dynamic> json) {
    return ContentEngagement(
      contentId: json['content_id'] as String,
      title: json['title'] as String? ?? '',
      viewCount: json['view_count'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [contentId, title, viewCount];
}
