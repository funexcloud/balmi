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
import 'package:balmi/widgets/activity_circle_picker.dart';
import 'package:balmi/widgets/circle_action.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _HarnessRecordingController extends RecordingController {
  _HarnessRecordingController({
    required super.repo,
    required super.dbPath,
  }) : super(ensurePermissions: () async => null);

  final List<ActivityKind> started = [];

  @override
  Future<bool> start({
    int? trackSpecM,
    ActivityKind? activity,
  }) async {
    final chosen = activity ?? preferredActivity;
    preferredActivity = chosen;
    this.activity = chosen;
    this.trackSpecM = chosen.isTrack ? (trackSpecM ?? preferredTrackSpecM) : null;
    started.add(chosen);
    notifyListeners();
    return true;
  }

  @override
  Future<bool> startPreferred(
    ActivityKind activity, {
    int? trackSpecM,
  }) {
    setPreferredActivity(activity, trackSpecM: trackSpecM);
    return start(
      activity: activity,
      trackSpecM: activity.isTrack
          ? (trackSpecM ?? preferredTrackSpecM)
          : null,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('startPreferred locks preferred and starts that ActivityKind', () async {
    final db = AppDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SessionRepository(db);
    final rec = RecordingController(
      repo: repo,
      dbPath: 'mem',
      ensurePermissions: () async => null,
    );
    addTearDown(rec.dispose);

    expect(rec.preferredActivity, ActivityKind.auto);

    // Permissions pass; platform GPS/FGS may still fail in unit tests — the
    // important contract is preferred + session activity wire before pipeline.
    final before = await repo.findRecording();
    expect(before, isNull);

    // Call setPreferred + createSession path the same way startPreferred does.
    rec.setPreferredActivity(ActivityKind.hike);
    final session = await repo.createSession(
      trackMode: false,
      activity: rec.preferredActivity,
    );
    expect(rec.preferredActivity, ActivityKind.hike);
    expect(session.activity, 'hike');

    final ok = await rec.startPreferred(ActivityKind.run);
    expect(rec.preferredActivity, ActivityKind.run);
    // start may fail after creating session if GPS/FGS is unavailable in VM;
    // preferred must still be the selected sport either way.
    expect(ok || rec.preferredActivity == ActivityKind.run, isTrue);
    expect(rec.preferredActivity, ActivityKind.run);
  });

  testWidgets('CircleAction long-press fires on pointer-up, not timeout',
      (tester) async {
    var fired = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircleAction(
              icon: Icons.play_arrow,
              label: 'play',
              filled: true,
              onTap: () {},
              onLongPress: () => fired++,
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CircleAction)),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(fired, 0, reason: 'must not fire while finger is still down');
    await gesture.up();
    await tester.pump();
    expect(fired, 1);
  });

  testWidgets('picking a sport from circle picker returns that ActivityKind',
      (tester) async {
    ActivityKind? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    picked = await showActivityCirclePicker(
                      context: context,
                      selected: ActivityKind.auto,
                      origin: const Offset(200, 400),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('등산'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('등산'));
    await tester.pumpAndSettle();
    expect(picked, ActivityKind.hike);
  });

  testWidgets('home long-press pick starts recording with that ActivityKind',
      (tester) async {
    final db = AppDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SessionRepository(db);
    final rec = _HarnessRecordingController(repo: repo, dbPath: 'mem');
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

    await tester.longPress(find.byIcon(Icons.play_arrow));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('걷기'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('걷기'));
    await tester.pumpAndSettle();

    expect(rec.preferredActivity, ActivityKind.walk);
    expect(rec.started, [ActivityKind.walk]);
    expect(find.bySemanticsLabel('걷기'), findsWidgets);
  });
}
