import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/route_names.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/room_provider.dart';
import 'add_student_screen.dart';

/// Teacher's roster for a room (spec §2.1: Name, Roll, Email — plus
/// name-only students with no account).
class StudentListScreen extends ConsumerWidget {
  const StudentListScreen({super.key, required this.roomId});

  final String roomId;

  static const _accents = [
    AppTheme.skyBlue,
    Color(0xFFB14DFF),
    Color(0xFF2FB57A),
    AppTheme.sunGold,
    Color(0xFFEA5B9C),
  ];

  String _add(String template) => template.replaceFirst(':roomId', roomId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(roomMembersProvider(roomId));
    final requests = ref.watch(roomJoinRequestsProvider(roomId));

    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(_add(RouteNames.addStudent)),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add student'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(roomMembersProvider(roomId));
          ref.invalidate(roomJoinRequestsProvider(roomId));
        },
        child: membersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(
              child: Text('Unable to load students. Please try again.')),
          data: (members) {
            final pending = requests.maybeWhen(
              data: (r) => r.where((x) => x.isPending).toList(),
              orElse: () => const [],
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                if (pending.isNotEmpty) ...[
                  _ClaimBanner(
                    count: pending.length,
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.push(_add(RouteNames.roomDetail)),
                  ),
                  const SizedBox(height: 16),
                ],
                if (members.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Text(
                      'No students yet.\nAdd them by name, or share the join '
                      'code.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF70655D)),
                    ),
                  ),
                for (var i = 0; i < members.length; i++) ...[
                  _StudentTile(
                    accent: _accents[i % _accents.length],
                    name: members[i].studentName,
                    roll: members[i].member.rollNumber,
                    contact: members[i].studentEmail ?? members[i].member.phone,
                    unclaimed: members[i].isUnclaimed,
                    onEdit: () => context.push(
                      _add(RouteNames.addStudent),
                      extra: AddStudentArgs(
                        memberId: members[i].member.id,
                        name: members[i].member.rosterName ??
                            members[i].studentName,
                        roll: members[i].member.rollNumber,
                        phone: members[i].member.phone,
                        email: members[i].member.email,
                        fee: members[i].member.monthlyFee,
                      ),
                    ),
                    onRemove: () async {
                      final ok = await _confirmRemove(
                          context, members[i].studentName);
                      if (ok != true) return;
                      await ref
                          .read(roomControllerProvider.notifier)
                          .removeMemberById(members[i].member.id);
                      ref.invalidate(roomMembersProvider(roomId));
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<bool?> _confirmRemove(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove student?'),
        content: Text('Remove $name from this room? '
            'Their attendance and payment history will be removed too.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _ClaimBanner extends StatelessWidget {
  const _ClaimBanner({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF3D6),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.how_to_reg_outlined, color: Color(0xFF9A6B00)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$count student${count == 1 ? '' : 's'} asked to link to a '
                  'name on your roster. Review in the room hub.',
                  style: const TextStyle(color: Color(0xFF6B4E00)),
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF9A6B00)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({
    required this.accent,
    required this.name,
    required this.unclaimed,
    required this.onEdit,
    required this.onRemove,
    this.roll,
    this.contact,
  });

  final Color accent;
  final String name;
  final bool unclaimed;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final String? roll;
  final String? contact;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (roll != null && roll!.isNotEmpty) 'Roll $roll',
      if (contact != null && contact!.isNotEmpty) contact!,
    ].join(' · ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: accent.withValues(alpha: 0.16),
              child: Text(
                name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
                style: TextStyle(color: accent, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (unclaimed) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE7FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'No account',
                            style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF5B45C7),
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(meta,
                        style: const TextStyle(
                            fontSize: 12.5, color: Color(0xFF70655D))),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) => v == 'edit' ? onEdit() : onRemove(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'remove', child: Text('Remove')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
