import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/route_names.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_nav_drawer.dart';
import '../../../core/widgets/premium.dart';
import '../../../providers/auth_provider.dart';

/// Admin's home tab — hub for teacher/student/content management and
/// analytics (spec §4).
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: const AppNavDrawer(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Builder(
            builder: (context) => GreetingHeader(
              onMenu: () => Scaffold.of(context).openDrawer(),
              eyebrow: 'Admin',
              title:
                  'Welcome, ${profile?.fullName.split(' ').first ?? 'Admin'}',
              subtitle: 'Manage people and content across Pathshala.',
            ),
          ),
          const SizedBox(height: 20),
          DashCard(
            icon: Icons.school_outlined,
            title: 'Teachers',
            subtitle: 'Review and manage teacher accounts.',
            onTap: () => context.push(RouteNames.manageTeachers),
          ),
          const SizedBox(height: 10),
          DashCard(
            icon: Icons.backpack_outlined,
            title: 'Students',
            subtitle: 'Review and manage student accounts.',
            accent: AppTheme.sunGold,
            onTap: () => context.push(RouteNames.manageStudents),
          ),
          const SizedBox(height: 10),
          DashCard(
            icon: Icons.video_library_outlined,
            title: 'Content',
            subtitle: 'Curate videos and links by class/grade.',
            accent: const Color(0xFFB14DFF),
            onTap: () => context.push(RouteNames.manageContent),
          ),
          const SizedBox(height: 10),
          DashCard(
            icon: Icons.analytics_outlined,
            title: 'Analytics',
            subtitle: 'Platform usage and engagement trends.',
            accent: const Color(0xFF2FB57A),
            onTap: () => context.push(RouteNames.analytics),
          ),
        ],
      ),
    );
  }
}
