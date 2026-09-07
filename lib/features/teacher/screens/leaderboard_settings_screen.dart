import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/room_provider.dart';

/// Teacher toggles whether students can see the leaderboard for this
/// room (spec §2.7 — "visibility is teacher-controlled").
class LeaderboardSettingsScreen extends ConsumerWidget {
  const LeaderboardSettingsScreen({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomByIdProvider(roomId));
    final controllerState = ref.watch(roomControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard Settings')),
      body: roomAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
            child: Text('Unable to load leaderboard. Please try again.')),
        data: (room) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile(
                  title: const Text('Show leaderboard to students'),
                  subtitle: const Text(
                    'Students will see a ranked list based on exam performance',
                  ),
                  value: room.leaderboardEnabled,
                  onChanged: controllerState.isLoading
                      ? null
                      : (value) async {
                          await ref
                              .read(roomControllerProvider.notifier)
                              .updateRoomSettings(
                                roomId,
                                leaderboardEnabled: value,
                              );
                          ref.invalidate(roomByIdProvider(roomId));
                        },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
