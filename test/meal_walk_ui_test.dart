import 'package:balmi/core/copy.dart';
import 'package:balmi/core/theme.dart';
import 'package:balmi/data/db/app_database.dart';
import 'package:balmi/data/notifications/meal_walk_alarms.dart';
import 'package:balmi/data/repositories/meal_walk_store.dart';
import 'package:balmi/data/repositories/session_repository.dart';
import 'package:balmi/domain/engines/meal_walk.dart';
import 'package:balmi/features/meal_walk/meal_walk_cards.dart';
import 'package:balmi/features/meal_walk/meal_walk_controller.dart';
import 'package:balmi/features/meal_walk/meal_walk_onboarding.dart';
import 'package:balmi/features/recording/recording_controller.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) {
  return MaterialApp(
    theme: BalmiTheme.light(),
    home: child,
  );
}

void main() {
  testWidgets('disclaimer must be confirmed before meal times', (tester) async {
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
    await meal.bootstrap();

    await tester.pumpWidget(
      _app(MealWalkOnboardingScreen(controller: meal)),
    );
    expect(find.text(BalmiCopy.mealWalkIntro), findsOneWidget);
    await tester.tap(find.text(BalmiCopy.continueLabel));
    await tester.pumpAndSettle();
    expect(find.text(BalmiCopy.mealWalkDisclaimer), findsOneWidget);
    expect(find.text(BalmiCopy.mealWalkAck), findsOneWidget);
    expect(find.text(BalmiCopy.mealWalkMealTimes), findsNothing);
    await tester.tap(find.text(BalmiCopy.mealWalkAck));
    await tester.pumpAndSettle();
    expect(find.text(BalmiCopy.mealWalkMealTimes), findsOneWidget);
  });

  testWidgets('discover card uses the spec prompt and can close', (tester) async {
    var dismissed = false;
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: MealWalkDiscoverCard(
            onStart: () {},
            onDismiss: () => dismissed = true,
          ),
        ),
      ),
    );
    expect(find.text(BalmiCopy.mealWalkDiscover), findsOneWidget);
    expect(find.byIcon(Icons.directions_walk), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    expect(dismissed, isTrue);
  });

  testWidgets('meal start card uses one-button copy', (tester) async {
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: MealWalkStartCard(
            meal: MealType.lunch,
            onStart: () {},
          ),
        ),
      ),
    );
    expect(find.text(BalmiCopy.mealWalkStartPrompt), findsOneWidget);
    expect(find.text(BalmiCopy.lunch), findsOneWidget);
  });
}
