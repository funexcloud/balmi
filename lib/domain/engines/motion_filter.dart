import 'dart:math' as math;

import 'distance.dart';

class MotionDecision {
  const MotionDecision({
    required this.addDistance,
    required this.filteredSpeedMs,
    required this.useForSport,
    this.distanceM = 0,
  });

  final bool addDistance;
  final double distanceM;

  /// Display / classifier speed in m/s. `null` = show last good or "—".
  final double? filteredSpeedMs;
  final bool useForSport;
}

/// Stationary + spike gate so 1Hz GPS jitter is not treated as running.
class GpsMotionFilter {
  GpsMotionFilter({
    this.maxAccuracyM = 30,
    this.minMoveM = 3,
    this.spikeMs = 8,
    this.hardCapMs = 12.5,
    this.standingCadenceSpm = 40,
    this.lowCadenceSpm = 80,
    this.goodSpeedAccMs = 2,
  });

  final double maxAccuracyM;
  final double minMoveM;
  final double spikeMs;
  final double hardCapMs;
  final double standingCadenceSpm;
  final double lowCadenceSpm;
  final double goodSpeedAccMs;

  bool moving = false;
  double? _lat;
  double? _lon;
  DateTime? _ts;
  double? lastGoodSpeedMs;
  int _stillStreak = 0;
  int _spikeStreak = 0;

  void restore({required double lat, required double lon, DateTime? ts}) {
    _lat = lat;
    _lon = lon;
    _ts = ts;
    moving = false;
    lastGoodSpeedMs = 0;
  }

  MotionDecision evaluate({
    required DateTime now,
    required double lat,
    required double lon,
    required double? hAccM,
    required double? rawSpeedMs,
    required double? speedAccuracyMs,
    required double? cadenceSpm,
  }) {
    final accOk = hAccM != null && hAccM <= maxAccuracyM;
    if (!accOk) {
      return MotionDecision(
        addDistance: false,
        filteredSpeedMs: lastGoodSpeedMs,
        useForSport: false,
      );
    }

    if (_lat == null || _lon == null || _ts == null) {
      _lat = lat;
      _lon = lon;
      _ts = now;
      lastGoodSpeedMs = 0;
      return const MotionDecision(
        addDistance: false,
        filteredSpeedMs: 0,
        useForSport: true,
      );
    }

    final d = haversineMeters(lat1: _lat!, lon1: _lon!, lat2: lat, lon2: lon);
    final dt = now.difference(_ts!).inMilliseconds / 1000.0;
    final derived = dt <= 0.2 ? 0.0 : d / dt;
    final dopplerOk = rawSpeedMs != null &&
        rawSpeedMs >= 0 &&
        speedAccuracyMs != null &&
        speedAccuracyMs < goodSpeedAccMs;
    var candidate = dopplerOk ? rawSpeedMs : derived;

    final h = hAccM;
    final jitterR = math.max(h, minMoveM);
    final insideCircle = d < jitterR || d < 0.7 * h;

    if (cadenceSpm != null && cadenceSpm < standingCadenceSpm) {
      moving = false;
      lastGoodSpeedMs = 0;
      return const MotionDecision(
        addDistance: false,
        filteredSpeedMs: 0,
        useForSport: true,
      );
    }

    final strongDopplerCadence =
        dopplerOk && cadenceSpm != null && cadenceSpm >= lowCadenceSpm;
    if (candidate > hardCapMs && !strongDopplerCadence) {
      _noteSpike();
      return MotionDecision(
        addDistance: false,
        filteredSpeedMs: lastGoodSpeedMs ?? 0,
        useForSport: false,
      );
    }

    if (derived > spikeMs &&
        (cadenceSpm == null || cadenceSpm < lowCadenceSpm) &&
        !dopplerOk) {
      _noteSpike();
      return const MotionDecision(
        addDistance: false,
        filteredSpeedMs: 0,
        useForSport: false,
      );
    }
    _spikeStreak = 0;

    if (!moving) {
      if (insideCircle) {
        lastGoodSpeedMs = 0;
        return const MotionDecision(
          addDistance: false,
          filteredSpeedMs: 0,
          useForSport: true,
        );
      }
      moving = true;
      _accept(lat, lon, now);
      lastGoodSpeedMs = candidate;
      return MotionDecision(
        addDistance: true,
        distanceM: d,
        filteredSpeedMs: candidate,
        useForSport: true,
      );
    }

    if (candidate < 0.4 && d < minMoveM) {
      _stillStreak++;
      if (_stillStreak >= 3) {
        moving = false;
        lastGoodSpeedMs = 0;
        return const MotionDecision(
          addDistance: false,
          filteredSpeedMs: 0,
          useForSport: true,
        );
      }
    } else {
      _stillStreak = 0;
    }

    _accept(lat, lon, now);
    lastGoodSpeedMs = candidate;
    return MotionDecision(
      addDistance: d > 0,
      distanceM: d,
      filteredSpeedMs: candidate,
      useForSport: true,
    );
  }

  void _accept(double lat, double lon, DateTime now) {
    _lat = lat;
    _lon = lon;
    _ts = now;
  }

  void _noteSpike() {
    _spikeStreak++;
    if (_spikeStreak >= 2) moving = false;
  }
}
