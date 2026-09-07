import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/route_names.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/schedule_utils.dart';
import '../../../core/widgets/app_nav_drawer.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/premium.dart';
import '../../../generated/app_localizations.dart';
import '../../../models/payment_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/payment_provider.dart';
import '../../../providers/room_provider.dart';

/// Teacher's home tab — greeting, live/next class, a payment snapshot,
/// and quick access to rooms (spec §2).
class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final roomsAsync = ref.watch(teacherRoomsProvider);
    final payAsync = ref.watch(teacherPaymentOverviewProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: const AppNavDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(teacherRoomsProvider);
          ref.invalidate(teacherPaymentOverviewProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Builder(
              builder: (context) => GreetingHeader(
                onMenu: () => Scaffold.of(context).openDrawer(),
                eyebrow: l10n.appName,
                title: l10n.welcomeTeacher(profile?.fullName ?? 'Teacher'),
                subtitle: 'Your teaching at a glance.',
                trailing: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  child: Text(
                    _initials(profile?.fullName),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            roomsAsync.when(
              loading: () => const Padding(
                  padding: EdgeInsets.only(top: 24), child: LoadingIndicator()),
              error: (_, __) => ErrorView(
                message: 'Unable to load rooms right now. Please try again.',
                onRetry: () => ref.invalidate(teacherRoomsProvider),
              ),
              data: (rooms) {
                final now = DateTime.now();
                final cls = resolveClasses(rooms, at: now);
                return Column(
                  children: [
                    _ClassNowNext(live: cls.live, next: cls.next),
                    const SizedBox(height: 16),
                    _SectionLabel('Payments', onTap: () {
                      context.push(RouteNames.roomList);
                    }),
                    const SizedBox(height: 8),
                    payAsync.when(
                      loading: () => const _MiniLoader(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (p) => _PaymentSnapshot(overview: p),
                    ),
                    const SizedBox(height: 16),
                    _SectionLabel('Rooms',
                        onTap: () => context.push(RouteNames.roomList)),
                    const SizedBox(height: 8),
                    DashCard(
                      icon: Icons.meeting_room_outlined,
                      title: l10n.roomsCount(rooms.length),
                      subtitle: l10n.manageRooms,
                      onTap: () => context.push(RouteNames.roomList),
                    ),
                    const SizedBox(height: 10),
                    DashCard(
                      icon: Icons.add_circle_outline,
                      title: l10n.createRoom,
                      subtitle: 'Start a new tuition room with a join code.',
                      accent: AppTheme.sunGold,
                      onTap: () => context.push(RouteNames.createRoom),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'T';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, {this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        if (onTap != null)
          TextButton(onPressed: onTap, child: const Text('View all')),
      ],
    );
  }
}

class _MiniLoader extends StatelessWidget {
  const _MiniLoader();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
              height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
}

class _ClassNowNext extends StatelessWidget {
  const _ClassNowNext({required this.live, required this.next});
  final ClassOccurrence? live;
  final ClassOccurrence? next;

  @override
  Widget build(BuildContext context) {
    if (live == null && next == null) {
      return _wrap(
        icon: Icons.event_available_outlined,
        accent: const Color(0xFF2FB57A),
        title: 'No classes scheduled',
        line: 'Set class days on a room to see what\'s on.',
      );
    }
    return Column(
      children: [
        if (live != null)
          _wrap(
            icon: Icons.sensors_rounded,
            accent: const Color(0xFFEA5B9C),
            title: 'On now · ${live!.room.name}',
            line: formatOccurrence(live!, context) +
                (live!.room.subject != null ? ' · ${live!.room.subject}' : ''),
          ),
        if (live != null && next != null) const SizedBox(height: 10),
        if (next != null)
          _wrap(
            icon: Icons.schedule_rounded,
            accent: AppTheme.skyBlue,
            title: 'Next · ${next!.room.name}',
            line: formatOccurrence(next!, context) +
                (next!.room.subject != null ? ' · ${next!.room.subject}' : ''),
          ),
      ],
    );
  }

  Widget _wrap({
    required IconData icon,
    required Color accent,
    required String title,
    required String line,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xE6FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(line,
                    style: const TextStyle(
                        fontSize: 12.5, color: Color(0xFF70655D))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentSnapshot extends StatelessWidget {
  const _PaymentSnapshot({required this.overview});
  final TeacherPaymentOverview overview;

  @override
  Widget build(BuildContext context) {
    final p = overview;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Paid up',
                value: '${p.paidUp}',
                icon: Icons.verified_outlined,
                accent: const Color(0xFF2FB57A),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'Due',
                value: '${p.due}',
                icon: Icons.hourglass_bottom_outlined,
                accent: AppTheme.sunGold,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'Overdue',
                value: '${p.overdue}',
                icon: Icons.error_outline,
                accent: const Color(0xFFB91C1C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppTheme.navyGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: _kv('Collected · 30 days',
                    '৳${p.collected30.toStringAsFixed(0)}'),
              ),
              Container(width: 1, height: 34, color: Colors.white24),
              const SizedBox(width: 14),
              Expanded(
                child: _kv('Outstanding',
                    '৳${p.outstanding.toStringAsFixed(0)}'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kv(String k, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(v,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(k,
              style: const TextStyle(color: Color(0xFFD9E5FF), fontSize: 11.5)),
        ],
      );
}
