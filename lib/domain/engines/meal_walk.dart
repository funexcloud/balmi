import 'land_city.dart';

/// Opt-in post-meal walk habit (not a medical device).
enum MealType {
  breakfast,
  lunch,
  dinner;

  String get wire => name;

  String get label => switch (this) {
        breakfast => '아침',
        lunch => '점심',
        dinner => '저녁',
      };

  static MealType fromWire(String value) {
    return MealType.values.firstWhere(
      (e) => e.wire == value,
      orElse: () => MealType.lunch,
    );
  }
}

enum MealWalkStatus {
  pending,
  prompted,
  walking,
  completed,
  partial,
  missed;

  String get wire => name;

  static MealWalkStatus fromWire(String value) {
    return MealWalkStatus.values.firstWhere(
      (e) => e.wire == value,
      orElse: () => MealWalkStatus.pending,
    );
  }
}

/// Minutes from local midnight. Domain stays Flutter-free.
class DayMinutes {
  const DayMinutes(this.minutes);

  final int minutes;

  int get hour => (minutes ~/ 60) % 24;
  int get minute => minutes % 60;

  static const breakfastDefault = DayMinutes(8 * 60);
  static const lunchDefault = DayMinutes(12 * 60 + 30);
  static const dinnerDefault = DayMinutes(19 * 60);

  factory DayMinutes.fromHm(int hour, int minute) {
    final h = hour.clamp(0, 23);
    final m = minute.clamp(0, 59);
    return DayMinutes(h * 60 + m);
  }

  static DayMinutes fromDate(DateTime local) {
    final t = local.toLocal();
    return DayMinutes(t.hour * 60 + t.minute);
  }

  DateTime onDay(DateTime day) {
    final d = day.toLocal();
    return DateTime(d.year, d.month, d.day, hour, minute);
  }
}

class MealSchedule {
  const MealSchedule({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.featureEnabled,
    this.disclaimerAcknowledgedAt,
  });

  final DayMinutes breakfast;
  final DayMinutes lunch;
  final DayMinutes dinner;
  final bool featureEnabled;
  final DateTime? disclaimerAcknowledgedAt;

  static const defaults = MealSchedule(
    breakfast: DayMinutes.breakfastDefault,
    lunch: DayMinutes.lunchDefault,
    dinner: DayMinutes.dinnerDefault,
    featureEnabled: false,
  );

  DayMinutes timeOf(MealType type) => switch (type) {
        MealType.breakfast => breakfast,
        MealType.lunch => lunch,
        MealType.dinner => dinner,
      };
}

class MealWalkSession {
  const MealWalkSession({
    required this.id,
    required this.mealType,
    required this.mealStartedAt,
    required this.status,
    this.walkPromptedAt,
    this.walkStartedAt,
    this.walkCompletedAt,
    this.walkDurationSec,
    this.distanceM,
    this.recordingSessionId,
  });

  final String id;
  final MealType mealType;
  final DateTime mealStartedAt;
  final DateTime? walkPromptedAt;
  final DateTime? walkStartedAt;
  final DateTime? walkCompletedAt;
  final int? walkDurationSec;
  final double? distanceM;
  final MealWalkStatus status;
  final String? recordingSessionId;
}

class MealWalkRules {
  static const promptAfterMeal = Duration(minutes: 30);
  static const walkGoal = Duration(minutes: 15);
  static const maxMealPromptsPerDay = 3;
  static const mealWindow = Duration(minutes: 45);
  static const missAfterPrompt = Duration(hours: 2);
  static const glucoseGuardBadge = 'glucose_guard';

  /// Same floor as land qualification — standing still does not count.
  static double get minMoveM => minLandSessionDistM;
}

bool canEnableFeature({required DateTime? disclaimerAcknowledgedAt}) {
  return disclaimerAcknowledgedAt != null;
}

/// Server/client invariant: feature_enabled cannot flip on without a disclaimer timestamp.
MealSchedule enableSchedule({
  required MealSchedule current,
  required DateTime acknowledgedAt,
  DayMinutes? breakfast,
  DayMinutes? lunch,
  DayMinutes? dinner,
}) {
  if (!canEnableFeature(disclaimerAcknowledgedAt: acknowledgedAt)) {
    throw StateError('disclaimer required');
  }
  return MealSchedule(
    breakfast: breakfast ?? current.breakfast,
    lunch: lunch ?? current.lunch,
    dinner: dinner ?? current.dinner,
    featureEnabled: true,
    disclaimerAcknowledgedAt: acknowledgedAt,
  );
}

MealSchedule disableSchedule(MealSchedule current) {
  return MealSchedule(
    breakfast: current.breakfast,
    lunch: current.lunch,
    dinner: current.dinner,
    featureEnabled: false,
    disclaimerAcknowledgedAt: current.disclaimerAcknowledgedAt,
  );
}

DateTime walkPromptAt(DateTime mealStartedAt) =>
    mealStartedAt.add(MealWalkRules.promptAfterMeal);

bool sameLocalDay(DateTime a, DateTime b) {
  final la = a.toLocal();
  final lb = b.toLocal();
  return la.year == lb.year && la.month == lb.month && la.day == lb.day;
}

