import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Default latitude when GPS is unavailable (central Korea).
const kFarmDefaultLatitude = 35.5;

/// Default longitude for Korea civil-time approximation.
const kFarmDefaultLongitude = 127.0;

const _twilight = Duration(minutes: 30);

enum FarmSkyPhase { night, dawn, day, dusk }

/// Local sunrise/sunset with civil-twilight dawn/dusk windows.
class FarmSunSchedule {
  const FarmSunSchedule({
    required this.sunrise,
    required this.sunset,
    required this.dawnStart,
    required this.dawnEnd,
    required this.duskStart,
    required this.duskEnd,
  });

  final DateTime sunrise;
  final DateTime sunset;
  final DateTime dawnStart;
  final DateTime dawnEnd;
  final DateTime duskStart;
  final DateTime duskEnd;

  factory FarmSunSchedule.forLocalDate({
    required DateTime localDate,
    double latitudeDeg = kFarmDefaultLatitude,
    double longitudeDeg = kFarmDefaultLongitude,
  }) {
    final day = DateTime(localDate.year, localDate.month, localDate.day);
    final mins = sunMinutesForDate(
      date: day,
      latitudeDeg: latitudeDeg,
      longitudeDeg: longitudeDeg,
    );
    final sunrise = _minutesOnDay(day, mins.sunriseMin);
    final sunset = _minutesOnDay(day, mins.sunsetMin);
    return FarmSunSchedule(
      sunrise: sunrise,
      sunset: sunset,
      dawnStart: sunrise.subtract(_twilight),
      dawnEnd: sunrise.add(_twilight),
      duskStart: sunset.subtract(_twilight),
      duskEnd: sunset.add(_twilight),
    );
  }
}

class FarmSkyPalette {
  const FarmSkyPalette({
    required this.top,
    required this.mid,
    required this.bottom,
    required this.sunOpacity,
    required this.moonOpacity,
    required this.starOpacity,
    required this.cloudOpacity,
    required this.groundDim,
    required this.nightOverlay,
  });

  final Color top;
  final Color mid;
  final Color bottom;
  final double sunOpacity;
  final double moonOpacity;
  final double starOpacity;
  final double cloudOpacity;
  /// 1 = full daylight ground, lower = dimmed hills/fields at night.
  final double groundDim;
  final double nightOverlay;

  static FarmSkyPalette lerp(FarmSkyPalette a, FarmSkyPalette b, double t) {
    final u = t.clamp(0.0, 1.0);
    return FarmSkyPalette(
      top: Color.lerp(a.top, b.top, u)!,
      mid: Color.lerp(a.mid, b.mid, u)!,
      bottom: Color.lerp(a.bottom, b.bottom, u)!,
      sunOpacity: _lerpD(a.sunOpacity, b.sunOpacity, u),
      moonOpacity: _lerpD(a.moonOpacity, b.moonOpacity, u),
      starOpacity: _lerpD(a.starOpacity, b.starOpacity, u),
      cloudOpacity: _lerpD(a.cloudOpacity, b.cloudOpacity, u),
      groundDim: _lerpD(a.groundDim, b.groundDim, u),
      nightOverlay: _lerpD(a.nightOverlay, b.nightOverlay, u),
    );
  }
}

class FarmSkyAppearance {
  const FarmSkyAppearance({
    required this.phase,
    required this.palette,
    required this.schedule,
  });

  final FarmSkyPhase phase;
  final FarmSkyPalette palette;
  final FarmSunSchedule schedule;
}

