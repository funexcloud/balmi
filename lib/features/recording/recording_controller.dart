import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../data/location/geolocator_location_engine.dart';
import '../../data/location/location_engine.dart';
import '../../data/recording/recording_pipeline.dart';
import '../../data/recording/recording_snapshot.dart';
import '../../data/recording/recording_task.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/sensors/cadence_engine.dart';
import '../../domain/models/sport.dart';

class RecordingController extends ChangeNotifier {
  RecordingController({
    required this.repo,
    required this.dbPath,
  });

  final SessionRepository repo;
  final String dbPath;

  final FlutterTts _tts = FlutterTts();
  Timer? _localTimer;
  LocationEngine? _localLocation;
  CadenceEngine? _localCadence;
  StreamSubscription<LocationFix>? _localLocSub;

  RecordingSnapshot? snapshot;
  bool get isRecording => snapshot != null;
  String? lastError;

  void attachTaskListener() {
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    _localTimer?.cancel();
    super.dispose();
  }

  void _onTaskData(Object data) {
    if (data is Map) {
      final snap = RecordingSnapshot.fromJson(data);
      snapshot = snap;
      notifyListeners();
      final tts = snap.lapTts;
      if (tts != null && tts.isNotEmpty) {
        unawaited(_speak(tts));
      }
    }
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.setLanguage('ko-KR');
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> initForeground() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'balmi_recording',
        channelName: 'balmi 기록',
        channelDescription: '걷기·달리기 기록을 이어가는 동안 표시됩니다.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<void> start({required bool trackMode, int? trackSpecM}) async {
    lastError = null;
    final session = await repo.createSession(
      trackMode: trackMode,
      trackSpecM: trackSpecM,
    );
    await _begin(session.id, trackMode: trackMode, trackSpecM: trackSpecM);
  }

  Future<void> resume(String sessionId) async {
    lastError = null;
    final session = await repo.sessionById(sessionId);
    if (session == null) return;
    await _begin(
      sessionId,
      trackMode: session.trackMode,
      trackSpecM: session.trackSpecM,
    );
  }

  Future<void> _begin(
    String sessionId, {
    required bool trackMode,
    int? trackSpecM,
  }) async {
    final useTaskIsolate = Platform.isAndroid;
    await FlutterForegroundTask.saveData(
      key: kFgDbPathKey,
      value: dbPath,
    );
    await FlutterForegroundTask.saveData(
      key: kFgSessionIdKey,
      value: sessionId,
    );
    await FlutterForegroundTask.saveData(
      key: kFgRecorderKey,
      value: useTaskIsolate ? 'task' : 'main',
    );
    await FlutterForegroundTask.saveData(
      key: kFgTrackModeKey,
      value: trackMode,
    );
    await FlutterForegroundTask.saveData(
      key: kFgTrackSpecKey,
      value: trackSpecM ?? -1,
    );

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.restartService();
    } else {
      await FlutterForegroundTask.startService(
        serviceId: 210,
        serviceTypes: const [ForegroundServiceTypes.location],
        notificationTitle: 'balmi 기록 중',
        notificationText: '통신이 끊겨도 기록은 기기에 전부 저장됩니다',
        callback: recordingStartCallback,
      );
    }

    if (!useTaskIsolate) {
      await _startLocalPipeline(
        sessionId,
        trackMode: trackMode,
        trackSpecM: trackSpecM,
      );
    } else {
      final session = await repo.sessionById(sessionId);
      snapshot = RecordingSnapshot(
        sessionId: sessionId,
        pointCount: await repo.maxSeq(sessionId),
        pendingChunks: await repo.pendingChunkCountFor(sessionId),
        hAccM: null,
        gpsStrength: 'none',
        sport: Sport.walk.wire,
        totalDistM: session?.totalDistM ?? 0,
        walkDistM: session?.walkDistM ?? 0,
        runDistM: session?.runDistM ?? 0,
        startedAtMs: session?.startedAt.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch,
        lapCount: (await repo.lapsFor(sessionId)).length,
        trackMode: trackMode,
      );
      notifyListeners();
    }
  }

  Future<void> _startLocalPipeline(
    String sessionId, {
    required bool trackMode,
    int? trackSpecM,
  }) async {
    final session = await repo.sessionById(sessionId);
    final pipeline = RecordingPipeline(
      repo: repo,
      sessionId: sessionId,
      startedAt: session?.startedAt ?? DateTime.now(),
      trackMode: trackMode,
      trackSpecM: trackSpecM,
    );
    await pipeline.restore();
    _localLocation = GeolocatorLocationEngine();
    _localCadence = CadenceEngine();
    await _localLocation!.start();
    await _localCadence!.start();
    _localLocSub = _localLocation!.fixes.listen(pipeline.onFix);
    _localTimer?.cancel();
    _localTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      pipeline.onCadence(_localCadence?.spm);
      final snap = await pipeline.sampleNow(DateTime.now());
      snapshot = snap;
      notifyListeners();
      final tts = snap.lapTts;
      if (tts != null && tts.isNotEmpty) {
        await _speak(tts);
      }
    });
  }

  Future<void> stop() async {
    FlutterForegroundTask.sendDataToTask('stop');
    await _stopLocal();
    final id = snapshot?.sessionId;
    if (id != null) {
      await repo.closeSession(id, status: SessionStatus.closed);
    }
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
    snapshot = null;
    notifyListeners();
  }

  Future<void> endRecovered(String sessionId) async {
    await repo.closeSession(sessionId, status: SessionStatus.recovered);
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  Future<void> _stopLocal() async {
    _localTimer?.cancel();
    _localTimer = null;
    await _localLocSub?.cancel();
    _localLocSub = null;
    await _localLocation?.stop();
    await _localCadence?.stop();
  }
}
