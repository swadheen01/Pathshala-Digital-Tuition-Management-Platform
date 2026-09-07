import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/config/supabase_config.dart';

/// Handles file/image uploads to Supabase Storage. Used by messaging
/// (image messages, spec §2.2), assignment submissions (spec §2.6),
/// and profile avatars.
///
/// SETUP REQUIRED: create these Storage buckets in your Supabase
/// project before using this service:
///   - `message-images`  (public read, authenticated write)
///   - `submissions`      (private — teacher + submitting student only)
///   - `avatars`          (public read, authenticated write)
class StorageService {
  StorageService({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;
  final _uuid = const Uuid();

  Future<String> _upload({
    required String bucket,
    required String pathPrefix,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final fileName = '$pathPrefix/${_uuid.v4()}.$fileExtension';

    try {
      await _client.storage.from(bucket).uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: false),
          );
    } on StorageException catch (error) {
      if (error.message.toLowerCase().contains('bucket')) {
        throw StorageBucketNotConfiguredException(bucket);
      }
      rethrow;
    }

    return _client.storage.from(bucket).getPublicUrl(fileName);
  }

  /// Uploads an image for a chat message (spec §2.2) and returns its
  /// public URL, ready to pass into MessagingService.sendImageMessage.
  Future<String> uploadMessageImage({
    required String roomId,
    required Uint8List bytes,
    String fileExtension = 'jpg',
  }) {
    return _upload(
      bucket: 'message-images',
      pathPrefix: roomId,
      bytes: bytes,
      fileExtension: fileExtension,
    );
  }

  /// Uploads a file/image submission for an assignment (spec §2.6).
  Future<String> uploadSubmissionFile({
    required String assignmentId,
    required Uint8List bytes,
    required String fileExtension,
  }) {
    final userId = _client.auth.currentUser?.id ?? 'unknown';
    return _upload(
      bucket: 'submissions',
      pathPrefix: '$assignmentId/$userId',
      bytes: bytes,
      fileExtension: fileExtension,
    );
  }

  /// Uploads a profile avatar image.
  Future<String> uploadAvatar({
    required Uint8List bytes,
    String fileExtension = 'jpg',
  }) {
    final userId = _client.auth.currentUser?.id ?? 'unknown';
    return _upload(
      bucket: 'avatars',
      pathPrefix: userId,
      bytes: bytes,
      fileExtension: fileExtension,
    );
  }
}

class StorageBucketNotConfiguredException implements Exception {
  const StorageBucketNotConfiguredException(this.bucket);

  final String bucket;

  @override
  String toString() =>
      'Storage bucket "$bucket" is not configured. Create it in '
      'Supabase Storage before uploading files.';
}
