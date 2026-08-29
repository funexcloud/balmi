import 'package:drift/drift.dart';

import '../../domain/engines/meal_walk.dart';
import '../db/app_database.dart';

const kLocalUserId = 'local';
const kMealWalkBadgeKey = 'badge_glucose_guard';
const kMealWalkDiscoverHiddenKey = 'meal_walk_discover_hidden';

class MealWalkStore {
  MealWalkStore(this.db, {this.newId});

  final AppDatabase db;
  final String Function()? newId;

  String _id() => newId?.call() ?? DateTime.now().microsecondsSinceEpoch.toString();

  Future<MealSchedule> loadSchedule() async {
    final rows = await db.customSelect(
      'SELECT * FROM user_meal_schedule WHERE user_id = ?',
      variables: [Variable.withString(kLocalUserId)],
    ).get();
    if (rows.isEmpty) return MealSchedule.defaults;
    final r = rows.first;
    return MealSchedule(
      breakfast: DayMinutes(r.read<int>('breakfast_min')),
      lunch: DayMinutes(r.read<int>('lunch_min')),
      dinner: DayMinutes(r.read<int>('dinner_min')),
      featureEnabled: r.read<int>('feature_enabled') != 0,
      disclaimerAcknowledgedAt: _dt(r.readNullable<int>('disclaimer_acknowledged_at')),
    );
  }

  Future<void> saveSchedule(MealSchedule schedule) async {
    if (schedule.featureEnabled &&
        !canEnableFeature(
          disclaimerAcknowledgedAt: schedule.disclaimerAcknowledgedAt,
        )) {
      throw StateError('disclaimer required');
    }
    await db.customStatement(
      '''
INSERT INTO user_meal_schedule (
  user_id, breakfast_min, lunch_min, dinner_min, feature_enabled,
  disclaimer_acknowledged_at
) VALUES (?, ?, ?, ?, ?, ?)
ON CONFLICT(user_id) DO UPDATE SET
  breakfast_min = excluded.breakfast_min,
  lunch_min = excluded.lunch_min,
  dinner_min = excluded.dinner_min,
  feature_enabled = excluded.feature_enabled,
  disclaimer_acknowledged_at = excluded.disclaimer_acknowledged_at
''',
      [
        kLocalUserId,
        schedule.breakfast.minutes,
        schedule.lunch.minutes,
        schedule.dinner.minutes,
        schedule.featureEnabled ? 1 : 0,
        schedule.disclaimerAcknowledgedAt?.millisecondsSinceEpoch,
      ],
    );
  }

  Future<MealWalkSession> startMeal({
    required MealType mealType,
    DateTime? at,
    int targetSeconds = 900,
  }) async {
    final id = _id();
    final started = at ?? DateTime.now();
    final availableAt = started.add(MealWalkRules.promptAfterMeal);

    await db.customStatement(
      '''
INSERT INTO meal_walk_sessions (
  id, user_id, meal_type, meal_started_at, walk_available_at,
  target_seconds, status
) VALUES (?, ?, ?, ?, ?, ?, ?)
''',
      [
        id,
        kLocalUserId,
        mealType.wire,
        started.millisecondsSinceEpoch,
        availableAt.millisecondsSinceEpoch,
        targetSeconds,
        MealWalkStatus.mealCountdown.wire,
      ],
    );
    return (await sessionById(id))!;
  }

  Future<MealWalkSession?> sessionById(String id) async {
    final rows = await db.customSelect(
      'SELECT * FROM meal_walk_sessions WHERE id = ?',
      variables: [Variable.withString(id)],
    ).get();
    if (rows.isEmpty) return null;
    return _row(rows.first);
  }

  Future<List<MealWalkSession>> listSessions() async {
    final rows = await db.customSelect(
      'SELECT * FROM meal_walk_sessions WHERE user_id = ? ORDER BY meal_started_at DESC',
      variables: [Variable.withString(kLocalUserId)],
    ).get();
    return rows.map(_row).toList();
  }

  Future<MealWalkSession?> openWalkSession() async {
    final rows = await db.customSelect(
      '''
SELECT * FROM meal_walk_sessions
WHERE user_id = ? AND status IN ('meal_countdown', 'pending', 'ready_to_walk', 'prompted', 'walking', 'paused', 'partial')
ORDER BY meal_started_at DESC LIMIT 1
''',
      variables: [Variable.withString(kLocalUserId)],
    ).get();
    if (rows.isEmpty) return null;
    return _row(rows.first);
  }

  Future<Set<MealType>> promptedMealsOn(DateTime day) async {
    final sessions = await listSessions();
    return {
      for (final s in sessions)
        if (sameLocalDay(s.mealStartedAt, day)) s.mealType,
    };
  }

