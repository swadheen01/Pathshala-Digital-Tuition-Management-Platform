import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/attendance_provider.dart';

/// Student's own attendance history + percentage in a room (spec §3).
class AttendanceViewScreen extends ConsumerWidget {
  const AttendanceViewScreen({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final historyAsync = ref.watch(
      studentAttendanceHistoryProvider((roomId: roomId, studentId: studentId)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('My attendance')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
            child: Text('Unable to load attendance. Please try again.')),
        data: (records) {
          if (records.isEmpty) {
            return const Center(child: Text('No attendance recorded yet.'));
          }
          final present = records.where((r) => r.present).length;
          final pct = present / records.length * 100;
          final barColor = pct >= 75
              ? const Color(0xFF2FB57A)
              : pct >= 50
                  ? AppTheme.sunGold
                  : const Color(0xFFB91C1C);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Text('${pct.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                        )),
                    Text('$present of ${records.length} classes attended',
                        style: const TextStyle(color: Color(0xFFD9E5FF))),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: pct / 100,
                        minHeight: 8,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation(barColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (final r in records)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (r.present
                              ? const Color(0xFF2FB57A)
                              : const Color(0xFFB91C1C))
                          .withValues(alpha: 0.14),
                      child: Icon(
                        r.present
                            ? Icons.check_rounded
                            : Icons.close_rounded,
                        color: r.present
                            ? const Color(0xFF2FB57A)
                            : const Color(0xFFB91C1C),
                      ),
                    ),
                    title: Text(
                        '${r.date.day}/${r.date.month}/${r.date.year}'),
                    trailing: Text(
                      r.present ? 'Present' : 'Absent',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: r.present
                            ? const Color(0xFF2FB57A)
                            : const Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
