import 'package:balmi/core/copy.dart';
import 'package:balmi/core/theme.dart';
import 'package:balmi/domain/models/activity.dart';
import 'package:balmi/domain/engines/workout_stats.dart';
import 'package:balmi/widgets/today_exercise_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final stats = summarizePeriod([
    WorkoutRow(
      id: '1',
      startedAt: DateTime(2026, 8, 26, 9),
      endedAt: DateTime(2026, 8, 26, 9, 12),
      activity: ActivityKind.walk,
      totalDistM: 1200,
      walkDistM: 1200,
      runDistM: 0,
      laps: 0,
    ),
  ]);

  testWidgets('TodayExerciseCard shows title and goal progress', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: BalmiTheme.light(),
        home: Scaffold(
          body: TodayExerciseCard(
            stats: stats,
            exerciseMinutes: 30,
            exerciseKm: 2.0,
          ),
        ),
      ),
    );

    expect(find.text(BalmiCopy.todayExercise), findsOneWidget);
    expect(find.text('12분 / 30분'), findsOneWidget);
    expect(find.text('1.20 / 2.00 km'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
  });

  testWidgets('TodayExerciseCard empty state uses todayEmpty copy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: BalmiTheme.light(),
        home: Scaffold(
          body: TodayExerciseCard(
            stats: summarizePeriod(const []),
            exerciseMinutes: 30,
            exerciseKm: 2.0,
          ),
        ),
      ),
    );

    expect(find.text(BalmiCopy.todayEmpty), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  test('exerciseGoalProgress uses session duration and distance', () {
    final progress = exerciseGoalProgress(
      stats: stats,
      exerciseMinutes: 30,
      exerciseKm: 2.0,
    );
    expect(progress.minutesCurrent, 12);
    expect(progress.kmCurrent, closeTo(1.2, 0.01));
    expect(progress.minutesRatio, closeTo(0.4, 0.01));
    expect(progress.kmRatio, closeTo(0.6, 0.01));
    expect(progress.minutesDone, isFalse);
    expect(progress.kmDone, isFalse);
  });
}
