import '../../core/format.dart';
import '../../domain/config/sport_params.dart';
import '../../domain/engines/distance.dart';
import '../../domain/engines/lap_detector.dart';
import '../../domain/engines/sport_classifier.dart';
import '../../domain/models/sport.dart';
import '../location/location_engine.dart';
import '../repositories/session_repository.dart';
import 'recording_snapshot.dart';

class RecordingPipeline {
  RecordingPipeline({
    required this.repo,
    required this.sessionId,
    required this.startedAt,
    required this.trackMode,
    this.trackSpecM,
    SportParams params = SportParams.defaults,
    this.chunkSize = 60,
  })  : classifier = SportClassifier(params: params),
        distance = DistanceAccumulator(
          maxHorizontalAccuracyM: params.maxHorizontalAccuracyM,
        ),
        laps = LapDetector(
          maxHorizontalAccuracyM: params.maxHorizontalAccuracyM,
        );

  final SessionRepository repo;
  final String sessionId;
  final DateTime startedAt;
  final bool trackMode;
  final int? trackSpecM;
  final int chunkSize;

  final SportClassifier classifier;
  final DistanceAccumulator distance;
  final LapDetector laps;

  LocationFix? lastFix;
  LocationFix? _prevSampled;
  double? lastCadence;
  int seq = 0;
  int _chunkFrom = 1;
  String? lastLapTts;
  double? lastLapTimeS;

  double walkDistM = 0;
  double runDistM = 0;

  Future<void> restore() async {
    seq = await repo.maxSeq(sessionId);
    _chunkFrom = await repo.maxQueuedSeqTo(sessionId) + 1;
    final session = await repo.sessionById(sessionId);
    if (session != null) {
      walkDistM = session.walkDistM;
      runDistM = session.runDistM;
      distance.meters = session.totalDistM;
    }
    final last = await repo.lastAccuratePoint(sessionId, 30);
    if (last != null) {
      distance.restoreLast(
        lat: last.lat,
        lon: last.lng,
        meters: distance.meters,
      );
    }
    final open = await repo.openSegment(sessionId);
    classifier.reset(sport: Sport.fromWire(open?.sport ?? Sport.walk.wire));
    if (trackMode) {
      final stored = await repo.lapsFor(sessionId);
      if (stored.isNotEmpty) {
        lastLapTimeS = stored.last.lapTimeS;
        final points = await repo.pointsForSession(sessionId);
        final firstAccurate = points.where((p) {
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

  Future<RecordingSnapshot> sampleNow(DateTime now) async {
    lastLapTts = null;
    final fix = lastFix;
    if (fix != null) {
      seq += 1;
      final speedMs = _speedMs(fix, now);
      await repo.insertPoint(
        sessionId: sessionId,
        seq: seq,
        ts: now,
        lat: fix.lat,
        lng: fix.lng,
        alt: fix.alt,
        speedMs: speedMs,
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

      final delta = distance.add(
        lat: fix.lat,
        lon: fix.lng,
        hAccM: fix.hAccM,
      );
      if (delta > 0) {
        if (classifier.current == Sport.run) {
          runDistM += delta;
        } else {
          walkDistM += delta;
        }
        await repo.addToOpenSegment(sessionId, delta);
      }

      final changed = classifier.ingest(
        SportSample(
          ts: now,
          speedKmh: (speedMs ?? 0) * 3.6,
          hAccM: fix.hAccM ?? 999,
          cadenceSpm: lastCadence,
        ),
      );
      if (changed != null) {
        await repo.splitSegment(
          sessionId: sessionId,
          newSport: changed,
          at: now,
        );
      }

      if (trackMode) {
        final lap = laps.ingest(
          TrackSample(
            ts: now,
            lat: fix.lat,
            lon: fix.lng,
            hAccM: fix.hAccM ?? 999,
            headingDeg: fix.headingDeg,
            speedMs: speedMs,
          ),
        );
        if (lap != null) {
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
          if (trackSpecM != null && trackSpecM! > 0) {
            distance.meters = specDist;
          }
        }
      }

      await repo.updateDistances(
        sessionId: sessionId,
        totalDistM: distance.meters,
        walkDistM: walkDistM,
        runDistM: runDistM,
      );
      _prevSampled = LocationFix(
        ts: now,
        lat: fix.lat,
        lng: fix.lng,
        speedMs: speedMs,
        hAccM: fix.hAccM,
        headingDeg: fix.headingDeg,
      );
    }

    return snapshot(now);
  }

  /// Prefer GPS Doppler [LocationFix.speedMs]; otherwise coordinate derivative.
  double? _speedMs(LocationFix fix, DateTime now) {
    if (fix.speedMs != null && fix.speedMs! >= 0) {
      return fix.speedMs;
    }
    final prev = _prevSampled;
    if (prev == null) return null;
    final dt = now.difference(prev.ts).inMilliseconds / 1000.0;
    if (dt <= 0.2) return prev.speedMs;
    final d = haversineMeters(
      lat1: prev.lat,
      lon1: prev.lng,
      lat2: fix.lat,
      lon2: fix.lng,
    );
    return d / dt;
  }

  Future<RecordingSnapshot> snapshot(DateTime now) async {
    final pending = await repo.pendingChunkCountFor(sessionId);
    final synced = await repo.syncedPointCount(sessionId);
    final durs = await repo.sportDurations(sessionId);
    return RecordingSnapshot(
      sessionId: sessionId,
      pointCount: seq,
      pendingChunks: pending,
      hAccM: lastFix?.hAccM,
      gpsStrength: RecordingSnapshot.strengthFor(lastFix?.hAccM),
      sport: classifier.current.wire,
      totalDistM: distance.meters,
      walkDistM: walkDistM,
      runDistM: runDistM,
      startedAtMs: startedAt.millisecondsSinceEpoch,
      lapCount: laps.lapNo,
      trackMode: trackMode,
      trackSpecM: trackSpecM,
      lapTts: lastLapTts,
      lastLapTimeS: lastLapTimeS,
      speedKmh: lastFix?.speedMs == null ? null : lastFix!.speedMs! * 3.6,
      walkDurationMs: (durs[Sport.walk] ?? Duration.zero).inMilliseconds,
      runDurationMs: (durs[Sport.run] ?? Duration.zero).inMilliseconds,
      syncedPoints: synced,
    );
  }
}
