import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:latlong2/latlong.dart';

import '../../core/copy.dart';
import '../../core/format.dart';
import '../../data/location/geolocator_location_engine.dart';
import '../../data/location/location_engine.dart';
import '../../data/location/recording_permissions.dart';
import '../../data/recording/recording_pipeline.dart';
import '../../data/recording/recording_snapshot.dart';
import '../../data/recording/recording_task.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/sensors/cadence_engine.dart';
import '../../domain/models/activity.dart';
import '../../domain/models/sport.dart';

/// Sentinel so callers can pass an explicit `null` track spec (자유).
const Object kTrackSpecUnset = Object();

class RecordingController extends ChangeNotifier {
  RecordingController({
    required this.repo,
    required this.dbPath,
    Future<String?> Function()? ensurePermissions,
  }) : _ensurePermissions = ensurePermissions ?? RecordingPermissions.ensure;

  final SessionRepository repo;
  final String dbPath;

  /// Injectable for tests; defaults to [RecordingPermissions.ensure].
  final Future<String?> Function() _ensurePermissions;

  final FlutterTts _tts = FlutterTts();
  Timer? _localTimer;
  LocationEngine? _localLocation;
  CadenceEngine? _localCadence;
  StreamSubscription<LocationFix>? _localLocSub;
  bool _starting = false;
  bool _ticking = false;

  RecordingPipeline? _pipeline;
  RecordingSnapshot? snapshot;
  String? mealWalkSessionId;
  ActivityKind activity = ActivityKind.auto;
  int? trackSpecM;
  bool paused = false;
  Duration _pausedTotal = Duration.zero;
  DateTime? _pauseStarted;

  /// Home play long-press selection. Survives HomeScreen dispose (tab switch).
  ActivityKind preferredActivity = ActivityKind.auto;
  int? preferredTrackSpecM = 400;

  /// Updates the home play preference.
  ///
  /// Pass [trackSpecM] explicitly (including `null` for 자유) when the user
  /// picks a track length. Omitting it keeps the previous preferred meters
  /// (defaulting to 400 the first time track is chosen).
  void setPreferredActivity(
    ActivityKind next, {
    Object? trackSpecM = kTrackSpecUnset,
  }) {
    preferredActivity = next;
    if (next.isTrack) {
      if (!identical(trackSpecM, kTrackSpecUnset)) {
        preferredTrackSpecM = trackSpecM as int?;
      } else {
        preferredTrackSpecM ??= 400;
      }
    }
    notifyListeners();
  }

  /// Persist [activity] (and optional track meters) then start recording.
  ///
  /// Used by the home play long-press flow so meter selection cannot be
  /// dropped between preference write and [start].
  Future<bool> startPreferred(
    ActivityKind activity, {
    Object? trackSpecM = kTrackSpecUnset,
  }) {
    setPreferredActivity(activity, trackSpecM: trackSpecM);
    return start(activity: activity, trackSpecM: trackSpecM);
  }

  bool get isRecording => snapshot != null;
  bool get isStarting => _starting;
  String? lastError;
  List<LatLng> get liveTrail => List<LatLng>.unmodifiable(_pipeline?.trail ?? const []);
  LatLng? get livePin => _pipeline?.mapPin;
  double? get liveAlt => _pipeline?.lastFix?.alt;

  Duration get pauseHold {
    if (!paused || _pauseStarted == null) return Duration.zero;
    return DateTime.now().difference(_pauseStarted!);
  }

