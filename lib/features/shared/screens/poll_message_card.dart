import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/messaging_provider.dart';

/// Renders a poll inline in the message feed (spec §2.2). Students vote
/// once; results (vote counts) are visible to everyone after voting.
class PollMessageCard extends ConsumerWidget {
  const PollMessageCard({super.key, required this.pollId});

  final String pollId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pollAsync = ref.watch(pollByIdProvider(pollId));
    final myVoteAsync = ref.watch(myPollVoteProvider(pollId));

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: pollAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) =>
              const Text('Unable to load this poll. Please try again.'),
          data: (poll) {
            final myVote = myVoteAsync.valueOrNull;
            final hasVoted = myVote != null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.poll_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        poll.question,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...poll.options.map((option) {
                  final total = poll.totalVotes;
                  final pct = total == 0 ? 0.0 : option.voteCount / total;
                  final isMyChoice = option.id == myVote;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: hasVoted
                          ? null
                          : () async {
                              await ref
                                  .read(messagingControllerProvider.notifier)
                                  .vote(pollId: poll.id, optionId: option.id);
                              ref.invalidate(pollByIdProvider(poll.id));
                              ref.invalidate(myPollVoteProvider(poll.id));
                            },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  option.label,
                                  style: TextStyle(
                                    fontWeight: isMyChoice
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (hasVoted)
                                Text('${(pct * 100).toStringAsFixed(0)}%'),
                            ],
                          ),
                          if (hasVoted) ...[
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
                if (hasVoted)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${poll.totalVotes} vote${poll.totalVotes == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
