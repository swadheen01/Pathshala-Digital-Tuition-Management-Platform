import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_nav_drawer.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../models/notification_model.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../generated/app_localizations.dart';
import '../../../providers/notification_provider.dart';

/// Notifications inbox — shown to every role (spec §1, §3: "Students
/// can view all notifications sent by the teacher (auto + custom)").
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return Icons.chat_bubble_outline;
      case NotificationType.poll:
        return Icons.poll_outlined;
      case NotificationType.content:
        return Icons.video_library_outlined;
      case NotificationType.attendance:
        return Icons.event_available_outlined;
      case NotificationType.assignment:
        return Icons.assignment_outlined;
      case NotificationType.examResult:
        return Icons.bar_chart_outlined;
      case NotificationType.paymentDue:
        return Icons.payment_outlined;
      case NotificationType.paymentReceived:
        return Icons.check_circle_outline;
      case NotificationType.custom:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(myNotificationsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: const AppNavDrawer(),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).notifications),
        actions: [
          TextButton(
            onPressed: () => ref
                .read(notificationControllerProvider.notifier)
                .markAllAsRead(),
            child: Text(AppLocalizations.of(context).markAllRead),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (err, _) => ErrorView(
          message: 'Unable to load notifications. Please try again.',
          onRetry: () => ref.invalidate(myNotificationsProvider),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return EmptyState(
              message: AppLocalizations.of(context).noNotifications,
              icon: Icons.notifications_none,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final n = notifications[index];
              final scheme = Theme.of(context).colorScheme;
              return GlassPanel(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  leading: Icon(
                    _iconFor(n.type),
                    color: n.isUnread ? scheme.primary : scheme.outline,
                  ),
                  title: Text(
                    n.title,
                    style: TextStyle(
                      fontWeight:
                          n.isUnread ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  subtitle: n.body != null ? Text(n.body!) : null,
                  trailing: n.createdAt != null
                      ? Text(
                          '${n.createdAt!.day}/${n.createdAt!.month}',
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      : null,
                  onTap: () {
                    if (n.isUnread) {
                      ref
                          .read(notificationControllerProvider.notifier)
                          .markAsRead(n.id);
                    }
                    // Deep-link into n.roomId here once shared room routing
                    // helpers are in place — left as a follow-up.
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
