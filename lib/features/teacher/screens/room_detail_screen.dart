import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/route_names.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/auth_error.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/premium.dart';
import '../../../generated/app_localizations.dart';
import '../../../models/room_member_model.dart';
import '../../../providers/room_provider.dart';

/// Hub for a single room: join code, pending claim requests, and quick
/// links to every teacher feature scoped to this room (spec §2.1–§2.8).
class RoomDetailScreen extends ConsumerWidget {
  const RoomDetailScreen({super.key, required this.roomId});

  final String roomId;

  String _path(String template) => template.replaceFirst(':roomId', roomId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final roomAsync = ref.watch(roomByIdProvider(roomId));
    final requestsAsync = ref.watch(roomJoinRequestsProvider(roomId));
    final pending = requestsAsync.maybeWhen(
      data: (r) => r.where((x) => x.isPending).toList(),
      orElse: () => <RoomJoinRequestModel>[],
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.room)),
      body: roomAsync.when(
        loading: () => const LoadingIndicator(),
        error: (err, _) => ErrorView(
          message: l10n.failedToLoadRoom(err.toString()),
          onRetry: () => ref.invalidate(roomByIdProvider(roomId)),
        ),
        data: (room) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(roomByIdProvider(roomId));
            ref.invalidate(roomJoinRequestsProvider(roomId));
            ref.invalidate(roomMembersProvider(roomId));
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              GreetingHeader(
                eyebrow: room.subject ?? 'Tuition room',
                title: room.name,
                subtitle: 'Tap the code to copy and share it.',
                trailing: _JoinCodeChip(code: room.joinCode),
              ),
              const SizedBox(height: 16),
              if (pending.isNotEmpty) ...[
                Text('Join requests',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final req in pending)
                  _ClaimRequestCard(
                    request: req,
                    onApprove: () => _resolve(context, ref, () => ref
                        .read(roomControllerProvider.notifier)
                        .approveClaim(req.id)),
                    onReject: () => _resolve(context, ref, () => ref
                        .read(roomControllerProvider.notifier)
                        .rejectClaim(req.id)),
                  ),
                const SizedBox(height: 16),
              ],
              _FeatureTile(
                icon: Icons.people_outline,
                accent: AppTheme.skyBlue,
                label: l10n.students,
                onTap: () => context.push(_path(RouteNames.studentList)),
              ),
              _FeatureTile(
                icon: Icons.event_available_outlined,
                accent: const Color(0xFF2FB57A),
                label: l10n.attendance,
                onTap: () => context.push(_path(RouteNames.attendance)),
              ),
              _FeatureTile(
                icon: Icons.calendar_month_outlined,
                accent: const Color(0xFF4C7DFF),
                label: l10n.classSchedule,
                onTap: () => context.push(_path(RouteNames.roomSchedule)),
              ),
              _FeatureTile(
                icon: Icons.chat_bubble_outline,
                accent: const Color(0xFFB14DFF),
                label: l10n.messagesPolls,
                onTap: () => context.push(_path(RouteNames.messaging)),
              ),
              _FeatureTile(
                icon: Icons.payments_outlined,
                accent: AppTheme.sunGold,
                label: l10n.paymentsDues,
                onTap: () => context.push(_path(RouteNames.payments)),
              ),
              _FeatureTile(
                icon: Icons.assignment_outlined,
                accent: const Color(0xFFEA5B9C),
                label: l10n.assignments,
                onTap: () => context.push(_path(RouteNames.assignments)),
              ),
              _FeatureTile(
                icon: Icons.bar_chart_outlined,
                accent: const Color(0xFF00A6A6),
                label: l10n.examsLeaderboard,
                onTap: () => context.push(_path(RouteNames.exams)),
              ),
              _FeatureTile(
                icon: Icons.family_restroom_outlined,
                accent: const Color(0xFF7A5CFF),
                label: l10n.parentAccess,
                onTap: () => context.push(_path(RouteNames.parentAccess)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resolve(
    BuildContext context,
    WidgetRef ref,
    Future<bool> Function() action,
  ) async {
    final ok = await action();
    if (!context.mounted) return;
    ref.invalidate(roomJoinRequestsProvider(roomId));
    ref.invalidate(roomMembersProvider(roomId));
    if (!ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content:
              Text(friendlyAuthError(ref.read(roomControllerProvider).error)),
        ));
    }
  }
}

class _JoinCodeChip extends StatelessWidget {
  const _JoinCodeChip({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: code));
        HapticFeedback.selectionClick();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Join code copied')));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              code,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.copy, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}

class _ClaimRequestCard extends StatelessWidget {
  const _ClaimRequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  final RoomJoinRequestModel request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: request.requesterName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const TextSpan(text: '  wants to be linked to  '),
                  TextSpan(
                    text: request.memberName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            if (request.requesterEmail != null) ...[
              const SizedBox(height: 4),
              Text(request.requesterEmail!,
                  style: const TextStyle(
                      fontSize: 12.5, color: Color(0xFF70655D))),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onApprove,
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DashCard(icon: icon, title: label, accent: accent, onTap: onTap),
    );
  }
}
