import 'package:flutter/foundation.dart';

import '../../data/repositories/mission_settings_store.dart';
import '../../domain/engines/workout_stats.dart';

class MissionSettingsController extends ChangeNotifier {
  MissionSettingsController({required this.store});

  final MissionSettingsStore store;

  bool reminderEnabled = kDefaultMissionReminder;
  bool showCompleted = kDefaultMissionShowCompleted;
  Set<String> enabledIds = Set<String>.from(kKnownMissionIds);
  var _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> bootstrap() async {
    final results = await Future.wait([
      store.loadReminderEnabled(),
      store.loadShowCompleted(),
      store.loadEnabledIds(),
    ]);
    reminderEnabled = results[0] as bool;
    showCompleted = results[1] as bool;
    enabledIds = results[2] as Set<String>;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setReminderEnabled(bool on) async {
    if (reminderEnabled == on) return;
    reminderEnabled = on;
    notifyListeners();
    await store.saveReminderEnabled(on);
  }

  Future<void> setShowCompleted(bool on) async {
    if (showCompleted == on) return;
    showCompleted = on;
    notifyListeners();
    await store.saveShowCompleted(on);
  }

  Future<void> setMissionEnabled(String id, bool on) async {
    if (!kKnownMissionIds.contains(id)) return;
    final next = Set<String>.from(enabledIds);
    if (on) {
      next.add(id);
    } else {
      // Keep at least one mission type visible.
      if (next.length <= 1 && next.contains(id)) return;
      next.remove(id);
    }
    if (setEquals(next, enabledIds)) return;
    enabledIds = next;
    notifyListeners();
    await store.saveEnabledIds(next);
  }

  bool isMissionEnabled(String id) => enabledIds.contains(id);

  /// Apply prefs to engine presets for the Missions list.
  List<MissionSnapshot> filterMissions(List<MissionSnapshot> presets) {
    return presets.where((m) {
      if (!enabledIds.contains(m.id)) return false;
      if (!showCompleted && m.done) return false;
      return true;
    }).toList();
  }
}
