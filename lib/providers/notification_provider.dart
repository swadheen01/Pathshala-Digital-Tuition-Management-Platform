import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_model.dart';
import '../services/notification_service.dart';

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

/// Realtime stream of the current user's notifications (spec §1, §3).
final myNotificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  return ref.watch(notificationServiceProvider).watchMyNotifications();
});

/// Unread count — used for a badge on the notifications icon.
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(myNotificationsProvider).valueOrNull ?? [];
  return notifications.where((n) => n.isUnread).length;
});

class NotificationController extends StateNotifier<AsyncValue<void>> {
  NotificationController(this._service) : super(const AsyncData(null));

  final NotificationService _service;

  Future<void> markAsRead(String notificationId) async {
    await _service.markAsRead(notificationId);
  }

  Future<void> markAllAsRead() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.markAllAsRead());
  }

  Future<bool> sendCustom({
    required String roomId,
    required List<String> studentIds,
    required String title,
    String? body,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _service.sendCustomNotification(
          roomId: roomId,
          studentIds: studentIds,
          title: title,
          body: body,
        ));
    state = result.hasError
        ? AsyncError(result.error!, result.stackTrace!)
        : const AsyncData(null);
    return !result.hasError;
  }
}

final notificationControllerProvider =
    StateNotifierProvider<NotificationController, AsyncValue<void>>((ref) {
  return NotificationController(ref.watch(notificationServiceProvider));
});
