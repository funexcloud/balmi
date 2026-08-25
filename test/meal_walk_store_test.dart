import 'package:balmi/data/db/app_database.dart';
import 'package:balmi/data/notifications/meal_walk_alarms.dart';
import 'package:balmi/data/repositories/meal_walk_store.dart';
import 'package:balmi/data/repositories/session_repository.dart';
import 'package:balmi/domain/engines/meal_walk.dart';
import 'package:balmi/features/meal_walk/meal_walk_controller.dart';
import 'package:balmi/features/recording/recording_controller.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late MealWalkStore store;

  setUp(() {
    db = AppDatabase.executor(NativeDatabase.memory());
    store = MealWalkStore(db, newId: () => 's1');
  });

  tearDown(() => db.close());

  test('enabled schedule is rejected without disclaimer', () async {
    expect(
      () => store.saveSchedule(
        const MealSchedule(
          breakfast: DayMinutes.breakfastDefault,
          lunch: DayMinutes.lunchDefault,
          dinner: DayMinutes.dinnerDefault,
          featureEnabled: true,
        ),
      ),
      throwsStateError,
    );
  });

  test('meal start then finish records duration and status', () async {
    final at = DateTime(2026, 8, 25, 12, 30);
    await store.saveSchedule(
      MealSchedule(
        breakfast: DayMinutes.breakfastDefault,
        lunch: DayMinutes.lunchDefault,
        dinner: DayMinutes.dinnerDefault,
        featureEnabled: true,
        disclaimerAcknowledgedAt: at,
      ),
    );
    final session = await store.startMeal(mealType: MealType.lunch, at: at);
    await store.markWalkPrompted(
      session.id,
      at: at.add(const Duration(minutes: 30)),
    );
    await store.markWalkStarted(
      session.id,
      at: at.add(const Duration(minutes: 31)),
    );
    await store.finishWalk(
      id: session.id,
      status: MealWalkStatus.completed,
      elapsed: const Duration(minutes: 15),
      distanceM: 80,
      at: at.add(const Duration(minutes: 46)),
    );
    final loaded = await store.sessionById(session.id);
    expect(loaded?.status, MealWalkStatus.completed);
    expect(loaded?.walkDurationSec, 15 * 60);
    expect(loaded?.distanceM, 80);
    expect(await store.promptedMealsOn(at), {MealType.lunch});
  });

  test('controller confirms a meal and schedules a walk prompt', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final repo = SessionRepository(db);
    final rec = RecordingController(repo: repo, dbPath: 'mem');
    final alarms = SilentMealWalkAlarms();
    final meal = MealWalkController(
      store: store,
      repo: repo,
      recording: rec,
      alarms: alarms,
    );
    await meal.bootstrap();
    await meal.enable(
      acknowledgedAt: DateTime(2026, 8, 25, 8),
      breakfast: DayMinutes.breakfastDefault,
      lunch: DayMinutes.lunchDefault,
      dinner: DayMinutes.dinnerDefault,
    );
    expect(meal.enabled, isTrue);
    final session = await meal.confirmMealStart(
      MealType.lunch,
      at: DateTime(2026, 8, 25, 12, 30),
    );
    expect(session?.mealType, MealType.lunch);
    expect(meal.mealsToday, contains(MealType.lunch));
    meal.dispose();
    rec.dispose();
  });

  test('payload parser reads meal and walk notices', () {
    final meal = MealWalkAlarms.parsePayload('balmi.meal|breakfast');
    expect(meal?.kind, MealWalkAlarmKind.meal);
    expect(meal?.mealType, MealType.breakfast);
    final walk = MealWalkAlarms.parsePayload('balmi.walk|abc');
    expect(walk?.kind, MealWalkAlarmKind.walk);
    expect(walk?.sessionId, 'abc');
    expect(MealWalkAlarms.parsePayload('nope'), isNull);
  });
}
