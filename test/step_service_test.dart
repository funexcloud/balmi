import 'package:balmi/data/sensors/step_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hardwareStepsToday subtracts daily baseline', () {
    expect(hardwareStepsToday(raw: 210_762, baseline: 210_000), 762);
    expect(hardwareStepsToday(raw: 100, baseline: 200), 0);
  });

  test('mergeTodaySteps prefers the larger daily count', () {
    expect(
      mergeTodaySteps(hardwareToday: 900, recordedToday: 1200),
      1200,
    );
    expect(
      mergeTodaySteps(hardwareToday: 1500, recordedToday: 1200),
      1500,
    );
    expect(mergeTodaySteps(hardwareToday: null, recordedToday: 42), 42);
  });

  test('stepLocalDayKey uses local calendar date', () {
    expect(
      stepLocalDayKey(DateTime(2026, 8, 26, 23, 59)),
      '2026-08-26',
    );
  });
}
