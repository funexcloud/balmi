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

  test('WALK→RUN after 8s of running speed without cadence', () {
    final c = SportClassifier();
    for (var i = 0; i < 8; i++) {
      expect(c.ingest(sample(i, cadence: null)), isNull);
    }
    expect(c.ingest(sample(8, cadence: null)), Sport.run);
    expect(c.current, Sport.run);
  });

  test('WALK→RUN does not fire at walking speed without cadence', () {
    final c = SportClassifier();
    for (var i = 0; i <= 20; i++) {
      expect(c.ingest(sample(i, speed: 5, cadence: null)), isNull);
    }
    expect(c.current, Sport.walk);
  });

  test('WALK→RUN from jog cadence at 7 km/h', () {
    final c = SportClassifier();
    for (var i = 0; i < 8; i++) {
      expect(c.ingest(sample(i, speed: 7, cadence: 140)), isNull);
    }
    expect(c.ingest(sample(8, speed: 7, cadence: 140)), Sport.run);
  });

  test('interrupt before hold resets walk→run timer', () {
    final c = SportClassifier();
    for (var i = 0; i < 4; i++) {
      expect(c.ingest(sample(i)), isNull);
    }
    expect(c.ingest(sample(4, speed: 5, cadence: 90)), isNull);
    for (var i = 5; i < 12; i++) {
      expect(c.ingest(sample(i)), isNull);
    }
    expect(c.ingest(sample(13)), Sport.run);
  });

  test('RUN→WALK after hold of slow speed', () {
    final c = SportClassifier()..current = Sport.run;
    for (var i = 0; i < 8; i++) {
      expect(c.ingest(sample(i, speed: 5, cadence: 110)), isNull);
    }
    expect(c.ingest(sample(8, speed: 5, cadence: 110)), Sport.walk);
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
    expect(params.walkToRunCadenceSpm, 130);

    final c = SportClassifier(params: params);
    for (var i = 0; i < 5; i++) {
      expect(c.ingest(sample(i, speed: 8.5)), isNull);
    }
    expect(c.ingest(sample(5, speed: 8.5)), Sport.run);
  });
}
