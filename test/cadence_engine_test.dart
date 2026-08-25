import 'package:balmi/data/sensors/cadence_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('two stray accelerometer peaks are unknown cadence, not standing', () {
    expect(
      trustedCadenceSpm(
        stepCount: 2,
        window: const Duration(seconds: 10),
      ),
      isNull,
    );
    expect(
      trustedCadenceSpm(
        stepCount: 6,
        window: const Duration(seconds: 10),
      ),
      isNull,
    );
  });

  test('a real walk window reports cadence', () {
    expect(
      trustedCadenceSpm(
        stepCount: 18,
        window: const Duration(seconds: 10),
      ),
      closeTo(108, 0.1),
    );
  });
}
