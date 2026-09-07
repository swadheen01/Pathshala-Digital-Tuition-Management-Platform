import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/parent_provider.dart';
import 'child_view_switcher.dart';

/// Parent's read-only view of a child's attendance in one room
/// (spec §2.8). `roomId` arrives via GoRouter's `extra`.
class ChildAttendanceScreen extends ConsumerWidget {
  const ChildAttendanceScreen({
    super.key,
    required this.childId,
    required this.roomId,
  });

  final String childId;
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(
      childAttendanceProvider((roomId: roomId, studentId: childId)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: Column(
        children: [
          ChildViewSwitcher(
            childId: childId,
            roomId: roomId,
            current: ChildView.attendance,
          ),
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Unable to load attendance. Please try again.')),
              data: (records) {
                if (records.isEmpty) {
                  return const Center(child: Text('No attendance recorded yet.'));
                }

                final present = records.where((r) => r.present).length;
                final percentage =
                    (present / records.length * 100).toStringAsFixed(1);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text('$percentage%',
                                  style:
                                      Theme.of(context).textTheme.headlineMedium),
                              Text('$present / ${records.length} classes attended'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final r = records[index];
                          return ListTile(
                            leading: Icon(
                              r.present ? Icons.check_circle : Icons.cancel,
                              color: r.present ? Colors.green : Colors.red,
                            ),
                            title: Text(
                                '${r.date.day}/${r.date.month}/${r.date.year}'),
                            trailing: Text(r.present ? 'Present' : 'Absent'),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
