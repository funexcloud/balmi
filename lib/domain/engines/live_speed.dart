/// Live recording speed / pace math.
///
/// Product rules:
/// - Current speed comes from recent GPS displacement (smoothed); 0 when still.
/// - Average = distance / moving time (elapsed only as a cold-start fallback).
/// - Pace is always derived from the same km/h value shown as speed.

/// Minimum speed treated as moving for pace display (matches [formatPace]).
const double kPaceMinSpeedKmh = 0.5;

/// Average speed in km/h.
///
/// Prefers [movingDurationMs] once at least 1s of moving time exists so pauses
/// and standstill do not dilute the average. Falls back to [elapsedMs] at the
/// very start of a session when moving time is still zero.
double averageSpeedKmh({
  required double distM,
  required int movingDurationMs,
  int elapsedMs = 0,
}) {
  if (distM <= 0) return 0;
  final movingSec = movingDurationMs / 1000.0;
  final elapsedSec = elapsedMs / 1000.0;
  final sec = movingSec >= 1 ? movingSec : elapsedSec;
  if (sec < 1) return 0;
  return (distM / 1000.0) / (sec / 3600.0);
}

/// Minutes per km from speed, or `null` when too slow / unknown.
double? paceMinPerKm(double speedKmh) {
  if (speedKmh <= kPaceMinSpeedKmh) return null;
  return 60.0 / speedKmh;
}

/// EMA blend for display speed in m/s.
///
/// Snaps to 0 immediately when [candidateMs] is still so the UI does not
/// linger on a ghost pace after stopping.
double smoothSpeedMs({
  required double candidateMs,
  required double? previousMs,
  double alpha = 0.35,
}) {
  if (candidateMs <= 0) return 0;
  final prev = previousMs;
  if (prev == null || prev <= 0) return candidateMs;
  final a = alpha.clamp(0.05, 1.0);
  return a * candidateMs + (1.0 - a) * prev;
}

/// Limits how fast displayed speed may rise (m/s per second of wall time).
///
/// GPS jitter chords can invent a 15–25 km/h spike for one second; capping the
/// rise keeps the live number honest without hiding real acceleration.
double clampSpeedRiseMs({
  required double nextMs,
  required double? previousMs,
  required double dtS,
  double maxRiseMsPerS = 2.5,
}) {
  if (nextMs <= 0) return 0;
  final prev = previousMs;
  if (prev == null || prev <= 0 || dtS <= 0) return nextMs;
  final maxNext = prev + maxRiseMsPerS * dtS;
  return nextMs > maxNext ? maxNext : nextMs;
}

/// Prefer displacement-based speed for the live number.
///
/// Phone Doppler often under-reports walking pace; use it only when the
/// displacement window is not ready yet (cold start / short dt).
double displaySpeedFromDisplacement({
  required double derivedMs,
  required double windowMs,
  required double? dopplerMs,
  required bool dopplerReliable,
  double walkFloorMs = 0.7,
}) {
  if (windowMs > 0) return windowMs;
  if (derivedMs > 0) return derivedMs;
  if (dopplerReliable &&
      dopplerMs != null &&
      dopplerMs >= walkFloorMs) {
    return dopplerMs;
  }
  return 0;
}
