import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/content_model.dart';
import '../models/user_model.dart';
import '../services/admin_service.dart';

final adminServiceProvider = Provider<AdminService>((ref) => AdminService());

final allTeachersProvider = FutureProvider<List<UserModel>>((ref) {
  return ref.watch(adminServiceProvider).fetchTeachers();
});

final allStudentsProvider = FutureProvider<List<UserModel>>((ref) {
  return ref.watch(adminServiceProvider).fetchStudents();
});

final platformAnalyticsProvider = FutureProvider<PlatformAnalytics>((ref) {
  return ref.watch(adminServiceProvider).fetchAnalytics();
});

class AdminController extends StateNotifier<AsyncValue<void>> {
  AdminController(this._service) : super(const AsyncData(null));

  final AdminService _service;

  Future<bool> deleteUser(String userId) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _service.deleteUser(userId));
    state = result.hasError
        ? AsyncError(result.error!, result.stackTrace!)
        : const AsyncData(null);
    return !result.hasError;
  }
}

final adminControllerProvider =
    StateNotifierProvider<AdminController, AsyncValue<void>>((ref) {
  return AdminController(ref.watch(adminServiceProvider));
});
