import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../generated/app_localizations.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../parent/screens/parent_dashboard_screen.dart';
import '../../student/screens/school_tuition_tabs_screen.dart';
import '../../teacher/screens/teacher_dashboard_screen.dart';
import 'calendar_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';

/// Bottom-navigation shell shown after login. Picks the right home tab
/// per role (spec §1/§5) and keeps Calendar/Notifications/Settings
/// consistent across all four roles.
class HomeShellScreen extends ConsumerStatefulWidget {
  const HomeShellScreen({super.key});

  @override
  ConsumerState<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends ConsumerState<HomeShellScreen> {
  int _index = 0;

  Widget _dashboardFor(UserRole role) {
    switch (role) {
      case UserRole.teacher:
        return const TeacherDashboardScreen();
      case UserRole.admin:
        return const AdminDashboardScreen();
      case UserRole.parent:
        return const ParentDashboardScreen();
      case UserRole.student:
        return const SchoolTuitionTabsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.transparent,
        body: LoadingIndicator(),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ErrorView(
                message:
                    'We could not load your dashboard. Please check your '
                    'connection and try again.',
                onRetry: () => ref.invalidate(currentProfileProvider),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: TextButton(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
                child: const Text('Sign out'),
              ),
            ),
          ],
        ),
      ),
      data: (profile) {
        final role = profile?.role ?? UserRole.student;

        final pages = [
          _dashboardFor(role),
          const CalendarScreen(),
          const NotificationsScreen(),
          const SettingsScreen(),
        ];

        return Scaffold(
          body: IndexedStack(index: _index, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: AppLocalizations.of(context).home,
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: AppLocalizations.of(context).calendar,
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text('$unreadCount'),
                  child: const Icon(Icons.notifications_outlined),
                ),
                selectedIcon: const Icon(Icons.notifications),
                label: AppLocalizations.of(context).alerts,
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: AppLocalizations.of(context).settings,
              ),
            ],
          ),
        );
      },
    );
  }
}
