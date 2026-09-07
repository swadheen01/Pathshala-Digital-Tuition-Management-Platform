import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';

/// Manages the app's current locale (spec §1: Bengali/English toggle).
/// Starts from the signed-in user's saved `language_preference`
/// (profiles table) and persists changes back to it.
class LocaleController extends StateNotifier<Locale> {
  LocaleController() : super(const Locale('en')) {
    _loadFromProfile();
  }

  Future<void> _loadFromProfile() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await SupabaseConfig.client
          .from('profiles')
          .select('language_preference')
          .eq('id', userId)
          .maybeSingle();

      final code = response?['language_preference'] as String?;
      if (code == 'en' || code == 'bn') {
        state = Locale(code!);
      }
    } on PostgrestException catch (error, stackTrace) {
      // The saved language is optional; an unavailable profile column or row
      // must not prevent unauthenticated users from reaching the login page.
      debugPrint(
        'Unable to load the saved locale: ${error.message}\n$stackTrace',
      );
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;

    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;

    await SupabaseConfig.client
        .from('profiles')
        .update({'language_preference': locale.languageCode}).eq('id', userId);
  }
}

final localeProvider = StateNotifierProvider<LocaleController, Locale>((ref) {
  return LocaleController();
});
