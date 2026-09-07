import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Raw Supabase auth state stream — emits on sign-in, sign-out, token
/// refresh, user update, and (crucially) when the email-confirmation /
/// OAuth deep link delivers a session back into the app.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// The current user's profile row (§1: role, class/grade, institution …).
///
/// Re-fetches whenever the auth state changes. Returns null when signed
/// out, or when the `profiles` row genuinely doesn't exist yet.
final currentProfileProvider = FutureProvider<UserModel?>((ref) async {
  // Re-run whenever auth state changes (login / logout / deep-link return).
  ref.watch(authStateChangesProvider);

  final authService = ref.watch(authServiceProvider);
  if (authService.currentSession == null) return null;

  return authService.fetchCurrentProfile();
});

/// Convenience bool for gating screens.
final isLoggedInProvider = Provider<bool>((ref) {
  final streamSession =
      ref.watch(authStateChangesProvider).valueOrNull?.session;
  return streamSession != null ||
      ref.watch(authServiceProvider).currentSession != null;
});

/// Where a signed-in but not-yet-completed user is in onboarding.
enum OnboardingStep { none, chooseRole, completeProfile, done }

/// Single source of truth the router uses to decide redirects. Computed
/// synchronously from the session + the (async) profile.
class AuthGate {
  const AuthGate({
    required this.isResolving,
    required this.isAuthenticated,
    required this.step,
    this.role,
    this.hasError = false,
  });

  /// Still waiting on the first profile fetch — the UI should hold on
  /// the splash rather than bounce to /login.
  final bool isResolving;
  final bool isAuthenticated;
  final OnboardingStep step;
  final UserRole? role;
  final bool hasError;

  bool get isReady => isAuthenticated && step == OnboardingStep.done;
}

/// Role the user picked during signup / role-selection, kept in memory so
/// the profile-setup step and the router redirect agree on it even before
/// the `profiles` row reflects the choice.
final pendingRoleProvider = StateProvider<UserRole?>((ref) => null);

final authGateProvider = Provider<AuthGate>((ref) {
  // Once any auth event has arrived, trust it (it reflects sign-out too);
  // before that, fall back to the session restored during initialize().
  final authEvent = ref.watch(authStateChangesProvider);
  final session = authEvent.hasValue
      ? authEvent.value!.session
      : ref.watch(authServiceProvider).currentSession;

  if (session == null) {
    return const AuthGate(
      isResolving: false,
      isAuthenticated: false,
      step: OnboardingStep.none,
    );
  }

  final profileAsync = ref.watch(currentProfileProvider);
  final pendingRole = ref.watch(pendingRoleProvider);
  final metaRoleRaw =
      ref.watch(authServiceProvider).currentUser?.userMetadata?['role']
          as String?;
  final metaRole = (metaRoleRaw == 'teacher' || metaRoleRaw == 'student')
      ? userRoleFromString(metaRoleRaw!)
      : null;

  return profileAsync.when(
    loading: () => AuthGate(
      isResolving: !profileAsync.hasValue,
      isAuthenticated: true,
      step: OnboardingStep.none,
      role: profileAsync.valueOrNull?.role,
    ),
    error: (_, __) => const AuthGate(
      isResolving: false,
      isAuthenticated: true,
      step: OnboardingStep.done, // let the destination screen show the error
      hasError: true,
    ),
    data: (profile) {
      if (profile != null && profile.profileCompleted) {
        return AuthGate(
          isResolving: false,
          isAuthenticated: true,
          step: OnboardingStep.done,
          role: profile.role,
        );
      }

      final knownRole = pendingRole ?? metaRole ?? profile?.role;
      final needsRole = pendingRole == null && metaRole == null;

      return AuthGate(
        isResolving: false,
        isAuthenticated: true,
        step: needsRole
            ? OnboardingStep.chooseRole
            : OnboardingStep.completeProfile,
        role: knownRole,
      );
    },
  );
});

/// Controller for auth actions. Screens call methods via
/// `ref.read(authControllerProvider.notifier)`; navigation is handled
/// centrally by the router redirect, not here.
class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._ref, this._authService)
      : super(const AsyncData(null));

  final Ref _ref;
  final AuthService _authService;

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);
    state = result;
    return !result.hasError;
  }

  Future<bool> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _run(() async {
      await _authService.signInWithPassword(email: email, password: password);
      _ref.invalidate(currentProfileProvider);
    });
  }

  Future<bool> signUpWithPassword({
    required String email,
    required String password,
    required UserRole role,
  }) {
    return _run(() async {
      _ref.read(pendingRoleProvider.notifier).state = role;
      await _authService.signUpWithPassword(
        email: email,
        password: password,
        role: role,
      );
      _ref.invalidate(currentProfileProvider);
    });
  }

  Future<bool> signInWithGoogle() {
    return _run(() async {
      final started = await _authService.signInWithGoogle();
      if (!started) {
        throw const AuthException('Could not start Google sign-in.');
      }
    });
  }

  Future<bool> verifyEmailOtp({
    required String email,
    required String token,
  }) {
    return _run(() async {
      await _authService.verifyEmailOtp(email: email, token: token);
      _ref.invalidate(currentProfileProvider);
    });
  }

  Future<bool> resendConfirmation(String email) {
    return _run(() => _authService.resendConfirmation(email));
  }

  Future<bool> sendPasswordReset(String email) {
    return _run(() => _authService.sendPasswordReset(email));
  }

  /// Persist the teacher/student choice for a signed-in user.
  Future<bool> chooseRole(UserRole role) {
    return _run(() async {
      _ref.read(pendingRoleProvider.notifier).state = role;
      await _authService.setMyRole(role);
      _ref.invalidate(currentProfileProvider);
    });
  }

  Future<UserModel?> completeProfile({
    required String fullName,
    required UserRole role,
    String? classGrade,
    String? institution,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => _authService.completeProfile(
        fullName: fullName,
        role: role,
        classGrade: classGrade,
        institution: institution,
      ),
    );
    state = result.hasError
        ? AsyncError(result.error!, result.stackTrace!)
        : const AsyncData(null);
    if (!result.hasError) {
      _ref.read(pendingRoleProvider.notifier).state = null;
      _ref.invalidate(currentProfileProvider);
    }
    return result.valueOrNull;
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _authService.signOut();
      _ref.read(pendingRoleProvider.notifier).state = null;
      _ref.invalidate(currentProfileProvider);
    });
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref, ref.watch(authServiceProvider));
});
