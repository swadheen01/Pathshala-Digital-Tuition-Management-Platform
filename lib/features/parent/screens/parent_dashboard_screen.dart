import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/route_names.dart';
import '../../../core/widgets/app_nav_drawer.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/premium.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/parent_provider.dart';

/// Parent's home tab: linked children, tap one to pick a room and view
/// its read-only attendance / payments / performance (spec §2.8).
class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(myChildrenProvider);
    final profile = ref.watch(currentProfileProvider).valueOrNull;

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: const AppNavDrawer(),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myChildrenProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Builder(
              builder: (context) => GreetingHeader(
                onMenu: () => Scaffold.of(context).openDrawer(),
                eyebrow: 'Parent',
                title: 'Hi, ${profile?.fullName.split(' ').first ?? 'there'}',
                subtitle:
                    'Follow your child\'s attendance, dues, and results.',
              ),
            ),
            const SizedBox(height: 20),
            childrenAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => ErrorView(message: friendlyLoadError(err)),
              data: (children) {
                if (children.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: Text(
                      "No children linked yet.\nAsk your child's teacher to "
                      'grant parent access.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF70655D)),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final child in children) ...[
                      DashCard(
                        icon: Icons.person_outline,
                        title: child.studentName ?? 'Unknown',
                        subtitle: 'View classes and progress',
                        onTap: () => _showRoomPicker(
                          context,
                          ref,
                          child.studentId,
                          child.studentName ?? 'Child',
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRoomPicker(
    BuildContext context,
    WidgetRef ref,
    String studentId,
    String studentName,
  ) async {
    final rooms = await ref.read(childRoomsProvider(studentId).future);
    if (!context.mounted) return;

    if (rooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$studentName is not in any rooms yet.')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            for (final room in rooms)
              DashCard(
                icon: Icons.meeting_room_outlined,
                title: room.name,
                subtitle: room.subject,
                onTap: () {
                  Navigator.pop(context);
                  context.push(
                    RouteNames.childAttendance
                        .replaceFirst(':childId', studentId),
                    extra: room.id,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
