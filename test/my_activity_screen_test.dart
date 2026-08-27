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

    expect(src.contains('today_summary_card.dart'), isFalse);
    expect(src.contains('StepLine('), isFalse);
    expect(src.contains('TodaySummaryCard('), isFalse);
    expect(src.contains('TodayStepsCard('), isFalse);
    expect(src.contains('TodayHero('), isFalse);
    expect(src.contains('SessionLandReward'), isFalse);
    expect(src.contains('OsmTraceMap'), isFalse);
    expect(src.contains('PathSpark'), isFalse);

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

  Future<void> pumpScreen(
    WidgetTester tester, {
    required SessionRepository repo,
    required StepService steps,
    required StepGoalController goals,
  }) async {
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
  }

  testWidgets('My Activity shows 오늘의 운동 only — no duplicate 오늘 걸음', (tester) async {
    final db = AppDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SessionRepository(db);
    final steps = StepService(repo: repo);
    addTearDown(steps.dispose);
    final goals = StepGoalController(store: StepGoalStore(db));
    addTearDown(goals.dispose);
    await goals.bootstrap();

    steps.setRecordedToday(0);

    await pumpScreen(tester, repo: repo, steps: steps, goals: goals);

    expect(find.text(BalmiCopy.myActivity), findsOneWidget);
    expect(find.text(BalmiCopy.todayExercise), findsOneWidget);
    expect(find.byType(TodayExerciseCard), findsOneWidget);
    expect(find.text(BalmiCopy.todaySteps), findsNothing);
    expect(find.text(BalmiCopy.recordingSteps), findsNothing);
    expect(find.byType(TodayStepsCard), findsNothing);
    expect(find.byType(TodayHero), findsNothing);
    expect(find.text(BalmiCopy.periodToday), findsOneWidget);
    expect(find.text(BalmiCopy.periodWeek), findsOneWidget);
    expect(find.text(BalmiCopy.periodMonth), findsOneWidget);
    // Empty period: no orphan 운동기록 header (summary already has empty copy).
    expect(find.text(BalmiCopy.workoutLogTab), findsNothing);
    expect(find.text(BalmiCopy.activityFilterSection), findsOneWidget);
    expect(find.text(BalmiCopy.todayEmpty), findsOneWidget);
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

    await pumpScreen(tester, repo: repo, steps: steps, goals: goals);

    expect(find.text(BalmiCopy.todayExercise), findsOneWidget);
    expect(find.textContaining('분 /'), findsOneWidget);
    expect(find.textContaining('km'), findsWidgets);
    expect(find.text(BalmiCopy.todaySteps), findsNothing);
    expect(find.text('2800'), findsNothing);
    expect(find.text(BalmiCopy.workoutLogTab), findsOneWidget);
    expect(find.textContaining('걷기'), findsWidgets);
  });

  testWidgets('period tabs switch summary and scope the session list', (tester) async {
    final db = AppDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SessionRepository(db);
    final steps = StepService(repo: repo);
    addTearDown(steps.dispose);
    final goals = StepGoalController(store: StepGoalStore(db));
    addTearDown(goals.dispose);
    await goals.bootstrap();

    final now = DateTime.now();
    final todayId = repo.newId();
    final oldId = repo.newId();
    await db.into(db.sessions).insert(
          SessionsCompanion.insert(
            id: todayId,
            startedAt: now.subtract(const Duration(hours: 2)),
            endedAt: Value(now.subtract(const Duration(hours: 1))),
            status: SessionStatus.closed.wire,
            activity: const Value('run'),
            totalDistM: const Value(5000),
            walkDistM: const Value(0),
            runDistM: const Value(5000),
            steps: const Value(0),
          ),
        );
    await db.into(db.sessions).insert(
          SessionsCompanion.insert(
            id: oldId,
            startedAt: now.subtract(const Duration(days: 20)),
            endedAt: Value(now.subtract(const Duration(days: 20)).add(const Duration(minutes: 30))),
            status: SessionStatus.closed.wire,
            activity: const Value('hike'),
            totalDistM: const Value(8000),
            walkDistM: const Value(8000),
            runDistM: const Value(0),
            steps: const Value(0),
          ),
        );

    await pumpScreen(tester, repo: repo, steps: steps, goals: goals);

    expect(find.textContaining('달리기'), findsWidgets);
    expect(find.textContaining('등산'), findsNothing);
    expect(find.byType(TodayExerciseCard), findsOneWidget);

    await tester.tap(find.text(BalmiCopy.periodMonth));
    await tester.pumpAndSettle();

    expect(find.text(BalmiCopy.monthSummary), findsOneWidget);
    expect(find.byType(TodayExerciseCard), findsNothing);
    expect(find.textContaining('등산'), findsWidgets);
    expect(find.textContaining('달리기'), findsWidgets);
    expect(find.text(BalmiCopy.todayEmpty), findsNothing);
    expect(find.text(BalmiCopy.monthEmpty), findsNothing);
  });

  testWidgets('week/month empty uses period copy, not 오늘 empty', (tester) async {
    final db = AppDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SessionRepository(db);
    final steps = StepService(repo: repo);
    addTearDown(steps.dispose);
    final goals = StepGoalController(store: StepGoalStore(db));
    addTearDown(goals.dispose);
    await goals.bootstrap();

    await pumpScreen(tester, repo: repo, steps: steps, goals: goals);

    await tester.tap(find.text(BalmiCopy.periodWeek));
    await tester.pumpAndSettle();
    expect(find.text(BalmiCopy.weekSummary), findsOneWidget);
    expect(find.text(BalmiCopy.weekEmpty), findsOneWidget);
    expect(find.text(BalmiCopy.todayEmpty), findsNothing);
    expect(find.text(BalmiCopy.workoutLogTab), findsNothing);

    await tester.tap(find.text(BalmiCopy.periodMonth));
    await tester.pumpAndSettle();
    expect(find.text(BalmiCopy.monthSummary), findsOneWidget);
    expect(find.text(BalmiCopy.monthEmpty), findsOneWidget);
    expect(find.text(BalmiCopy.todayEmpty), findsNothing);
    expect(find.text(BalmiCopy.workoutLogTab), findsNothing);
  });

  testWidgets('week tab includes earlier-this-week sessions, not only today', (tester) async {
    final db = AppDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SessionRepository(db);
    final steps = StepService(repo: repo);
    addTearDown(steps.dispose);
    final goals = StepGoalController(store: StepGoalStore(db));
    addTearDown(goals.dispose);
    await goals.bootstrap();

    final now = DateTime.now();
    // Place a walk earlier in the ISO week but not today (clamp so it stays Mon+).
    final daysFromMonday = now.weekday - 1;
    final earlierOffset = daysFromMonday >= 1 ? 1 : 0;
    if (earlierOffset == 0) {
      // Monday: seed yesterday would fall in prior week — use today-only + assert week == day.
      final id = repo.newId();
      await db.into(db.sessions).insert(
            SessionsCompanion.insert(
              id: id,
              startedAt: now.subtract(const Duration(hours: 3)),
              endedAt: Value(now.subtract(const Duration(hours: 2))),
              status: SessionStatus.closed.wire,
              activity: const Value('walk'),
              totalDistM: const Value(1200),
              walkDistM: const Value(1200),
              runDistM: const Value(0),
              steps: const Value(0),
            ),
          );
      await pumpScreen(tester, repo: repo, steps: steps, goals: goals);
      expect(find.textContaining('걷기'), findsWidgets);
      await tester.tap(find.text(BalmiCopy.periodWeek));
      await tester.pumpAndSettle();
      expect(find.text(BalmiCopy.weekSummary), findsOneWidget);
      expect(find.textContaining('걷기'), findsWidgets);
      return;
    }

    final earlier = now.subtract(Duration(days: earlierOffset, hours: 4));
    await db.into(db.sessions).insert(
          SessionsCompanion.insert(
            id: repo.newId(),
            startedAt: earlier,
            endedAt: Value(earlier.add(const Duration(minutes: 40))),
            status: SessionStatus.closed.wire,
            activity: const Value('walk'),
            totalDistM: const Value(1500),
            walkDistM: const Value(1500),
            runDistM: const Value(0),
            steps: const Value(0),
          ),
        );
    await db.into(db.sessions).insert(
          SessionsCompanion.insert(
            id: repo.newId(),
            startedAt: now.subtract(const Duration(hours: 2)),
            endedAt: Value(now.subtract(const Duration(hours: 1))),
            status: SessionStatus.closed.wire,
            activity: const Value('run'),
            totalDistM: const Value(3000),
            walkDistM: const Value(0),
            runDistM: const Value(3000),
            steps: const Value(0),
          ),
        );

    await pumpScreen(tester, repo: repo, steps: steps, goals: goals);

    expect(find.textContaining('달리기'), findsWidgets);
    expect(find.textContaining('걷기'), findsNothing);

    await tester.tap(find.text(BalmiCopy.periodWeek));
    await tester.pumpAndSettle();
    expect(find.text(BalmiCopy.weekSummary), findsOneWidget);
    expect(find.textContaining('달리기'), findsWidgets);
    expect(find.textContaining('걷기'), findsWidgets);
    expect(find.text(BalmiCopy.workoutLogTab), findsOneWidget);
  });

  testWidgets('sport filter scopes list and shows filter-empty copy', (tester) async {
    final db = AppDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SessionRepository(db);
    final steps = StepService(repo: repo);
    addTearDown(steps.dispose);
    final goals = StepGoalController(store: StepGoalStore(db));
    addTearDown(goals.dispose);
    await goals.bootstrap();

    final now = DateTime.now();
    await db.into(db.sessions).insert(
          SessionsCompanion.insert(
            id: repo.newId(),
            startedAt: now.subtract(const Duration(hours: 3)),
            endedAt: Value(now.subtract(const Duration(hours: 2))),
            status: SessionStatus.closed.wire,
            activity: const Value('walk'),
            totalDistM: const Value(2000),
            walkDistM: const Value(2000),
            runDistM: const Value(0),
            steps: const Value(0),
          ),
        );
    await db.into(db.sessions).insert(
          SessionsCompanion.insert(
            id: repo.newId(),
            startedAt: now.subtract(const Duration(hours: 1)),
            endedAt: Value(now.subtract(const Duration(minutes: 30))),
            status: SessionStatus.closed.wire,
            activity: const Value('run'),
            totalDistM: const Value(4000),
            walkDistM: const Value(0),
            runDistM: const Value(4000),
            steps: const Value(0),
          ),
        );

    await pumpScreen(tester, repo: repo, steps: steps, goals: goals);

    expect(find.textContaining('걷기'), findsWidgets);
    expect(find.textContaining('달리기'), findsWidgets);
    // Today summary is unfiltered (home parity) — still 2 sessions on the card.
    expect(find.text('2회'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('등산'));
    await tester.pumpAndSettle();
    expect(find.text(BalmiCopy.activityFilterEmpty), findsOneWidget);
    expect(find.textContaining('걷기'), findsNothing);
    expect(find.textContaining('달리기'), findsNothing);

    await tester.tap(find.bySemanticsLabel('걷기'));
    await tester.pumpAndSettle();
    expect(find.text(BalmiCopy.activityFilterEmpty), findsNothing);
    expect(find.textContaining('걷기'), findsWidgets);
    expect(find.textContaining('달리기'), findsNothing);
  });
}
