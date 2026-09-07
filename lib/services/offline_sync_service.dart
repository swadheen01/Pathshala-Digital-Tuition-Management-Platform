import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'attendance_service.dart';

/// Queues attendance-marking actions locally when offline, then flushes
/// them to Supabase once connectivity returns (spec §2.3: "teacher can
/// mark attendance without an internet connection; data syncs
/// automatically once back online").
///
/// Usage from a screen/provider:
///   await offlineSyncService.queueOrSend(roomId: ..., date: ..., presentMap: ...);
///   // call this once, e.g. in main.dart or a top-level listener, to
///   // auto-flush whenever connectivity is restored:
///   offlineSyncService.listenForConnectivity();
class OfflineSyncService {
  OfflineSyncService({AttendanceService? attendanceService})
      : _attendanceService = attendanceService ?? AttendanceService();

  final AttendanceService _attendanceService;
  Database? _db;

  static const _tableName = 'pending_attendance';

  Future<Database> _getDb() async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'pathshala_offline.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            room_id TEXT NOT NULL,
            date TEXT NOT NULL,
            present_map TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Call this instead of AttendanceService.markAttendanceBulk directly
  /// from the attendance screen. Sends immediately if online; otherwise
  /// queues locally and returns without throwing.
  Future<void> queueOrSend({
    required String roomId,
    required DateTime date,
    required Map<String, bool> presentMap,
  }) async {
    if (await _isOnline()) {
      try {
        await _attendanceService.markAttendanceBulk(
          roomId: roomId,
          date: date,
          presentMap: presentMap,
        );
        return;
      } catch (_) {
        // Network dropped mid-request or server error — fall through
        // to queue locally rather than losing the teacher's input.
      }
    }
    await _queueLocally(roomId: roomId, date: date, presentMap: presentMap);
  }

  Future<void> _queueLocally({
    required String roomId,
    required DateTime date,
    required Map<String, bool> presentMap,
  }) async {
    final db = await _getDb();
    await db.insert(_tableName, {
      'room_id': roomId,
      'date': date.toIso8601String(),
      'present_map': jsonEncode(presentMap),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Number of attendance batches waiting to sync — show this as a
  /// badge/banner in the UI so the teacher knows sync is pending.
  Future<int> pendingCount() async {
    final db = await _getDb();
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Attempts to push every queued batch to Supabase. Safe to call
  /// repeatedly (e.g. on app resume, or on a connectivity-restored
  /// event) — successfully synced rows are deleted; failures stay
  /// queued for the next attempt.
  Future<void> flushPending() async {
    if (!await _isOnline()) return;

    final db = await _getDb();
    final rows = await db.query(_tableName, orderBy: 'created_at ASC');

    for (final row in rows) {
      try {
        final presentMap = (jsonDecode(row['present_map'] as String) as Map)
            .map((k, v) => MapEntry(k as String, v as bool));

        await _attendanceService.markAttendanceBulk(
          roomId: row['room_id'] as String,
          date: DateTime.parse(row['date'] as String),
          presentMap: presentMap,
        );

        await db.delete(_tableName, where: 'id = ?', whereArgs: [row['id']]);
      } catch (_) {
        // Leave this row queued; stop here so a persistent failure
        // (e.g. auth expired) doesn't spin through every row pointlessly.
        break;
      }
    }
  }

  /// Starts listening for connectivity changes and auto-flushes the
  /// queue when the device comes back online. Call once at app startup.
  void listenForConnectivity() {
    Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        flushPending();
      }
    });
  }
}
