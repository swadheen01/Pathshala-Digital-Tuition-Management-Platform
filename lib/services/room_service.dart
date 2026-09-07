import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../models/room_member_model.dart';
import '../models/room_model.dart';

/// Result of looking up a room by its join code before actually joining.
class RoomCodeLookup {
  const RoomCodeLookup({
    required this.roomId,
    required this.name,
    this.subject,
    this.unclaimedNames = const [],
  });

  final String roomId;
  final String name;
  final String? subject;

  /// Names of teacher-added students in this room that no account has
  /// claimed yet — offered to the joining student as "is this you?".
  final List<String> unclaimedNames;
}

/// Handles all Supabase calls related to Tuition Rooms (spec §2.1, §2.5).
class RoomService {
  RoomService({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  static const _joinCodeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no O/0/I/1

  String _generateJoinCode({int length = 6}) {
    final rand = Random.secure();
    return List.generate(
      length,
      (_) => _joinCodeChars[rand.nextInt(_joinCodeChars.length)],
    ).join();
  }

  /// Creates a new room for the currently signed-in teacher.
  /// Retries a couple of times on the (rare) join-code collision.
  Future<RoomModel> createRoom({
    required String name,
    String? subject,
    String? description,
    List<int> classDays = const [],
    String? classStartTime,
    String? classEndTime,
  }) async {
    final teacherId = _client.auth.currentUser?.id;
    if (teacherId == null) {
      throw StateError('Must be signed in to create a room.');
    }

    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await _client
            .from('rooms')
            .insert({
              'teacher_id': teacherId,
              'name': name,
              'subject': subject,
              'description': description,
              'join_code': _generateJoinCode(),
              'class_days': classDays,
              if (classStartTime != null) 'class_start_time': classStartTime,
              if (classEndTime != null) 'class_end_time': classEndTime,
            })
            .select()
            .single();
        return RoomModel.fromJson(response);
      } on PostgrestException catch (e) {
        // Unique violation on join_code — retry with a new code.
        if (e.code == '23505' && attempt < 2) continue;
        rethrow;
      }
    }
    throw StateError('Could not generate a unique join code. Try again.');
  }