bool inMealWindow({
  required DayMinutes scheduled,
  required DateTime now,
  Duration window = MealWalkRules.mealWindow,
}) {
  final today = scheduled.onDay(now);
  final delta = now.difference(today).abs();
  return delta <= window;
}

MealType? mealInWindow(
  MealSchedule schedule,
  DateTime now, {
  Iterable<MealType>? promptedToday,
}) {
  final used = promptedToday?.toSet() ?? {};
  // 1. Strict window check first
  for (final type in MealType.values) {
    if (!used.contains(type) && inMealWindow(scheduled: schedule.timeOf(type), now: now)) {
      return type;
    }
  }
  // 2. Fallback for past meal times today: return the most recent meal that hasn't been logged yet
  for (final type in MealType.values.reversed) {
    final schedTime = schedule.timeOf(type).onDay(now);
    if (!used.contains(type) && now.isAfter(schedTime.subtract(const Duration(minutes: 30)))) {
      return type;
    }
  }
  // 3. Fallback for upcoming meal today if none logged yet
  for (final type in MealType.values) {
    if (!used.contains(type)) {
      return type;
    }
  }
  return null;
}

/// Unique meal types already reminded today (cap 3 = breakfast/lunch/dinner).
int mealPromptsUsedToday(Iterable<MealType> promptedToday) {
  return promptedToday.toSet().length;
}

bool canSendMealReminder({
  required Iterable<MealType> promptedToday,
  required MealType meal,
}) {
  if (promptedToday.contains(meal)) return false;
  return mealPromptsUsedToday(promptedToday) < MealWalkRules.maxMealPromptsPerDay;
}

bool meetsWalkGoal({required Duration elapsed, required double distanceM}) {
  return elapsed >= MealWalkRules.walkGoal &&
      distanceM + 1e-6 >= MealWalkRules.minMoveM;
}

/// Existing recording already covers the 15-minute walk — complete without a second prompt.
bool shouldAutoCompleteDuringRecording({
  required bool isRecording,
  required Duration sessionElapsed,
  required double sessionDistanceM,
}) {
  return isRecording &&
      meetsWalkGoal(elapsed: sessionElapsed, distanceM: sessionDistanceM);
}

/// Duplicate walk push while another session is live.
bool shouldSuppressWalkNotification({required bool isRecording}) => isRecording;

MealWalkStatus statusAfterWalkStop({
  required Duration elapsed,
  required double distanceM,
}) {
  if (meetsWalkGoal(elapsed: elapsed, distanceM: distanceM)) {
    return MealWalkStatus.completed;
  }
  return MealWalkStatus.partial;
}

bool isMissed({
  required MealWalkSession session,
  required DateTime now,
}) {
  if (session.status == MealWalkStatus.completed ||
      session.status == MealWalkStatus.partial ||
      session.status == MealWalkStatus.missed) {
    return session.status == MealWalkStatus.missed;
  }
  final prompted = session.walkPromptedAt;
  if (prompted == null) {
    return now.difference(session.mealStartedAt) >
        MealWalkRules.promptAfterMeal + MealWalkRules.missAfterPrompt;
  }
  if (session.walkStartedAt != null) return false;
  return now.difference(prompted) > MealWalkRules.missAfterPrompt;
}

String partialFeedback({required Duration elapsed}) {
  final m = elapsed.inMinutes.clamp(0, 14);
  return '그래도 오늘 $m분 걸으셨어요';
}

const skipCopy = '괜찮아요, 다음 끼니에 다시 해봐요';

class MealWalkVasa {
  const MealWalkVasa({
    required this.promptedSessions,
    required this.completedSessions,
    required this.meanReaction,
  });

  final int promptedSessions;
  final int completedSessions;
  final Duration? meanReaction;

  /// Completed meal_walk_sessions ÷ sessions that received a walk prompt.
  double get adherenceRate {
    if (promptedSessions <= 0) return 0;
    return completedSessions / promptedSessions;
  }
}

MealWalkVasa computeMealWalkVasa(Iterable<MealWalkSession> sessions) {
  final prompted = sessions.where((s) => s.walkPromptedAt != null).toList();
  final completed =
      prompted.where((s) => s.status == MealWalkStatus.completed).length;
  final delays = <Duration>[];
  for (final s in prompted) {
    final start = s.walkStartedAt;
    final prompt = s.walkPromptedAt;
    if (start != null && prompt != null && !start.isBefore(prompt)) {
      delays.add(start.difference(prompt));
    }
  }
  Duration? mean;
  if (delays.isNotEmpty) {
    final us = delays.fold<int>(0, (n, d) => n + d.inMicroseconds) ~/ delays.length;
    mean = Duration(microseconds: us);
  }
  return MealWalkVasa(
    promptedSessions: prompted.length,
    completedSessions: completed,
    meanReaction: mean,
  );
}

DateTime nextOccurrence(DayMinutes clock, DateTime now) {
  final today = clock.onDay(now);
  if (!today.isBefore(now)) return today;
  return clock.onDay(now.add(const Duration(days: 1)));
}
