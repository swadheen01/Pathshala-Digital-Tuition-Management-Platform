import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/route_names.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/premium.dart';
import '../../../providers/room_provider.dart';

/// Student's view of a joined room — a Google-Classroom-style hub with
/// quick links to attendance, assignments, performance and content
/// (spec §3). Chat / leaderboard tiles only show when the teacher enabled
/// them.
class RoomFeedScreen extends ConsumerWidget {
  const RoomFeedScreen({super.key, required this.roomId});

  final String roomId;

  String _path(String template) => template.replaceFirst(':roomId', roomId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomByIdProvider(roomId));

    return Scaffold(
      appBar: AppBar(title: const Text('Room')),
      body: roomAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
            child: Text('Unable to load the room. Please try again.')),
        data: (room) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            GreetingHeader(
              eyebrow: room.subject ?? 'Room',
              title: room.name,
              subtitle: room.description,
            ),
            const SizedBox(height: 16),
            DashCard(
              icon: Icons.event_available_outlined,
              title: 'My attendance',
              subtitle: 'Your record for this room',
              accent: const Color(0xFF2FB57A),
              onTap: () => context.push(_path(RouteNames.attendanceView)),
            ),
            const SizedBox(height: 10),
            if (room.chatEnabled) ...[
              DashCard(
                icon: Icons.chat_bubble_outline,
                title: 'Messages & polls',
                accent: const Color(0xFFB14DFF),
                onTap: () => context.push(_path(RouteNames.messaging)),
              ),
              const SizedBox(height: 10),
            ],
            DashCard(
              icon: Icons.assignment_outlined,
              title: 'Assignments',
              subtitle: 'Homework and submissions',
              accent: const Color(0xFFEA5B9C),
              onTap: () => context.push(_path(RouteNames.studentAssignments)),
            ),
            const SizedBox(height: 10),
            DashCard(
              icon: Icons.bar_chart_outlined,
              title: 'My performance',
              subtitle: 'Exam scores and progress',
              accent: AppTheme.skyBlue,
              onTap: () => context.push(_path(RouteNames.examPerformance)),
            ),
            if (room.leaderboardEnabled) ...[
              const SizedBox(height: 10),
              DashCard(
                icon: Icons.leaderboard_outlined,
                title: 'Leaderboard',
                accent: AppTheme.sunGold,
                onTap: () => context.push(_path(RouteNames.leaderboard)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
