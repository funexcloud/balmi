import 'distance.dart';

class TrackSample {
  const TrackSample({
    required this.ts,
    required this.lat,
    required this.lon,
    required this.hAccM,
    this.headingDeg,
    this.speedMs,
  });

  final DateTime ts;
  final double lat;
  final double lon;
  final double hAccM;
  final double? headingDeg;
  final double? speedMs;
}

class LapEvent {
  const LapEvent({
    required this.lapNo,
    required this.crossedAt,
    required this.lapTimeS,
    required this.lapDistM,
  });

  final int lapNo;
  final DateTime crossedAt;
  final double lapTimeS;
  final double lapDistM;
}

class _PathWaypoint {
  const _PathWaypoint({
    required this.lat,
    required this.lon,
    required this.pathM,
    required this.headingDeg,
    required this.ts,
  });

  final double lat;
  final double lon;
  final double pathM;
  final double headingDeg;
  final DateTime ts;
}

/// School/park track laps from GPS. First 200m defines virtual finish.
///
/// Auto mode also detects stadium-like loops that never return to the session
/// start (e.g. street → gym track) by revisiting earlier path waypoints after
/// ~250–850m with a matching heading.
class LapDetector {
  LapDetector({
    this.startRadiusM = 22,
    this.headingToleranceDeg = 90,
    this.minGap = const Duration(seconds: 60),
    this.calibrationDistM = 200,
    this.maxHorizontalAccuracyM = 30,
    this.autoLoopMinM = 250,
    this.autoLoopMaxM = 850,
    this.waypointSpacingM = 25,
  });

  final double startRadiusM;
  final double headingToleranceDeg;
  final Duration minGap;
  final double calibrationDistM;
  final double maxHorizontalAccuracyM;
  final double autoLoopMinM;
  final double autoLoopMaxM;
  final double waypointSpacingM;

  static const trackSpecsM = [200, 300, 400, 500, 600];

  double? startLat;
  double? startLon;
  double? firstPassHeading;
  bool calibrating = true;
  int lapNo = 0;
  DateTime? lastLapAt;
  DateTime? _sessionStart;

  final DistanceAccumulator _calib = DistanceAccumulator();
  final DistanceAccumulator _path = DistanceAccumulator();
  double _metersAtLastLap = 0;
  double? _lastLat;
  double? _lastLon;
  bool _insideRadius = true;
  bool _exitedOnce = false;
  final List<_PathWaypoint> _waypoints = [];
  double _lastWaypointPathM = -1e9;

  void reset() {
    startLat = null;
    startLon = null;
    firstPassHeading = null;
    calibrating = true;
    lapNo = 0;
    lastLapAt = null;
    _sessionStart = null;
    _calib.reset();
    _path.reset();
    _metersAtLastLap = 0;
    _lastLat = null;
    _lastLon = null;
    _insideRadius = true;
    _exitedOnce = false;
    _waypoints.clear();
    _lastWaypointPathM = -1e9;
  }

  void restore({
    required double startLat,
    required double startLon,
    required double firstPassHeading,
    required int lapNo,
    required DateTime lastLapAt,
    required bool calibrating,
  }) {
    this.startLat = startLat;
    this.startLon = startLon;
    this.firstPassHeading = firstPassHeading;
    this.lapNo = lapNo;
    this.lastLapAt = lastLapAt;
    this.calibrating = calibrating;
    _insideRadius = true;
    _exitedOnce = !calibrating;
    _waypoints.clear();
    _lastWaypointPathM = -1e9;
  }

  /// Distance = laps × spec when a spec is selected and at least one lap exists.
  static double correctedDistanceM({
    required int? trackSpecM,
    required int laps,
    required double gpsDistM,
  }) {
    if (trackSpecM != null && trackSpecM > 0 && laps > 0) {
      return laps * trackSpecM.toDouble();
    }
    return gpsDistM;
  }

