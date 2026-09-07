import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/parent_provider.dart';
import 'child_view_switcher.dart';

/// Parent's read-only view of a child's payments/dues in one room
/// (spec §2.8). `roomId` arrives via GoRouter's `extra`.
class ChildPaymentsScreen extends ConsumerWidget {
  const ChildPaymentsScreen({
    super.key,
    required this.childId,
    required this.roomId,
  });

  final String childId;
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(
      childPaymentsProvider((roomId: roomId, studentId: childId)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Dues')),
      body: Column(
        children: [
          ChildViewSwitcher(
            childId: childId,
            roomId: roomId,
            current: ChildView.payments,
          ),
          Expanded(
            child: paymentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Unable to load payments. Please try again.')),
              data: (payments) {
                if (payments.isEmpty) {
                  return const Center(child: Text('No payments recorded yet.'));
                }

                final total = payments.fold<double>(0, (sum, p) => sum + p.amount);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text('৳${total.toStringAsFixed(0)}',
                                  style:
                                      Theme.of(context).textTheme.headlineMedium),
                              const Text('Total paid'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: payments.length,
                        itemBuilder: (context, index) {
                          final p = payments[index];
                          return ListTile(
                            leading: const Icon(Icons.receipt_long_outlined),
                            title: Text('৳${p.amount.toStringAsFixed(0)}'),
                            subtitle: Text(
                              '${p.paidOn.day}/${p.paidOn.month}/${p.paidOn.year}'
                              '${p.forMonth != null ? ' · for ${p.forMonth}' : ''}',
                            ),
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
