import 'package:equatable/equatable.dart';

/// Join-table row linking a student to a room (spec §2.1).
///
/// A row may be **claimed** (backed by a real account — [studentId] set) or
/// **unclaimed** (a name-only student the teacher added; [studentId] null).
/// [refId] is the stable identity used everywhere attendance / payments /
/// exam scores are recorded: the profile id for a real user, otherwise the
/// roster row's own id.
class RoomMemberModel extends Equatable {
  const RoomMemberModel({
    required this.id,
    required this.roomId,
    this.studentId,
    this.rosterName,
    this.phone,
    this.email,
    this.rollNumber,
    this.monthlyFee = 0,
    this.joinedAt,
    String? refId,
  }) : _refId = refId;

  final String id;
  final String roomId;

  /// Non-null once linked to a real account.
  final String? studentId;

  /// Name typed by the teacher for a name-only student.
  final String? rosterName;
  final String? phone;
  final String? email;
  final String? rollNumber;
  final num monthlyFee;
  final DateTime? joinedAt;

  final String? _refId;

  /// Identity used by attendance / payments / exam_scores.
  String get refId => _refId ?? studentId ?? id;

  bool get isClaimed => studentId != null;

  factory RoomMemberModel.fromJson(Map<String, dynamic> json) {
    return RoomMemberModel(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      studentId: json['student_id'] as String?,
      rosterName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      rollNumber: json['roll_number'] as String?,
      monthlyFee: (json['monthly_fee'] as num?) ?? 0,
      refId: json['ref_id'] as String?,
      joinedAt: json['joined_at'] != null
          ? DateTime.tryParse(json['joined_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'student_id': studentId,
      'full_name': rosterName,
      'phone': phone,
      'email': email,
      'roll_number': rollNumber,
      'monthly_fee': monthlyFee,
    };
  }

  @override
  List<Object?> get props =>
      [id, roomId, studentId, rosterName, phone, email, rollNumber, monthlyFee];
}

/// A room membership joined with the linked profile (when there is one).
/// Convenient for rendering roster screens without a second query.
class RoomMemberWithProfile extends Equatable {
  const RoomMemberWithProfile({
    required this.member,
    required this.studentName,
    this.studentEmail,
    this.avatarUrl,
  });

  final RoomMemberModel member;
  final String studentName;
  final String? studentEmail;
  final String? avatarUrl;

  /// True when this is a teacher-added name-only student.
  bool get isUnclaimed => !member.isClaimed;

  /// Stable id for attendance / payments / exams.
  String get refId => member.refId;

  factory RoomMemberWithProfile.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>? ?? const {};
    final member = RoomMemberModel.fromJson(json);
    final profileName = profile['full_name'] as String?;
    final name = (profileName != null && profileName.trim().isNotEmpty)
        ? profileName
        : (member.rosterName?.trim().isNotEmpty ?? false)
            ? member.rosterName!
            : 'Unknown';
    return RoomMemberWithProfile(
      member: member,
      studentName: name,
      studentEmail: profile['email'] as String? ?? member.email,
      avatarUrl: profile['avatar_url'] as String?,
    );
  }

  @override
  List<Object?> get props => [member, studentName, studentEmail, avatarUrl];
}

/// A pending / resolved request from a student to be linked to a name-only
/// roster row (see migration 0015).
class RoomJoinRequestModel extends Equatable {
  const RoomJoinRequestModel({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.memberId,
    required this.memberName,
    required this.status,
    this.requesterEmail,
    this.createdAt,
  });

  final String id;
  final String requesterId;
  final String requesterName;
  final String? requesterEmail;
  final String memberId;
  final String memberName;
  final String status; // pending | approved | rejected
  final DateTime? createdAt;

  bool get isPending => status == 'pending';

  factory RoomJoinRequestModel.fromJson(Map<String, dynamic> json) {
    return RoomJoinRequestModel(
      id: json['id'] as String,
      requesterId: json['requester_id'] as String,
      requesterName: json['requester_name'] as String? ?? 'Unknown',
      requesterEmail: json['requester_email'] as String?,
      memberId: json['member_id'] as String,
      memberName: json['member_name'] as String? ?? 'Unknown',
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, status, memberId, requesterId];
}
