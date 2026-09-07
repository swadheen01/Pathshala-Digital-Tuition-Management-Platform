import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';
import 'services/offline_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up the Supabase client (auth, database, storage, realtime).
  // Never let a init hiccup leave the user staring at a black screen —
  // start the app anyway; network calls will surface a friendly error.
  try {
    await SupabaseConfig.initialize();
  } catch (e, st) {
    debugPrint('Supabase init failed: $e\n$st');
  }

  // Auto-flush any attendance marked while offline as soon as
  // connectivity returns (spec §2.3).
  try {
    OfflineSyncService().listenForConnectivity();
  } catch (e) {
    debugPrint('OfflineSyncService init failed: $e');
  }

  runApp(
    // ProviderScope makes Riverpod providers available to the whole tree.
    const ProviderScope(
      child: PathshalaApp(),
    ),
  );
}
