import 'dart:math' as math;

import 'package:balmi/domain/engines/distance.dart';
import 'package:balmi/domain/engines/lap_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('circle track: calibration then a lap with heading and 60s gap', () {
    const startLat = 37.5;
    const startLon = 127.0;
    const trackM = 400.0;
    final radiusM = trackM / (2 * math.pi);
    final detector = LapDetector();
    final t0 = DateTime.utc(2026, 8, 20, 10);
    LapEvent? lastLap;

    // 2° steps, 1s each → 180s per lap.
    for (var i = 0; i <= 360; i++) {
      final theta = math.pi / 2 + i * (math.pi / 180); // north, CCW
      final east = radiusM * math.cos(theta);
      final north = radiusM * math.sin(theta);
      final pos = _offset(startLat, startLon, north - radiusM, east);
      double? heading;
      if (i > 0) {
        final prevTheta = math.pi / 2 + (i - 1) * (math.pi / 180);
        final prev = _offset(
          startLat,
          startLon,
          radiusM * math.sin(prevTheta) - radiusM,
          radiusM * math.cos(prevTheta),
        );
        heading = bearingDegrees(
          lat1: prev.$1,
          lon1: prev.$2,
          lat2: pos.$1,
          lon2: pos.$2,
        );
      }
      final event = detector.ingest(
        TrackSample(
          ts: t0.add(Duration(seconds: i)),
          lat: pos.$1,
          lon: pos.$2,
          hAccM: 6,
          headingDeg: heading,
        ),
      );
      if (event != null) lastLap = event;
    }

    expect(detector.calibrating, isFalse);
    expect(lastLap, isNotNull);
    expect(lastLap!.lapNo, 1);
    expect(lastLap.lapTimeS, greaterThanOrEqualTo(60));
  });

  test('spec distance is laps × spec', () {
    expect(
      LapDetector.correctedDistanceM(trackSpecM: 400, laps: 3, gpsDistM: 1180),
      1200,
    );
    expect(
      LapDetector.correctedDistanceM(trackSpecM: null, laps: 3, gpsDistM: 1180),
      1180,
    );
  });

  test('guessSpec maps 600m stadium loops', () {
    expect(LapDetector.guessSpecM(620), 600);
    expect(LapDetector.guessSpecM(400), 400);
    expect(LapDetector.guessSpecM(1200), isNull);
  });

  test('600m walk loop auto-counts a lap without locked track mode', () {
    const startLat = 35.5324;
    const startLon = 129.2593;
    const trackM = 600.0;
    final radiusM = trackM / (2 * math.pi);
    final detector = LapDetector();
    final t0 = DateTime.utc(2026, 8, 25, 12);
    LapEvent? lastLap;
    const speedMs = 1.4;
    final seconds = (trackM / speedMs).round() + 8;

    for (var i = 0; i <= seconds; i++) {
      final dist = speedMs * i;
      final ang = (dist / trackM) * 2 * math.pi;
      final north = radiusM * math.cos(ang) - radiusM;
      final east = radiusM * math.sin(ang);
      final pos = _offset(startLat, startLon, north, east);
      final event = detector.ingest(
        TrackSample(
          ts: t0.add(Duration(seconds: i)),
          lat: pos.$1,
          lon: pos.$2,
          hAccM: 6,
        ),
        countAnyLoop: false,
      );
      if (event != null) lastLap = event;
    }

    expect(detector.calibrating, isFalse);
    expect(lastLap, isNotNull);
    expect(lastLap!.lapNo, 1);
    expect(lastLap.lapDistM, greaterThan(500));
    expect(lastLap.lapDistM, lessThan(750));
    expect(detector.isTrackLikeLoop(lastLap.lapDistM), isTrue);
  });

  test('street approach then stadium loops still auto-count laps', () {
    // Session starts ~350m north of the track (street → gym), then circles.
    const streetLat = 35.5355;
    const streetLon = 129.2593;
    const trackLat = 35.5324;
    const trackLon = 129.2593;
    const trackM = 600.0;
    const speedMs = 1.5;
    final radiusM = trackM / (2 * math.pi);
    final detector = LapDetector();
    final t0 = DateTime.utc(2026, 8, 26, 11);
    var t = 0;
    LapEvent? lastLap;

    // Walk south from street toward track entry (north point of circle).
    const approachM = 350.0;
    final approachSec = (approachM / speedMs).round();
    for (var i = 0; i <= approachSec; i++) {
      final frac = i / approachSec;
      final lat = streetLat + (trackLat - streetLat) * frac;
      final lon = streetLon + (trackLon - streetLon) * frac;
      final event = detector.ingest(
        TrackSample(
          ts: t0.add(Duration(seconds: t++)),
          lat: lat,
          lon: lon,
          hAccM: 6,
        ),
      );
      if (event != null) lastLap = event;
    }

    // Three full stadium loops starting at the north point.
    final loopSec = (trackM / speedMs).round();
    for (var lap = 0; lap < 3; lap++) {
      for (var i = 1; i <= loopSec; i++) {
        final dist = speedMs * i;
        final ang = (dist / trackM) * 2 * math.pi;
        final north = radiusM * math.cos(ang) - radiusM;
        final east = radiusM * math.sin(ang);
        final pos = _offset(trackLat, trackLon, north, east);
        final event = detector.ingest(
          TrackSample(
            ts: t0.add(Duration(seconds: t++)),
            lat: pos.$1,
            lon: pos.$2,
            hAccM: 6,
          ),
        );
        if (event != null) lastLap = event;
      }
    }

    expect(detector.calibrating, isFalse);
    expect(lastLap, isNotNull);
    expect(lastLap!.lapNo, greaterThanOrEqualTo(2));
    expect(detector.lapNo, greaterThanOrEqualTo(2));
  });

  test('out-and-back trail does not invent auto laps', () {
    const startLat = 37.5;
    const startLon = 127.0;
    const speedMs = 1.5;
    final detector = LapDetector();
    final t0 = DateTime.utc(2026, 8, 26, 9);
    var t = 0;
    // 600m out, 600m back along the same line (opposite heading on return).
    for (var i = 0; i <= 400; i++) {
      final signed = i <= 200 ? i * speedMs : (400 - i) * speedMs;
      final pos = _offset(startLat, startLon, signed, 0);
      detector.ingest(
        TrackSample(
          ts: t0.add(Duration(seconds: t++)),
          lat: pos.$1,
          lon: pos.$2,
          hAccM: 6,
        ),
      );
    }
    expect(detector.lapNo, 0);
  });

  test('400m distance-threshold loops count successive laps', () {
    const startLat = 37.5665;
    const startLon = 126.978;
    const trackM = 400.0;
    const speedMs = 2.0;
    final radiusM = trackM / (2 * math.pi);
    final detector = LapDetector();
    final t0 = DateTime.utc(2026, 8, 26, 14);
    final seconds = ((trackM * 4) / speedMs).round() + 20;

    for (var i = 0; i <= seconds; i++) {
      final dist = speedMs * i;
      final ang = (dist / trackM) * 2 * math.pi;
      final north = radiusM * math.cos(ang) - radiusM;
      final east = radiusM * math.sin(ang);
      final pos = _offset(startLat, startLon, north, east);
      detector.ingest(
        TrackSample(
          ts: t0.add(Duration(seconds: i)),
          lat: pos.$1,
          lon: pos.$2,
          hAccM: 5,
        ),
      );
    }

    expect(detector.lapNo, greaterThanOrEqualTo(3));
  });
}

(double, double) _offset(double lat, double lon, double northM, double eastM) {
  const mPerDeg = 111320.0;
  final dLat = northM / mPerDeg;
  final dLon = eastM / (mPerDeg * math.cos(lat * math.pi / 180));
  return (lat + dLat, lon + dLon);
}
