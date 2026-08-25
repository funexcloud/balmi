import 'farm_resource.dart';
import 'land_city.dart';

/// Minimal qualifying distance — same threshold as v1 land/water ledger.
const kFarmSessionQualifyingDistM = 50.0;

class SessionPaceSample {
  const SessionPaceSample({
    required this.distM,
    required this.duration,
  });

  final double distM;
  final Duration duration;
}

/// Pace as seconds per km (higher = slower).
double sessionPaceSecPerKm(double distM, Duration duration) {
  if (distM < 1 || duration.inSeconds <= 0) return 0;
  return duration.inSeconds / (distM / 1000);
}

/// Spec §2.1 — this session pace ÷ recent 30-day average pace.
double avgPaceRatioForSession({
  required double sessionDistM,
  required Duration sessionDuration,
  required Iterable<SessionPaceSample> prior30Days,
}) {
  final sessionPace = sessionPaceSecPerKm(sessionDistM, sessionDuration);
  if (sessionPace <= 0) return 1.0;

  var totalDist = 0.0;
  var totalSec = 0;
  for (final s in prior30Days) {
    if (s.distM < 1 || s.duration.inSeconds <= 0) continue;
    totalDist += s.distM;
    totalSec += s.duration.inSeconds;
  }
  if (totalDist < 100) return 1.0;

  final avgPace = totalSec / (totalDist / 1000);
  if (avgPace <= 0) return 1.0;
  return sessionPace / avgPace;
}

/// Consecutive local days with at least one qualifying closed session.
int activityStreakDays({
  required DateTime sessionDay,
  required Set<String> activeLocalDayKeys,
}) {
  var streak = 0;
  var day = sessionDay.toLocal();
  day = DateTime(day.year, day.month, day.day);
  while (activeLocalDayKeys.contains(localDateKey(day))) {
    streak++;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}

SessionResourceInput buildSessionResourceInput({
  required double totalDistM,
  required Duration duration,
  required Iterable<SessionPaceSample> prior30Days,
  required Set<String> activeLocalDayKeys,
  required DateTime sessionEndedAt,
  int newTilesClaimed = 0,
  int todayFeedGranted = 0,
}) {
  return SessionResourceInput(
    distanceKm: totalDistM / 1000,
    avgPaceRatio: avgPaceRatioForSession(
      sessionDistM: totalDistM,
      sessionDuration: duration,
      prior30Days: prior30Days,
    ),
    streakDays: activityStreakDays(
      sessionDay: sessionEndedAt,
      activeLocalDayKeys: activeLocalDayKeys,
    ),
    newTilesClaimed: newTilesClaimed,
    todayFeedGranted: todayFeedGranted,
  );
}

bool sessionQualifiesForFarmGrant(double totalDistM) =>
    qualifiesForLand(totalDistM);
