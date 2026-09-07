import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/payment_model.dart';
import '../../../providers/payment_provider.dart';

/// Exports payment history as CSV so teachers can keep records / share
/// proof of dues with students or parents (spec §2.4).
///
/// NOTE: add `share_plus: ^10.0.0` to pubspec.yaml for this screen —
/// it wasn't in the original dependency list since export wasn't
/// scoped until this phase.
class PaymentHistoryExportScreen extends ConsumerWidget {
  const PaymentHistoryExportScreen({super.key, required this.roomId});

  final String roomId;

  String _buildCsv(List<PaymentModel> payments) {
    final buffer = StringBuffer('Date,Student ID,Amount,For Month,Note\n');
    for (final p in payments) {
      final date =
          '${p.paidOn.year}-${p.paidOn.month.toString().padLeft(2, '0')}-${p.paidOn.day.toString().padLeft(2, '0')}';
      final note = (p.note ?? '').replaceAll(',', ';');
      buffer.writeln(
          '$date,${p.studentId},${p.amount},${p.forMonth ?? ''},$note');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(roomPaymentsProvider(roomId));

    return Scaffold(
      appBar: AppBar(title: const Text('Export Payment History')),
      body: paymentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
            child: Text('Unable to load payment history. Please try again.')),
        data: (payments) {
          if (payments.isEmpty) {
            return const Center(child: Text('No payments recorded yet.'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final p = payments[index];
                    return ListTile(
                      title: Text('৳${p.amount.toStringAsFixed(0)}'),
                      subtitle: Text(
                        '${p.paidOn.day}/${p.paidOn.month}/${p.paidOn.year}'
                        '${p.forMonth != null ? ' · for ${p.forMonth}' : ''}',
                      ),
                      trailing: p.note != null ? Text(p.note!) : null,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('Share as CSV'),
                  onPressed: () {
                    final csv = _buildCsv(payments);
                    Share.share(
                      csv,
                      subject: 'Payment History Export',
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
