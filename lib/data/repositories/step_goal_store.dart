import '../db/app_database.dart';

/// Local keys for daily goals in `app_kv`.
const kDailyStepGoalKey = 'daily_step_goal';
const kDailyExerciseMinKey = 'daily_exercise_min';
const kDailyExerciseKmKey = 'daily_exercise_km';

/// Default daily step target (common in Korean health apps).
const kDefaultDailyStepGoal = 10000;

/// Default balmi-recorded exercise targets.
const kDefaultDailyExerciseMin = 30;
const kDefaultDailyExerciseKm = 2.0;

const kMinDailyStepGoal = 1000;
const kMaxDailyStepGoal = 50000;

const kMinDailyExerciseMin = 5;
const kMaxDailyExerciseMin = 300;

const kMinDailyExerciseKm = 0.5;
const kMaxDailyExerciseKm = 100.0;

/// Preset choices shown in settings.
const kDailyStepGoalPresets = <int>[6000, 8000, 10000, 12000, 15000];
const kDailyExerciseMinPresets = <int>[15, 20, 30, 45, 60];
const kDailyExerciseKmPresets = <double>[1.0, 1.5, 2.0, 3.0, 5.0];

class StepGoalStore {
  StepGoalStore(this.db);

  final AppDatabase db;

  Future<int> loadGoal() async {
    final row = await (db.select(db.appKv)
          ..where((t) => t.key.equals(kDailyStepGoalKey)))
        .getSingleOrNull();
    if (row == null) return kDefaultDailyStepGoal;
    final parsed = int.tryParse(row.value);
    if (parsed == null) return kDefaultDailyStepGoal;
    return parsed.clamp(kMinDailyStepGoal, kMaxDailyStepGoal);
  }

  Future<int> loadExerciseMinutes() async {
    final row = await (db.select(db.appKv)
          ..where((t) => t.key.equals(kDailyExerciseMinKey)))
        .getSingleOrNull();
    if (row == null) return kDefaultDailyExerciseMin;
    final parsed = int.tryParse(row.value);
    if (parsed == null) return kDefaultDailyExerciseMin;
    return parsed.clamp(kMinDailyExerciseMin, kMaxDailyExerciseMin);
  }

  Future<double> loadExerciseKm() async {
    final row = await (db.select(db.appKv)
          ..where((t) => t.key.equals(kDailyExerciseKmKey)))
        .getSingleOrNull();
    if (row == null) return kDefaultDailyExerciseKm;
    final parsed = double.tryParse(row.value);
    if (parsed == null) return kDefaultDailyExerciseKm;
    return parsed.clamp(kMinDailyExerciseKm, kMaxDailyExerciseKm);
  }

  Future<void> saveGoal(int steps) {
    final clamped = steps.clamp(kMinDailyStepGoal, kMaxDailyStepGoal);
    return db.into(db.appKv).insertOnConflictUpdate(
          AppKvCompanion.insert(
            key: kDailyStepGoalKey,
            value: clamped.toString(),
          ),
        );
  }

  Future<void> saveExerciseMinutes(int minutes) {
    final clamped = minutes.clamp(kMinDailyExerciseMin, kMaxDailyExerciseMin);
    return db.into(db.appKv).insertOnConflictUpdate(
          AppKvCompanion.insert(
            key: kDailyExerciseMinKey,
            value: clamped.toString(),
          ),
        );
  }

  Future<void> saveExerciseKm(double km) {
    final clamped = km.clamp(kMinDailyExerciseKm, kMaxDailyExerciseKm);
    return db.into(db.appKv).insertOnConflictUpdate(
          AppKvCompanion.insert(
            key: kDailyExerciseKmKey,
            value: clamped.toStringAsFixed(2),
          ),
        );
  }
}
