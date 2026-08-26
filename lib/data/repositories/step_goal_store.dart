import '../db/app_database.dart';

/// Local key for [StepGoalStore] in `app_kv`.
const kDailyStepGoalKey = 'daily_step_goal';

/// Default daily step target (common in Korean health apps).
const kDefaultDailyStepGoal = 10000;

const kMinDailyStepGoal = 1000;
const kMaxDailyStepGoal = 50000;

/// Preset choices shown in settings.
const kDailyStepGoalPresets = <int>[6000, 8000, 10000, 12000, 15000];

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

  Future<void> saveGoal(int steps) {
    final clamped = steps.clamp(kMinDailyStepGoal, kMaxDailyStepGoal);
    return db.into(db.appKv).insertOnConflictUpdate(
          AppKvCompanion.insert(
            key: kDailyStepGoalKey,
            value: clamped.toString(),
          ),
        );
  }
}
