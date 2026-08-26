import 'dart:io';

import 'package:balmi/core/copy.dart';
import 'package:balmi/core/theme.dart';
import 'package:balmi/data/db/app_database.dart';
import 'package:balmi/data/repositories/session_repository.dart';
import 'package:balmi/data/repositories/step_goal_store.dart';
import 'package:balmi/data/sensors/step_service.dart';
import 'package:balmi/domain/models/sport.dart';
import 'package:balmi/features/activity/my_activity_screen.dart';
import 'package:balmi/features/settings/step_goal_controller.dart';
import 'package:balmi/widgets/today_exercise_card.dart';
import 'package:balmi/widgets/today_summary_card.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  test('My Activity source never reintroduces StepLine / 오늘 걸음 widgets', () {
    final file = File('lib/features/activity/my_activity_screen.dart');
    expect(file.existsSync(), isTrue);
    final src = file.readAsStringSync();

    // Forbidden imports / constructors that duplicated home step UI.
    expect(src.contains('today_summary_card.dart'), isFalse);
    expect(src.contains('StepLine('), isFalse);
    expect(src.contains('TodaySummaryCard('), isFalse);
    expect(src.contains('TodayStepsCard('), isFalse);
    expect(src.contains('TodayHero('), isFalse);

    // Must keep exercise card; must not use step label copy as a hero.
    expect(src.contains('TodayExerciseCard('), isTrue);
    expect(src.contains('today_exercise_card.dart'), isTrue);
    expect(
      RegExp(r'BalmiCopy\.todaySteps\b').hasMatch(src),
      isFalse,
      reason: 'My Activity must not render BalmiCopy.todaySteps (오늘 걸음)',
    );
    expect(
      RegExp(r'BalmiCopy\.recordingSteps\b').hasMatch(src),
      isFalse,
    );
  });

  testWidgets('My Activity shows 오늘의 운동 only — no duplicate 오늘 걸음', (tester) async {
    final db = AppDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SessionRepository(db);
    final steps = StepService(repo: repo);
    addTearDown(steps.dispose);
    final goals = StepGoalController(store: StepGoalStore(db));
    addTearDown(goals.dispose);
    await goals.bootstrap();

    // Hardware-style steps exist; My Activity must still ignore them in the UI.
    steps.setRecordedToday(0);
    // displaySteps may be 0 in tests without a pedometer — inject via label path:
    // StepService.label still resolves to 오늘 걸음 when hasHardware is false → recordingSteps.
    // Either way the screen must not paint that string.

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

    expect(find.text(BalmiCopy.myActivity), findsOneWidget);
    expect(find.text(BalmiCopy.todayExercise), findsOneWidget);
    expect(find.byType(TodayExerciseCard), findsOneWidget);
    expect(find.text(BalmiCopy.todaySteps), findsNothing);
    expect(find.text(BalmiCopy.recordingSteps), findsNothing);
    expect(find.byType(TodayStepsCard), findsNothing);
    expect(find.byType(TodayHero), findsNothing);
  });

  testWidgets('My Activity exercise card reflects recorded workout, not step hero', (tester) async {
    final db = AppDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SessionRepository(db);
    final steps = StepService(repo: repo);
    addTearDown(steps.dispose);
    final goals = StepGoalController(store: StepGoalStore(db));
    addTearDown(goals.dispose);
    await goals.bootstrap();

    final now = DateTime.now();
    final id = repo.newId();
    await db.into(db.sessions).insert(
          SessionsCompanion.insert(
            id: id,
            startedAt: now.subtract(const Duration(minutes: 40)),
            endedAt: Value(now.subtract(const Duration(minutes: 10))),
            status: SessionStatus.closed.wire,
            activity: const Value('walk'),
            totalDistM: const Value(2100),
            walkDistM: const Value(2100),
            runDistM: const Value(0),
            steps: const Value(2800),
          ),
        );

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
    expect(find.textContaining('분 /'), findsOneWidget);
    expect(find.textContaining('km'), findsWidgets);
    expect(find.text(BalmiCopy.todaySteps), findsNothing);
    expect(find.text('2800'), findsNothing);
  });
}
