import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/route_names.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/premium.dart';
import '../../../models/payment_model.dart';
import '../../../providers/payment_provider.dart';

/// Teacher's dues overview for a room — a paid/due/overdue count strip
/// plus a per-student breakdown (spec §2.4).
class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duesAsync = ref.watch(duesSummaryProvider(roomId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments & dues'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export history',
            onPressed: () => context.push(
              RouteNames.paymentHistoryExport.replaceFirst(':roomId', roomId),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          RouteNames.recordPayment.replaceFirst(':roomId', roomId),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Record'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(duesSummaryProvider(roomId)),
        child: duesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(
              child: Text('Unable to load payments. Please try again.')),
          data: (dues) {
            if (dues.isEmpty) {
              return const Center(
                  child: Text('No students in this room yet.'));
            }
            final paidUp = dues
                .where((d) => d.monthlyFee == 0 || d.outstanding <= 0)
                .length;
            final overdue = dues.where((d) => d.monthsOverdue >= 2).length;
            final due = dues.length - paidUp - overdue;
            final collected =
                dues.fold<double>(0, (s, d) => s + d.totalPaid);
            final outstanding =
                dues.fold<double>(0, (s, d) => s + d.outstanding);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        label: 'Paid up',
                        value: '$paidUp',
                        icon: Icons.verified_outlined,
                        accent: const Color(0xFF2FB57A),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        label: 'Due',
                        value: '$due',
                        icon: Icons.hourglass_bottom_outlined,
                        accent: AppTheme.sunGold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        label: 'Overdue',
                        value: '$overdue',
                        icon: Icons.error_outline,
                        accent: const Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.navyGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _kv('Collected',
                            '৳${collected.toStringAsFixed(0)}'),
                      ),
                      Container(width: 1, height: 32, color: Colors.white24),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _kv('Outstanding',
                            '৳${outstanding.toStringAsFixed(0)}'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text('By student',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final d in dues) ...[
                  _DuesCard(dues: d),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(v,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          Text(k,
              style: const TextStyle(color: Color(0xFFD9E5FF), fontSize: 11.5)),
        ],
      );
}

class _DuesCard extends StatelessWidget {
  const _DuesCard({required this.dues});
  final DuesSummary dues;

  @override
  Widget build(BuildContext context) {
    final overdue = dues.monthsOverdue >= 2;
    final settled = dues.monthlyFee == 0 || dues.outstanding <= 0;
    final ratio = dues.totalExpected <= 0
        ? 1.0
        : (dues.totalPaid / dues.totalExpected).clamp(0.0, 1.0);
    final barColor = settled
        ? const Color(0xFF2FB57A)
        : overdue
            ? const Color(0xFFB91C1C)
            : AppTheme.sunGold;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(dues.studentName,
                      style:
                          const TextStyle(fontWeight: FontWeight.w700)),
                ),
                if (settled)
                  const Chip(
                    label: Text('Paid up'),
                    backgroundColor: Color(0xFFD5F5E3),
                    visualDensity: VisualDensity.compact,
                  )
                else if (overdue)
                  Chip(
                    label: Text('${dues.monthsOverdue} mo overdue'),
                    backgroundColor: const Color(0xFFFAD7D7),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 7,
                backgroundColor: const Color(0xFFEDE9F5),
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Paid ৳${dues.totalPaid.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 12.5, color: Color(0xFF70655D))),
                Text(
                  settled
                      ? 'No dues'
                      : 'Due ৳${dues.outstanding.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: settled ? const Color(0xFF2FB57A) : barColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
