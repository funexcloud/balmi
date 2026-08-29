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
  Timer? _liveCountdownTimer;

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

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    _syncTimer();
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    _syncTimer();
  }

  @override
  void notifyListeners() {
    _syncTimer();
    super.notifyListeners();
  }

  void _syncTimer() {
    if (open != null && open!.status == MealWalkStatus.mealCountdown && hasListeners) {
      _liveCountdownTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        final session = open;
        if (session != null && session.status == MealWalkStatus.mealCountdown) {
          final now = DateTime.now();
          final avail = session.walkAvailableAt ?? session.mealStartedAt.add(MealWalkRules.promptAfterMeal);
          if (!now.isBefore(avail)) {
            unawaited(catchUp());
          } else {
            super.notifyListeners();
          }
        } else {
          _liveCountdownTimer?.cancel();
          _liveCountdownTimer = null;
        }
      });
    } else {
      _liveCountdownTimer?.cancel();
      _liveCountdownTimer = null;
    }
  }

  @override
  void dispose() {
    _liveCountdownTimer?.cancel();
    _liveCountdownTimer = null;
    recording.removeListener(_onRecording);
    _taps?.cancel();
    super.dispose();
  }

  Future<void> catchUp({DateTime? now}) async {
    final t = now ?? DateTime.now();
    final session = open ?? await store.openWalkSession();
    if (session == null) return;

    final evaluatedStatus = evaluateSessionStatus(session, t);
    if (evaluatedStatus != session.status) {
      if (evaluatedStatus == MealWalkStatus.readyToWalk && session.walkPromptedAt == null) {
        await store.markWalkPrompted(session.id, at: t);
      }
      open = await store.sessionById(session.id);
      notifyListeners();
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
    int targetSeconds = 900,
  }) async {
    if (!enabled) return null;
    final t = at ?? DateTime.now();
    final used = await store.promptedMealsOn(t);
    if (!canSendMealReminder(promptedToday: used, meal: meal) && used.contains(meal)) {
      open = await store.openWalkSession();
      notifyListeners();
      return open;
    }
    final session = await store.startMeal(mealType: meal, at: t, targetSeconds: targetSeconds);
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
    const steps = 0;

    final totalSec = session.walkDurationSec + elapsed.inSeconds;
    if (totalSec >= session.targetSeconds) {
      await _complete(
        session,
        elapsed: elapsed,
        distanceM: dist,
        steps: steps,
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
    const steps = 0;

    final totalSec = session.walkDurationSec + elapsed.inSeconds;
    final isCompleted = totalSec >= session.targetSeconds;

    if (isCompleted) {
      await _complete(
        session,
        elapsed: elapsed,
        distanceM: dist,
        steps: steps,
        stopRecording: ownsRecording,
      );
      return;
    }

    final updated = await store.accumulateWalkProgress(
      id: session.id,
      addDurationSec: elapsed.inSeconds,
      addDistanceM: dist,
      addSteps: steps,
      status: MealWalkStatus.paused,
    );

    try {
      await alarms.cancelWalk(session.id);
    } catch (_) {}
    lastFeedback = MealWalkFeedback(partialFeedback(elapsed: Duration(seconds: updated.walkDurationSec)));
    if (ownsRecording && recording.isRecording) {
      await recording.stop();
    }
    ownsRecording = false;
    recording.mealWalkSessionId = null;
    open = updated;
    vasa = computeMealWalkVasa(await store.listSessions());
    notifyListeners();
  }

  Future<void> _complete(
    MealWalkSession session, {
    required Duration elapsed,
    required double distanceM,
    required int steps,
    DateTime? at,
    bool stopRecording = true,
  }) async {
    final t = at ?? DateTime.now();
    final updated = await store.accumulateWalkProgress(
      id: session.id,
      addDurationSec: elapsed.inSeconds,
      addDistanceM: distanceM,
      addSteps: steps,
      status: MealWalkStatus.completed,
      at: t,
    );
    try {
      await alarms.cancelWalk(session.id);
    } catch (_) {}
    await store.earnBadge(t);
    badgeAt = await store.badgeEarnedAt();
    if (stopRecording && ownsRecording && recording.isRecording) {
      await recording.stop();
    }
    ownsRecording = false;
    recording.mealWalkSessionId = null;
    open = updated;
    vasa = computeMealWalkVasa(await store.listSessions());
    lastFeedback = const MealWalkFeedback(BalmiCopy.mealWalkDone);
    notifyListeners();
  }
}

MealWalkVasa computeMealWalkVasa(List<MealWalkSession> sessions) {
  var prompted = 0;
  var completed = 0;
  final reactions = <Duration>[];
  for (final s in sessions) {
    if (s.status == MealWalkStatus.readyToWalk ||
        s.status == MealWalkStatus.walking ||
        s.status == MealWalkStatus.paused ||
        s.status == MealWalkStatus.completed ||
        s.status == MealWalkStatus.expired) {
      prompted++;
    }
    if (s.status == MealWalkStatus.completed || s.walkDurationSec >= s.targetSeconds) {
      completed++;
    }
    if (s.walkPromptedAt != null && s.walkStartedAt != null) {
      final d = s.walkStartedAt!.difference(s.walkPromptedAt!);
      if (!d.isNegative) reactions.add(d);
    }
  }
  Duration? mean;
  if (reactions.isNotEmpty) {
    final sumMs = reactions.fold<int>(0, (a, b) => a + b.inMilliseconds);
    mean = Duration(milliseconds: sumMs ~/ reactions.length);
  }
  return MealWalkVasa(
    promptedSessions: prompted,
    completedSessions: completed,
    meanReaction: mean,
  );
}
