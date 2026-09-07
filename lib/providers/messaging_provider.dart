import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/message_model.dart';
import '../models/poll_model.dart';
import '../services/messaging_service.dart';

final messagingServiceProvider =
    Provider<MessagingService>((ref) => MessagingService());

/// Realtime stream of messages in a room (spec §2.2). Auto-updates as
/// new messages/polls are inserted, thanks to Supabase Realtime.
final roomMessagesProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, roomId) {
  return ref.watch(messagingServiceProvider).watchMessages(roomId);
});

final pollByIdProvider =
    FutureProvider.family<PollModel, String>((ref, pollId) {
  return ref.watch(messagingServiceProvider).fetchPoll(pollId);
});

/// The current student's vote on a poll, if any — null means not voted yet.
final myPollVoteProvider =
    FutureProvider.family<String?, String>((ref, pollId) {
  return ref.watch(messagingServiceProvider).myVote(pollId);
});

/// Controller for sending messages, creating polls, and voting.
class MessagingController extends StateNotifier<AsyncValue<void>> {
  MessagingController(this._service) : super(const AsyncData(null));

  final MessagingService _service;

  Future<bool> sendText({required String roomId, required String text}) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => _service.sendTextMessage(roomId: roomId, text: text),
    );
    state = result.hasError
        ? AsyncError(result.error!, result.stackTrace!)
        : const AsyncData(null);
    return !result.hasError;
  }

  Future<bool> sendImage({required String roomId, required String imageUrl}) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => _service.sendImageMessage(roomId: roomId, imageUrl: imageUrl),
    );
    state = result.hasError
        ? AsyncError(result.error!, result.stackTrace!)
        : const AsyncData(null);
    return !result.hasError;
  }

  Future<bool> createPoll({
    required String roomId,
    required String question,
    required List<String> options,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => _service.createPoll(roomId: roomId, question: question, optionLabels: options),
    );
    state = result.hasError
        ? AsyncError(result.error!, result.stackTrace!)
        : const AsyncData(null);
    return !result.hasError;
  }

  Future<bool> vote({required String pollId, required String optionId}) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => _service.vote(pollId: pollId, optionId: optionId),
    );
    state = result.hasError
        ? AsyncError(result.error!, result.stackTrace!)
        : const AsyncData(null);
    return !result.hasError;
  }

  Future<bool> setChatEnabled(String roomId, bool enabled) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => _service.setChatEnabled(roomId, enabled),
    );
    state = result.hasError
        ? AsyncError(result.error!, result.stackTrace!)
        : const AsyncData(null);
    return !result.hasError;
  }
}

final messagingControllerProvider =
    StateNotifierProvider<MessagingController, AsyncValue<void>>((ref) {
  return MessagingController(ref.watch(messagingServiceProvider));
});
