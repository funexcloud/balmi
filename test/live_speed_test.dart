import 'package:balmi/core/format.dart';
import 'package:balmi/domain/engines/live_speed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('averageSpeedKmh', () {
    test('uses moving time, not elapsed with pauses', () {
      // 5.67 km in 50 min moving / 60 min elapsed → ~6.8 km/h moving avg
      final avg = averageSpeedKmh(
        distM: 5670,
        movingDurationMs: 50 * 60 * 1000,
        elapsedMs: 60 * 60 * 1000,
      );
      expect(avg, closeTo(6.804, 0.02));
    });

    test('falls back to elapsed before any moving sample', () {
      final avg = averageSpeedKmh(
        distM: 100,
        movingDurationMs: 0,
        elapsedMs: 60 * 1000,
      );
      expect(avg, closeTo(6.0, 0.01));
    });

    test('stadium hour walk matches distance / moving hour', () {
      final avg = averageSpeedKmh(
        distM: 5670,
        movingDurationMs: 60 * 60 * 1000,
        elapsedMs: 60 * 60 * 1000,
      );
      expect(avg, closeTo(5.67, 0.01));
    });

    test('zero distance is zero', () {
      expect(
        averageSpeedKmh(distM: 0, movingDurationMs: 60000, elapsedMs: 60000),
        0,
      );
    });
  });

  group('paceMinPerKm / formatPace', () {
    test('pace derives from the same speed used for display', () {
      expect(paceMinPerKm(10), closeTo(6.0, 1e-9));
      expect(formatPace(10), '6\'00"');
      expect(paceMinPerKm(5.67), closeTo(60 / 5.67, 1e-9));
      expect(formatPace(5.67), "10'35\"");
    });

    test('slow / still has no pace', () {
      expect(paceMinPerKm(0.4), isNull);
      expect(formatPace(0.4), '--\'--"');
      expect(paceMinPerKm(0), isNull);
    });
  });

  group('smoothSpeedMs + clampSpeedRiseMs', () {
    test('snaps to zero when candidate is still', () {
      expect(
        smoothSpeedMs(candidateMs: 0, previousMs: 1.5),
        0,
      );
    });

    test('EMA pulls toward candidate without jumping fully', () {
      final next = smoothSpeedMs(
        candidateMs: 2.0,
        previousMs: 1.0,
        alpha: 0.35,
      );
      expect(next, closeTo(1.35, 0.001));
    });

    test('rise clamp blocks a one-second GPS spike', () {
      final spiked = clampSpeedRiseMs(
        nextMs: 6.0, // 21.6 km/h
        previousMs: 1.5, // 5.4 km/h walk
        dtS: 1.0,
        maxRiseMsPerS: 2.5,
      );
      expect(spiked, closeTo(4.0, 0.001));
      expect(spiked * 3.6, lessThan(15));
    });
  });

  group('displaySpeedFromDisplacement', () {
    test('prefers window displacement over reliable Doppler', () {
      final v = displaySpeedFromDisplacement(
        derivedMs: 1.4,
        windowMs: 1.55,
        dopplerMs: 1.1, // phone Doppler under-report
        dopplerReliable: true,
      );
      expect(v, closeTo(1.55, 1e-9));
    });

    test('uses Doppler only when displacement is not ready', () {
      final v = displaySpeedFromDisplacement(
        derivedMs: 0,
        windowMs: 0,
        dopplerMs: 1.4,
        dopplerReliable: true,
      );
      expect(v, closeTo(1.4, 1e-9));
    });

    test('ignores unreliable Doppler', () {
      final v = displaySpeedFromDisplacement(
        derivedMs: 0,
        windowMs: 0,
        dopplerMs: 1.4,
        dopplerReliable: false,
      );
      expect(v, 0);
    });
  });
}
