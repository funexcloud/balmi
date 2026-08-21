import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../domain/config/sport_params.dart';
import '../db/app_database.dart';
import '../location/geolocator_location_engine.dart';
import '../location/location_engine.dart';
import '../repositories/session_repository.dart';
import '../sensors/cadence_engine.dart';
import 'recording_pipeline.dart';

const kFgRecorderKey = 'recorder';
const kFgDbPathKey = 'dbPath';
const kFgSessionIdKey = 'sessionId';
const kFgTrackModeKey = 'trackMode';
const kFgTrackSpecKey = 'trackSpecM';

/// Entry point for the Android foreground-service isolate.
@pragma('vm:entry-point')
void recordingStartCallback() {
  FlutterForegroundTask.setTaskHandler(RecordingTaskHandler());
}

class RecordingTaskHandler extends TaskHandler {
  AppDatabase? _db;
  RecordingPipeline? _pipeline;
  LocationEngine? _location;
  CadenceEngine? _cadence;
  StreamSubscription<dynamic>? _locSub;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final recorder =
        await FlutterForegroundTask.getData<String>(key: kFgRecorderKey);
    if (recorder != 'task') return;

    final dbPath =
        await FlutterForegroundTask.getData<String>(key: kFgDbPathKey);
    final sessionId =
        await FlutterForegroundTask.getData<String>(key: kFgSessionIdKey);
    if (dbPath == null || sessionId == null) return;

    final trackMode =
        await FlutterForegroundTask.getData<bool>(key: kFgTrackModeKey) ??
            false;
    final spec =
        await FlutterForegroundTask.getData<int>(key: kFgTrackSpecKey);
    final trackSpecM = (spec == null || spec < 0) ? null : spec;

    _db = AppDatabase.file(dbPath);
    final repo = SessionRepository(_db!);
    final session = await repo.sessionById(sessionId);
    _pipeline = RecordingPipeline(
      repo: repo,
      sessionId: sessionId,
      startedAt: session?.startedAt ?? timestamp,
      trackMode: trackMode,
      trackSpecM: trackSpecM,
      params: SportParams.defaults,
    );
    await _pipeline!.restore();

    _location = GeolocatorLocationEngine();
    _cadence = CadenceEngine();
    await _location!.start();
    await _cadence!.start();
    _locSub = _location!.fixes.listen(_pipeline!.onFix);
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    final pipeline = _pipeline;
    if (pipeline == null) return;
    pipeline.onCadence(_cadence?.spm);
    unawaited(_tick(pipeline, timestamp));
  }

  Future<void> _tick(RecordingPipeline pipeline, DateTime timestamp) async {
    final snap = await pipeline.sampleNow(timestamp);
    FlutterForegroundTask.sendDataToMain(snap.toJson());
    unawaited(
      FlutterForegroundTask.updateService(
        notificationTitle: 'balmi 기록 중',
        notificationText:
            '${snap.pointCount}점 · ${(snap.totalDistM / 1000).toStringAsFixed(2)}km',
      ),
    );
  }

  Future<void> _tearDown({bool enqueueLeftover = true}) async {
    await _locSub?.cancel();
    _locSub = null;
    await _location?.stop();
    await _cadence?.stop();
    final p = _pipeline;
    if (enqueueLeftover && p != null) {
      await p.repo.enqueueLeftover(p.sessionId);
    }
    await _db?.close();
    _db = null;
    _pipeline = null;
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _tearDown();
  }

  @override
  void onReceiveData(Object data) {
    if (data == 'stop' ||
        (data is Map && data['cmd'] == 'stop')) {
      unawaited(_tearDown());
    }
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }
}
