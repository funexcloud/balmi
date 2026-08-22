import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../core/copy.dart';
import '../../data/location/geolocator_location_engine.dart';
import '../../data/location/location_engine.dart';
import '../../data/location/recording_permissions.dart';
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
  bool _starting = false;
  bool _ticking = false;

  RecordingSnapshot? snapshot;
  bool paused = false;
  Duration _pausedTotal = Duration.zero;
  DateTime? _pauseStarted;

  bool get isRecording => snapshot != null;
  bool get isStarting => _starting;
  String? lastError;

  Duration get elapsed {
    if (snapshot == null) return Duration.zero;
    var d = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(snapshot!.startedAtMs),
    );
    d -= _pausedTotal;
    if (paused && _pauseStarted != null) {
      d -= DateTime.now().difference(_pauseStarted!);
    }
    if (d.isNegative) return Duration.zero;
    return d;
  }

  /// Honest GPS line while a session is open (waiting / error / null).
  String? get gpsHint {
    if (!isRecording) return lastError;
    if ((snapshot?.pointCount ?? 0) > 0) return lastError;
    return lastError ?? BalmiCopy.waitingGps;
  }

  void attachTaskListener() {
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    _localTimer?.cancel();
    unawaited(_stopLocal());
    super.dispose();
  }

  void _onTaskData(Object data) {
    // UI isolate is the recorder. Ignore task snapshots so a dead isolate
    // cannot freeze the header at 0 points.
    if (_localTimer != null) {
      if (data is Map && data['error'] != null) {
        lastError = '${data['error']}';
        notifyListeners();
      }
      return;
    }
    if (data is Map) {
      if (data['error'] != null) {
        lastError = '${data['error']}';
        notifyListeners();
        return;
      }
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

  Future<void> nudgeGps() async {
    await _localLocation?.nudge();
  }

  /// Returns false when recording cannot start (permissions / GPS off).
  Future<bool> start({required bool trackMode, int? trackSpecM}) async {
    if (_starting) return false;
    _starting = true;
    lastError = null;
    notifyListeners();
    try {
      final denied = await RecordingPermissions.ensure();
      if (denied != null) {
        lastError = denied;
        notifyListeners();
        return false;
      }
      final open = await repo.findRecording();
      if (open != null) {
        _resetPauseClock();
        await _begin(
          open.id,
          trackMode: open.trackMode,
          trackSpecM: open.trackSpecM,
        );
        return true;
      }
      final session = await repo.createSession(
        trackMode: trackMode,
        trackSpecM: trackSpecM,
      );
      _resetPauseClock();
      await _begin(session.id, trackMode: trackMode, trackSpecM: trackSpecM);
      return true;
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
      return false;
    } finally {
      _starting = false;
      notifyListeners();
    }
  }

  Future<bool> resume(String sessionId) async {
    lastError = null;
    final denied = await RecordingPermissions.ensure();
    if (denied != null) {
      lastError = denied;
      notifyListeners();
      return false;
    }
    final session = await repo.sessionById(sessionId);
    if (session == null) return false;
    _resetPauseClock();
    await _begin(
      sessionId,
      trackMode: session.trackMode,
      trackSpecM: session.trackSpecM,
    );
    return true;
  }

  Future<void> _begin(
    String sessionId, {
    required bool trackMode,
    int? trackSpecM,
  }) async {
    // Geolocator in the FGS Dart isolate often never emits (helper service
    // bind race, no Activity). Keep the FGS as a process keep-alive and
    // record GPS + SQLite on the UI isolate so Start actually stores points.
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
      value: 'main',
    );
    await FlutterForegroundTask.saveData(
      key: kFgTrackModeKey,
      value: trackMode,
    );
    await FlutterForegroundTask.saveData(
      key: kFgTrackSpecKey,
      value: trackSpecM ?? -1,
    );

    if (Platform.isAndroid) {
      final ServiceRequestResult fgs;
      if (await FlutterForegroundTask.isRunningService) {
        fgs = await FlutterForegroundTask.restartService();
      } else {
        fgs = await FlutterForegroundTask.startService(
          serviceId: 210,
          serviceTypes: const [ForegroundServiceTypes.location],
          notificationTitle: 'balmi 기록 중',
          notificationText: '통신이 끊겨도 기록은 기기에 전부 저장됩니다',
          callback: recordingStartCallback,
        );
      }
      if (fgs is ServiceRequestFailure) {
        lastError = '${BalmiCopy.keepAliveFailed} (${fgs.error})';
      }
    }

    await _startLocalPipeline(
      sessionId,
      trackMode: trackMode,
      trackSpecM: trackSpecM,
    );
  }

  Future<void> _startLocalPipeline(
    String sessionId, {
    required bool trackMode,
    int? trackSpecM,
  }) async {
    await _stopLocal();
    final session = await repo.sessionById(sessionId);
    final pipeline = RecordingPipeline(
      repo: repo,
      sessionId: sessionId,
      startedAt: session?.startedAt ?? DateTime.now(),
      trackMode: trackMode,
      trackSpecM: trackSpecM,
    );
    await pipeline.restore();
    snapshot = await pipeline.snapshot(DateTime.now());
    notifyListeners();
    _localLocation = GeolocatorLocationEngine();
    _localCadence = CadenceEngine();
    await _localLocation!.start();
    await _localCadence!.start();
    _localLocSub = _localLocation!.fixes.listen(pipeline.onFix);
    _localTimer?.cancel();
    unawaited(_tick(pipeline));
    _localTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_tick(pipeline));
    });
  }

  void pause() {
    if (!isRecording || paused) return;
    paused = true;
    _pauseStarted = DateTime.now();
    notifyListeners();
  }

  void resumeLive() {
    if (!paused) return;
    if (_pauseStarted != null) {
      _pausedTotal += DateTime.now().difference(_pauseStarted!);
    }
    _pauseStarted = null;
    paused = false;
    notifyListeners();
  }

  void _resetPauseClock() {
    paused = false;
    _pausedTotal = Duration.zero;
    _pauseStarted = null;
  }

  Future<void> _tick(RecordingPipeline pipeline) async {
    if (_ticking) return;
    _ticking = true;
    try {
      if (paused) {
        unawaited(
          FlutterForegroundTask.updateService(
            notificationTitle: 'balmi 일시정지',
            notificationText: '기록이 멈춰 있습니다. 포인트는 기기에 남아 있습니다.',
          ),
        );
        return;
      }
      pipeline.onCadence(_localCadence?.spm);
      final engineError = _localLocation?.lastError;
      if (engineError != null) {
        lastError = engineError;
      } else if (_localLocation?.hasFix == true &&
          lastError != null &&
          !lastError!.startsWith(BalmiCopy.keepAliveFailed)) {
        lastError = null;
      }
      final snap = await pipeline.sampleNow(DateTime.now());
      snapshot = snap;
      notifyListeners();
      unawaited(
        FlutterForegroundTask.updateService(
          notificationTitle: 'balmi 기록 중',
          notificationText: snap.pointCount == 0
              ? BalmiCopy.waitingGpsShort
              : '${snap.pointCount}점 · ${(snap.totalDistM / 1000).toStringAsFixed(2)}km',
        ),
      );
      final tts = snap.lapTts;
      if (tts != null && tts.isNotEmpty) {
        await _speak(tts);
      }
    } finally {
      _ticking = false;
    }
  }

  Future<String?> stop() async {
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
    lastError = null;
    _resetPauseClock();
    notifyListeners();
    return id;
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
    _localLocation = null;
    _localCadence = null;
  }
}
