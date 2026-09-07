import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show TimeOfDay;

/// A Tuition Room, created by a teacher (spec §2.1).
/// Students join using `joinCode`. Mirrors the `rooms` table.
class RoomModel extends Equatable {
  const RoomModel({
    required this.id,
    required this.teacherId,
    required this.name,
    required this.joinCode,
    this.subject,
    this.description,
    this.chatEnabled = false,
    this.leaderboardEnabled = false,
    this.classDays = const [],
    this.classStartTime,
    this.classEndTime,
    this.createdAt,
  });

  final String id;
  final String teacherId;
  final String name;
  final String joinCode; // short unique code students enter to join (§2.1)
  final String? subject;
  final String? description;
  final bool chatEnabled; // teacher-controlled toggle (§2.2)
  final bool leaderboardEnabled; // teacher-controlled toggle (§2.7)

  /// Weekday ints, 1 (Sunday) – 7 (Saturday), matching spec §2.5.
  /// Attendance can only be marked on these days.
  final List<int> classDays;

  /// "HH:MM:SS" (Postgres `time`) — optional class window used by the home
  /// screen to show which class is on now / which is next.
  final String? classStartTime;
  final String? classEndTime;

  final DateTime? createdAt;

  TimeOfDay? get startTime => _parseTime(classStartTime);
  TimeOfDay? get endTime => _parseTime(classEndTime);

  static TimeOfDay? _parseTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      name: json['name'] as String,
      joinCode: json['join_code'] as String,
      subject: json['subject'] as String?,
      description: json['description'] as String?,
      chatEnabled: json['chat_enabled'] as bool? ?? false,
      leaderboardEnabled: json['leaderboard_enabled'] as bool? ?? false,
      classDays: (json['class_days'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [],
      classStartTime: json['class_start_time'] as String?,
      classEndTime: json['class_end_time'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacher_id': teacherId,
      'name': name,
      'join_code': joinCode,
      'subject': subject,
      'description': description,
      'chat_enabled': chatEnabled,
      'leaderboard_enabled': leaderboardEnabled,
      'class_days': classDays,
      'class_start_time': classStartTime,
      'class_end_time': classEndTime,
    };
  }

  RoomModel copyWith({
    String? name,
    String? subject,
    String? description,
    bool? chatEnabled,
    bool? leaderboardEnabled,
    List<int>? classDays,
    String? classStartTime,
    String? classEndTime,
  }) {
    return RoomModel(
      id: id,
      teacherId: teacherId,
      name: name ?? this.name,
      joinCode: joinCode,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      chatEnabled: chatEnabled ?? this.chatEnabled,
      leaderboardEnabled: leaderboardEnabled ?? this.leaderboardEnabled,
      classDays: classDays ?? this.classDays,
      classStartTime: classStartTime ?? this.classStartTime,
      classEndTime: classEndTime ?? this.classEndTime,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        teacherId,
        name,
        joinCode,
        subject,
        description,
        chatEnabled,
        leaderboardEnabled,
        classDays,
      ];
}
