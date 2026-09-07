import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/attendance_provider.dart';

/// Teacher's summary view of every student's attendance % in a room
/// (spec §2.3 — "visible to both teacher and students").
class AttendanceSummaryScreen extends ConsumerWidget {
  const AttendanceSummaryScreen({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(roomSummaryProvider(roomId));

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Summary')),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
            child: Text('Unable to load attendance. Please try again.')),
        data: (summaries) {
          if (summaries.isEmpty) {
            return const Center(child: Text('No attendance recorded yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: summaries.length,
            itemBuilder: (context, index) {
              final s = summaries[index];
              return Card(
                child: ListTile(
                  title: Text(s.studentName),
                  subtitle: Text('${s.presentDays} / ${s.totalDays} classes'),
                  trailing: Text(
                    '${s.percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: s.percentage >= 75 ? Colors.green : Colors.orange,
                    ),
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
