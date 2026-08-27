import '../db/app_database.dart';
import '../../domain/engines/workout_stats.dart';

/// Local keys for mission prefs in `app_kv` — separate from health habits.
const kMissionReminderKey = 'mission_reminder_enabled';
const kMissionShowCompletedKey = 'mission_show_completed';
const kMissionEnabledIdsKey = 'mission_enabled_ids';

const kDefaultMissionReminder = false;
const kDefaultMissionShowCompleted = true;

/// Default: all built-in mission types on.
String defaultMissionEnabledIdsCsv() => kKnownMissionIds.join(',');

class MissionSettingsStore {
  MissionSettingsStore(this.db);

  final AppDatabase db;

  Future<bool> loadReminderEnabled() async {
    final row = await (db.select(db.appKv)
          ..where((t) => t.key.equals(kMissionReminderKey)))
        .getSingleOrNull();
    if (row == null) return kDefaultMissionReminder;
    return row.value == '1';
  }

  Future<bool> loadShowCompleted() async {
    final row = await (db.select(db.appKv)
          ..where((t) => t.key.equals(kMissionShowCompletedKey)))
        .getSingleOrNull();
    if (row == null) return kDefaultMissionShowCompleted;
    return row.value != '0';
  }

  Future<Set<String>> loadEnabledIds() async {
    final row = await (db.select(db.appKv)
          ..where((t) => t.key.equals(kMissionEnabledIdsKey)))
        .getSingleOrNull();
    if (row == null || row.value.trim().isEmpty) {
      return Set<String>.from(kKnownMissionIds);
    }
    final parsed = row.value
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && kKnownMissionIds.contains(s))
        .toSet();
    return parsed.isEmpty ? Set<String>.from(kKnownMissionIds) : parsed;
  }

  Future<void> saveReminderEnabled(bool on) {
    return db.into(db.appKv).insertOnConflictUpdate(
          AppKvCompanion.insert(
            key: kMissionReminderKey,
            value: on ? '1' : '0',
          ),
        );
  }

  Future<void> saveShowCompleted(bool on) {
    return db.into(db.appKv).insertOnConflictUpdate(
          AppKvCompanion.insert(
            key: kMissionShowCompletedKey,
            value: on ? '1' : '0',
          ),
        );
  }

  Future<void> saveEnabledIds(Set<String> ids) {
    final cleaned = ids.where(kKnownMissionIds.contains).toList()..sort();
    final value =
        cleaned.isEmpty ? defaultMissionEnabledIdsCsv() : cleaned.join(',');
    return db.into(db.appKv).insertOnConflictUpdate(
          AppKvCompanion.insert(
            key: kMissionEnabledIdsKey,
            value: value,
          ),
        );
  }
}
