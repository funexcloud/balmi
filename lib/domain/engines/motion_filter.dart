import 'dart:math' as math;

import 'distance.dart';

class MotionDecision {
  const MotionDecision({
    required this.addDistance,
    required this.filteredSpeedMs,
    required this.useForSport,
    this.distanceM = 0,
    this.plotOnMap = false,
  });

  final bool addDistance;
  final double distanceM;

  /// Draw this unique GPS sample on the live / saved path.
  final bool plotOnMap;

  /// Display / classifier speed in m/s. `null` = show last good or "—".
  final double? filteredSpeedMs;
  final bool useForSport;
}

/// Stationary + spike gate so 1Hz GPS jitter is not treated as running.
class GpsMotionFilter {
  GpsMotionFilter({
    this.maxAccuracyM = 30,
    this.plotAccuracyM = 40,
    this.minMoveM = 3,
    this.spikeMs = 8,
    this.hardCapMs = 12.5,
    this.standingCadenceSpm = 40,
    this.lowCadenceSpm = 80,
    this.goodSpeedAccMs = 2,
    this.gapResume = const Duration(seconds: 8),
  });

  final double maxAccuracyM;
  final double plotAccuracyM;
  final double minMoveM;
  final double spikeMs;
  final double hardCapMs;
  final double standingCadenceSpm;
  final double lowCadenceSpm;
  final double goodSpeedAccMs;
  final Duration gapResume;

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
    final plotOk = hAccM != null && hAccM <= plotAccuracyM;
    final accOk = hAccM != null && hAccM <= maxAccuracyM;
    if (!plotOk) {
      return MotionDecision(
        addDistance: false,
        plotOnMap: false,
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
        plotOnMap: false,
        filteredSpeedMs: 0,
        useForSport: true,
      );
    }

    final d = haversineMeters(lat1: _lat!, lon1: _lon!, lat2: lat, lon2: lon);
    final dt = now.difference(_ts!).inMilliseconds / 1000.0;
    final derived = dt <= 0.2 ? 0.0 : d / dt;
    final dopplerOk = rawSpeedMs != null &&
        rawSpeedMs >= 0.4 &&
        speedAccuracyMs != null &&
        speedAccuracyMs > 0 &&
        speedAccuracyMs < goodSpeedAccMs;
    var candidate = dopplerOk ? rawSpeedMs : derived;
    final resumedAfterGap =
        dt >= gapResume.inMilliseconds / 1000.0 && d >= plotAccuracyM;

    final h = hAccM;
    final jitterR = math.max(h, minMoveM);
    final insideCircle = d < jitterR || d < 0.7 * h;
    final stepping =
        cadenceSpm != null && cadenceSpm >= lowCadenceSpm;
    final gpsWalk = (derived >= 0.7 && derived <= 4.0) ||
        (dopplerOk && rawSpeedMs >= 0.7 && rawSpeedMs <= 4.0);

    // Weak/false cadence must not hide a real walk. Indoor GPS jumps
    // (derived well above walking) still freeze when steps are absent.
    if (cadenceSpm != null &&
        cadenceSpm < standingCadenceSpm &&
        !gpsWalk) {
      moving = false;
      lastGoodSpeedMs = 0;
      _ts = now;
      return const MotionDecision(
        addDistance: false,
        plotOnMap: false,
        filteredSpeedMs: 0,
        useForSport: true,
      );
    }

    if (d < 0.5) {
      _ts = now;
      return MotionDecision(
        addDistance: false,
        plotOnMap: false,
        filteredSpeedMs: lastGoodSpeedMs ?? 0,
        useForSport: false,
      );
    }

    if (resumedAfterGap) {
      _spikeStreak = 0;
      _stillStreak = 0;
      moving = gpsWalk || stepping;
      _accept(lat, lon, now);
      if (dopplerOk) lastGoodSpeedMs = rawSpeedMs;
      final plausible = derived >= 0.7 && derived <= spikeMs;
      if (plausible) lastGoodSpeedMs = derived;
      return MotionDecision(
        addDistance: plausible,
        plotOnMap: true,
        distanceM: plausible ? d : 0,
        filteredSpeedMs: lastGoodSpeedMs ?? 0,
        useForSport: plausible,
      );
    }

    if (!accOk) {
      if (d >= minMoveM) _accept(lat, lon, now);
      return MotionDecision(
        addDistance: false,
        plotOnMap: d >= minMoveM,
        filteredSpeedMs: lastGoodSpeedMs,
        useForSport: false,
      );
    }

    final strongDopplerCadence = dopplerOk && stepping;
    if (candidate > hardCapMs && !strongDopplerCadence) {
      _noteSpike();
      return MotionDecision(
        addDistance: false,
        plotOnMap: false,
        filteredSpeedMs: lastGoodSpeedMs ?? 0,
        useForSport: false,
      );
    }

    if (derived > spikeMs &&
        (cadenceSpm == null || cadenceSpm < lowCadenceSpm) &&
        !dopplerOk) {
      _noteSpike();
      return MotionDecision(
        addDistance: false,
        plotOnMap: false,
        filteredSpeedMs: lastGoodSpeedMs ?? 0,
        useForSport: false,
      );
    }
    _spikeStreak = 0;

    if (!moving) {
      final walkOutOfStandstill =
          gpsWalk && d >= minMoveM;
      if (insideCircle && !walkOutOfStandstill) {
        lastGoodSpeedMs = 0;
        return const MotionDecision(
          addDistance: false,
          plotOnMap: false,
          filteredSpeedMs: 0,
          useForSport: true,
        );
      }
      moving = true;
      _accept(lat, lon, now);
      lastGoodSpeedMs = candidate;
      return MotionDecision(
        addDistance: true,
        plotOnMap: true,
        distanceM: d,
        filteredSpeedMs: candidate,
        useForSport: true,
      );
    }

    if (candidate < 0.4 && d < minMoveM) {
      if (stepping) {
        _stillStreak = 0;
        return MotionDecision(
          addDistance: false,
          plotOnMap: false,
          filteredSpeedMs: lastGoodSpeedMs ?? candidate,
          useForSport: true,
        );
      }
      _stillStreak++;
      if (_stillStreak >= 3) {
        moving = false;
        lastGoodSpeedMs = 0;
        return const MotionDecision(
          addDistance: false,
          plotOnMap: false,
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
      plotOnMap: d > 0,
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
