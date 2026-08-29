import 'package:balmi/core/copy.dart';
import 'package:balmi/core/theme.dart';
import 'package:balmi/data/db/app_database.dart';
import 'package:balmi/data/notifications/meal_walk_alarms.dart';
import 'package:balmi/data/repositories/meal_walk_store.dart';
import 'package:balmi/data/repositories/session_repository.dart';
import 'package:balmi/domain/engines/meal_walk.dart';
import 'package:balmi/features/meal_walk/meal_walk_controller.dart';
import 'package:balmi/features/meal_walk/meal_walk_hub_screen.dart';
import 'package:balmi/features/recording/recording_controller.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('MealWalkHubScreen renders 3 meal slots and catch-up buttons', (tester) async {
    final db = AppDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final store = MealWalkStore(db, newId: () => 's1');
    final repo = SessionRepository(db);
    final rec = RecordingController(repo: repo, dbPath: 'mem');
    addTearDown(rec.dispose);
    final ctrl = MealWalkController(
      store: store,
      repo: repo,
      recording: rec,
      alarms: SilentMealWalkAlarms(),
    );
    addTearDown(ctrl.dispose);

    // Enable schedule
    await store.saveSchedule(
      enableSchedule(
        current: MealSchedule.defaults,
        acknowledgedAt: DateTime.now(),
      ),
    );
    await ctrl.bootstrap();

    await tester.pumpWidget(
      MaterialApp(
        theme: BalmiTheme.light(),
        home: ChangeNotifierProvider<MealWalkController>.value(
          value: ctrl,
          child: const MealWalkHubScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text(BalmiCopy.mealWalkHubTitle), findsWidgets);
    expect(find.text('아침'), findsOneWidget);
    expect(find.text('점심'), findsOneWidget);
    expect(find.text('저녁', skipOffstage: false), findsOneWidget);
    expect(find.text(BalmiCopy.mealWalkStartBtn, skipOffstage: false), findsWidgets);
    expect(find.text(BalmiCopy.mealWalkStartWalkNow, skipOffstage: false), findsWidgets);
  });
}
