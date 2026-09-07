import 'package:equatable/equatable.dart';

/// Every notification-triggering event type in the spec (§1): new
/// messages, poll creation, new content upload, attendance marked,
/// assignment posted, exam result published, payment due/received.
enum NotificationType {
  message,
  poll,
  content,
  attendance,
  assignment,
  examResult,
  paymentDue,
  paymentReceived,
  custom, // teacher's manual/custom notifications (spec §2.4)
}

NotificationType _typeFromString(String v) => NotificationType.values
    .firstWhere((e) => e.name == v, orElse: () => NotificationType.custom);

class NotificationModel extends Equatable {
  const NotificationModel({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    this.body,
    this.roomId,
    this.readAt,
    this.createdAt,
  });

  final String id;
  final String recipientId;
  final NotificationType type;
  final String title;
  final String? body;
  final String? roomId; // deep-links back to the relevant room, if any
  final DateTime? readAt;
  final DateTime? createdAt;

  bool get isRead => readAt != null;
  bool get isUnread => readAt == null;
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      recipientId: json['recipient_id'] as String,
      type: _typeFromString(json['type'] as String? ?? 'custom'),
      title: json['title'] as String,
      body: json['body'] as String?,
      roomId: json['room_id'] as String?,
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recipient_id': recipientId,
      'type': type.name,
      'title': title,
      'body': body,
      'room_id': roomId,
    };
  }

  @override
  List<Object?> get props =>
      [id, recipientId, type, title, body, roomId, readAt];
}
