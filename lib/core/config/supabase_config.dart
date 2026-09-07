import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Central place for Supabase connection details and initialization.
///
/// SECURITY NOTE:
/// Never hardcode the URL/anon key directly if this repo will be public.
/// Pass them at build/run time instead:
///
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=your-anon-key
class SupabaseConfig {
  SupabaseConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://lrodshwhnufvdnujhvrv.supabase.co',
  );

  /// New-style Supabase "publishable" key (`sb_publishable_...`). Passed as
  /// `publishableKey` below. A legacy JWT anon key also works if supplied.
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_CnW5_WLyV83PfK8tbNmyiA_LEiAmgeI',
  );

  /// The redirect used by BOTH Google OAuth and email confirmation /
  /// magic links. This exact string must be registered in the Supabase
  /// Dashboard under Authentication > URL Configuration > Redirect URLs,
  /// and it must match the deep-link intent filter in
  /// android/app/src/main/AndroidManifest.xml and the CFBundleURLSchemes
  /// entry in ios/Runner/Info.plist.
  static const String authRedirectUri =
      'io.supabase.pathshala://login-callback/';

  /// Call this once in main() before runApp().
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
      // PKCE is required for the email-confirmation / magic-link deep link
      // to complete inside the app. supabase_flutter automatically listens
      // for the `authRedirectUri` deep link and exchanges the `?code=` for
      // a session (detectSessionInUri defaults to true).
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      ),
      // Surface auth / network logs while developing so
      // AuthRetryableFetchException root causes are visible.
      debug: kDebugMode,
    );
  }

  /// Shortcut accessor used throughout the app's service layer.
  static SupabaseClient get client => Supabase.instance.client;
}