/// Resolve sky colors and celestial visibility from device-local [now].
FarmSkyAppearance resolveFarmSky({
  required DateTime now,
  double latitudeDeg = kFarmDefaultLatitude,
  double longitudeDeg = kFarmDefaultLongitude,
}) {
  final schedule = FarmSunSchedule.forLocalDate(
    localDate: now,
    latitudeDeg: latitudeDeg,
    longitudeDeg: longitudeDeg,
  );

  const night = FarmSkyPalette(
    top: Color(0xFF0D1B3E),
    mid: Color(0xFF1B2C54),
    bottom: Color(0xFF2A3B6B),
    sunOpacity: 0,
    moonOpacity: 1,
    starOpacity: 1,
    cloudOpacity: 0,
    groundDim: 0.52,
    nightOverlay: 0.35,
  );
  const dawn = FarmSkyPalette(
    top: Color(0xFF6B5B95),
    mid: Color(0xFFFFB6A3),
    bottom: Color(0xFFFFD9B3),
    sunOpacity: 0.35,
    moonOpacity: 0.65,
    starOpacity: 0.15,
    cloudOpacity: 0.55,
    groundDim: 0.72,
    nightOverlay: 0.08,
  );
  const day = FarmSkyPalette(
    top: Color(0xFFF7EFE3),
    mid: Color(0xFFFAF6EF),
    bottom: Color(0xFFE8D5C2),
    sunOpacity: 1,
    moonOpacity: 0,
    starOpacity: 0,
    cloudOpacity: 0.85,
    groundDim: 1,
    nightOverlay: 0,
  );
  const dusk = FarmSkyPalette(
    top: Color(0xFFF5E1D3),
    mid: Color(0xFFF0B88A),
    bottom: Color(0xFFE8845C),
    sunOpacity: 0.85,
    moonOpacity: 0.2,
    starOpacity: 0.05,
    cloudOpacity: 0.7,
    groundDim: 0.82,
    nightOverlay: 0.05,
  );

  if (!_isBefore(now, schedule.dawnStart) && _isBefore(now, schedule.dawnEnd)) {
    final t = _progress(now, schedule.dawnStart, schedule.dawnEnd);
    return FarmSkyAppearance(
      phase: FarmSkyPhase.dawn,
      palette: FarmSkyPalette.lerp(night, day, t),
      schedule: schedule,
    );
  }
  if (!_isBefore(now, schedule.dawnEnd) && _isBefore(now, schedule.duskStart)) {
    return FarmSkyAppearance(
      phase: FarmSkyPhase.day,
      palette: day,
      schedule: schedule,
    );
  }
  if (!_isBefore(now, schedule.duskStart) && _isBefore(now, schedule.duskEnd)) {
    final t = _progress(now, schedule.duskStart, schedule.duskEnd);
    return FarmSkyAppearance(
      phase: FarmSkyPhase.dusk,
      palette: FarmSkyPalette.lerp(day, night, t),
      schedule: schedule,
    );
  }

  return FarmSkyAppearance(
    phase: FarmSkyPhase.night,
    palette: night,
    schedule: schedule,
  );
}

/// Approximate local sunrise/sunset minutes from midnight (civil twilight).
///
/// Seasonal curve tuned for central Korea (~35.5°N). Uses the calendar date's
/// local timezone for wall-clock comparison with [DateTime.now()].
@visibleForTesting
({double sunriseMin, double sunsetMin}) sunMinutesForDate({
  required DateTime date,
  required double latitudeDeg,
  double longitudeDeg = kFarmDefaultLongitude,
}) {
  final n = _dayOfYear(date);
  final seasonal = math.sin(2 * math.pi * (n - 81) / 365);

  // Summer ~05:15 / ~19:30, winter ~06:45 / ~18:00 at 35.5°N.
  final latAdjust = (latitudeDeg - kFarmDefaultLatitude) * 4.0;
  final sunriseMin = 6 * 60 - seasonal * 45 - latAdjust;
  final sunsetMin = 19 * 60 + seasonal * 60 + latAdjust;
  return (sunriseMin: sunriseMin, sunsetMin: sunsetMin);
}

DateTime _minutesOnDay(DateTime day, double minutes) {
  final total = minutes.round().clamp(0, 24 * 60 - 1);
  return day.add(Duration(hours: total ~/ 60, minutes: total % 60));
}

int _dayOfYear(DateTime date) {
  final start = DateTime(date.year, 1, 1);
  return date.difference(start).inDays + 1;
}

bool _isBefore(DateTime a, DateTime b) => a.isBefore(b);

double _progress(DateTime now, DateTime start, DateTime end) {
  final span = end.difference(start).inMilliseconds;
  if (span <= 0) return 1;
  return now.difference(start).inMilliseconds / span;
}

double _lerpD(double a, double b, double t) => a + (b - a) * t;
