import 'package:drift/drift.dart';

import '../../domain/engines/activity_recovery.dart';
import '../../domain/models/activity.dart';
import '../db/app_database.dart';

class ActivityRecoveryRecord {
  const ActivityRecoveryRecord({
    required this.id,
    required this.workoutSessionId,
    required this.activity,
    required this.distanceM,
    required this.durationSec,
    required this.symptom,
    required this.status,
    required this.startedAt,
    this.avgSpeedKmh,
    this.foodChoice,
    this.guidanceKey,
    this.intakeAt,
    this.recheckAt,
    this.recheckDueAt,
    this.recheckSymptom,
    this.outcome,
    this.notes,
  });

  final String id;
  final String workoutSessionId;
  final ActivityKind activity;
  final double distanceM;
  final int durationSec;
  final double? avgSpeedKmh;
  final RecoverySymptom symptom;
  final RecoveryCheckStatus status;
  final RecoveryFood? foodChoice;
  final String? guidanceKey;
  final DateTime startedAt;
  final DateTime? intakeAt;
  final DateTime? recheckAt;
  final DateTime? recheckDueAt;
  final RecoverySymptom? recheckSymptom;
  final String? outcome;
  final String? notes;

  RecoverySessionMetrics get metrics => RecoverySessionMetrics(
        activity: activity,
        distanceM: distanceM,
        duration: Duration(seconds: durationSec),
        avgSpeedKmh: avgSpeedKmh,
      );
}

class ActivityRecoveryStore {
  ActivityRecoveryStore(this.db, {this.newId});

  final AppDatabase db;
  final String Function()? newId;

  String _id() =>
      newId?.call() ?? DateTime.now().microsecondsSinceEpoch.toString();

  Future<ActivityRecoveryRecord> startCheck({
    required String workoutSessionId,
    required RecoverySessionMetrics metrics,
    required RecoverySymptom symptom,
    DateTime? at,
  }) async {
    final id = _id();
    final started = at ?? DateTime.now();
    final guide = guidanceFor(symptom: symptom, metrics: metrics);
    await db.customStatement(
      '''
INSERT INTO activity_recovery_checks (
  id, workout_session_id, activity, distance_m, duration_sec, avg_speed_kmh,
  symptom, status, guidance_key, started_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
''',
      [
        id,
        workoutSessionId,
        metrics.activity.wire,
        metrics.distanceM,
        metrics.duration.inSeconds,
        metrics.avgSpeedKmh,
        symptom.wire,
        RecoveryCheckStatus.guided.wire,
        guide.key,
        started.millisecondsSinceEpoch,
      ],
    );
    return (await byId(id))!;
  }

  Future<ActivityRecoveryRecord?> byId(String id) async {
    final rows = await db.customSelect(
      'SELECT * FROM activity_recovery_checks WHERE id = ?',
      variables: [Variable.withString(id)],
    ).get();
    if (rows.isEmpty) return null;
    return _row(rows.first);
  }

  Future<ActivityRecoveryRecord?> latestForWorkout(String workoutSessionId) async {
    final rows = await db.customSelect(
      '''
SELECT * FROM activity_recovery_checks
WHERE workout_session_id = ?
ORDER BY started_at DESC
LIMIT 1
''',
      variables: [Variable.withString(workoutSessionId)],
    ).get();
    if (rows.isEmpty) return null;
    return _row(rows.first);
  }

  Future<List<ActivityRecoveryRecord>> listAll() async {
    final rows = await db.customSelect(
      'SELECT * FROM activity_recovery_checks ORDER BY started_at DESC',
    ).get();
    return rows.map(_row).toList();
  }

