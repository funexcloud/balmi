import '../../domain/models/health_goals.dart';
import 'session_repository.dart';

const kHealthGoalStepsKey = 'health_goal_steps';
const kHealthGoalExerciseMinKey = 'health_goal_exercise_min';
const kHealthGoalExerciseKmKey = 'health_goal_exercise_km';

class HealthGoalsStore {
  HealthGoalsStore(this.repo);

  final SessionRepository repo;

  Future<HealthGoals> load() async {
    final steps = await repo.getKv(kHealthGoalStepsKey);
    final minutes = await repo.getKv(kHealthGoalExerciseMinKey);
    final km = await repo.getKv(kHealthGoalExerciseKmKey);
    if (steps == null && minutes == null && km == null) {
      return HealthGoals.defaults;
    }
    return HealthGoals(
      stepGoal: int.tryParse(steps ?? '') ?? HealthGoals.defaults.stepGoal,
      exerciseMinutes:
          int.tryParse(minutes ?? '') ?? HealthGoals.defaults.exerciseMinutes,
      exerciseKm: double.tryParse(km ?? '') ?? HealthGoals.defaults.exerciseKm,
    ).clamped();
  }

  Future<HealthGoals> save(HealthGoals goals) async {
    final next = goals.clamped();
    await repo.putKv(kHealthGoalStepsKey, '${next.stepGoal}');
    await repo.putKv(kHealthGoalExerciseMinKey, '${next.exerciseMinutes}');
    await repo.putKv(
      kHealthGoalExerciseKmKey,
      next.exerciseKm.toStringAsFixed(2),
    );
    return next;
  }
}