  static int? guessSpecM(double loopM) {
    int? best;
    var bestErr = double.infinity;
    for (final spec in trackSpecsM) {
      final err = (loopM - spec).abs();
      if (err <= spec * 0.18 && err < bestErr) {
        best = spec;
        bestErr = err;
      }
    }
    return best;
  }

  bool isTrackLikeLoop(double loopM) =>
      loopM >= autoLoopMinM && loopM <= autoLoopMaxM;

  /// [countAnyLoop] is true when the user locked 트랙. Auto-detect only
  /// counts a finish-line return after a stadium-like loop length.
  LapEvent? ingest(TrackSample sample, {bool countAnyLoop = false}) {
    _sessionStart ??= sample.ts;
    final accurate = isAccurateEnough(sample.hAccM, maxHorizontalAccuracyM);

    if (accurate) {
      _path.add(lat: sample.lat, lon: sample.lon, hAccM: sample.hAccM);
    }

    if (calibrating) {
      if (accurate) {
        startLat ??= sample.lat;
        startLon ??= sample.lon;
        _calib.add(lat: sample.lat, lon: sample.lon, hAccM: sample.hAccM);
        if (!_exitedOnce && startLat != null) {
          final d0 = haversineMeters(
            lat1: startLat!,
            lon1: startLon!,
            lat2: sample.lat,
            lon2: sample.lon,
          );
          if (d0 > startRadiusM) {
            firstPassHeading = sample.headingDeg ??
                bearingDegrees(
                  lat1: startLat!,
                  lon1: startLon!,
                  lat2: sample.lat,
                  lon2: sample.lon,
                );
            _exitedOnce = true;
            _insideRadius = false;
          }
        }
        if (_calib.meters >= calibrationDistM &&
            startLat != null &&
            firstPassHeading != null) {
          calibrating = false;
          lastLapAt ??= sample.ts;
        }
        _recordWaypoint(sample);
      }
      _lastLat = sample.lat;
      _lastLon = sample.lon;
      return null;
    }

    if (!accurate || startLat == null || startLon == null) {
      _lastLat = sample.lat;
      _lastLon = sample.lon;
      return null;
    }

    final heading = sample.headingDeg ??
        (_lastLat != null
            ? bearingDegrees(
                lat1: _lastLat!,
                lon1: _lastLon!,
                lat2: sample.lat,
                lon2: sample.lon,
              )
            : firstPassHeading ?? 0);
    final last = lastLapAt ?? _sessionStart!;
    final timeOk = !sample.ts.difference(last).isNegative &&
        sample.ts.difference(last) >= minGap;

    LapEvent? event = _tryFinishLineCrossing(
      sample: sample,
      heading: heading,
      timeOk: timeOk,
      countAnyLoop: countAnyLoop,
      last: last,
    );

    event ??= _tryWaypointRevisit(
      sample: sample,
      heading: heading,
      timeOk: timeOk,
      countAnyLoop: countAnyLoop,
      last: last,
    );

    _recordWaypoint(sample, headingDeg: heading);
    _pruneWaypoints();

    _lastLat = sample.lat;
    _lastLon = sample.lon;
    return event;
  }

  LapEvent? _tryFinishLineCrossing({
    required TrackSample sample,
    required double heading,
    required bool timeOk,
    required bool countAnyLoop,
    required DateTime last,
  }) {
    final distToStart = haversineMeters(
      lat1: startLat!,
      lon1: startLon!,
      lat2: sample.lat,
      lon2: sample.lon,
    );
    final nowInside = distToStart <= startRadiusM;
    final headingOk = firstPassHeading == null ||
        headingDeltaDeg(heading, firstPassHeading!) <= headingToleranceDeg;

    LapEvent? event;
    if (!_insideRadius && nowInside && headingOk && timeOk) {
      final loopM = _path.meters > _metersAtLastLap
          ? _path.meters - _metersAtLastLap
          : 0.0;
      final accept = countAnyLoop || isTrackLikeLoop(loopM);
      if (accept) {
        event = _commitLap(
          sample: sample,
          last: last,
          loopM: loopM,
          finishLat: startLat!,
          finishLon: startLon!,
          finishHeading: firstPassHeading ?? heading,
        );
      }
    }

    _insideRadius = nowInside;
    return event;
  }

