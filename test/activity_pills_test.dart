import 'package:balmi/core/theme.dart';
import 'package:balmi/data/db/app_database.dart';
import 'package:balmi/data/notifications/meal_walk_alarms.dart';
import 'package:balmi/data/repositories/meal_walk_store.dart';
import 'package:balmi/data/repositories/session_repository.dart';
import 'package:balmi/data/repositories/step_goal_store.dart';
import 'package:balmi/data/sensors/step_service.dart';
import 'package:balmi/domain/models/activity.dart';
import 'package:balmi/features/home/home_screen.dart';
import 'package:balmi/features/meal_walk/meal_walk_controller.dart';
import 'package:balmi/features/recording/recording_controller.dart';
import 'package:balmi/features/settings/step_goal_controller.dart';
import 'package:balmi/widgets/activity_pills.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('pills include 트랙 on the same row as other activities', (tester) async {
    ActivityKind selected = ActivityKind.auto;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivityPills(
            value: selected,
            onChanged: (v) => selected = v,
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('자동'), findsOneWidget);
    expect(find.bySemanticsLabel('걷기'), findsOneWidget);
    expect(find.bySemanticsLabel('달리기'), findsOneWidget);
    expect(find.bySemanticsLabel('등산'), findsOneWidget);
    expect(find.bySemanticsLabel('트레일 러닝'), findsOneWidget);
    expect(find.bySemanticsLabel('트랙'), findsOneWidget);
    expect(find.text('트랙'), findsNothing);

    await tester.tap(find.bySemanticsLabel('트랙'));
    expect(selected, ActivityKind.track);
  });

  testWidgets('track spec uses compact pills not a dropdown', (tester) async {
    int? spec = 400;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrackSpecPills(
            value: spec,
            onChanged: (v) => spec = v,
          ),
        ),
      ),
    );
    expect(find.text('400'), findsOneWidget);
    expect(find.text('600'), findsOneWidget);
    expect(find.text('300'), findsOneWidget);
    expect(find.text('200'), findsNothing);
    expect(find.text('자유'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<int?>), findsNothing);

    await tester.tap(find.text('자유'));
    expect(spec, isNull);
  });

  testWidgets('home dock shows one activity control not the full grid', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final db = AppDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SessionRepository(db);
    final rec = RecordingController(repo: repo, dbPath: 'mem');
    addTearDown(rec.dispose);
    final meal = MealWalkController(
      store: MealWalkStore(db, newId: () => 'id'),
      repo: repo,
      recording: rec,
      alarms: SilentMealWalkAlarms(),
    );
    addTearDown(meal.dispose);
    final stepGoal = StepGoalController(store: StepGoalStore(db));
    addTearDown(stepGoal.dispose);
    final steps = StepService(repo: repo);
    addTearDown(steps.dispose);
    await meal.bootstrap();
    await stepGoal.bootstrap();

    await tester.pumpWidget(
      MaterialApp(
        theme: BalmiTheme.light(),
        home: MultiProvider(
          providers: [
            Provider<SessionRepository>.value(value: repo),
            ChangeNotifierProvider<RecordingController>.value(value: rec),
            ChangeNotifierProvider<MealWalkController>.value(value: meal),
            ChangeNotifierProvider<StepGoalController>.value(value: stepGoal),
            ChangeNotifierProvider<StepService>.value(value: steps),
          ],
          child: const Scaffold(body: HomeScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('자동'), findsOneWidget);
    expect(find.bySemanticsLabel('걷기'), findsNothing);
    expect(find.bySemanticsLabel('달리기'), findsNothing);
    expect(find.bySemanticsLabel('등산'), findsNothing);
    expect(find.bySemanticsLabel('트레일 러닝'), findsNothing);
    expect(find.bySemanticsLabel('트랙'), findsNothing);
    expect(find.text('400'), findsNothing);
    expect(find.text('자유'), findsNothing);
  });
}
