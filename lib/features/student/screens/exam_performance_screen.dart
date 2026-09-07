import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../providers/exam_provider.dart';

/// Student's own performance graph across all exams in a room
/// (spec §2.7, §3).
class ExamPerformanceScreen extends ConsumerWidget {
  const ExamPerformanceScreen({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performanceAsync = ref.watch(myPerformanceProvider(roomId));

    return Scaffold(
      appBar: AppBar(title: const Text('My Performance')),
      body: performanceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
            child: Text('Unable to load performance. Please try again.')),
        data: (points) {
          if (points.isEmpty) {
            return const Center(child: Text('No exam scores recorded yet.'));
          }

          final spots = points
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.percentage))
              .toList();

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 240,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: 100,
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= points.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  points[index].examTitle,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: points.length,
                    itemBuilder: (context, index) {
                      final p = points[index];
                      return ListTile(
                        title: Text(p.examTitle),
                        trailing: Text(
                          '${p.marksObtained.toStringAsFixed(0)}/${p.maxMarks.toStringAsFixed(0)} '
                          '(${p.percentage.toStringAsFixed(0)}%)',
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
