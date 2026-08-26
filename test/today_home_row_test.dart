import 'package:balmi/core/copy.dart';
import 'package:balmi/core/theme.dart';
import 'package:balmi/domain/engines/workout_stats.dart';
import 'package:balmi/domain/models/activity.dart';
import 'package:balmi/widgets/today_exercise_card.dart';
import 'package:balmi/widgets/today_summary_card.dart';
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

  testWidgets('home today row places steps and exercise side by side', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: BalmiTheme.light(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: TodayStepsCard(
                      stepLabel: BalmiCopy.todaySteps,
                      steps: 8420,
                      stepGoal: 10000,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TodayExerciseCard(
                      stats: stats,
                      exerciseMinutes: 30,
                      exerciseKm: 2.0,
                      compact: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text(BalmiCopy.todaySteps), findsOneWidget);
    expect(find.text(BalmiCopy.todayExercise), findsOneWidget);
    expect(find.text('8420'), findsOneWidget);
    expect(find.text('12분 / 30분'), findsOneWidget);

    final stepsBox = tester.getRect(find.byType(TodayStepsCard));
    final exerciseBox = tester.getRect(find.byType(TodayExerciseCard));
    expect(stepsBox.left < exerciseBox.left, isTrue);
    expect((stepsBox.center.dy - exerciseBox.center.dy).abs() < 8, isTrue);
    expect((stepsBox.width - exerciseBox.width).abs() < 4, isTrue);
  });
}
