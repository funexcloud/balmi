/// Daily health targets persisted in app_kv.
class HealthGoals {
  const HealthGoals({
    required this.stepGoal,
    required this.exerciseMinutes,
    required this.exerciseKm,
  });

  static const defaults = HealthGoals(
    stepGoal: 10000,
    exerciseMinutes: 30,
    exerciseKm: 2.0,
  );

  final int stepGoal;
  final int exerciseMinutes;
  final double exerciseKm;

  HealthGoals copyWith({
    int? stepGoal,
    int? exerciseMinutes,
    double? exerciseKm,
  }) {
    return HealthGoals(
      stepGoal: stepGoal ?? this.stepGoal,
      exerciseMinutes: exerciseMinutes ?? this.exerciseMinutes,
      exerciseKm: exerciseKm ?? this.exerciseKm,
    );
  }

  HealthGoals clamped() {
    return HealthGoals(
      stepGoal: stepGoal.clamp(1000, 100000),
      exerciseMinutes: exerciseMinutes.clamp(5, 300),
      exerciseKm: exerciseKm.clamp(0.5, 100.0),
    );
  }
}
