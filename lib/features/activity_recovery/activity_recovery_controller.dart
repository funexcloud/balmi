import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/engines/activity_recovery.dart';
import '../../domain/models/activity.dart';
import '../../data/notifications/activity_recovery_alarms.dart';
import '../../data/repositories/activity_recovery_store.dart';

class ActivityRecoveryController extends ChangeNotifier {
  ActivityRecoveryController({
    required this.store,
    required ActivityRecoveryAlarmPort alarms,
  }) : _alarms = alarms;

  final ActivityRecoveryStore store;
  final ActivityRecoveryAlarmPort _alarms;

  StreamSubscription<ActivityRecoveryAlarmTap>? _tapSub;
  ActivityRecoveryRecord? _pendingPrompt;
  String? _focusCheckId;

  ActivityRecoveryRecord? get pendingPrompt => _pendingPrompt;
  String? get focusCheckId => _focusCheckId;

  Future<void> bootstrap() async {
    await _alarms.init();
    _tapSub ??= _alarms.taps.listen((tap) {
      _focusCheckId = tap.checkId;
      notifyListeners();
    });
    await refreshPending();
  }

  Future<void> refreshPending({DateTime? now}) async {
    final due = await store.pendingRechecks(now: now);
    _pendingPrompt = due.isEmpty ? null : due.first;
    notifyListeners();
  }

  void clearFocus() {
    _focusCheckId = null;
    notifyListeners();
  }

  Future<ActivityRecoveryRecord?> latestForWorkout(String workoutSessionId) {
    return store.latestForWorkout(workoutSessionId);
  }

  Future<ActivityRecoveryRecord> start({
    required String workoutSessionId,
    required ActivityKind activity,
    required double distanceM,
    required Duration duration,
    double? avgSpeedKmh,
    required RecoverySymptom symptom,
  }) {
    return store.startCheck(
      workoutSessionId: workoutSessionId,
      metrics: RecoverySessionMetrics(
        activity: activity,
        distanceM: distanceM,
        duration: duration,
        avgSpeedKmh: avgSpeedKmh,
      ),
      symptom: symptom,
    );
  }

  Future<ActivityRecoveryRecord> logFood({
    required ActivityRecoveryRecord record,
    required RecoveryFood food,
    Duration delay = recoveryRecheckDelay,
  }) async {
    await _alarms.requestPermission();
    final updated = food == RecoveryFood.later
        ? await store.skipIntakeScheduleRecheck(
            id: record.id,
            recheckDelay: delay,
          )
        : await store.logIntake(
            id: record.id,
            food: food,
            recheckDelay: delay,
          );
    final guide = guidanceFor(
      symptom: updated.symptom,
      metrics: updated.metrics,
    );
    if (updated.status == RecoveryCheckStatus.recheckPending &&
        updated.recheckDueAt != null) {
      await _alarms.scheduleRecheck(
        checkId: updated.id,
        at: updated.recheckDueAt!,
        body: guide.recheckPrompt,
      );
    }
    await refreshPending();
    return updated;
  }

  Future<ActivityRecoveryRecord> finishWithoutFood({
    required ActivityRecoveryRecord record,
    Duration delay = recoveryRecheckDelay,
  }) {
    return logFood(
      record: record,
      food: RecoveryFood.later,
      delay: delay,
    );
  }

  Future<ActivityRecoveryRecord> answerRecheck({
    required ActivityRecoveryRecord record,
    required bool feelingOk,
    RecoverySymptom? stillSymptom,
  }) async {
    final updated = await store.completeRecheck(
      id: record.id,
      feelingOk: feelingOk,
      stillSymptom: stillSymptom,
    );
    await _alarms.cancel(record.id);
    if (_pendingPrompt?.id == record.id) _pendingPrompt = null;
    if (_focusCheckId == record.id) _focusCheckId = null;
    notifyListeners();
    return updated;
  }

  @override
  void dispose() {
    _tapSub?.cancel();
    super.dispose();
  }
}
