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
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late MealWalkStore store;
  late SessionRepository repo;
  late RecordingController rec;
  late MealWalkController ctrl;

  setUp(() async {
    db = AppDatabase.executor(NativeDatabase.memory());
    store = MealWalkStore(db, newId: () => 'test_session');
    repo = SessionRepository(db);
    rec = RecordingController(repo: repo, dbPath: 'mem');
    ctrl = MealWalkController(
      store: store,
      repo: repo,
      recording: rec,
      alarms: SilentMealWalkAlarms(),
    );

    await store.saveSchedule(
      enableSchedule(
        current: MealSchedule.defaults,
        acknowledgedAt: DateTime.now(),
      ),
    );
    await ctrl.bootstrap();
  });

  tearDown(() async {
    ctrl.dispose();
    rec.dispose();
    await db.close();
  });

  test('TEST 01: 식사 시작 -> 30분 Countdown -> READY -> 15분 걷기 -> COMPLETED', () async {
    final now = DateTime(2026, 8, 29, 12, 0, 0);

    // 1. 식사 시작
    final session = await ctrl.confirmMealStart(MealType.lunch, at: now);
    expect(session, isNotNull);
    expect(session!.status, equals(MealWalkStatus.mealCountdown));

    // 2. 30분 대기 후 READY 확인
    final after30m = now.add(const Duration(minutes: 30));
    final evaluatedStatus = evaluateSessionStatus(session, after30m);
    expect(evaluatedStatus, equals(MealWalkStatus.readyToWalk));

    // 3. 15분 (900초) 걷기 진행 후 완료
    final completedSession = await store.accumulateWalkProgress(
      id: session.id,
      addDurationSec: 900,
      addDistanceM: 1200.0,
      addSteps: 1500,
      status: MealWalkStatus.completed,
      at: after30m.add(const Duration(minutes: 15)),
    );

    expect(completedSession.status, equals(MealWalkStatus.completed));
    expect(completedSession.isCompleted, isTrue);
  });

  test('TEST 02: 식사 시작 -> 앱 종료 -> 20분 후 실행 -> countdown 약 10분 남음', () async {
    final t1 = DateTime(2026, 8, 29, 12, 0, 0);
    final session = await ctrl.confirmMealStart(MealType.lunch, at: t1);
    expect(session, isNotNull);

    // 20분 후 재실행 (앱 복구)
    final t2 = t1.add(const Duration(minutes: 20));
    final remaining = remainingCountdown(session!, t2);

    expect(remaining.inMinutes, equals(10)); // 약 10분 남음
    expect(evaluateSessionStatus(session, t2), equals(MealWalkStatus.mealCountdown));
  });

  test('TEST 03: 30분 완료 -> 알림 dismiss -> 앱 실행 -> READY 상태 유지', () async {
    final t1 = DateTime(2026, 8, 29, 12, 0, 0);
    final session = await ctrl.confirmMealStart(MealType.lunch, at: t1);

    // 30분 후 + 알림 dismiss 후 앱 실행 (3시간 경과)
    final t3h = t1.add(const Duration(hours: 3, minutes: 30));
    final restoredSession = (await store.sessionById(session!.id))!;

    final evaluated = evaluateSessionStatus(restoredSession, t3h);
    expect(evaluated, equals(MealWalkStatus.readyToWalk)); // READY 상태 유지
  });

  test('TEST 04: 5분 걷기 -> 종료 -> PAUSED -> 10분 후 재진입 -> 10분 남음 -> 이어 걷기 -> COMPLETED', () async {
    final t1 = DateTime(2026, 8, 29, 12, 0, 0);
    final session = await ctrl.confirmMealStart(MealType.lunch, at: t1);
    final tWalkStart = t1.add(const Duration(minutes: 30));

    // 1. 5분 (300초) 걷고 종료 -> PAUSED
    final pausedSession = await store.accumulateWalkProgress(
      id: session!.id,
      addDurationSec: 300,
      addDistanceM: 400.0,
      addSteps: 500,
      status: MealWalkStatus.paused,
      at: tWalkStart.add(const Duration(minutes: 5)),
    );

    expect(pausedSession.walkDurationSec, equals(300));
    expect(pausedSession.remainingTargetSeconds, equals(600)); // 10분 (600초) 남음
    expect(evaluateSessionStatus(pausedSession, tWalkStart.add(const Duration(minutes: 15))), equals(MealWalkStatus.paused));

    // 2. 이어 걷기 10분 (600초) 수행 -> COMPLETED
    final completedSession = await store.accumulateWalkProgress(
      id: session.id,
      addDurationSec: 600,
      addDistanceM: 800.0,
      addSteps: 1000,
      status: MealWalkStatus.completed,
      at: tWalkStart.add(const Duration(minutes: 25)),
    );

    expect(completedSession.walkDurationSec, equals(900));
    expect(completedSession.remainingTargetSeconds, equals(0));
    expect(completedSession.status, equals(MealWalkStatus.completed));
  });

  test('TEST 05: 당일 목표 미완료 -> 날짜 변경 -> 어제 기록은 미완료 보존 -> 오늘 새로운 목표 생성', () async {
    final today = DateTime(2026, 8, 29, 12, 0, 0);
    final yesterdaySession = await ctrl.confirmMealStart(MealType.lunch, at: today);

    // 5분만 걸음
    await store.accumulateWalkProgress(
      id: yesterdaySession!.id,
      addDurationSec: 300,
      addDistanceM: 400.0,
      addSteps: 500,
      status: MealWalkStatus.paused,
      at: today.add(const Duration(minutes: 35)),
    );

    // 날짜 변경 (다음날)
    final tomorrow = DateTime(2026, 8, 30, 12, 0, 0);
    final evalYesterday = evaluateSessionStatus((await store.sessionById(yesterdaySession.id))!, tomorrow);
    expect(evalYesterday, equals(MealWalkStatus.expired)); // 어제 기록은 미완료 보존 (expired)

    // 오늘 새로운 식사 시작 (새 세션)
    final newSessionId = 'test_session_today';
    final todayStore = MealWalkStore(db, newId: () => newSessionId);
    final todaySession = await todayStore.startMeal(mealType: MealType.lunch, at: tomorrow);

    expect(todaySession.id, equals(newSessionId));
    expect(todaySession.status, equals(MealWalkStatus.mealCountdown));
    expect(todaySession.walkDurationSec, equals(0)); // 새 목표 0초에서 시작
  });

  test('TEST 06: 앱 강제 종료 -> 재실행 -> 현재 PostMealWalk 상태 Recovery', () async {
    final now = DateTime.now();
    await ctrl.confirmMealStart(MealType.lunch, at: now);

    // 재실행 (새 컨트롤러 bootstrap)
    final newCtrl = MealWalkController(
      store: store,
      repo: repo,
      recording: rec,
      alarms: SilentMealWalkAlarms(),
    );
    addTearDown(newCtrl.dispose);

    await newCtrl.bootstrap();
    expect(newCtrl.open, isNotNull);
    expect(newCtrl.open!.status, equals(MealWalkStatus.mealCountdown));
  });
}
