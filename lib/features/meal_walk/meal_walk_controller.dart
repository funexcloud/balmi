import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/copy.dart';
import '../../data/notifications/meal_walk_alarms.dart';
import '../../data/repositories/meal_walk_store.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/engines/meal_walk.dart';
import '../../domain/models/activity.dart';
import '../recording/recording_controller.dart';

class MealWalkFeedback {
  const MealWalkFeedback(this.message);
  final String message;
}

class MealWalkController extends ChangeNotifier {
  MealWalkController({
    required this.store,
    required this.repo,
    required this.recording,
    required this.alarms,
  });

  final MealWalkStore store;
  final SessionRepository repo;
  final RecordingController recording;
  final MealWalkAlarmPort alarms;

  MealSchedule schedule = MealSchedule.defaults;
  MealWalkSession? open;
  MealWalkVasa vasa = const MealWalkVasa(
    promptedSessions: 0,
    completedSessions: 0,
    meanReaction: null,
  );
  String? badgeAt;
  var discoverHidden = false;
  MealWalkFeedback? lastFeedback;
  var ownsRecording = false;
  Set<MealType> mealsToday = {};
  StreamSubscription<MealWalkAlarmTap>? _taps;

  bool get enabled => schedule.featureEnabled;

  MealType? mealDueNow([DateTime? now]) {
    if (!enabled) return null;
    return mealInWindow(
      schedule,
      now ?? DateTime.now(),
      promptedToday: mealsToday,
    );
  }

