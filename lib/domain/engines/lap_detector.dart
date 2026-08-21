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

/// School/park track laps from GPS. First 200m defines virtual finish.
class LapDetector {
  LapDetector({
    this.startRadiusM = 18,
    this.headingToleranceDeg = 60,
    this.minGap = const Duration(seconds: 60),
    this.calibrationDistM = 200,
    this.maxHorizontalAccuracyM = 30,
  });

  final double startRadiusM;
  final double headingToleranceDeg;
  final Duration minGap;
  final double calibrationDistM;
  final double maxHorizontalAccuracyM;

  double? startLat;
  double? startLon;
  double? firstPassHeading;
  bool calibrating = true;
  int lapNo = 0;
  DateTime? lastLapAt;
  DateTime? _sessionStart;

  final DistanceAccumulator _calib = DistanceAccumulator();
  double? _lastLat;
  double? _lastLon;
  bool _insideRadius = true;
  bool _exitedOnce = false;

  void reset() {
    startLat = null;
    startLon = null;
    firstPassHeading = null;
    calibrating = true;
    lapNo = 0;
    lastLapAt = null;
    _sessionStart = null;
    _calib.reset();
    _lastLat = null;
    _lastLon = null;
    _insideRadius = true;
    _exitedOnce = false;
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

  LapEvent? ingest(TrackSample sample) {
    _sessionStart ??= sample.ts;
    final accurate = isAccurateEnough(sample.hAccM, maxHorizontalAccuracyM);

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

    final distToStart = haversineMeters(
      lat1: startLat!,
      lon1: startLon!,
      lat2: sample.lat,
      lon2: sample.lon,
    );
    final nowInside = distToStart <= startRadiusM;
    final heading = sample.headingDeg ??
        (_lastLat != null
            ? bearingDegrees(
                lat1: _lastLat!,
                lon1: _lastLon!,
                lat2: sample.lat,
                lon2: sample.lon,
              )
            : firstPassHeading ?? 0);
    final headingOk = firstPassHeading == null ||
        headingDeltaDeg(heading, firstPassHeading!) <= headingToleranceDeg;
    final last = lastLapAt ?? _sessionStart!;
    final timeOk = !sample.ts.difference(last).isNegative &&
        sample.ts.difference(last) >= minGap;

    LapEvent? event;
    if (!_insideRadius && nowInside && headingOk && timeOk) {
      lapNo += 1;
      final lapTimeS = sample.ts.difference(last).inMilliseconds / 1000.0;
      lastLapAt = sample.ts;
      event = LapEvent(
        lapNo: lapNo,
        crossedAt: sample.ts,
        lapTimeS: lapTimeS,
        lapDistM: distToStart,
      );
    }

    _insideRadius = nowInside;
    _lastLat = sample.lat;
    _lastLon = sample.lon;
    return event;
  }
}
