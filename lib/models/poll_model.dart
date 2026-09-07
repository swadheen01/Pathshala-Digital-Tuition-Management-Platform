import 'package:equatable/equatable.dart';

/// A poll created by a teacher for voting/feedback (spec §2.2).
class PollModel extends Equatable {
  const PollModel({
    required this.id,
    required this.roomId,
    required this.question,
    required this.options,
    this.createdBy,
    this.createdAt,
  });

  final String id;
  final String roomId;
  final String question;
  final List<PollOption> options;
  final String? createdBy;
  final DateTime? createdAt;

  int get totalVotes => options.fold(0, (sum, o) => sum + o.voteCount);

  factory PollModel.fromJson(Map<String, dynamic> json) {
    return PollModel(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      question: json['question'] as String,
      options: (json['poll_options'] as List<dynamic>? ?? [])
          .map((o) => PollOption.fromJson(o as Map<String, dynamic>))
          .toList(),
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, roomId, question, options];
}

class PollOption extends Equatable {
  const PollOption({
    required this.id,
    required this.pollId,
    required this.label,
    this.voteCount = 0,
  });

  final String id;
  final String pollId;
  final String label;
  final int voteCount;

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id'] as String,
      pollId: json['poll_id'] as String,
      label: json['label'] as String,
      voteCount: json['vote_count'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, pollId, label, voteCount];
}

/// One student's vote on a poll option. Unique per (poll, student) —
/// enforced server-side so a student can't vote twice (spec §2.2, §3).
class PollVote extends Equatable {
  const PollVote({
    required this.id,
    required this.pollId,
    required this.optionId,
    required this.studentId,
  });

  final String id;
  final String pollId;
  final String optionId;
  final String studentId;

  factory PollVote.fromJson(Map<String, dynamic> json) {
    return PollVote(
      id: json['id'] as String,
      pollId: json['poll_id'] as String,
      optionId: json['option_id'] as String,
      studentId: json['student_id'] as String,
    );
  }

  @override
  List<Object?> get props => [id, pollId, optionId, studentId];
}
