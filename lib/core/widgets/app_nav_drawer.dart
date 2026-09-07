import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../routes/route_names.dart';
import '../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';

/// The "three-line" app drawer. Role-aware: every section a user can reach
/// is one tap away from here.
class AppNavDrawer extends ConsumerWidget {
  const AppNavDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final role = profile?.role ?? UserRole.student;
    final unread = ref.watch(unreadNotificationCountProvider);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Header(name: profile?.fullName ?? 'Pathshala',
              subtitle: _roleLabel(role), email: profile?.email),
          const SizedBox(height: 6),
          ..._itemsFor(role, unread).map((it) => it.build(context)),
          const Divider(height: 24),
          _DrawerItem(
            icon: Icons.person_outline,
            label: 'My profile',
            onTap: (c) => c.push(RouteNames.profile),
          ).build(context),
          _DrawerItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: (c) => c.push(RouteNames.settings),
          ).build(context),
          _DrawerItem(
            icon: Icons.logout,
            label: 'Sign out',
            danger: true,
            onTap: (c) => ref.read(authControllerProvider.notifier).signOut(),
          ).build(context),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  static String _roleLabel(UserRole r) => switch (r) {
        UserRole.teacher => 'Teacher',
        UserRole.admin => 'Administrator',
        UserRole.parent => 'Parent',
        UserRole.student => 'Student',
      };

  List<_DrawerItem> _itemsFor(UserRole role, int unread) {
    final home = _DrawerItem(
      icon: Icons.home_outlined,
      label: 'Home',
      onTap: (c) => c.go(_homeRouteFor(role)),
    );
    final calendar = _DrawerItem(
      icon: Icons.calendar_month_outlined,
      label: 'Calendar',
      onTap: (c) => c.push(RouteNames.calendar),
    );
    final alerts = _DrawerItem(
      icon: Icons.notifications_outlined,
      label: 'Notifications',
      badge: unread > 0 ? '$unread' : null,
      onTap: (c) => c.push(RouteNames.notifications),
    );

    switch (role) {
      case UserRole.teacher:
        return [
          home,
          _DrawerItem(
            icon: Icons.meeting_room_outlined,
            label: 'My rooms',
            onTap: (c) => c.push(RouteNames.roomList),
          ),
          _DrawerItem(
            icon: Icons.add_circle_outline,
            label: 'Create a room',
            onTap: (c) => c.push(RouteNames.createRoom),
          ),
          calendar,
          alerts,
        ];
      case UserRole.student:
        return [
          home,
          _DrawerItem(
            icon: Icons.group_add_outlined,
            label: 'Join a room',
            onTap: (c) => c.push(RouteNames.joinRoom),
          ),
          _DrawerItem(
            icon: Icons.video_library_outlined,
            label: 'Learning content',
            onTap: (c) => c.push(RouteNames.contentFeed),
          ),
          calendar,
          alerts,
        ];
      case UserRole.admin:
        return [
          home,
          _DrawerItem(
            icon: Icons.school_outlined,
            label: 'Teachers',
            onTap: (c) => c.push(RouteNames.manageTeachers),
          ),
          _DrawerItem(
            icon: Icons.backpack_outlined,
            label: 'Students',
            onTap: (c) => c.push(RouteNames.manageStudents),
          ),
          _DrawerItem(
            icon: Icons.video_library_outlined,
            label: 'Content',
            onTap: (c) => c.push(RouteNames.manageContent),
          ),
          _DrawerItem(
            icon: Icons.analytics_outlined,
            label: 'Analytics',
            onTap: (c) => c.push(RouteNames.analytics),
          ),
          calendar,
          alerts,
        ];
      case UserRole.parent:
        return [home, calendar, alerts];
    }
  }

  static String _homeRouteFor(UserRole r) => switch (r) {
        UserRole.teacher => RouteNames.teacherDashboard,
        UserRole.admin => RouteNames.adminDashboard,
        UserRole.parent => RouteNames.parentDashboard,
        UserRole.student => RouteNames.studentDashboard,
      };
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.subtitle, this.email});
  final String name;
  final String subtitle;
  final String? email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 20, 20, 22),
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              name.isNotEmpty ? name.characters.first.toUpperCase() : 'P',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 12),
          Text(name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(email ?? subtitle,
              style: const TextStyle(color: Color(0xFFD9E5FF), fontSize: 12.5)),
        ],
      ),
    );
  }
}

class _DrawerItem {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final void Function(BuildContext) onTap;
  final String? badge;
  final bool danger;

  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFB91C1C) : const Color(0xFF3B3357);
    return ListTile(
      dense: true,
      leading: Icon(icon, color: danger ? color : AppTheme.skyBlue),
      title: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      trailing: badge == null
          ? null
          : Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEA5B9C),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(badge!,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
      onTap: () {
        Navigator.of(context).pop(); // close the drawer
        onTap(context);
      },
    );
  }
}
