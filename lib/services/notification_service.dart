import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../models/notification_model.dart';

/// Handles in-app notifications (spec §1, §2.4). Most notification
/// rows are auto-created by database triggers (see
/// 0010_notifications.sql) — this service mainly reads them and lets
/// teachers send custom/manual ones.
class NotificationService {
  NotificationService({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  /// Realtime stream of the current user's notifications, newest first.
  Stream<List<NotificationModel>> watchMyNotifications() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('recipient_id', userId)
        .order('created_at')
        .map((rows) {
          final list = rows.map(NotificationModel.fromJson).toList();
          return list.reversed.toList(); // newest first
        });
  }

  Future<int> unreadCount() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    final response = await _client
        .from('notifications')
        .select('id')
        .eq('recipient_id', userId)
        .filter('read_at', 'is', null)
        .count(CountOption.exact);

    return response.count;
  }

  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('recipient_id', userId)
        .filter('read_at', 'is', null);
  }

  /// Teacher sends a custom/manual notification to every student in a
  /// room (spec §2.4: "Teacher can also send custom (manual)
  /// notifications anytime").
  Future<void> sendCustomNotification({
    required String roomId,
    required List<String> studentIds,
    required String title,
    String? body,
  }) async {
    if (studentIds.isEmpty) return;

    final rows = studentIds
        .map((studentId) => {
              'recipient_id': studentId,
              'type': 'custom',
              'title': title,
              'body': body,
              'room_id': roomId,
            })
        .toList();

    await _client.from('notifications').insert(rows);
  }
}
