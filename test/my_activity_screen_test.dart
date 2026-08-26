import 'package:balmi/core/copy.dart';
import 'package:balmi/core/theme.dart';
import 'package:balmi/data/db/app_database.dart';
import 'package:balmi/data/repositories/session_repository.dart';
import 'package:balmi/data/repositories/step_goal_store.dart';
import 'package:balmi/data/sensors/step_service.dart';
import 'package:balmi/features/activity/my_activity_screen.dart';
import 'package:balmi/features/settings/step_goal_controller.dart';
import 'package:balmi/widgets/today_exercise_card.dart';
import 'package:balmi/widgets/today_summary_card.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('My Activity shows 오늘의 운동 only — no duplicate 오늘 걸음', (tester) async {
    final db = AppDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SessionRepository(db);
    final steps = StepService(repo: repo);
    addTearDown(steps.dispose);
    final goals = StepGoalController(store: StepGoalStore(db));
    addTearDown(goals.dispose);
    await goals.bootstrap();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SessionRepository>.value(value: repo),
          ChangeNotifierProvider<StepService>.value(value: steps),
          ChangeNotifierProvider<StepGoalController>.value(value: goals),
        ],
        child: MaterialApp(
          theme: BalmiTheme.light(),
          home: const Scaffold(body: MyActivityScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(BalmiCopy.todayExercise), findsOneWidget);
    expect(find.byType(TodayExerciseCard), findsOneWidget);
    expect(find.text(BalmiCopy.todaySteps), findsNothing);
    expect(find.text(BalmiCopy.recordingSteps), findsNothing);
    expect(find.byType(TodaySummaryCard), findsNothing);
    expect(find.byType(TodayStepsCard), findsNothing);
    expect(find.byType(StepLine), findsNothing);
  });
}
