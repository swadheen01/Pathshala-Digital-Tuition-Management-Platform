import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/room_member_model.dart';
import '../models/room_model.dart';
import '../services/room_service.dart';

final roomServiceProvider = Provider<RoomService>((ref) => RoomService());

/// Rooms owned by the current teacher (spec §2.1). Call
/// `ref.invalidate(teacherRoomsProvider)` after create/delete to refresh.
final teacherRoomsProvider = FutureProvider<List<RoomModel>>((ref) {
  return ref.watch(roomServiceProvider).fetchTeacherRooms();
});

/// Rooms the current student has joined.
final studentRoomsProvider = FutureProvider<List<RoomModel>>((ref) {
  return ref.watch(roomServiceProvider).fetchStudentRooms();
});

/// A single room by id — used on detail screens.
final roomByIdProvider =
    FutureProvider.family<RoomModel, String>((ref, roomId) {
  return ref.watch(roomServiceProvider).fetchRoomById(roomId);
});

/// Roster of students in a room (spec §2.1), joined with profile info.
final roomMembersProvider =
    FutureProvider.family<List<RoomMemberWithProfile>, String>((ref, roomId) {
  return ref.watch(roomServiceProvider).fetchRoomMembers(roomId);
});

/// Pending / resolved claim requests for a room (teacher view, 0015).
final roomJoinRequestsProvider =
    FutureProvider.family<List<RoomJoinRequestModel>, String>((ref, roomId) {
  return ref.watch(roomServiceProvider).fetchJoinRequests(roomId);
});

/// Count of pending claim requests — drives the badge on the room hub.
final pendingClaimCountProvider =
    Provider.family<int, String>((ref, roomId) {
  return ref.watch(roomJoinRequestsProvider(roomId)).maybeWhen(
        data: (rows) => rows.where((r) => r.isPending).length,
        orElse: () => 0,
      );
});

/// Controller for room mutations: create, join, update settings, delete.
/// UI calls these via ref.read(roomControllerProvider.notifier).
class RoomController extends StateNotifier<AsyncValue<void>> {
  RoomController(this._service) : super(const AsyncData(null));

  final RoomService _service;

  Future<RoomModel?> createRoom({
    required String name,
    String? subject,
    String? description,
    List<int> classDays = const [],
    String? classStartTime,
    String? classEndTime,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _service.createRoom(
          name: name,
          subject: subject,
          description: description,
          classDays: classDays,
          classStartTime: classStartTime,
          classEndTime: classEndTime,
        ));
    state = result.hasError
        ? AsyncError(result.error!, result.stackTrace!)
        : const AsyncData(null);
    return result.valueOrNull;
  }

  Future<RoomModel?> joinRoom(String joinCode, {String? rollNumber}) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => _service.joinRoomByCode(joinCode, rollNumber: rollNumber),
    );
    state = result.hasError
        ? AsyncError(result.error!, result.stackTrace!)
        : const AsyncData(null);
    return result.valueOrNull;
  }

  Future<bool> updateRoomSettings(
    String roomId, {
    bool? chatEnabled,
    bool? leaderboardEnabled,
    List<int>? classDays,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _service.updateRoom(
          roomId,
          chatEnabled: chatEnabled,
          leaderboardEnabled: leaderboardEnabled,
          classDays: classDays,
        ));
    state = result.hasError
        ? AsyncError(result.error!, result.stackTrace!)
        : const AsyncData(null);
    return !result.hasError;
  }

  Future<bool> deleteRoom(String roomId) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _service.deleteRoom(roomId));
    state = result.hasError
        ? AsyncError(result.error!, result.stackTrace!)
        : const AsyncData(null);
    return !result.hasError;
  }

  Future<bool> _guard(Future<void> Function() action) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);
    state = result;
    return !result.hasError;
  }

  Future<bool> addRosterStudent({
    required String roomId,
    required String fullName,
    String? rollNumber,
    String? phone,
    String? email,
    num monthlyFee = 0,
  }) {
    return _guard(() => _service.addRosterStudent(
          roomId: roomId,
          fullName: fullName,
          rollNumber: rollNumber,
          phone: phone,
          email: email,
          monthlyFee: monthlyFee,
        ));
  }

  Future<bool> updateRosterStudent({
    required String memberId,
    String? fullName,
    String? rollNumber,
    String? phone,
    String? email,
    num? monthlyFee,
  }) {
    return _guard(() => _service.updateRosterStudent(
          memberId: memberId,
          fullName: fullName,
          rollNumber: rollNumber,
          phone: phone,
          email: email,
          monthlyFee: monthlyFee,
        ));
  }

  Future<bool> removeMemberById(String memberId) {
    return _guard(() => _service.removeMemberById(memberId));
  }

  Future<bool> approveClaim(String requestId) {
    return _guard(() => _service.approveClaim(requestId));
  }

  Future<bool> rejectClaim(String requestId) {
    return _guard(() => _service.rejectClaim(requestId));
  }

  /// Student-side: request to be linked to a name-only roster row.
  /// Returns the room name on success, or null on failure.
  Future<String?> requestClaim({
    required String joinCode,
    required String fullName,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => _service.requestClaim(joinCode: joinCode, fullName: fullName),
    );
    state = result.hasError
        ? AsyncError(result.error!, result.stackTrace!)
        : const AsyncData(null);
    return result.valueOrNull;
  }
}

final roomControllerProvider =
    StateNotifierProvider<RoomController, AsyncValue<void>>((ref) {
  return RoomController(ref.watch(roomServiceProvider));
});
