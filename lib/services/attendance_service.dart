import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../models/attendance_model.dart';

/// Handles Supabase calls for attendance (spec §2.3).
/// Offline queuing/retry lives in offline_sync_service.dart — this
/// service assumes network is available when its methods are called.
class AttendanceService {
  AttendanceService({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Marks/updates attendance for a whole room on one date in a single
  /// upsert call (spec §2.3: tick/check per student for a specific date).
  /// `presentMap` keys are student_id, values are true/false.
  Future<void> markAttendanceBulk({
    required String roomId,
    required DateTime date,
    required Map<String, bool> presentMap,
  }) async {
    final teacherId = _client.auth.currentUser?.id;

    final rows = presentMap.entries
        .map((e) => {
              'room_id': roomId,
              'student_id': e.key,
              'date': _dateOnly(date),
              'present': e.value,
              'marked_by': teacherId,
            })
        .toList();

    if (rows.isEmpty) return;

    await _client
        .from('attendance')
        .upsert(rows, onConflict: 'room_id,student_id,date');
  }

  /// Attendance for a room on a specific date — used to pre-fill the
  /// teacher's marking screen if attendance was already taken.
  Future<Map<String, bool>> fetchAttendanceForDate({
    required String roomId,
    required DateTime date,
  }) async {
    final response = await _client
        .from('attendance')
        .select('student_id, present')
        .eq('room_id', roomId)
        .eq('date', _dateOnly(date));

    return {
      for (final row in response as List)
        row['student_id'] as String: row['present'] as bool,
    };
  }

  /// A single student's attendance history in a room (for their own
  /// summary view or the teacher's per-student drill-down).
  Future<List<AttendanceModel>> fetchStudentHistory({
    required String roomId,
    required String studentId,
  }) async {
    final response = await _client
        .from('attendance')
        .select()
        .eq('room_id', roomId)
        .eq('student_id', studentId)
        .order('date', ascending: false);

    return (response as List)
        .map((row) => AttendanceModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// The signed-in student's attendance standing in each of their rooms
  /// (get_my_room_attendance RPC, 0016) — for the home screen.
  Future<List<RoomAttendanceStat>> fetchMyRoomAttendance() async {
    final rows = await _client.rpc('get_my_room_attendance') as List;
    return rows
        .map((r) => RoomAttendanceStat.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Percentage summary for every student in a room (spec §2.3).
  /// Calls the get_attendance_summary RPC (see 0003_attendance.sql).
  Future<List<AttendanceSummary>> fetchRoomSummary(String roomId) async {
    final response = await _client.rpc(
      'get_attendance_summary',
      params: {'p_room_id': roomId},
    );

    return (response as List)
        .map((row) => AttendanceSummary.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
