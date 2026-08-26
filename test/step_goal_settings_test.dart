import 'package:balmi/core/copy.dart';
import 'package:balmi/core/theme.dart';
import 'package:balmi/data/db/app_database.dart';
import 'package:balmi/data/notifications/meal_walk_alarms.dart';
import 'package:balmi/data/repositories/meal_walk_store.dart';
import 'package:balmi/data/repositories/session_repository.dart';
import 'package:balmi/data/repositories/step_goal_store.dart';
import 'package:balmi/features/meal_walk/meal_walk_controller.dart';
import 'package:balmi/features/recording/recording_controller.dart';
import 'package:balmi/features/settings/settings_screen.dart';
import 'package:balmi/features/settings/step_goal_controller.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _settingsApp({
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
      child: const SettingsScreen(),
    ),
  );
}

void main() {
  testWidgets('settings shows step goal picker under health section', (tester) async {
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

    await tester.pumpWidget(_settingsApp(stepGoal: stepGoal, mealWalk: meal));
    await tester.pumpAndSettle();

    expect(find.text(BalmiCopy.mealWalkHealthSection), findsOneWidget);
    expect(find.text(BalmiCopy.dailyStepGoal), findsOneWidget);
    expect(find.text('10,000'), findsWidgets);
    expect(find.byIcon(Icons.flag_outlined), findsOneWidget);

    await tester.tap(find.text('8,000').last);
    await tester.pumpAndSettle();
    expect(stepGoal.goal, 8000);
    expect(find.text('8,000걸음'), findsOneWidget);
  });
}
