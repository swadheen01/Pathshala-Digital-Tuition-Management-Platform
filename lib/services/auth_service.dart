import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../models/user_model.dart';

/// Handles all Supabase Auth calls: password/Google signup+login and
/// reading/writing the matching row in the `profiles` table (§1).
///
/// NOTE: This assumes a `profiles` table keyed by auth.users.id with
/// a Postgres trigger (or explicit insert here) that creates a row
/// on first signup. See supabase/migrations/0001_init.sql.
class AuthService {
  AuthService({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  /// Current logged-in session, or null if signed out.
  Session? get currentSession => _auth.currentSession;

  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes — use this to drive router redirects.
  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  /// Step 1 of email OTP flow: sends a one-time code to the email.
  /// Supabase's `signInWithOtp` handles both signup and login —
  /// if the user doesn't exist yet, it creates one.
  Future<void> sendEmailOtp(String email) async {
    await _auth.signInWithOtp(email: email);
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithPassword({
    required String email,
    required String password,
    required UserRole role,
  }) {
    return _auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: SupabaseConfig.authRedirectUri,
      data: {'role': role.name},
    );
  }

  /// Re-send the confirmation email for a user who signed up but hasn't
  /// clicked the link yet.
  Future<void> resendConfirmation(String email) {
    return _auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: SupabaseConfig.authRedirectUri,
    );
  }

  /// Send a password-reset email.
  Future<void> sendPasswordReset(String email) {
    return _auth.resetPasswordForEmail(
      email,
      redirectTo: SupabaseConfig.authRedirectUri,
    );
  }

  /// Starts Google OAuth. Returns true once the browser/customtab handoff
  /// has been launched; the session itself arrives asynchronously via the
  /// `io.supabase.pathshala://login-callback/` deep link, which
  /// supabase_flutter exchanges automatically. Listen to
  /// [authStateChanges] for completion.
  Future<bool> signInWithGoogle() {
    // Default launch mode = an in-app Custom Tab, which hands control back
    // to the app via the io.supabase.pathshala://login-callback/ deep link
    // far more reliably than an external browser.
    return _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: SupabaseConfig.authRedirectUri,
    );
  }

  /// Persist a teacher/student choice for an already-authenticated user
  /// (used by the role-selection step, especially for Google sign-ups that
  /// arrive with no role). Backed by the `set_my_role` RPC (migration 0014).
  Future<void> setMyRole(UserRole role) async {
    await _client.rpc('set_my_role', params: {'new_role': role.name});
  }

  /// Step 2: verify the code the user received by email.
  Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    return _auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }

  /// Phone OTP variant, if you prefer SMS-based signup over email.
  Future<void> sendPhoneOtp(String phone) async {
    await _auth.signInWithOtp(phone: phone);
  }

  Future<AuthResponse> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    return _auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  Future<void> signOut() => _auth.signOut();

  /// Call right after first successful verification to create/complete
  /// the profile row: role, name, class/grade, institution (§1).
  Future<UserModel> completeProfile({
    required String fullName,
    required UserRole role,
    String? classGrade,
    String? institution,
  }) async {
    final userId = _auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No authenticated user — cannot complete profile.');
    }

    final data = {
      'id': userId,
      'full_name': fullName.trim(),
      'role': role.name,
      'email': _auth.currentUser?.email,
      'phone': _auth.currentUser?.phone,
      'class_grade': classGrade,
      'institution': institution,
      'profile_completed': true,
    }..removeWhere((_, value) => value == null);

    final response =
        await _client.from('profiles').upsert(data).select().single();

    return UserModel.fromJson(response);
  }

  Future<UserModel> updateProfile({
    required String fullName,
    required String email,
    required String phone,
    required UserRole role,
    String? classGrade,
    String? institution,
    String? avatarUrl,
  }) async {
    final userId = _auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No authenticated user — cannot update profile.');
    }

    final currentUser = _auth.currentUser;
    if ((email.trim().isNotEmpty && email.trim() != currentUser?.email) ||
        (phone.trim().isNotEmpty && phone.trim() != currentUser?.phone)) {
      await _auth.updateUser(
        UserAttributes(
          email: email.trim().isEmpty ? null : email.trim(),
          phone: phone.trim().isEmpty ? null : phone.trim(),
        ),
      );
    }

    final response = await _client
        .from('profiles')
        .update({
          'full_name': fullName,
          'email': email.trim().isEmpty ? null : email.trim(),
          'phone': phone.trim().isEmpty ? null : phone.trim(),
          'role': role.name,
          'class_grade': classGrade,
          'institution': institution,
          'avatar_url': avatarUrl,
          'profile_completed': true,
        })
        .eq('id', userId)
        .select()
        .single();

    return UserModel.fromJson(response);
  }

  /// Fetch the profile row for the currently signed-in user.
  ///
  /// Immediately after signup/OAuth the `handle_new_user` trigger row can
  /// lag the client by a few hundred ms, so we retry a couple of times
  /// before giving up. Returns null only if the row genuinely isn't there.
  Future<UserModel?> fetchCurrentProfile() async {
    final userId = _auth.currentUser?.id;
    if (userId == null) return null;

    for (var attempt = 0; attempt < 3; attempt++) {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) return UserModel.fromJson(response);
      if (attempt < 2) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
    }
    return null;
  }
}
