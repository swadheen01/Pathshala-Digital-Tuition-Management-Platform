import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/route_names.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/schedule_utils.dart';
import '../../../core/widgets/app_nav_drawer.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/premium.dart';
import '../../../models/attendance_model.dart';
import '../../../models/room_model.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/room_provider.dart';

/// Student's home tab: School / Tuition split (spec §3), with the live/next
/// class and per-room attendance standing surfaced up top.
class SchoolTuitionTabsScreen extends ConsumerWidget {
  const SchoolTuitionTabsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(studentRoomsProvider);
    final attendanceAsync = ref.watch(myRoomAttendanceProvider);
    final profile = ref.watch(currentProfileProvider).valueOrNull;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: const AppNavDrawer(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push(RouteNames.joinRoom),
          icon: const Icon(Icons.add),
          label: const Text('Join room'),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(studentRoomsProvider);
            ref.invalidate(myRoomAttendanceProvider);
          },
          child: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    children: [
                      Builder(
                        builder: (context) => GreetingHeader(
                          onMenu: () => Scaffold.of(context).openDrawer(),
                          eyebrow: 'Pathshala',
                          title: 'Hi, '
                              '${profile?.fullName.split(' ').first ?? 'there'}',
                          subtitle: profile?.classGrade == null
                              ? 'Your classes, all in one place.'
                              : '${profile!.classGrade} · your classes in one '
                                  'place.',
                        ),
                      ),
                      const SizedBox(height: 14),
                      roomsAsync.maybeWhen(
                        data: (rooms) {
                          final cls = resolveClasses(rooms);
                          return _ClassStrip(live: cls.live, next: cls.next);
                        },
                        orElse: () => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 10),
                      attendanceAsync.maybeWhen(
                        data: (stats) => _AttendanceStrip(stats: stats),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: TabBar(tabs: [Tab(text: 'Tuition'), Tab(text: 'School')]),
                ),
              ),
            ],
            body: TabBarView(
              children: [
                _RoomsTab(roomsAsync: roomsAsync),
                _RoomsTab(roomsAsync: roomsAsync),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassStrip extends StatelessWidget {
  const _ClassStrip({required this.live, required this.next});
  final ClassOccurrence? live;
  final ClassOccurrence? next;

  @override
  Widget build(BuildContext context) {
    final occ = live ?? next;
    if (occ == null) return const SizedBox.shrink();
    final isLive = live != null;
    final accent = isLive ? const Color(0xFFEA5B9C) : AppTheme.skyBlue;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xE6FFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(isLive ? Icons.sensors_rounded : Icons.schedule_rounded,
              color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isLive ? 'Class on now' : 'Next class',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 12.5)),
                const SizedBox(height: 2),
                Text(
                  '${occ.room.name} · ${formatOccurrence(occ, context)}',
                  style: const TextStyle(
                      fontSize: 12.5, color: Color(0xFF70655D)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceStrip extends StatelessWidget {
  const _AttendanceStrip({required this.stats});
  final List<RoomAttendanceStat> stats;

  @override
  Widget build(BuildContext context) {
    final withData = stats.where((s) => s.total > 0).toList();
    if (withData.isEmpty) return const SizedBox.shrink();
    final present = withData.fold<int>(0, (s, r) => s + r.present);
    final total = withData.fold<int>(0, (s, r) => s + r.total);
    final overall = total == 0 ? 0.0 : present / total * 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.navyGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('My attendance',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
              Text('${overall.toStringAsFixed(0)}% overall',
                  style: const TextStyle(
                      color: Color(0xFFD9E5FF),
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5)),
            ],
          ),
          const SizedBox(height: 12),
          for (final s in withData) ...[
            _row(s),
            if (s != withData.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _row(RoomAttendanceStat s) {
    final pct = s.percentage;
    final barColor = pct >= 75
        ? const Color(0xFF6EE7B7)
        : pct >= 50
            ? AppTheme.sunGold
            : const Color(0xFFFCA5A5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(s.roomName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12.5)),
            ),
            Text('${s.present}/${s.total} · ${pct.toStringAsFixed(0)}%',
                style:
                    const TextStyle(color: Color(0xFFD9E5FF), fontSize: 11.5)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (pct / 100).clamp(0, 1),
            minHeight: 6,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation(barColor),
          ),
        ),
      ],
    );
  }
}

class _RoomsTab extends StatelessWidget {
  const _RoomsTab({required this.roomsAsync});
  final AsyncValue<List<RoomModel>> roomsAsync;

  @override
  Widget build(BuildContext context) {
    return roomsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => ErrorView(message: friendlyLoadError(err)),
      data: (rooms) {
        if (rooms.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 40),
              Icon(Icons.school_outlined,
                  size: 56, color: AppTheme.skyBlue.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              const Text('No rooms yet',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text(
                'Tap "Join room" and enter the code your teacher gave you.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF70655D)),
              ),
            ],
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: rooms.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final room = rooms[index];
            return DashCard(
              icon: Icons.meeting_room_outlined,
              title: room.name,
              subtitle: room.subject,
              onTap: () => context.push(
                RouteNames.roomFeed.replaceFirst(':roomId', room.id),
              ),
            );
          },
        );
      },
    );
  }
}
