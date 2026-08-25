import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../core/copy.dart';
import '../../core/format.dart';
import '../../domain/models/activity.dart';
import '../../domain/models/sport.dart';
import '../db/app_database.dart';
import '../location/geolocator_location_engine.dart';
import '../location/location_engine.dart';
import '../repositories/session_repository.dart';
import 'recorder_lease.dart';
import 'recording_pipeline.dart';

const kFgRecorderKey = 'recorder';
const kFgDbPathKey = 'dbPath';
const kFgSessionIdKey = 'sessionId';
const kFgTrackModeKey = 'trackMode';
const kFgTrackSpecKey = 'trackSpecM';
const kFgPausedKey = 'paused';
const kFgHeartbeatCommand = 'mainHeartbeat';
const kFgStopCommand = 'stop';

/// Entry point for the Android foreground-service isolate.
@pragma('vm:entry-point')
void recordingStartCallback() {
  FlutterForegroundTask.setTaskHandler(RecordingTaskHandler());
}

class RecordingTaskHandler extends TaskHandler {
  static const _lease = RecorderLease();

  int? _mainHeartbeatMs;
  bool _paused = false;
  bool _busy = false;
  bool _stopping = false;
  AppDatabase? _db;
  GeolocatorLocationEngine? _location;
  StreamSubscription<LocationFix>? _locationSub;
  RecordingPipeline? _pipeline;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _mainHeartbeatMs = timestamp.millisecondsSinceEpoch;
    _paused =
        await FlutterForegroundTask.getData<bool>(key: kFgPausedKey) ?? false;
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    unawaited(_tick(timestamp));
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _stopping = true;
    final deadline = DateTime.now().add(const Duration(seconds: 2));
    while (_busy && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    await _suspendBackup();
  }

  @override
  void onReceiveData(Object data) {
    if (data == kFgStopCommand) {
      _stopping = true;
      return;
    }
    if (data is Map) {
      final command = data['type'];
      if (command == kFgHeartbeatCommand) {
        final at = data['atMs'];
        if (at is num) _mainHeartbeatMs = at.round();
        _paused = data['paused'] == true;
      }
    }
  }

  Future<void> _tick(DateTime now) async {
    if (_busy || _stopping) return;
    _busy = true;
    try {
      final shouldTakeOver =
          !_paused &&
          _lease.shouldTakeOver(now: now, mainHeartbeatMs: _mainHeartbeatMs);
      if (!shouldTakeOver) {
        await _suspendBackup();
        return;
      }
      if (!await _ensureBackup()) return;
      final pipeline = _pipeline!;
      final snapshot = await pipeline.sampleNow(now);
      FlutterForegroundTask.sendDataToMain({
        ...snapshot.toJson(),
        'source': 'foregroundBackup',
      });
      await FlutterForegroundTask.updateService(
        notificationTitle: 'balmi 기록 보호 중',
        notificationText: snapshot.pointCount == 0
            ? BalmiCopy.waitingGpsShort
            : formatRecordingNotification(
                elapsed: now.difference(
                  DateTime.fromMillisecondsSinceEpoch(snapshot.startedAtMs),
                ),
                distM: snapshot.totalDistM,
              ),
      );
    } catch (_) {
      FlutterForegroundTask.sendDataToMain({
        'error': BalmiCopy.backgroundRetry,
        'source': 'foregroundBackup',
      });
      await _suspendBackup();
    } finally {
      _busy = false;
    }
  }

  Future<bool> _ensureBackup() async {
    if (_pipeline != null && _location != null) return true;
    final dbPath = await FlutterForegroundTask.getData<String>(
      key: kFgDbPathKey,
    );
    final sessionId = await FlutterForegroundTask.getData<String>(
      key: kFgSessionIdKey,
    );
    if (dbPath == null ||
        dbPath.isEmpty ||
        sessionId == null ||
        sessionId.isEmpty) {
      return false;
    }

    final db = AppDatabase.file(dbPath);
    final repo = SessionRepository(db);
    final session = await repo.sessionById(sessionId);
    if (session == null || session.status != SessionStatus.recording.wire) {
      await db.close();
      return false;
    }

    final activity = ActivityKind.fromWire(session.activity);
    final pipeline = RecordingPipeline(
      repo: repo,
      sessionId: sessionId,
      startedAt: session.startedAt,
      trackMode: session.trackMode || activity.isTrack,
      trackSpecM: session.trackSpecM,
      activity: activity,
    );
    await pipeline.restore();
    final location = GeolocatorLocationEngine();
    await location.start();
    final subscription = location.fixes.listen(pipeline.onFix);

    _db = db;
    _pipeline = pipeline;
    _location = location;
    _locationSub = subscription;
    return true;
  }

  Future<void> _suspendBackup() async {
    await _locationSub?.cancel();
    _locationSub = null;
    await _location?.stop();
    _location = null;
    _pipeline = null;
    await _db?.close();
    _db = null;
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }
}