  /// When the session start is off-track (street → stadium), finish-line
  /// crossing never fires. Count a lap when GPS revisits an earlier waypoint
  /// after a stadium-like path length with a matching heading.
  LapEvent? _tryWaypointRevisit({
    required TrackSample sample,
    required double heading,
    required bool timeOk,
    required bool countAnyLoop,
    required DateTime last,
  }) {
    if (!timeOk || _waypoints.isEmpty) return null;

    _PathWaypoint? hit;
    var hitAlong = 0.0;
    for (final w in _waypoints) {
      final along = _path.meters - w.pathM;
      if (along < autoLoopMinM) continue;
      if (!countAnyLoop && along > autoLoopMaxM) continue;
      if (countAnyLoop && along > autoLoopMaxM * 2) continue;
      final d = haversineMeters(
        lat1: w.lat,
        lon1: w.lon,
        lat2: sample.lat,
        lon2: sample.lon,
      );
      if (d > startRadiusM) continue;
      if (headingDeltaDeg(heading, w.headingDeg) > headingToleranceDeg) {
        continue;
      }
      if (sample.ts.difference(w.ts) < minGap) continue;
      hit = w;
      hitAlong = along;
      break;
    }
    if (hit == null) return null;

    // Accept auto only for track-like loop lengths; locked track is looser.
    final accept = countAnyLoop || isTrackLikeLoop(hitAlong);
    if (!accept) return null;

    return _commitLap(
      sample: sample,
      last: last,
      loopM: hitAlong,
      finishLat: hit.lat,
      finishLon: hit.lon,
      finishHeading: hit.headingDeg,
    );
  }

  LapEvent _commitLap({
    required TrackSample sample,
    required DateTime last,
    required double loopM,
    required double finishLat,
    required double finishLon,
    required double finishHeading,
  }) {
    lapNo += 1;
    final lapTimeS = sample.ts.difference(last).inMilliseconds / 1000.0;
    lastLapAt = sample.ts;
    _metersAtLastLap = _path.meters;
    startLat = finishLat;
    startLon = finishLon;
    firstPassHeading = finishHeading;
    _insideRadius = true;
    _exitedOnce = true;
    // Drop waypoints from before this finish so the next lap must travel again.
    _waypoints.removeWhere((w) => w.pathM < _path.meters - 5);
    _lastWaypointPathM = _path.meters;
    return LapEvent(
      lapNo: lapNo,
      crossedAt: sample.ts,
      lapTimeS: lapTimeS,
      lapDistM: loopM,
    );
  }

  void _recordWaypoint(TrackSample sample, {double? headingDeg}) {
    if (_path.meters - _lastWaypointPathM < waypointSpacingM) return;
    final heading = headingDeg ??
        sample.headingDeg ??
        (_lastLat != null
            ? bearingDegrees(
                lat1: _lastLat!,
                lon1: _lastLon!,
                lat2: sample.lat,
                lon2: sample.lon,
              )
            : firstPassHeading ?? 0);
    _waypoints.add(
      _PathWaypoint(
        lat: sample.lat,
        lon: sample.lon,
        pathM: _path.meters,
        headingDeg: heading,
        ts: sample.ts,
      ),
    );
    _lastWaypointPathM = _path.meters;
  }

  void _pruneWaypoints() {
    final minPath = _path.meters - autoLoopMaxM * 2;
    if (minPath <= 0) return;
    _waypoints.removeWhere((w) => w.pathM < minPath);
  }
}
