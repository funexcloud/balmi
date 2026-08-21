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
}

(double, double) _offset(double lat, double lon, double northM, double eastM) {
  const mPerDeg = 111320.0;
  final dLat = northM / mPerDeg;
  final dLon = eastM / (mPerDeg * math.cos(lat * math.pi / 180));
  return (lat + dLat, lon + dLon);
}
