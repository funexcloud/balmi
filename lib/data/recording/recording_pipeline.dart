import 'package:latlong2/latlong.dart';

import '../../core/format.dart';
import '../../domain/config/sport_params.dart';
import '../../domain/engines/distance.dart';
import '../../domain/engines/lap_detector.dart';
import '../../domain/engines/motion_filter.dart';
import '../../domain/engines/sport_classifier.dart';
import '../../domain/engines/step_distance.dart';
import '../../domain/models/activity.dart';
import '../../domain/models/sport.dart';
import '../location/location_engine.dart';
import '../map/session_trace_line.dart';
import '../repositories/session_repository.dart';
import 'recording_snapshot.dart';

class RecordingPipeline {
  RecordingPipeline({
    required this.repo,
    required this.sessionId,
    required this.startedAt,
    required this.trackMode,
    this.trackSpecM,
    this.activity = ActivityKind.auto,
    SportParams params = SportParams.defaults,
    this.chunkSize = 60,
    GpsMotionFilter? filter,
    StepDistanceIntegrator? stepDistance,
  })  : classifier = SportClassifier(params: params),
        distance = DistanceAccumulator(
          maxHorizontalAccuracyM: params.maxHorizontalAccuracyM,
        ),
        laps = LapDetector(
          maxHorizontalAccuracyM: params.maxHorizontalAccuracyM,
        ),
        filter = filter ?? GpsMotionFilter(),
        steps = stepDistance ?? StepDistanceIntegrator();

  final SessionRepository repo;
  final String sessionId;
  final DateTime startedAt;
  bool trackMode;
  int? trackSpecM;
  ActivityKind activity;
  final int chunkSize;

  final SportClassifier classifier;
  final DistanceAccumulator distance;
  final LapDetector laps;
  final GpsMotionFilter filter;
  final StepDistanceIntegrator steps;

  LocationFix? lastFix;
  LocationFix? _consumedFix;
  double? lastCadence;
  int seq = 0;
  int _chunkFrom = 1;
  String? lastLapTts;
  double? lastLapTimeS;
  double? _displaySpeedMs;
  int recordingSteps = 0;
  int movingMs = 0;
  DateTime? _lastSampleAt;

  double walkDistM = 0;
  double runDistM = 0;

  /// Live map line: only metres the filter accepted (no indoor jitter scribble).
  final trail = <LatLng>[];
  LatLng? mapPin;

  Future<void> restore() async {
    seq = await repo.maxSeq(sessionId);
    _chunkFrom = await repo.maxQueuedSeqTo(sessionId) + 1;
    final session = await repo.sessionById(sessionId);
    if (session != null) {
      walkDistM = session.walkDistM;
      runDistM = session.runDistM;
      distance.meters = session.totalDistM;
      activity = ActivityKind.fromWire(session.activity);
      trackMode = session.trackMode || activity.isTrack;
      trackSpecM = session.trackSpecM ?? trackSpecM;
      recordingSteps = session.steps;
    }
    final storedPts = await repo.pointsForSession(sessionId);
    trail
      ..clear()
      ..addAll(traceLineFromPoints(storedPts));
    if (trail.isNotEmpty) mapPin = trail.last;
    final last = await repo.lastAccuratePoint(sessionId, 30);
    if (last != null) {
      distance.restoreLast(
        lat: last.lat,
        lon: last.lng,
        meters: distance.meters,
      );
      filter.restore(lat: last.lat, lon: last.lng, ts: last.ts);
      steps.restore(lastGpsAt: DateTime.now(), steps: recordingSteps);
    }
    final open = await repo.openSegment(sessionId);
    if (activity.isAuto) {
      classifier.reset(sport: Sport.fromWire(open?.sport ?? Sport.walk.wire));
    } else {
      classifier.reset(sport: activity.lockedSport);
    }
    if (trackMode) {
      final stored = await repo.lapsFor(sessionId);
      if (stored.isNotEmpty) {
        lastLapTimeS = stored.last.lapTimeS;
        final firstAccurate = storedPts.where((p) {
          final acc = p.hAccM;
          return acc != null && acc <= 30;
        });
        if (firstAccurate.isNotEmpty) {
          final p0 = firstAccurate.first;
          laps.restore(
            startLat: p0.lat,
            startLon: p0.lng,
            firstPassHeading: 0,
            lapNo: stored.length,
            lastLapAt: stored.last.crossedAt,
            calibrating: false,
          );
        }
      }
    }
  }

