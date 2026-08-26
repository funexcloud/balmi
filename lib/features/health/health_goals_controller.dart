import 'package:flutter/foundation.dart';

import '../../data/repositories/health_goals_store.dart';
import '../../domain/models/health_goals.dart';

class HealthGoalsController extends ChangeNotifier {
  HealthGoalsController({required this.store});

  final HealthGoalsStore store;

  HealthGoals goals = HealthGoals.defaults;
  var _loaded = false;

  bool get loaded => _loaded;

  Future<void> bootstrap() async {
    goals = await store.load();
    _loaded = true;
    notifyListeners();
  }

  Future<void> updateGoals(HealthGoals next) async {
    goals = await store.save(next);
    notifyListeners();
  }
}
