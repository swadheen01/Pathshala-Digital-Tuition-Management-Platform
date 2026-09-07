import 'package:equatable/equatable.dart';

enum MessageType { text, image, poll }

MessageType _typeFromString(String v) =>
    MessageType.values.firstWhere((e) => e.name == v, orElse: () => MessageType.text);

/// A message in a room's chat/announcement feed (spec §2.2).
class MessageModel extends Equatable {
  const MessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.type,
    this.senderName,
    this.text,
    this.imageUrl,
    this.pollId,
    this.createdAt,
  });

  final String id;
  final String roomId;
  final String senderId;
  final MessageType type;
  final String? senderName; // joined from profiles, for display
  final String? text;
  final String? imageUrl; // spec §2.2: teacher can share images
  final String? pollId; // set if type == poll
  final DateTime? createdAt;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return MessageModel(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      senderId: json['sender_id'] as String,
      type: _typeFromString(json['type'] as String? ?? 'text'),
      senderName: profile?['full_name'] as String?,
      text: json['text'] as String?,
      imageUrl: json['image_url'] as String?,
      pollId: json['poll_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'sender_id': senderId,
      'type': type.name,
      'text': text,
      'image_url': imageUrl,
      'poll_id': pollId,
    };
  }

  @override
  List<Object?> get props =>
      [id, roomId, senderId, type, text, imageUrl, pollId];
}
