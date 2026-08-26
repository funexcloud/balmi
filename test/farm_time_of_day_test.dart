import 'package:balmi/domain/engines/farm_time_of_day.dart';
import 'package:balmi/widgets/farm_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sunMinutesForDate', () {
    test('late August Korea sunrise before 07:00 and sunset after 19:00', () {
      final mins = sunMinutesForDate(
        date: DateTime(2026, 8, 26),
        latitudeDeg: 35.5,
        longitudeDeg: 127.0,
      );
      expect(mins.sunriseMin, greaterThan(5.5 * 60));
      expect(mins.sunriseMin, lessThan(7 * 60));
      expect(mins.sunsetMin, greaterThan(19 * 60));
      expect(mins.sunsetMin, lessThan(20.5 * 60));
    });
  });

  group('resolveFarmSky', () {
    test('20:36 local is night after sunset', () {
      final appearance = resolveFarmSky(
        now: DateTime(2026, 8, 26, 20, 36),
        latitudeDeg: 35.5,
      );
      expect(appearance.phase, FarmSkyPhase.night);
      expect(appearance.palette.sunOpacity, 0);
      expect(appearance.palette.moonOpacity, greaterThan(0.9));
      expect(appearance.palette.starOpacity, greaterThan(0.9));
    });

    test('noon local is day with sun', () {
      final appearance = resolveFarmSky(
        now: DateTime(2026, 8, 26, 12, 0),
        latitudeDeg: 35.5,
      );
      expect(appearance.phase, FarmSkyPhase.day);
      expect(appearance.palette.sunOpacity, 1);
      expect(appearance.palette.moonOpacity, 0);
    });

    test('sunrise window is dawn with blended palette', () {
      final schedule = FarmSunSchedule.forLocalDate(
        localDate: DateTime(2026, 8, 26),
        latitudeDeg: 35.5,
      );
      final midDawn = schedule.dawnStart.add(
        schedule.dawnEnd.difference(schedule.dawnStart) ~/ 2,
      );
      final appearance = resolveFarmSky(now: midDawn, latitudeDeg: 35.5);
      expect(appearance.phase, FarmSkyPhase.dawn);
      expect(appearance.palette.sunOpacity, greaterThan(0));
      expect(appearance.palette.moonOpacity, greaterThan(0));
    });

    test('sunset window is dusk', () {
      final schedule = FarmSunSchedule.forLocalDate(
        localDate: DateTime(2026, 8, 26),
        latitudeDeg: 35.5,
      );
      final midDusk = schedule.duskStart.add(
        schedule.duskEnd.difference(schedule.duskStart) ~/ 2,
      );
      final appearance = resolveFarmSky(now: midDusk, latitudeDeg: 35.5);
      expect(appearance.phase, FarmSkyPhase.dusk);
      expect(appearance.palette.sunOpacity, greaterThan(0));
      expect(appearance.palette.moonOpacity, greaterThan(0));
    });
  });

  group('FarmScene widget', () {
    testWidgets('night override paints without sun', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FarmScene(
            buildings: const [],
            herds: const [],
            nowOverride: DateTime(2026, 8, 26, 20, 36),
          ),
        ),
      );
      final paints = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
      final scene = paints
          .map((w) => w.painter)
          .whereType<FarmScenePainter>()
          .first;
      expect(scene.sky.phase, FarmSkyPhase.night);
      expect(scene.sky.palette.moonOpacity, greaterThan(0.9));
    });

    testWidgets('day override keeps sun phase', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FarmScene(
            buildings: const [],
            herds: const [],
            nowOverride: DateTime(2026, 8, 26, 12, 0),
          ),
        ),
      );
      final paints = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
      final scene = paints
          .map((w) => w.painter)
          .whereType<FarmScenePainter>()
          .first;
      expect(scene.sky.phase, FarmSkyPhase.day);
      expect(scene.sky.palette.sunOpacity, 1);
    });
  });
}
