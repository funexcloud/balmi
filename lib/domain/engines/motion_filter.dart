import 'dart:math' as math;

import 'distance.dart';

class MotionDecision {
  const MotionDecision({
    required this.addDistance,
    required this.filteredSpeedMs,
    required this.useForSport,
    this.distanceM = 0,
    this.plotOnMap = false,
    this.moving = false,
  });

  final bool addDistance;
  final double distanceM;

  /// Draw this unique GPS sample on the live / saved path.
  final bool plotOnMap;

  /// Display / classifier speed in m/s. `null` = show last good or "—".
  final double? filteredSpeedMs;
  final bool useForSport;
  final bool moving;
}

class _SpeedSample {
  const _SpeedSample({
    required this.ts,
    required this.lat,
    required this.lon,
  });

  final DateTime ts;
  final double lat;
  final double lon;
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
    this.speedWindow = const Duration(seconds: 4),
    this.stillNetM = 2.5,
    this.walkFloorMs = 0.7,
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
  final Duration speedWindow;
  final double stillNetM;
  final double walkFloorMs;

  bool moving = false;
  double? _lat;
  double? _lon;
  DateTime? _ts;
  double? lastGoodSpeedMs;
  int _stillStreak = 0;
  int _spikeStreak = 0;
  final _recent = <_SpeedSample>[];

  void restore({required double lat, required double lon, DateTime? ts}) {
    _lat = lat;
    _lon = lon;
    _ts = ts;
    moving = false;
    lastGoodSpeedMs = 0;
    _stillStreak = 0;
    _recent
      ..clear()
      ..add(_SpeedSample(ts: ts ?? DateTime.now(), lat: lat, lon: lon));
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
        moving: moving,
      );
    }

    if (_lat == null || _lon == null || _ts == null) {
      _lat = lat;
      _lon = lon;
      _ts = now;
      lastGoodSpeedMs = 0;
      _remember(now, lat, lon);
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
    _remember(now, lat, lon);

    final dopplerOk = rawSpeedMs != null &&
        rawSpeedMs >= walkFloorMs &&
        speedAccuracyMs != null &&
        speedAccuracyMs > 0 &&
        speedAccuracyMs < goodSpeedAccMs;
    final windowSp = _windowSpeedMs();
    var candidate = dopplerOk
        ? rawSpeedMs
        : (windowSp > 0 ? windowSp : derived);
    final resumedAfterGap =
        dt >= gapResume.inMilliseconds / 1000.0 && d >= plotAccuracyM;

    final h = hAccM;
    final jitterR = math.max(h, minMoveM);
    final insideCircle = d < jitterR || d < 0.7 * h;
    final stepping = cadenceSpm != null && cadenceSpm >= lowCadenceSpm;
    final gpsWalk = (derived >= walkFloorMs && derived <= 4.0) ||
        (dopplerOk && rawSpeedMs >= walkFloorMs && rawSpeedMs <= 4.0);
    final windowStill = _isWindowStill();

    MotionDecision still() {
      moving = false;
      lastGoodSpeedMs = 0;
      _stillStreak = 0;
      _ts = now;
      return const MotionDecision(
        addDistance: false,
        plotOnMap: false,
        filteredSpeedMs: 0,
        useForSport: true,
      );
    }

    // Weak/false cadence must not hide a real walk. Indoor GPS jumps
    // (derived well above walking) still freeze when steps are absent.
    if (cadenceSpm != null &&
        cadenceSpm < standingCadenceSpm &&
        !gpsWalk &&
        !dopplerOk) {
      return still();
    }

    if (d < 0.5 && !stepping) {
      return still();
    }

    if (windowStill && !stepping && !dopplerOk) {
      return still();
    }

    if (insideCircle &&
        derived < walkFloorMs &&
        !stepping &&
        !dopplerOk) {
      return still();
    }

    if (resumedAfterGap) {
      _spikeStreak = 0;
      _stillStreak = 0;
      moving = gpsWalk || stepping || derived >= walkFloorMs;
      _accept(lat, lon, now);
      if (dopplerOk) lastGoodSpeedMs = rawSpeedMs;
      final plausible = derived >= walkFloorMs && derived <= spikeMs;
      if (plausible) lastGoodSpeedMs = derived;
      return MotionDecision(
        addDistance: plausible,
        plotOnMap: true,
        distanceM: plausible ? d : 0,
        filteredSpeedMs: lastGoodSpeedMs ?? 0,
        useForSport: plausible,
        moving: moving,
      );
    }

    if (!accOk) {
      if (d >= minMoveM) _accept(lat, lon, now);
      return MotionDecision(
        addDistance: false,
        plotOnMap: d >= minMoveM,
        filteredSpeedMs: lastGoodSpeedMs,
        useForSport: false,
        moving: moving,
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
        moving: moving,
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
        moving: moving,
      );
    }
    _spikeStreak = 0;

    if (!moving) {
      final walkOutOfStandstill = gpsWalk && d >= minMoveM;
      final windowWalk = _windowNetM() >= minMoveM &&
          _windowSpeedMs() >= walkFloorMs;
      if (insideCircle && !walkOutOfStandstill && !windowWalk && !stepping) {
        return still();
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
        moving: true,
      );
    }

    if (candidate < walkFloorMs && d < minMoveM && !dopplerOk) {
      if (stepping) {
        _stillStreak = 0;
        return MotionDecision(
          addDistance: false,
          plotOnMap: false,
          filteredSpeedMs: lastGoodSpeedMs ?? candidate,
          useForSport: true,
          moving: true,
        );
      }
      _stillStreak++;
      if (_stillStreak >= 2) {
        return still();
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
      moving: true,
    );
  }

  void _remember(DateTime ts, double lat, double lon) {
    _recent.add(_SpeedSample(ts: ts, lat: lat, lon: lon));
    final cut = ts.subtract(speedWindow);
    _recent.removeWhere((e) => e.ts.isBefore(cut));
  }

  double _windowNetM() {
    if (_recent.length < 2) return 0;
    final a = _recent.first;
    final b = _recent.last;
    return haversineMeters(lat1: a.lat, lon1: a.lon, lat2: b.lat, lon2: b.lon);
  }

  double _windowDtS() {
    if (_recent.length < 2) return 0;
    return _recent.last.ts.difference(_recent.first.ts).inMilliseconds /
        1000.0;
  }

  double _windowSpeedMs() {
    final dt = _windowDtS();
    if (dt < 1.5) return 0;
    return _windowNetM() / dt;
  }

  bool _isWindowStill() {
    final dt = _windowDtS();
    if (dt < 2.5) return false;
    return _windowNetM() < stillNetM;
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
