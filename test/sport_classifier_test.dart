import 'package:balmi/domain/config/sport_params.dart';
import 'package:balmi/domain/engines/sport_classifier.dart';
import 'package:balmi/domain/models/sport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime.utc(2026, 8, 20, 9);

  SportSample sample(int seconds, {double speed = 10, double acc = 5, double? cadence = 150}) {
    return SportSample(
      ts: t0.add(Duration(seconds: seconds)),
      speedKmh: speed,
      hAccM: acc,
      cadenceSpm: cadence,
    );
  }

  test('WALK→RUN requires 15s of speed and cadence', () {
    final c = SportClassifier();
    for (var i = 0; i < 15; i++) {
      expect(c.ingest(sample(i)), isNull);
    }
    expect(c.ingest(sample(15)), Sport.run);
    expect(c.current, Sport.run);
  });

  test('WALK→RUN does not fire without cadence', () {
    final c = SportClassifier();
    for (var i = 0; i <= 20; i++) {
      expect(c.ingest(sample(i, cadence: null)), isNull);
    }
    expect(c.current, Sport.walk);
  });

  test('interrupt before 15s resets walk→run timer', () {
    final c = SportClassifier();
    for (var i = 0; i < 10; i++) {
      expect(c.ingest(sample(i)), isNull);
    }
    expect(c.ingest(sample(10, speed: 5, cadence: 90)), isNull);
    for (var i = 11; i < 25; i++) {
      expect(c.ingest(sample(i)), isNull);
    }
    expect(c.ingest(sample(26)), Sport.run);
  });

  test('RUN→WALK after 15s of slow speed', () {
    final c = SportClassifier()..current = Sport.run;
    for (var i = 0; i < 15; i++) {
      expect(c.ingest(sample(i, speed: 6, cadence: 110)), isNull);
    }
    expect(c.ingest(sample(15, speed: 6, cadence: 110)), Sport.walk);
  });

  test('h_acc > 30 holds current sport', () {
    final c = SportClassifier()..current = Sport.run;
    for (var i = 0; i <= 20; i++) {
      expect(c.ingest(sample(i, speed: 4, acc: 40, cadence: 80)), isNull);
    }
    expect(c.current, Sport.run);
  });

  test('remote-config map overrides defaults', () {
    final params = SportParams.fromRemoteConfig({
      'walk_to_run_speed_kmh': 8,
      'hold_seconds': 5,
    });
    expect(params.walkToRunSpeedKmh, 8);
    expect(params.holdSeconds, 5);
    expect(params.walkToRunCadenceSpm, 140);

    final c = SportClassifier(params: params);
    for (var i = 0; i < 5; i++) {
      expect(c.ingest(sample(i, speed: 8.5)), isNull);
    }
    expect(c.ingest(sample(5, speed: 8.5)), Sport.run);
  });
}
