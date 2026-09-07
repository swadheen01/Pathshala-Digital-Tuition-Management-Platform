import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../models/content_model.dart';
import '../models/user_model.dart';

/// Admin-only operations: list/manage teachers & students, view
/// analytics (spec §4). Relies on the `profiles_select_admin` RLS
/// policy (0001_init.sql) to allow reading every profile.
class AdminService {
  AdminService({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  Future<List<UserModel>> fetchTeachers() async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('role', 'teacher')
        .order('full_name');

    return (response as List)
        .map((row) => UserModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserModel>> fetchStudents() async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('role', 'student')
        .order('full_name');

    return (response as List)
        .map((row) => UserModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Platform analytics dashboard (spec §4): active users, rooms,
  /// content, engagement. Calls the get_platform_analytics RPC which
  /// self-checks that the caller is an admin.
  Future<PlatformAnalytics> fetchAnalytics() async {
    final response = await _client.rpc('get_platform_analytics');
    return PlatformAnalytics.fromJson(response as Map<String, dynamic>);
  }

  /// Removing a teacher/student account. Cascades via FK constraints
  /// to their rooms/memberships (see migrations) — use with caution.
  Future<void> deleteUser(String userId) async {
    await _client.from('profiles').delete().eq('id', userId);
  }
}