  Future<void> markWalkPrompted(String id, {DateTime? at}) async {
    final t = at ?? DateTime.now();
    await db.customStatement(
      '''
UPDATE meal_walk_sessions
SET walk_prompted_at = ?, status = ?
WHERE id = ? AND walk_prompted_at IS NULL
''',
      [t.millisecondsSinceEpoch, MealWalkStatus.readyToWalk.wire, id],
    );
  }

  Future<void> markWalkStarted(
    String id, {
    DateTime? at,
    String? recordingSessionId,
  }) async {
    final t = at ?? DateTime.now();
    await db.customStatement(
      '''
UPDATE meal_walk_sessions
SET walk_started_at = COALESCE(walk_started_at, ?), status = ?, recording_session_id = COALESCE(?, recording_session_id)
WHERE id = ?
''',
      [
        t.millisecondsSinceEpoch,
        MealWalkStatus.walking.wire,
        recordingSessionId,
        id,
      ],
    );
  }

  Future<MealWalkSession> accumulateWalkProgress({
    required String id,
    required int addDurationSec,
    required double addDistanceM,
    required int addSteps,
    required MealWalkStatus status,
    DateTime? at,
  }) async {
    final existing = await sessionById(id);
    if (existing == null) throw StateError('Session $id not found');

    final newSec = existing.walkDurationSec + addDurationSec;
    final newDist = existing.distanceM + addDistanceM;
    final newSteps = existing.steps + addSteps;
    final t = at ?? DateTime.now();
    final isDone = status == MealWalkStatus.completed || newSec >= existing.targetSeconds;
    final finalStatus = isDone ? MealWalkStatus.completed : status;

    await db.customStatement(
      '''
UPDATE meal_walk_sessions
SET walk_completed_at = COALESCE(walk_completed_at, ?),
    walk_duration_sec = ?,
    distance_m = ?,
    steps = ?,
    status = ?
WHERE id = ?
''',
      [
        isDone ? t.millisecondsSinceEpoch : null,
        newSec,
        newDist,
        newSteps,
        finalStatus.wire,
        id,
      ],
    );
    return (await sessionById(id))!;
  }

  Future<void> finishWalk({
    required String id,
    required MealWalkStatus status,
    required Duration elapsed,
    required double distanceM,
    DateTime? at,
  }) async {
    await accumulateWalkProgress(
      id: id,
      addDurationSec: elapsed.inSeconds,
      addDistanceM: distanceM,
      addSteps: 0,
      status: status,
      at: at,
    );
  }

  Future<void> markMissed(String id) {
    return db.customStatement(
      "UPDATE meal_walk_sessions SET status = ? WHERE id = ?",
      [MealWalkStatus.expired.wire, id],
    );
  }

  Future<String?> badgeEarnedAt() async {
    final row = await (db.select(db.appKv)
          ..where((t) => t.key.equals(kMealWalkBadgeKey)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> earnBadge(DateTime at) async {
    final existing = await badgeEarnedAt();
    if (existing != null) return;
    await db.into(db.appKv).insertOnConflictUpdate(
          AppKvCompanion.insert(
            key: kMealWalkBadgeKey,
            value: at.toIso8601String(),
          ),
        );
  }

  Future<bool> discoverHidden() async {
    final row = await (db.select(db.appKv)
          ..where((t) => t.key.equals(kMealWalkDiscoverHiddenKey)))
        .getSingleOrNull();
    return row?.value == '1';
  }

  Future<void> hideDiscover() {
    return db.into(db.appKv).insertOnConflictUpdate(
          AppKvCompanion.insert(key: kMealWalkDiscoverHiddenKey, value: '1'),
        );
  }

  MealWalkSession _row(QueryRow r) {
    return MealWalkSession(
      id: r.read<String>('id'),
      mealType: MealType.fromWire(r.read<String>('meal_type')),
      mealStartedAt: DateTime.fromMillisecondsSinceEpoch(r.read<int>('meal_started_at')),
      walkAvailableAt: _dt(r.readNullable<int>('walk_available_at')),
      walkPromptedAt: _dt(r.readNullable<int>('walk_prompted_at')),
      walkStartedAt: _dt(r.readNullable<int>('walk_started_at')),
      walkCompletedAt: _dt(r.readNullable<int>('walk_completed_at')),
      walkDurationSec: r.readNullable<int>('walk_duration_sec') ?? 0,
      distanceM: r.readNullable<double>('distance_m') ?? 0.0,
      steps: r.readNullable<int>('steps') ?? 0,
      targetSeconds: r.readNullable<int>('target_seconds') ?? 900,
      status: MealWalkStatus.fromWire(r.read<String>('status')),
      recordingSessionId: r.readNullable<String>('recording_session_id'),
    );
  }

  DateTime? _dt(int? ms) =>
      ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
}
