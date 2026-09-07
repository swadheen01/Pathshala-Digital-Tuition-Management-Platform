import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Exposes online/offline status app-wide. Used to show a "you're
/// offline" banner and to trigger offline_sync_service's flush when
/// connectivity returns (spec §2.3).
final connectivityStreamProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// Simple bool derived from the stream — true when online.
final isOnlineProvider = Provider<bool>((ref) {
  final results = ref.watch(connectivityStreamProvider).valueOrNull;
  if (results == null) return true; // assume online until first event
  return !results.contains(ConnectivityResult.none);
});
