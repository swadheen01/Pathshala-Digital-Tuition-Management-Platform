import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Turns raw Supabase / network auth failures into a single short line
/// that is safe and useful to show a user.
///
/// The screens previously printed `${state.error}` straight into a
/// SnackBar, which surfaced noise like
/// `AuthRetryableFetchException(message: ..., statusCode: null)`.
String friendlyAuthError(Object? error) {
  if (error == null) return 'Something went wrong. Please try again.';

  // No connection / DNS / TLS / timeout reaching the auth server.
  if (error is AuthRetryableFetchException ||
      error is SocketException ||
      error is HttpException) {
    return "Can't reach the server. Check your internet connection and "
        'try again.';
  }

  if (error is AuthApiException || error is AuthException) {
    final message = (error as AuthException).message.toLowerCase();

    if (message.contains('email not confirmed')) {
      return 'Please confirm your email first. We just re-sent the link.';
    }
    if (message.contains('invalid login credentials')) {
      return 'Email or password is incorrect.';
    }
    if (message.contains('user already registered') ||
        message.contains('already been registered')) {
      return 'An account with this email already exists. Try signing in.';
    }
    if (message.contains('password should be at least')) {
      return 'Password is too short. Use at least 6 characters.';
    }
    if (message.contains('rate limit') || message.contains('too many')) {
      return 'Too many attempts. Please wait a minute and try again.';
    }
    if (message.contains('otp') && message.contains('expired')) {
      return 'That code has expired. Request a new one.';
    }
    if (message.contains('token has expired') || message.contains('invalid')) {
      return 'That code is invalid or has expired. Request a new one.';
    }
    // Fall back to Supabase's own message — it's usually human-readable.
    return (error).message;
  }

  return 'Something went wrong. Please try again.';
}
