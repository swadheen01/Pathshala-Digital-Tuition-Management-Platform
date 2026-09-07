import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../models/message_model.dart';
import '../models/poll_model.dart';

/// Handles messages, polls, and votes for a room (spec §2.2, §3).
class MessagingService {
  MessagingService({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  Stream<List<MessageModel>> watchMessages(String roomId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at')
        .map((rows) => rows.map(MessageModel.fromJson).toList());
  }

  Future<void> sendTextMessage({
    required String roomId,
    required String text,
  }) async {
    final senderId = _client.auth.currentUser?.id;
    if (senderId == null) throw StateError('Not signed in.');

    await _client.from('messages').insert({
      'room_id': roomId,
      'sender_id': senderId,
      'type': 'text',
      'text': text,
    });
  }

  /// Sends an image message. Assumes the image is already uploaded to
  /// Supabase Storage and imageUrl is a public/signed URL
  /// (see storage_service.dart, built in a later phase).
  Future<void> sendImageMessage({
    required String roomId,
    required String imageUrl,
  }) async {
    final senderId = _client.auth.currentUser?.id;
    if (senderId == null) throw StateError('Not signed in.');

    await _client.from('messages').insert({
      'room_id': roomId,
      'sender_id': senderId,
      'type': 'image',
      'image_url': imageUrl,
    });
  }

  /// Toggles whether students can chat in a room (spec §2.2).
  Future<void> setChatEnabled(String roomId, bool enabled) async {
    await _client.from('rooms').update({'chat_enabled': enabled}).eq('id', roomId);
  }

  // --- Polls ---

  Future<PollModel> createPoll({
    required String roomId,
    required String question,
    required List<String> optionLabels,
  }) async {
    final teacherId = _client.auth.currentUser?.id;
    if (teacherId == null) throw StateError('Not signed in.');

    final pollRow = await _client
        .from('polls')
        .insert({
          'room_id': roomId,
          'question': question,
          'created_by': teacherId,
        })
        .select()
        .single();

    final pollId = pollRow['id'] as String;

    final optionRows = await _client
        .from('poll_options')
        .insert(optionLabels
            .map((label) => {'poll_id': pollId, 'label': label})
            .toList())
        .select();

    // Post a message referencing this poll so it shows in the feed.
    await _client.from('messages').insert({
      'room_id': roomId,
      'sender_id': teacherId,
      'type': 'poll',
      'poll_id': pollId,
    });

    return PollModel(
      id: pollId,
      roomId: roomId,
      question: question,
      options: (optionRows as List)
          .map((o) => PollOption.fromJson(o as Map<String, dynamic>))
          .toList(),
      createdBy: teacherId,
    );
  }

  Future<PollModel> fetchPoll(String pollId) async {
    final pollRow =
        await _client.from('polls').select().eq('id', pollId).single();

    final optionRows = await _client
        .from('poll_options_with_counts')
        .select()
        .eq('poll_id', pollId);

    return PollModel(
      id: pollRow['id'] as String,
      roomId: pollRow['room_id'] as String,
      question: pollRow['question'] as String,
      createdBy: pollRow['created_by'] as String?,
      options: (optionRows as List)
          .map((o) => PollOption.fromJson(o as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Casts a vote. Server-side unique constraint prevents double-voting
  /// (spec §2.2, §3), so this can simply attempt the insert.
  Future<void> vote({required String pollId, required String optionId}) async {
    final studentId = _client.auth.currentUser?.id;
    if (studentId == null) throw StateError('Not signed in.');

    await _client.from('poll_votes').insert({
      'poll_id': pollId,
      'option_id': optionId,
      'student_id': studentId,
    });
  }

  /// Returns the option id the current student already voted for, if any.
  Future<String?> myVote(String pollId) async {
    final studentId = _client.auth.currentUser?.id;
    if (studentId == null) return null;

    final row = await _client
        .from('poll_votes')
        .select('option_id')
        .eq('poll_id', pollId)
        .eq('student_id', studentId)
        .maybeSingle();

    return row?['option_id'] as String?;
  }
}
