import 'package:balmi/core/copy.dart';
import 'package:balmi/core/theme.dart';
import 'package:balmi/data/db/app_database.dart';
import 'package:balmi/data/notifications/meal_walk_alarms.dart';
import 'package:balmi/data/repositories/meal_walk_store.dart';
import 'package:balmi/data/repositories/session_repository.dart';
import 'package:balmi/data/repositories/step_goal_store.dart';
import 'package:balmi/features/meal_walk/meal_walk_controller.dart';
import 'package:balmi/features/recording/recording_controller.dart';
import 'package:balmi/features/settings/health_habits_screen.dart';
import 'package:balmi/features/settings/settings_screen.dart';
import 'package:balmi/features/settings/step_goal_controller.dart';
import 'package:balmi/features/more/more_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _habitsApp({
  required StepGoalController stepGoal,
  required MealWalkController mealWalk,
}) {
  return MaterialApp(
    theme: BalmiTheme.light(),
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<StepGoalController>.value(value: stepGoal),
        ChangeNotifierProvider<MealWalkController>.value(value: mealWalk),
      ],
      child: const HealthHabitsScreen(),
    ),
  );
}

void main() {
  testWidgets('health habits shows step goal picker; settings does not',
      (tester) async {
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
    await meal.bootstrap();
    await stepGoal.bootstrap();

    await tester.pumpWidget(_habitsApp(stepGoal: stepGoal, mealWalk: meal));
    await tester.pumpAndSettle();

    expect(find.text(BalmiCopy.mealWalkHealthSection), findsWidgets);
    expect(find.text(BalmiCopy.dailyGoals), findsOneWidget);
    expect(find.text(BalmiCopy.dailyStepGoal), findsOneWidget);
    expect(find.text(BalmiCopy.exerciseTimeGoal), findsOneWidget);
    expect(find.text(BalmiCopy.exerciseDistanceGoal), findsOneWidget);
    expect(find.text('10,000'), findsWidgets);
    expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    expect(find.byIcon(Icons.route_outlined), findsOneWidget);

    await tester.tap(find.text('8,000').last);
    await tester.pumpAndSettle();
    expect(stepGoal.goal, 8000);
    expect(find.text('8,000걸음'), findsOneWidget);

    // Verify dragging the step goal Slider updates goal
    final stepSlider = find.byType(Slider).at(0);
    await tester.ensureVisible(stepSlider);
    await tester.pumpAndSettle();
    await tester.drag(stepSlider, const Offset(50, 0));
    await tester.pumpAndSettle();
    expect(stepGoal.goal, greaterThan(8000));

    // Verify dragging exercise time Slider updates exerciseMinutes
    final timeSlider = find.byType(Slider).at(1);
    await tester.ensureVisible(timeSlider);
    await tester.pumpAndSettle();
    final initialMin = stepGoal.exerciseMinutes;
    await tester.drag(timeSlider, const Offset(60, 0));
    await tester.pumpAndSettle();
    expect(stepGoal.exerciseMinutes, greaterThan(initialMin));

    // Verify dragging exercise distance Slider updates exerciseKm
    final distSlider = find.byType(Slider).at(2);
    await tester.ensureVisible(distSlider);
    await tester.pumpAndSettle();
    final initialKm = stepGoal.exerciseKm;
    await tester.drag(distSlider, const Offset(60, 0));
    await tester.pumpAndSettle();
    expect(stepGoal.exerciseKm, greaterThan(initialKm));

    await tester.pumpWidget(
      MaterialApp(
        theme: BalmiTheme.light(),
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<StepGoalController>.value(value: stepGoal),
            ChangeNotifierProvider<MealWalkController>.value(value: meal),
          ],
          child: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(BalmiCopy.settings), findsWidgets);
    expect(find.text(BalmiCopy.about), findsOneWidget);
    expect(find.text(BalmiCopy.dailyStepGoal), findsNothing);
    expect(find.text(BalmiCopy.mealWalkTitle), findsNothing);
  });

  testWidgets('more screen opens separate health habits and settings',
      (tester) async {
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
    await meal.bootstrap();
    await stepGoal.bootstrap();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<StepGoalController>.value(value: stepGoal),
          ChangeNotifierProvider<MealWalkController>.value(value: meal),
        ],
        child: MaterialApp(
          theme: BalmiTheme.light(),
          home: const Scaffold(body: MoreScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(BalmiCopy.mealWalkHealthSection));
    await tester.pumpAndSettle();
    expect(find.byType(HealthHabitsScreen), findsOneWidget);
    expect(find.text(BalmiCopy.dailyGoals), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text(BalmiCopy.settings));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text(BalmiCopy.about), findsOneWidget);
    expect(find.text(BalmiCopy.dailyGoals), findsNothing);
  });
}
