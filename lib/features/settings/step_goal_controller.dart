import 'package:flutter/foundation.dart';

import '../../data/repositories/step_goal_store.dart';

class StepGoalController extends ChangeNotifier {
  StepGoalController({required this.store});

  final StepGoalStore store;

  int goal = kDefaultDailyStepGoal;
  var _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> bootstrap() async {
    goal = await store.loadGoal();
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

  double progressFor(int steps) {
    if (goal <= 0) return 0;
    return (steps / goal).clamp(0.0, 1.0);
  }
}