  static const notificationIcon = NotificationIcon(
    metaDataName: 'im.balmi.app.notification_icon',
  );

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
  ///
  /// When [activity] is omitted, uses [preferredActivity] from the home
  /// long-press sport picker so play starts in the selected mode.
  ///
  /// Pass [trackSpecM] explicitly (including `null` for 자유). Omitting it
  /// uses [preferredTrackSpecM] when [activity] is track.
  Future<bool> start({
    Object? trackSpecM = kTrackSpecUnset,
    ActivityKind? activity,
  }) async {
    if (_starting) return false;
    _starting = true;
    lastError = null;
    notifyListeners();
    try {
      final denied = await _ensurePermissions();
      if (denied != null) {
        lastError = denied;
        notifyListeners();
        return false;
      }
      final open = await repo.findRecording();
      if (open != null) {
        _resetPauseClock();
        this.activity = ActivityKind.fromWire(open.activity);
        this.trackSpecM = open.trackSpecM;
        await _begin(
          open.id,
          trackMode: open.trackMode || this.activity.isTrack,
          trackSpecM: open.trackSpecM,
          activity: this.activity,
        );
        return true;
      }
      final chosen = activity ?? preferredActivity;
      final int? spec;
      if (!chosen.isTrack) {
        spec = null;
      } else if (!identical(trackSpecM, kTrackSpecUnset)) {
        spec = trackSpecM as int?;
      } else {
        spec = preferredTrackSpecM;
      }
      this.activity = chosen;
      this.trackSpecM = spec;
      preferredActivity = chosen;
      if (chosen.isTrack) preferredTrackSpecM = spec;
      final trackMode = chosen.isTrack;
      final session = await repo.createSession(
        trackMode: trackMode,
        trackSpecM: this.trackSpecM,
        activity: chosen,
      );
      _resetPauseClock();
      await _begin(
        session.id,
        trackMode: trackMode,
        trackSpecM: this.trackSpecM,
        activity: chosen,
      );
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
    final denied = await _ensurePermissions();
    if (denied != null) {
      lastError = denied;
      notifyListeners();
      return false;
    }
    final session = await repo.sessionById(sessionId);
    if (session == null) return false;
    _resetPauseClock();
    activity = ActivityKind.fromWire(session.activity);
    trackSpecM = session.trackSpecM;
    await _begin(
      sessionId,
      trackMode: session.trackMode || activity.isTrack,
      trackSpecM: session.trackSpecM,
      activity: activity,
    );
    return true;
  }

  Future<void> _begin(
    String sessionId, {
    required bool trackMode,
    int? trackSpecM,
    ActivityKind activity = ActivityKind.auto,
  }) async {
    // The proven UI-isolate pipeline stays primary. The foreground task uses
    // these values to take over after the main-isolate heartbeat expires.
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
    await FlutterForegroundTask.saveData(key: kFgPausedKey, value: false);
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
          notificationText: BalmiCopy.trustAlways,
          notificationIcon: notificationIcon,
          callback: recordingStartCallback,
        );
      }
      if (fgs is ServiceRequestFailure) {
        lastError = '${BalmiCopy.keepAliveFailed} (${fgs.error})';
      }
      _sendMainHeartbeat();
    }

    await _startLocalPipeline(
      sessionId,
      trackMode: trackMode,
      trackSpecM: trackSpecM,
      activity: activity,
    );
  }

  Future<void> setActivity(ActivityKind next) async {
    activity = next;
    if (next.isTrack) {
      trackSpecM ??= 400;
    }
    final pipe = _pipeline;
    if (pipe != null) {
      await pipe.setActivity(next, DateTime.now());
      activity = pipe.activity;
      trackSpecM = pipe.trackSpecM;
      snapshot = await pipe.snapshot(DateTime.now());
    }
    notifyListeners();
  }

  Future<void> setTrackSpec(int? spec) async {
    trackSpecM = spec;
    final pipe = _pipeline;
    if (pipe != null) {
      await pipe.setTrackSpec(spec);
      snapshot = await pipe.snapshot(DateTime.now());
    }
    notifyListeners();
  }

  Future<void> _startLocalPipeline(
    String sessionId, {
    required bool trackMode,
    int? trackSpecM,
    ActivityKind activity = ActivityKind.auto,
  }) async {
    await _stopLocal();
    final session = await repo.sessionById(sessionId);
    final pipeline = RecordingPipeline(
      repo: repo,
      sessionId: sessionId,
      startedAt: session?.startedAt ?? DateTime.now(),
      trackMode: trackMode,
      trackSpecM: trackSpecM,
      activity: activity,
    );
    await pipeline.restore();
    _pipeline = pipeline;
    this.activity = pipeline.activity;
    this.trackSpecM = pipeline.trackSpecM;
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
    unawaited(FlutterForegroundTask.saveData(key: kFgPausedKey, value: true));
    _sendMainHeartbeat();
    notifyListeners();
  }

  void resumeLive() {
    if (!paused) return;
    if (_pauseStarted != null) {
      _pausedTotal += DateTime.now().difference(_pauseStarted!);
    }
    _pauseStarted = null;
    paused = false;
    unawaited(FlutterForegroundTask.saveData(key: kFgPausedKey, value: false));
    _sendMainHeartbeat();
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
      _sendMainHeartbeat();
      if (paused) {
        unawaited(
          FlutterForegroundTask.updateService(
            notificationTitle: 'balmi 일시정지',
            notificationText: '기록이 멈춰 있습니다. 포인트는 기기에 남아 있습니다.',
            notificationIcon: notificationIcon,
          ),
        );
        return;
      }
      pipeline.onCadence(_localCadence?.spm);
      pipeline.recordingSteps = _localCadence?.totalSteps ?? pipeline.recordingSteps;
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
              : formatRecordingNotification(
                  elapsed: elapsed,
                  distM: snap.totalDistM,
                ),
          notificationIcon: notificationIcon,
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
    FlutterForegroundTask.sendDataToTask(kFgStopCommand);
    await FlutterForegroundTask.saveData(key: kFgPausedKey, value: false);
    await _stopLocal();
    final id = snapshot?.sessionId;
    final steps = _pipeline?.recordingSteps ?? _localCadence?.totalSteps ?? 0;
    _pipeline = null;
    if (id != null) {
      await repo.updateSteps(id, steps);
      await repo.closeSession(id, status: SessionStatus.closed);
    }
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
    snapshot = null;
    lastError = null;
    mealWalkSessionId = null;
    _resetPauseClock();
    notifyListeners();
    return id;
  }

  Future<void> endRecovered(String sessionId) async {
    FlutterForegroundTask.sendDataToTask(kFgStopCommand);
    await FlutterForegroundTask.saveData(key: kFgPausedKey, value: false);
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
    if (!isRecording) _pipeline = null;
  }

  void _sendMainHeartbeat() {
    FlutterForegroundTask.sendDataToTask({
      'type': kFgHeartbeatCommand,
      'atMs': DateTime.now().millisecondsSinceEpoch,
      'paused': paused,
    });
  }
}
