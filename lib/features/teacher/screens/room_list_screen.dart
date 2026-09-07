import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/route_names.dart';
import '../../../models/room_model.dart';
import '../../../providers/room_provider.dart';

/// Teacher's list of tuition rooms they've created (spec §2.1).
class RoomListScreen extends ConsumerWidget {
  const RoomListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(teacherRoomsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Rooms')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(teacherRoomsProvider),
        child: roomsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(
              child: Text('Unable to load rooms. Please try again.')),
          data: (rooms) {
            if (rooms.isEmpty) {
              return LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No rooms yet.\nTap + to create your first tuition room.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rooms.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _RoomCard(room: rooms[index]),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RouteNames.createRoom),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room});
  final RoomModel room;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(room.name, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              if (room.subject != null) ...[
                Text(room.subject!),
                const SizedBox(width: 12),
              ],
              Icon(Icons.key,
                  size: 14, color: Theme.of(context).colorScheme.outline),
              const SizedBox(width: 4),
              Text(
                room.joinCode,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(
          RouteNames.roomDetail.replaceFirst(':roomId', room.id),
        ),
      ),
    );
  }
}