  /// Rooms owned by the current teacher.
  Future<List<RoomModel>> fetchTeacherRooms() async {
    final teacherId = _client.auth.currentUser?.id;
    if (teacherId == null) return [];

    final response = await _client
        .from('rooms')
        .select()
        .eq('teacher_id', teacherId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => RoomModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Rooms the current student has joined.
  Future<List<RoomModel>> fetchStudentRooms() async {
    final studentId = _client.auth.currentUser?.id;
    if (studentId == null) return [];

    final response = await _client
        .from('room_members')
        .select('rooms(*)')
        .eq('student_id', studentId);

    return (response as List)
        .map((row) =>
            RoomModel.fromJson(row['rooms'] as Map<String, dynamic>))
        .toList();
  }

  /// Student joins a room using the teacher-provided join code (spec §2.1).
  /// Calls the join_room RPC (see 0002_rooms.sql) so we don't need a
  /// broad "anyone can read any room" RLS policy just for lookups.
  Future<RoomModel> joinRoomByCode(String joinCode, {String? rollNumber}) async {
    try {
      final response = await _client.rpc('join_room', params: {
        'p_join_code': joinCode.trim().toUpperCase(),
        'p_roll_number': rollNumber,
      });
      return RoomModel.fromJson(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      if (e.message.contains('Invalid join code')) {
        throw Exception('Invalid join code. Please check and try again.');
      }
      rethrow;
    }
  }

  Future<RoomModel> fetchRoomById(String roomId) async {
    final response =
        await _client.from('rooms').select().eq('id', roomId).single();
    return RoomModel.fromJson(response);
  }

  /// Update room settings — schedule, chat toggle, leaderboard toggle.
  /// Pass `clearTimes: true` to null out the class window.
  Future<RoomModel> updateRoom(
    String roomId, {
    String? name,
    String? subject,
    String? description,
    bool? chatEnabled,
    bool? leaderboardEnabled,
    List<int>? classDays,
    String? classStartTime,
    String? classEndTime,
    bool clearTimes = false,
  }) async {
    final updates = <String, dynamic>{
      if (name != null) 'name': name,
      if (subject != null) 'subject': subject,
      if (description != null) 'description': description,
      if (chatEnabled != null) 'chat_enabled': chatEnabled,
      if (leaderboardEnabled != null)
        'leaderboard_enabled': leaderboardEnabled,
      if (classDays != null) 'class_days': classDays,
      if (clearTimes) 'class_start_time': null,
      if (clearTimes) 'class_end_time': null,
      if (!clearTimes && classStartTime != null)
        'class_start_time': classStartTime,
      if (!clearTimes && classEndTime != null) 'class_end_time': classEndTime,
    };

    final response = await _client
        .from('rooms')
        .update(updates)
        .eq('id', roomId)
        .select()
        .single();

    return RoomModel.fromJson(response);
  }

  /// Roster of students in a room, joined with profile info (spec §2.1).
  Future<List<RoomMemberWithProfile>> fetchRoomMembers(String roomId) async {
    final response = await _client
        .from('room_members')
        .select('*, profiles(full_name, email, avatar_url)')
        .eq('room_id', roomId)
        .order('joined_at');

    return (response as List)
        .map((row) =>
            RoomMemberWithProfile.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Teacher adds a student by name — no account required (spec §2.1).
  /// The row is "unclaimed" until a joining student is linked to it.
  Future<void> addRosterStudent({
    required String roomId,
    required String fullName,
    String? rollNumber,
    String? phone,
    String? email,
    num monthlyFee = 0,
  }) async {
    await _client.from('room_members').insert({
      'room_id': roomId,
      'student_id': null,
      'full_name': fullName.trim(),
      'roll_number': rollNumber?.trim().isEmpty ?? true ? null : rollNumber!.trim(),
      'phone': phone?.trim().isEmpty ?? true ? null : phone!.trim(),
      'email': email?.trim().isEmpty ?? true ? null : email!.trim(),
      'monthly_fee': monthlyFee,
    });
  }

  /// Edit an existing roster row (name / roll / contact / fee).
  Future<void> updateRosterStudent({
    required String memberId,
    String? fullName,
    String? rollNumber,
    String? phone,
    String? email,
    num? monthlyFee,
  }) async {
    await _client.from('room_members').update({
      if (fullName != null) 'full_name': fullName.trim(),
      if (rollNumber != null)
        'roll_number': rollNumber.trim().isEmpty ? null : rollNumber.trim(),
      if (phone != null) 'phone': phone.trim().isEmpty ? null : phone.trim(),
      if (email != null) 'email': email.trim().isEmpty ? null : email.trim(),
      if (monthlyFee != null) 'monthly_fee': monthlyFee,
    }).eq('id', memberId);
  }

  Future<void> removeMemberById(String memberId) async {
    await _client.from('room_members').delete().eq('id', memberId);
  }

  /// Look up a room by code and see which names are still unclaimed,
  /// without joining yet (calls the find_room_by_code RPC, 0015).
  Future<RoomCodeLookup?> findRoomByCode(String joinCode) async {
    final rows = await _client.rpc('find_room_by_code', params: {
      'p_join_code': joinCode.trim().toUpperCase(),
    }) as List;
    if (rows.isEmpty) return null;
    final row = rows.first as Map<String, dynamic>;
    return RoomCodeLookup(
      roomId: row['room_id'] as String,
      name: row['name'] as String? ?? 'Room',
      subject: row['subject'] as String?,
      unclaimedNames:
          (row['unclaimed_names'] as List? ?? []).cast<String>(),
    );
  }

  /// Student asks to be linked to a name-only roster row. Returns the
  /// room name on success (request is now pending teacher approval).
  Future<String> requestClaim({
    required String joinCode,
    required String fullName,
  }) async {
    final result = await _client.rpc('request_room_claim', params: {
      'p_join_code': joinCode.trim().toUpperCase(),
      'p_full_name': fullName.trim(),
    });
    return result as String? ?? 'the room';
  }

  Future<List<RoomJoinRequestModel>> fetchJoinRequests(String roomId) async {
    final rows = await _client.rpc('get_room_join_requests', params: {
      'p_room_id': roomId,
    }) as List;
    return rows
        .map((r) =>
            RoomJoinRequestModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> approveClaim(String requestId) async {
    await _client.rpc('approve_room_claim', params: {'p_request_id': requestId});
  }

  Future<void> rejectClaim(String requestId) async {
    await _client.rpc('reject_room_claim', params: {'p_request_id': requestId});
  }

  Future<void> removeMember(String roomId, String studentId) async {
    await _client
        .from('room_members')
        .delete()
        .eq('room_id', roomId)
        .eq('student_id', studentId);
  }

  Future<void> deleteRoom(String roomId) async {
    await _client.from('rooms').delete().eq('id', roomId);
  }
}