  Future<List<ActivityRecoveryRecord>> pendingRechecks({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final rows = await db.customSelect(
      '''
SELECT * FROM activity_recovery_checks
WHERE status = ?
ORDER BY recheck_due_at ASC
''',
      variables: [Variable.withString(RecoveryCheckStatus.recheckPending.wire)],
    ).get();
    return rows
        .map(_row)
        .where(
          (r) => isRecheckDue(
            dueAt: r.recheckDueAt,
            now: at,
            status: r.status,
          ),
        )
        .toList();
  }

  Future<ActivityRecoveryRecord> logIntake({
    required String id,
    required RecoveryFood food,
    DateTime? at,
    Duration recheckDelay = recoveryRecheckDelay,
  }) async {
    final current = await byId(id);
    if (current == null) throw StateError('recovery check missing: $id');
    final when = at ?? DateTime.now();
    final guide = guidanceFor(
      symptom: current.symptom,
      metrics: current.metrics,
    );
    final schedule = guide.scheduleRecheck;
    final due = schedule ? recheckDueAt(when, delay: recheckDelay) : null;
    final status = schedule
        ? RecoveryCheckStatus.recheckPending
        : RecoveryCheckStatus.intakeLogged;
    await db.customStatement(
      '''
UPDATE activity_recovery_checks
SET food_choice = ?, intake_at = ?, status = ?, recheck_due_at = ?
WHERE id = ?
''',
      [
        food.wire,
        when.millisecondsSinceEpoch,
        status.wire,
        due?.millisecondsSinceEpoch,
        id,
      ],
    );
    return (await byId(id))!;
  }

  /// Skip food but still schedule recheck when guidance asks for it.
  Future<ActivityRecoveryRecord> skipIntakeScheduleRecheck({
    required String id,
    DateTime? at,
    Duration recheckDelay = recoveryRecheckDelay,
  }) async {
    final current = await byId(id);
    if (current == null) throw StateError('recovery check missing: $id');
    final guide = guidanceFor(
      symptom: current.symptom,
      metrics: current.metrics,
    );
    if (!guide.scheduleRecheck) {
      await db.customStatement(
        'UPDATE activity_recovery_checks SET status = ? WHERE id = ?',
        [RecoveryCheckStatus.guided.wire, id],
      );
      return (await byId(id))!;
    }
    final when = at ?? DateTime.now();
    final due = recheckDueAt(when, delay: recheckDelay);
    await db.customStatement(
      '''
UPDATE activity_recovery_checks
SET food_choice = ?, intake_at = ?, status = ?, recheck_due_at = ?
WHERE id = ?
''',
      [
        RecoveryFood.later.wire,
        when.millisecondsSinceEpoch,
        RecoveryCheckStatus.recheckPending.wire,
        due.millisecondsSinceEpoch,
        id,
      ],
    );
    return (await byId(id))!;
  }

  Future<ActivityRecoveryRecord> completeRecheck({
    required String id,
    required bool feelingOk,
    RecoverySymptom? stillSymptom,
    DateTime? at,
  }) async {
    final current = await byId(id);
    if (current == null) throw StateError('recovery check missing: $id');
    final resolved = resolveRecheck(
      feelingOk: feelingOk,
      original: current.symptom,
      stillSymptom: stillSymptom,
    );
    final when = at ?? DateTime.now();
    await db.customStatement(
      '''
UPDATE activity_recovery_checks
SET status = ?, recheck_at = ?, recheck_symptom = ?, outcome = ?, notes = ?
WHERE id = ?
''',
      [
        resolved.status.wire,
        when.millisecondsSinceEpoch,
        feelingOk ? null : (stillSymptom ?? current.symptom).wire,
        resolved.status.wire,
        resolved.message,
        id,
      ],
    );
    return (await byId(id))!;
  }

  Future<void> dismiss(String id) async {
    await db.customStatement(
      '''
UPDATE activity_recovery_checks
SET status = ?, outcome = ?
WHERE id = ?
''',
      [
        RecoveryCheckStatus.dismissed.wire,
        RecoveryCheckStatus.dismissed.wire,
        id,
      ],
    );
  }

  ActivityRecoveryRecord _row(QueryRow r) {
    return ActivityRecoveryRecord(
      id: r.read<String>('id'),
      workoutSessionId: r.read<String>('workout_session_id'),
      activity: ActivityKind.fromWire(r.read<String>('activity')),
      distanceM: r.read<double>('distance_m'),
      durationSec: r.read<int>('duration_sec'),
      avgSpeedKmh: r.readNullable<double>('avg_speed_kmh'),
      symptom: RecoverySymptom.fromWire(r.read<String>('symptom')),
      status: RecoveryCheckStatus.fromWire(r.read<String>('status')),
      foodChoice: () {
        final f = r.readNullable<String>('food_choice');
        return f == null ? null : RecoveryFood.fromWire(f);
      }(),
      guidanceKey: r.readNullable<String>('guidance_key'),
      startedAt: _dt(r.read<int>('started_at'))!,
      intakeAt: _dt(r.readNullable<int>('intake_at')),
      recheckAt: _dt(r.readNullable<int>('recheck_at')),
      recheckDueAt: _dt(r.readNullable<int>('recheck_due_at')),
      recheckSymptom: () {
        final s = r.readNullable<String>('recheck_symptom');
        return s == null ? null : RecoverySymptom.fromWire(s);
      }(),
      outcome: r.readNullable<String>('outcome'),
      notes: r.readNullable<String>('notes'),
    );
  }

  DateTime? _dt(int? ms) =>
      ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
}
