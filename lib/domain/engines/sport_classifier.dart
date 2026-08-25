import '../config/sport_params.dart';
import '../models/sport.dart';

class SportSample {
  const SportSample({
    required this.ts,
    required this.speedKmh,
    required this.hAccM,
    this.cadenceSpm,
  });

  final DateTime ts;
  final double speedKmh;
  final double hAccM;
  final double? cadenceSpm;
}

/// Walk/run hysteresis. No Flutter imports.
class SportClassifier {
  SportClassifier({
    this.params = SportParams.defaults,
    this.current = Sport.walk,
  });

  SportParams params;
  Sport current;

  DateTime? _walkToRunSince;
  DateTime? _runToWalkSince;

  void reset({Sport sport = Sport.walk}) {
    current = sport;
    _walkToRunSince = null;
    _runToWalkSince = null;
  }

  /// Returns the new [Sport] when a transition happens, otherwise null.
  Sport? ingest(SportSample sample) {
    if (sample.hAccM > params.maxHorizontalAccuracyM) {
      return null;
    }

    if (current == Sport.walk) {
      final ready = _walkToRunReady(sample);
      if (ready) {
        _walkToRunSince ??= sample.ts;
        if (!sample.ts.difference(_walkToRunSince!).isNegative &&
            sample.ts.difference(_walkToRunSince!) >= params.hold) {
          current = Sport.run;
          _walkToRunSince = null;
          _runToWalkSince = null;
          return Sport.run;
        }
      } else {
        _walkToRunSince = null;
      }
    } else {
      final ready = sample.speedKmh <= params.runToWalkSpeedKmh;
      if (ready) {
        _runToWalkSince ??= sample.ts;
        if (!sample.ts.difference(_runToWalkSince!).isNegative &&
            sample.ts.difference(_runToWalkSince!) >= params.hold) {
          current = Sport.walk;
          _runToWalkSince = null;
          _walkToRunSince = null;
          return Sport.walk;
        }
      } else {
        _runToWalkSince = null;
      }
    }
    return null;
  }

  /// Run if speed is clearly running, or a jog with running cadence.
  /// Cadence is optional so pocket-weak step counts still switch.
  bool _walkToRunReady(SportSample sample) {
    if (sample.speedKmh >= params.walkToRunSpeedKmh) return true;
    final cadence = sample.cadenceSpm;
    return cadence != null &&
        cadence >= params.walkToRunCadenceSpm &&
        sample.speedKmh >= params.runToWalkSpeedKmh;
  }
}