  void onFix(LocationFix fix) {
    lastFix = fix;
  }

  void onCadence(double? spm) {
    lastCadence = spm;
  }

  Future<void> setActivity(ActivityKind next, DateTime now) async {
    if (activity == next) return;
    activity = next;
    if (next.isTrack) {
      if (laps.calibrating || laps.startLat == null) {
        laps.reset();
      }
      trackMode = true;
      trackSpecM ??= 400;
      await repo.updateTrackSpec(sessionId, trackSpecM);
    } else {
      trackMode = false;
    }
    await repo.updateActivity(sessionId, next);
    if (!next.isAuto) {
      classifier.reset(sport: next.lockedSport);
      await repo.splitSegment(
        sessionId: sessionId,
        newSport: next.lockedSport,
        at: now,
      );
    }
  }

  Future<void> setTrackSpec(int? spec) async {
    trackSpecM = spec;
    await repo.updateTrackSpec(sessionId, spec);
  }

  Future<RecordingSnapshot> sampleNow(DateTime now) async {
    lastLapTts = null;
    final fix = lastFix;
    var usedGps = false;
    if (fix != null && !_alreadyConsumed(fix)) {
      _consumedFix = fix;
      usedGps = true;
      seq += 1;
      final decision = filter.evaluate(
        now: now,
        lat: fix.lat,
        lon: fix.lng,
        hAccM: fix.hAccM,
        rawSpeedMs: fix.speedMs,
        speedAccuracyMs: fix.speedAccuracyMs,
        cadenceSpm: lastCadence,
      );
      if (decision.filteredSpeedMs != null) {
        _displaySpeedMs = decision.filteredSpeedMs;
      }

      mapPin = LatLng(fix.lat, fix.lng);
      if (decision.plotOnMap) {
        _appendTrail(mapPin!);
      }

      await repo.insertPoint(
        sessionId: sessionId,
        seq: seq,
        ts: fix.ts,
        lat: fix.lat,
        lng: fix.lng,
        alt: fix.alt,
        speedMs: fix.speedMs,
        hAccM: fix.hAccM,
        cadenceSpm: lastCadence,
        satCount: fix.satCount,
      );

      if (seq - _chunkFrom + 1 >= chunkSize) {
        await repo.enqueueChunk(
          sessionId: sessionId,
          seqFrom: _chunkFrom,
          seqTo: seq,
          now: now,
        );
        _chunkFrom = seq + 1;
      }

      steps.markGps(now, totalSteps: recordingSteps);
      final gpsM = decision.addDistance ? decision.distanceM : 0.0;
      final credited = steps.takeGpsMeters(gpsM);
      if (credited > 0) {
        await _addDistance(credited, now);
      }

      if (activity.isAuto) {
        await _maybeSwitchSport(
          now: now,
          speedKmh: (_displaySpeedMs ?? 0) * 3.6,
          hAccM: fix.hAccM ?? 999,
        );
      }

      if (decision.moving ||
          (decision.filteredSpeedMs != null && decision.filteredSpeedMs! >= 0.4)) {
        movingMs += _elapsedTickMs(now);
      }

      final lap = laps.ingest(
        TrackSample(
          ts: now,
          lat: fix.lat,
          lon: fix.lng,
          hAccM: fix.hAccM ?? 999,
          headingDeg: fix.headingDeg,
          speedMs: _displaySpeedMs,
        ),
        countAnyLoop: activity.isTrack,
      );
      if (lap != null) {
        if (!trackMode) {
          trackMode = true;
          trackSpecM ??= LapDetector.guessSpecM(lap.lapDistM);
          await repo.updateTrackMode(
            sessionId,
            trackMode: true,
            trackSpecM: trackSpecM,
          );
        }
        final specDist = LapDetector.correctedDistanceM(
          trackSpecM: trackSpecM,
          laps: lap.lapNo,
          gpsDistM: distance.meters,
        );
        final lapDist = trackSpecM != null && trackSpecM! > 0
            ? trackSpecM!.toDouble()
            : lap.lapDistM;
        await repo.insertLap(
          sessionId: sessionId,
          lapNo: lap.lapNo,
          crossedAt: lap.crossedAt,
          lapTimeS: lap.lapTimeS,
          lapDistM: lapDist,
        );
        lastLapTts = formatLapTts(lapNo: lap.lapNo, lapTimeS: lap.lapTimeS);
        lastLapTimeS = lap.lapTimeS;
        if (activity.isTrack && trackSpecM != null && trackSpecM! > 0) {
          distance.meters = specDist;
        }
      }

      await repo.updateDistances(
        sessionId: sessionId,
        totalDistM: distance.meters,
        walkDistM: walkDistM,
        runDistM: runDistM,
      );
    }

    if (!usedGps) {
      final running = activity.isAuto
          ? classifier.current == Sport.run
          : activity.lockedSport == Sport.run;
      final stepM = steps.sampleWhileGpsStale(
        now: now,
        totalSteps: recordingSteps,
        cadenceSpm: lastCadence,
        running: running,
      );
      if (stepM > 0) {
        await _addDistance(stepM, now);
        final dt = _elapsedTickMs(now) / 1000.0;
        _displaySpeedMs = dt > 0.2 ? stepM / dt : stepM;
        movingMs += _elapsedTickMs(now);
        if (activity.isAuto) {
          await _maybeSwitchSport(
            now: now,
            speedKmh: (_displaySpeedMs ?? 0) * 3.6,
            hAccM: lastFix?.hAccM ?? 15,
          );
        }
        await repo.updateDistances(
          sessionId: sessionId,
          totalDistM: distance.meters,
          walkDistM: walkDistM,
          runDistM: runDistM,
        );
      }
    }

    _lastSampleAt = now;
    return snapshot(now);
  }

