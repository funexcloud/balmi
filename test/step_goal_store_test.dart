import 'package:balmi/data/db/app_database.dart';
import 'package:balmi/data/repositories/step_goal_store.dart';
import 'package:balmi/features/settings/step_goal_controller.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late StepGoalStore store;

  setUp(() {
    db = AppDatabase.executor(NativeDatabase.memory());
    store = StepGoalStore(db);
  });

  tearDown(() => db.close());

  test('loadGoal returns default when unset', () async {
    expect(await store.loadGoal(), kDefaultDailyStepGoal);
  });

  test('saveGoal persists and clamps out-of-range values', () async {
    await store.saveGoal(8000);
    expect(await store.loadGoal(), 8000);

    await store.saveGoal(999999);
    expect(await store.loadGoal(), kMaxDailyStepGoal);

    await store.saveGoal(100);
    expect(await store.loadGoal(), kMinDailyStepGoal);
  });

  test('controller bootstrap loads saved goal', () async {
    await store.saveGoal(12000);
    final controller = StepGoalController(store: store);
    await controller.bootstrap();
    expect(controller.goal, 12000);
    expect(controller.isLoaded, isTrue);
  });

  test('controller setGoal updates memory and storage', () async {
    final controller = StepGoalController(store: store);
    await controller.bootstrap();
    await controller.setGoal(6000);
    expect(controller.goal, 6000);
    expect(await store.loadGoal(), 6000);
  });

  test('progressFor caps at 1.0', () {
    final controller = StepGoalController(store: store);
    controller.goal = 10000;
    expect(controller.progressFor(5000), 0.5);
    expect(controller.progressFor(15000), 1.0);
  });
}
