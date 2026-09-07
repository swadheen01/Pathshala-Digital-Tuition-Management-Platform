import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../providers/exam_provider.dart';

/// Ranked leaderboard for a room — only reachable when the teacher has
/// enabled it (room_feed_screen.dart already hides the nav link
/// otherwise, spec §2.7).
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider(roomId));
    final myId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: leaderboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
            child: Text('Unable to load leaderboard. Please try again.')),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('No scores recorded yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isMe = entry.studentId == myId;
              final rank = index + 1;

              return Card(
                color: isMe
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: rank <= 3
                        ? Colors.amber
                        : Theme.of(context).colorScheme.surfaceContainerHigh,
                    child: Text('$rank'),
                  ),
                  title: Text(entry.studentName),
                  trailing: Text(
                    '${entry.percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