  int _elapsedTickMs(DateTime now) {
    final prev = _lastSampleAt;
    if (prev == null) return 0;
    final ms = now.difference(prev).inMilliseconds;
    if (ms <= 0) return 0;
    return ms > 2000 ? 2000 : ms;
  }

  Future<void> _maybeSwitchSport({
    required DateTime now,
    required double speedKmh,
    required double hAccM,
  }) async {
    final changed = classifier.ingest(
      SportSample(
        ts: now,
        speedKmh: speedKmh,
        hAccM: hAccM,
        cadenceSpm: lastCadence,
      ),
    );
    if (changed == null) return;
    await repo.splitSegment(
      sessionId: sessionId,
      newSport: changed,
      at: now,
    );
  }

  Future<void> _addDistance(double meters, DateTime now) async {
    if (meters <= 0) return;
    distance.meters += meters;
    final intoRun = activity.isAuto
        ? classifier.current == Sport.run
        : activity.lockedSport == Sport.run;
    if (intoRun) {
      runDistM += meters;
    } else {
      walkDistM += meters;
    }
    await repo.addToOpenSegment(sessionId, meters);
  }

  bool _alreadyConsumed(LocationFix fix) {
    final prev = _consumedFix;
    if (prev == null) return false;
    return prev.ts == fix.ts &&
        prev.lat == fix.lat &&
        prev.lng == fix.lng;
  }

  void _appendTrail(LatLng point) {
    if (trail.isNotEmpty &&
        trail.last.latitude == point.latitude &&
        trail.last.longitude == point.longitude) {
      return;
    }
    trail.add(point);
  }

  Future<RecordingSnapshot> snapshot(DateTime now) async {
    final pending = await repo.pendingChunkCountFor(sessionId);
    final synced = await repo.syncedPointCount(sessionId);
    final durs = await repo.sportDurations(sessionId);
    final sportWire = activity.isAuto
        ? classifier.current.wire
        : activity.lockedSport.wire;
    return RecordingSnapshot(
      sessionId: sessionId,
      pointCount: seq,
      pendingChunks: pending,
      hAccM: lastFix?.hAccM,
      gpsStrength: RecordingSnapshot.strengthFor(lastFix?.hAccM),
      sport: sportWire,
      activity: activity.wire,
      totalDistM: distance.meters,
      walkDistM: walkDistM,
      runDistM: runDistM,
      startedAtMs: startedAt.millisecondsSinceEpoch,
      lapCount: laps.lapNo,
      trackMode: trackMode,
      trackSpecM: trackSpecM,
      lapTts: lastLapTts,
      lastLapTimeS: lastLapTimeS,
      speedKmh: _displaySpeedMs == null ? null : _displaySpeedMs! * 3.6,
      walkDurationMs: (durs[Sport.walk] ?? Duration.zero).inMilliseconds,
      runDurationMs: (durs[Sport.run] ?? Duration.zero).inMilliseconds,
      syncedPoints: synced,
      movingDurationMs: movingMs,
    );
  }
}
