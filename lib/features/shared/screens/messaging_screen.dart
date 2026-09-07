import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/routes/route_names.dart';
import '../../../models/message_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/messaging_provider.dart';
import '../../../providers/room_provider.dart';
import 'poll_message_card.dart';

/// Room chat/announcement feed (spec §2.2, §3). Works for both roles:
/// teacher can always post; student can post only if the room's
/// chat_enabled toggle is on.
class MessagingScreen extends ConsumerStatefulWidget {
  const MessagingScreen({super.key, required this.roomId});

  final String roomId;

  @override
  ConsumerState<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends ConsumerState<MessagingScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final success = await ref
        .read(messagingControllerProvider.notifier)
        .sendText(roomId: widget.roomId, text: text);

    if (success) {
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(roomMessagesProvider(widget.roomId));
    final roomAsync = ref.watch(roomByIdProvider(widget.roomId));
    final profileAsync = ref.watch(currentProfileProvider);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    final isTeacher = profileAsync.valueOrNull?.role == UserRole.teacher;
    final chatEnabled = roomAsync.valueOrNull?.chatEnabled ?? false;
    final canPost = isTeacher || chatEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          if (isTeacher)
            IconButton(
              icon: const Icon(Icons.poll_outlined),
              tooltip: 'Create Poll',
              onPressed: () => context.push(
                RouteNames.createPoll.replaceFirst(':roomId', widget.roomId),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(
                  child: Text('Unable to load messages. Please try again.')),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message.senderId == currentUserId;
                    return _MessageBubble(message: message, isMine: isMine);
                  },
                );
              },
            ),
          ),
          if (!canPost)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Text(
                'Chat is disabled by your teacher',
                textAlign: TextAlign.center,
              ),
            )
          else
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message…',
                        ),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _handleSend,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final MessageModel message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    if (message.type == MessageType.poll && message.pollId != null) {
      return Align(
        alignment: Alignment.center,
        child: PollMessageCard(pollId: message.pollId!),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMine
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMine && message.senderName != null)
              Text(
                message.senderName!,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            if (message.type == MessageType.image && message.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(message.imageUrl!, fit: BoxFit.cover),
              )
            else
              Text(message.text ?? ''),
          ],
        ),
      ),
    );
  }
}
