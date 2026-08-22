import '../models/activity.dart';

class WorkoutRow {
  const WorkoutRow({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.activity,
    required this.totalDistM,
    required this.walkDistM,
    required this.runDistM,
    required this.laps,
    this.steps = 0,
  });

  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final ActivityKind activity;
  final double totalDistM;
  final double walkDistM;
  final double runDistM;
  final int laps;
  final int steps;

  Duration get duration {
    final d = endedAt.difference(startedAt);
    return d.isNegative ? Duration.zero : d;
  }

  double get paceKmh {
    final h = duration.inMilliseconds / 3600000.0;
    if (h <= 0) return 0;
    return (totalDistM / 1000) / h;
  }

  bool matchesFilter(ActivityKind? filter) {
    if (filter == null) return true;
    if (filter == ActivityKind.auto) return activity == ActivityKind.auto;
    if (activity == filter) return true;
    if (activity == ActivityKind.auto) {
      if (filter == ActivityKind.walk) return walkDistM >= runDistM;
      if (filter == ActivityKind.run) return runDistM > walkDistM;
    }
    return false;
  }
}

class PeriodStats {
  const PeriodStats({
    required this.sessions,
    required this.distM,
    required this.duration,
    required this.steps,
    required this.byActivity,
  });

  final int sessions;
  final double distM;
  final Duration duration;
  final int steps;
  final Map<ActivityKind, double> byActivity;

  bool get isEmpty => sessions == 0;

  ActivityKind? get primaryActivity {
    if (byActivity.isEmpty) return null;
    var best = byActivity.entries.first;
    for (final e in byActivity.entries) {
      if (e.value > best.value) best = e;
    }
    if (best.value <= 0) return null;
    return best.key;
  }
}

class MissionSnapshot {
  const MissionSnapshot({
    required this.id,
    required this.title,
    required this.current,
    required this.target,
    required this.unit,
  });

  final String id;
  final String title;
  final double current;
  final double target;
  final String unit;

  double get ratio => target <= 0 ? 0 : (current / target).clamp(0, 1);
  bool get done => current + 1e-6 >= target;
}

class EventSpec {
  const EventSpec({
    required this.id,
    required this.name,
    required this.startsAt,
    required this.endsAt,
    required this.activityFilter,
    required this.goalType,
    required this.goalValue,
  });

  final String id;
  final String name;
  final DateTime startsAt;
  final DateTime endsAt;

  /// `null` = 전체.
  final ActivityKind? activityFilter;

  /// `distance_km` or `duration_min`.
  final String goalType;
  final double goalValue;

  bool isOpen(DateTime now) =>
      !now.isBefore(startsAt) && now.isBefore(endsAt.add(const Duration(days: 1)));
}

PeriodStats summarizePeriod(List<WorkoutRow> rows) {
  var dist = 0.0;
  var ms = 0;
  var steps = 0;
  final by = <ActivityKind, double>{
    for (final a in ActivityKind.selectable) a: 0,
  };
  for (final r in rows) {
    dist += r.totalDistM;
    ms += r.duration.inMilliseconds;
    steps += r.steps;
    final key = r.activity == ActivityKind.auto
        ? (r.runDistM > r.walkDistM ? ActivityKind.run : ActivityKind.walk)
        : r.activity;
    by[key] = (by[key] ?? 0) + r.totalDistM;
  }
  return PeriodStats(
    sessions: rows.length,
    distM: dist,
    duration: Duration(milliseconds: ms),
    steps: steps,
    byActivity: by,
  );
}

List<WorkoutRow> inLocalDay(List<WorkoutRow> rows, DateTime day) {
  final start = DateTime(day.year, day.month, day.day);
  final end = start.add(const Duration(days: 1));
  return rows
      .where((r) => !r.startedAt.isBefore(start) && r.startedAt.isBefore(end))
      .toList();
}

List<WorkoutRow> inLocalWeek(List<WorkoutRow> rows, DateTime day) {
  final date = DateTime(day.year, day.month, day.day);
  final monday = date.subtract(Duration(days: date.weekday - 1));
  final end = monday.add(const Duration(days: 7));
  return rows
      .where((r) => !r.startedAt.isBefore(monday) && r.startedAt.isBefore(end))
      .toList();
}

List<WorkoutRow> inLocalMonth(List<WorkoutRow> rows, DateTime day) {
  final start = DateTime(day.year, day.month, 1);
  final end = DateTime(day.year, day.month + 1, 1);
  return rows
      .where((r) => !r.startedAt.isBefore(start) && r.startedAt.isBefore(end))
      .toList();
}

List<MissionSnapshot> missionPresets(List<WorkoutRow> closed, DateTime now) {
  final today = summarizePeriod(inLocalDay(closed, now));
  final week = summarizePeriod(inLocalWeek(closed, now));
  final weekLaps = inLocalWeek(closed, now).fold<int>(0, (s, r) => s + r.laps);
  return [
    MissionSnapshot(
      id: 'today_30m',
      title: '오늘 30분',
      current: today.duration.inMinutes.toDouble(),
      target: 30,
      unit: '분',
    ),
    MissionSnapshot(
      id: 'week_15km',
      title: '이번 주 15km',
      current: week.distM / 1000,
      target: 15,
      unit: 'km',
    ),
    MissionSnapshot(
      id: 'track_10',
      title: '트랙 10바퀴',
      current: weekLaps.toDouble(),
      target: 10,
      unit: '바퀴',
    ),
    MissionSnapshot(
      id: 'today_feed_800m',
      title: '오늘 800m — 목장 먹이',
      current: today.distM,
      target: 800,
      unit: 'm',
    ),
  ];
}

double eventProgress(EventSpec event, List<WorkoutRow> closed) {
  final rows = closed.where((r) {
    if (r.startedAt.isBefore(event.startsAt)) return false;
    if (!r.startedAt.isBefore(event.endsAt.add(const Duration(days: 1)))) {
      return false;
    }
    return r.matchesFilter(event.activityFilter);
  });
  if (event.goalType == 'duration_min') {
    return rows.fold<double>(0, (s, r) => s + r.duration.inMinutes);
  }
  return rows.fold<double>(0, (s, r) => s + r.totalDistM / 1000);
}