  Duration walkRemaining(Duration elapsed) {
    final left = MealWalkRules.walkGoal - elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  Future<void> bootstrap() async {
    schedule = await store.loadSchedule();
    discoverHidden = await store.discoverHidden();
    badgeAt = await store.badgeEarnedAt();
    open = await store.openWalkSession();
    mealsToday = await store.promptedMealsOn(DateTime.now());
    vasa = computeMealWalkVasa(await store.listSessions());
    recording.addListener(_onRecording);
    try {
      await alarms.init();
      _taps ??= alarms.taps.listen((tap) => unawaited(onAlarmTap(tap)));
      if (enabled) {
        await alarms.scheduleDailyMeals(schedule);
      }
    } catch (_) {}
    await catchUp();
    notifyListeners();
  }

  Future<void> catchUp({DateTime? now}) async {
    final t = now ?? DateTime.now();
    final session = open ?? await store.openWalkSession();
    if (session == null) return;
    if (isMissed(session: session, now: t)) {
      await store.markMissed(session.id);
      lastFeedback = const MealWalkFeedback(skipCopy);
      open = await store.sessionById(session.id);
      notifyListeners();
      return;
    }
    if (session.status == MealWalkStatus.pending &&
        !t.isBefore(walkPromptAt(session.mealStartedAt))) {
      await _promptWalk(session, at: t);
    }
  }

  void _onRecording() {
    unawaited(onRecordingTick());
  }

  Future<void> hideDiscover() async {
    await store.hideDiscover();
    discoverHidden = true;
    notifyListeners();
  }

  Future<void> disable() async {
    schedule = disableSchedule(schedule);
    await store.saveSchedule(schedule);
    try {
      await alarms.cancelAll();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> enable({
    required DateTime acknowledgedAt,
    required DayMinutes breakfast,
    required DayMinutes lunch,
    required DayMinutes dinner,
  }) async {
    schedule = enableSchedule(
      current: schedule,
      acknowledgedAt: acknowledgedAt,
      breakfast: breakfast,
      lunch: lunch,
      dinner: dinner,
    );
    await store.saveSchedule(schedule);
    discoverHidden = true;
    await store.hideDiscover();
    try {
      await alarms.requestPermission();
      await alarms.scheduleDailyMeals(schedule);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> updateTimes({
    required DayMinutes breakfast,
    required DayMinutes lunch,
    required DayMinutes dinner,
  }) async {
    schedule = MealSchedule(
      breakfast: breakfast,
      lunch: lunch,
      dinner: dinner,
      featureEnabled: schedule.featureEnabled,
      disclaimerAcknowledgedAt: schedule.disclaimerAcknowledgedAt,
    );
    await store.saveSchedule(schedule);
    if (enabled) {
      try {
        await alarms.scheduleDailyMeals(schedule);
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> onAlarmTap(MealWalkAlarmTap tap) async {
    if (tap.kind == MealWalkAlarmKind.meal && tap.mealType != null) {
      await confirmMealStart(tap.mealType!);
      return;
    }
    if (tap.kind == MealWalkAlarmKind.walk && tap.sessionId != null) {
      await beginWalk(tap.sessionId!);
    }
  }

  Future<MealWalkSession?> confirmMealStart(
    MealType meal, {
    DateTime? at,
  }) async {
    if (!enabled) return null;
    final t = at ?? DateTime.now();
    final used = await store.promptedMealsOn(t);
    if (!canSendMealReminder(promptedToday: used, meal: meal) &&
        used.contains(meal)) {
      open = await store.openWalkSession();
      notifyListeners();
      return open;
    }
    final session = await store.startMeal(mealType: meal, at: t);
    open = session;
    mealsToday = await store.promptedMealsOn(t);
    try {
      await alarms.scheduleWalkPrompt(
        sessionId: session.id,
        at: walkPromptAt(session.mealStartedAt),
      );
    } catch (_) {}
    notifyListeners();
    return session;
  }

  Future<void> beginWalk(String sessionId, {DateTime? at}) async {
    final session = await store.sessionById(sessionId);
    if (session == null) return;
    final t = at ?? DateTime.now();
    await store.markWalkPrompted(sessionId, at: t);
    if (shouldAutoCompleteDuringRecording(
      isRecording: recording.isRecording,
      sessionElapsed: recording.elapsed,
      sessionDistanceM: recording.snapshot?.totalDistM ?? 0,
    )) {
      await _complete(
        session,
        elapsed: recording.elapsed,
        distanceM: recording.snapshot?.totalDistM ?? 0,
        at: t,
        stopRecording: false,
      );
      return;
    }
    if (shouldSuppressWalkNotification(isRecording: recording.isRecording) &&
        recording.isRecording) {
      await store.markWalkStarted(
        sessionId,
        at: t,
        recordingSessionId: recording.snapshot?.sessionId,
      );
      ownsRecording = false;
      open = await store.sessionById(sessionId);
      notifyListeners();
      return;
    }
    final ok = await recording.start(activity: ActivityKind.walk);
    if (!ok) {
      lastFeedback = MealWalkFeedback(recording.lastError ?? skipCopy);
      notifyListeners();
      return;
    }
    ownsRecording = true;
    recording.mealWalkSessionId = sessionId;
    await store.markWalkStarted(
      sessionId,
      at: t,
      recordingSessionId: recording.snapshot?.sessionId,
    );
    open = await store.sessionById(sessionId);
    notifyListeners();
  }

  Future<void> onRecordingTick() async {
    final session = open;
    if (session == null || session.status != MealWalkStatus.walking) return;
    if (!recording.isRecording) return;
    final elapsed = recording.elapsed;
    final dist = recording.snapshot?.totalDistM ?? 0;
    if (meetsWalkGoal(elapsed: elapsed, distanceM: dist)) {
      await _complete(
        session,
        elapsed: elapsed,
        distanceM: dist,
        stopRecording: ownsRecording,
      );
    }
  }

  Future<void> abortWalk() async {
    final session = open;
    if (session == null) return;
    if (session.status != MealWalkStatus.walking) return;
    final elapsed = recording.isRecording ? recording.elapsed : Duration.zero;
    final dist = recording.snapshot?.totalDistM ?? 0;
    final status = statusAfterWalkStop(elapsed: elapsed, distanceM: dist);
    if (status == MealWalkStatus.completed) {
      await _complete(
        session,
        elapsed: elapsed,
        distanceM: dist,
        stopRecording: ownsRecording,
      );
      return;
    }
    await store.finishWalk(
      id: session.id,
      status: MealWalkStatus.partial,
      elapsed: elapsed,
      distanceM: dist,
    );
    try {
      await alarms.cancelWalk(session.id);
    } catch (_) {}
    lastFeedback = MealWalkFeedback(partialFeedback(elapsed: elapsed));
    if (ownsRecording && recording.isRecording) {
      await recording.stop();
    }
    ownsRecording = false;
    recording.mealWalkSessionId = null;
    open = await store.sessionById(session.id);
    vasa = computeMealWalkVasa(await store.listSessions());
    notifyListeners();
  }

  Future<void> _promptWalk(MealWalkSession session, {DateTime? at}) async {
    final t = at ?? DateTime.now();
    await store.markWalkPrompted(session.id, at: t);
    if (shouldAutoCompleteDuringRecording(
      isRecording: recording.isRecording,
      sessionElapsed: recording.elapsed,
      sessionDistanceM: recording.snapshot?.totalDistM ?? 0,
    )) {
      await _complete(
        session,
        elapsed: recording.elapsed,
        distanceM: recording.snapshot?.totalDistM ?? 0,
        at: t,
        stopRecording: false,
      );
      return;
    }
    if (shouldSuppressWalkNotification(isRecording: recording.isRecording)) {
      await store.markWalkStarted(
        session.id,
        at: t,
        recordingSessionId: recording.snapshot?.sessionId,
      );
      ownsRecording = false;
      open = await store.sessionById(session.id);
      notifyListeners();
      return;
    }
    try {
      await alarms.scheduleWalkPrompt(sessionId: session.id, at: t);
    } catch (_) {}
    open = await store.sessionById(session.id);
    notifyListeners();
  }

  Future<void> _complete(
    MealWalkSession session, {
    required Duration elapsed,
    required double distanceM,
    DateTime? at,
    required bool stopRecording,
  }) async {
    final t = at ?? DateTime.now();
    await store.finishWalk(
      id: session.id,
      status: MealWalkStatus.completed,
      elapsed: elapsed,
      distanceM: distanceM,
      at: t,
    );
    await store.earnBadge(t);
    badgeAt = await store.badgeEarnedAt();
    try {
      await alarms.cancelWalk(session.id);
    } catch (_) {}
    final pin = recording.livePin;
    await repo.applyMealWalkReward(
      lat: pin?.latitude ?? 0,
      lng: pin?.longitude ?? 0,
      now: t,
    );
    if (stopRecording && recording.isRecording) {
      await recording.stop();
    }
    ownsRecording = false;
    recording.mealWalkSessionId = null;
    lastFeedback = const MealWalkFeedback(BalmiCopy.mealWalkDone);
    open = await store.sessionById(session.id);
    vasa = computeMealWalkVasa(await store.listSessions());
    notifyListeners();
  }

  @override
  void dispose() {
    recording.removeListener(_onRecording);
    _taps?.cancel();
    super.dispose();
  }
}
