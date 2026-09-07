import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/parent_provider.dart';
import 'child_view_switcher.dart';

/// Parent's read-only view of a child's exam performance in one room
/// (spec §2.8). `roomId` arrives via GoRouter's `extra`.
class ChildPerformanceScreen extends ConsumerWidget {
  const ChildPerformanceScreen({
    super.key,
    required this.childId,
    required this.roomId,
  });

  final String childId;
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performanceAsync = ref.watch(
      childPerformanceProvider((roomId: roomId, studentId: childId)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Performance')),
      body: Column(
        children: [
          ChildViewSwitcher(
            childId: childId,
            roomId: roomId,
            current: ChildView.performance,
          ),
          Expanded(
            child: performanceAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Unable to load performance. Please try again.')),
              data: (points) {
                if (points.isEmpty) {
                  return const Center(child: Text('No exam scores recorded yet.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: points.length,
                  itemBuilder: (context, index) {
                    final p = points[index];
                    return Card(
                      child: ListTile(
                        title: Text(p.examTitle),
                        trailing: Text(
                          '${p.marksObtained.toStringAsFixed(0)}/${p.maxMarks.toStringAsFixed(0)} '
                          '(${p.percentage.toStringAsFixed(0)}%)',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
