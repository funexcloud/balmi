import 'package:balmi/domain/engines/workout_stats.dart';
import 'package:balmi/domain/models/activity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final day = DateTime(2026, 8, 22, 10);
  final rows = [
    WorkoutRow(
      id: '1',
      startedAt: day,
      endedAt: day.add(const Duration(minutes: 20)),
      activity: ActivityKind.walk,
      totalDistM: 2000,
      walkDistM: 2000,
      runDistM: 0,
      laps: 0,
      steps: 2400,
    ),
    WorkoutRow(
      id: '2',
      startedAt: day.add(const Duration(hours: 2)),
      endedAt: day.add(const Duration(hours: 2, minutes: 15)),
      activity: ActivityKind.hike,
      totalDistM: 3000,
      walkDistM: 3000,
      runDistM: 0,
      laps: 0,
      steps: 3600,
    ),
    WorkoutRow(
      id: '3',
      startedAt: day.subtract(const Duration(days: 2)),
      endedAt: day.subtract(const Duration(days: 2)).add(const Duration(minutes: 40)),
      activity: ActivityKind.run,
      totalDistM: 8000,
      walkDistM: 0,
      runDistM: 8000,
      laps: 10,
      steps: 7000,
    ),
  ];

  test('today summary counts only local day', () {
    final today = summarizePeriod(inLocalDay(rows, day));
    expect(today.sessions, 2);
    expect(today.distM, closeTo(5000, 0.1));
    expect(today.duration.inMinutes, 35);
    expect(today.steps, 6000);
    expect(today.primaryActivity, ActivityKind.hike);
  });

  test('mission presets update from closed sessions', () {
    final missions = missionPresets(rows, day);
    expect(missions[0].id, 'today_30m');
    expect(missions[0].current, 35);
    expect(missions[0].done, isTrue);
    expect(missions[1].current, closeTo(13, 0.01));
    expect(missions[1].done, isFalse);
    expect(missions[2].current, 10);
    expect(missions[3].id, 'today_feed_800m');
    expect(missions[3].current, closeTo(5000, 0.1));
    expect(missions[3].done, isTrue);
  });

  test('exerciseGoalProgress uses session stats not pedometer', () {
    final today = summarizePeriod(inLocalDay(rows, day));
    final progress = exerciseGoalProgress(
      stats: today,
      exerciseMinutes: 30,
      exerciseKm: 2.0,
    );
    expect(progress.minutesCurrent, 35);
    expect(progress.kmCurrent, closeTo(5.0, 0.01));
    expect(progress.minutesDone, isTrue);
    expect(progress.kmDone, isTrue);
  });

  test('event progress sums only matching window and activity', () {
    final event = EventSpec(
      id: 'e',
      name: '주말',
      startsAt: DateTime(2026, 8, 22),
      endsAt: DateTime(2026, 8, 24),
      activityFilter: ActivityKind.walk,
      goalType: 'distance_km',
      goalValue: 10,
    );
    expect(eventProgress(event, rows), closeTo(2, 0.01));
  });

  test('track sessions keep 트랙 as the activity label', () {
    final track = WorkoutRow(
      id: 't',
      startedAt: day,
      endedAt: day.add(const Duration(minutes: 10)),
      activity: ActivityKind.track,
      totalDistM: 1600,
      walkDistM: 0,
      runDistM: 1600,
      laps: 4,
    );
    final stats = summarizePeriod([track]);
    expect(stats.byActivity[ActivityKind.track], closeTo(1600, 0.1));
    expect(stats.primaryActivity, ActivityKind.track);
    expect(track.matchesFilter(ActivityKind.track), isTrue);
    expect(track.matchesFilter(ActivityKind.run), isFalse);
    expect(track.activity.label, '트랙');
  });
}
