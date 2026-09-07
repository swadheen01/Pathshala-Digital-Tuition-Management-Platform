import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../models/parent_link_model.dart';
import '../models/room_model.dart';

/// Handles parent-student linking (teacher grants) and fetching a
/// linked child's data for the parent's read-only view (spec §2.8).
class ParentService {
  ParentService({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  /// Teacher grants a parent read-only access to a student.
  Future<ParentLinkModel> grantParentAccess({
    required String parentEmail,
    required String studentId,
  }) async {
    final teacherId = _client.auth.currentUser?.id;
    if (teacherId == null) throw StateError('Not signed in.');

    // Look up the parent's profile by email — they must already have
    // a Pathshala account with role = 'parent'.
    final parentProfile = await _client
        .from('profiles')
        .select('id')
        .eq('email', parentEmail.trim())
        .eq('role', 'parent')
        .maybeSingle();

    if (parentProfile == null) {
      throw Exception(
          'No parent account found for that email. They need to sign up first.');
    }

    final response = await _client
        .from('parent_links')
        .insert({
          'parent_id': parentProfile['id'],
          'student_id': studentId,
          'granted_by': teacherId,
        })
        .select('*, profiles!parent_links_student_id_fkey(full_name)')
        .single();

    return ParentLinkModel.fromJson(response);
  }

  Future<void> revokeParentAccess(String linkId) async {
    await _client.from('parent_links').delete().eq('id', linkId);
  }

  /// Every parent link for students in a specific room (teacher's
  /// parent-access management screen, spec §2.8). Fetches the room's
  /// student ids first, then filters parent_links — parent_links has
  /// no direct FK to room_members, so this avoids relying on an
  /// implicit PostgREST join that wouldn't otherwise resolve.
  Future<List<ParentLinkModel>> fetchLinksForRoom(String roomId) async {
    final memberRows = await _client
        .from('room_members')
        .select('student_id')
        .eq('room_id', roomId);

    final studentIds =
        (memberRows as List).map((r) => r['student_id'] as String).toList();

    if (studentIds.isEmpty) return [];

    final response = await _client
        .from('parent_links')
        .select('*, profiles!parent_links_student_id_fkey(full_name)')
        .inFilter('student_id', studentIds);

    return (response as List)
        .map((row) => ParentLinkModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Children linked to the currently signed-in parent (spec §2.8).
  Future<List<ParentLinkModel>> fetchMyChildren() async {
    final parentId = _client.auth.currentUser?.id;
    if (parentId == null) return [];

    final response = await _client
        .from('parent_links')
        .select('*, profiles!parent_links_student_id_fkey(full_name)')
        .eq('parent_id', parentId);

    return (response as List)
        .map((row) => ParentLinkModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Rooms a linked child belongs to — lets the parent pick which room's
  /// attendance/payments/performance to view (spec §2.8). Relies on the
  /// room_members_select_parent / rooms_select_parent RLS policies.
  Future<List<RoomModel>> fetchChildRooms(String studentId) async {
    final response = await _client
        .from('room_members')
        .select('rooms(*)')
        .eq('student_id', studentId);

    return (response as List)
        .map((row) => RoomModel.fromJson(row['rooms'] as Map<String, dynamic>))
        .toList();
  }
}
