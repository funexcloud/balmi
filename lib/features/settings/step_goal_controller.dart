import 'package:flutter/foundation.dart';

import '../../data/repositories/step_goal_store.dart';

class StepGoalController extends ChangeNotifier {
  StepGoalController({required this.store});

  final StepGoalStore store;

  int goal = kDefaultDailyStepGoal;
  int exerciseMinutes = kDefaultDailyExerciseMin;
  double exerciseKm = kDefaultDailyExerciseKm;
  var _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> bootstrap() async {
    final results = await Future.wait([
      store.loadGoal(),
      store.loadExerciseMinutes(),
      store.loadExerciseKm(),
    ]);
    goal = results[0] as int;
    exerciseMinutes = results[1] as int;
    exerciseKm = results[2] as double;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setGoal(int steps) async {
    final next = steps.clamp(kMinDailyStepGoal, kMaxDailyStepGoal);
    if (goal == next) return;
    goal = next;
    notifyListeners();
    await store.saveGoal(next);
  }

  Future<void> setExerciseMinutes(int minutes) async {
    final next = minutes.clamp(kMinDailyExerciseMin, kMaxDailyExerciseMin);
    if (exerciseMinutes == next) return;
    exerciseMinutes = next;
    notifyListeners();
    await store.saveExerciseMinutes(next);
  }

  Future<void> setExerciseKm(double km) async {
    final next = km.clamp(kMinDailyExerciseKm, kMaxDailyExerciseKm);
    if ((exerciseKm - next).abs() < 1e-6) return;
    exerciseKm = next;
    notifyListeners();
    await store.saveExerciseKm(next);
  }

  double progressFor(int steps) {
    if (goal <= 0) return 0;
    return (steps / goal).clamp(0.0, 1.0);
  }
}
