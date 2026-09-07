import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/route_names.dart';

enum ChildView { attendance, payments, performance }

/// Segmented control letting a parent switch between their child's
/// attendance/dues/performance views without returning to the room
/// picker (spec §2.8).
class ChildViewSwitcher extends StatelessWidget {
  const ChildViewSwitcher({
    super.key,
    required this.childId,
    required this.roomId,
    required this.current,
  });

  final String childId;
  final String roomId;
  final ChildView current;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SegmentedButton<ChildView>(
        segments: const [
          ButtonSegment(value: ChildView.attendance, label: Text('Attendance')),
          ButtonSegment(value: ChildView.payments, label: Text('Dues')),
          ButtonSegment(value: ChildView.performance, label: Text('Performance')),
        ],
        selected: {current},
        onSelectionChanged: (selection) {
          final view = selection.first;
          if (view == current) return;

          switch (view) {
            case ChildView.attendance:
              context.pushReplacement(
                RouteNames.childAttendance.replaceFirst(':childId', childId),
                extra: roomId,
              );
            case ChildView.payments:
              context.pushReplacement(
                RouteNames.childPayments.replaceFirst(':childId', childId),
                extra: roomId,
              );
            case ChildView.performance:
              context.pushReplacement(
                RouteNames.childPerformance.replaceFirst(':childId', childId),
                extra: roomId,
              );
          }
        },
      ),
    );
  }
}
