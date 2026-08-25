import 'dart:math' as math;

/// Fills recording distance from steps/cadence while GPS is stale.
/// Does not invent map vertices. GPS credits are reduced by metres
/// already counted in the current outage so a jump chord is not added
/// on top of the walked gap.
class StepDistanceIntegrator {
  StepDistanceIntegrator({
    this.walkStrideM = 0.72,
    this.runStrideM = 0.95,
    this.minCadenceSpm = 80,
    this.staleAfter = const Duration(seconds: 3),
    this.maxSpeedMs = 3.5,
  });

  double walkStrideM;
  double runStrideM;
  final double minCadenceSpm;
  final Duration staleAfter;
  final double maxSpeedMs;

  DateTime? lastGpsAt;
  DateTime? _lastTick;
  int _lastSteps = 0;
  bool _primed = false;

  /// Step metres counted in the current GPS outage, not yet reconciled.
  double uncountedStepM = 0;

  void restore({DateTime? lastGpsAt, int steps = 0}) {
    this.lastGpsAt = lastGpsAt;
    _lastSteps = math.max(0, steps);
    _lastTick = lastGpsAt;
    _primed = true;
    uncountedStepM = 0;
  }

  bool isGpsStale(DateTime now) {
    if (lastGpsAt == null) return false;
    return now.difference(lastGpsAt!) >= staleAfter;
  }

  void markGps(DateTime now, {int? totalSteps}) {
    lastGpsAt = now;
    _lastTick = now;
    if (totalSteps != null) {
      _lastSteps = math.max(0, totalSteps);
      _primed = true;
    }
  }

  /// Remaining GPS metres after subtracting outage step fill.
  double takeGpsMeters(double gpsM) {
    final credit = math.max(0.0, gpsM - uncountedStepM);
    uncountedStepM = 0;
    return credit;
  }

  double strideM({required bool running}) =>
      running ? runStrideM : walkStrideM;

  /// Metres to add this tick. 0 unless GPS is stale and the user is stepping.
  double sampleWhileGpsStale({
    required DateTime now,
    required int totalSteps,
    required double? cadenceSpm,
    required bool running,
  }) {
    if (!isGpsStale(now)) {
      _syncClock(now, totalSteps);
      return 0;
    }

    if (!_primed) {
      _syncClock(now, totalSteps);
      _primed = true;
      return 0;
    }

    final rawDt = _lastTick == null
        ? 1.0
        : now.difference(_lastTick!).inMilliseconds / 1000.0;
    _lastTick = now;
    if (rawDt <= 0) return 0;
    if (rawDt > 5) {
      _lastSteps = math.max(_lastSteps, totalSteps);
      return 0;
    }
    final dt = rawDt.clamp(0.0, 2.0);
    final stride = strideM(running: running);
    var metres = 0.0;
    if (totalSteps > _lastSteps) {
      metres = (totalSteps - _lastSteps) * stride;
      _lastSteps = totalSteps;
    } else if (cadenceSpm != null && cadenceSpm >= minCadenceSpm) {
      metres = (cadenceSpm / 60.0) * stride * dt;
      _lastSteps = math.max(_lastSteps, totalSteps);
    } else {
      _lastSteps = math.max(_lastSteps, totalSteps);
      return 0;
    }

    final cap = maxSpeedMs * dt;
    if (metres > cap) metres = cap;
    if (metres <= 0) return 0;
    uncountedStepM += metres;
    return metres;
  }

  void _syncClock(DateTime now, int totalSteps) {
    _lastTick = now;
    _lastSteps = math.max(_lastSteps, totalSteps);
  }
}
