import 'package:drift/drift.dart';

Future<void> createMealWalkTables(GeneratedDatabase database) async {
  await database.customStatement('''
CREATE TABLE IF NOT EXISTS user_meal_schedule (
  user_id TEXT PRIMARY KEY NOT NULL,
  breakfast_min INTEGER NOT NULL,
  lunch_min INTEGER NOT NULL,
  dinner_min INTEGER NOT NULL,
  feature_enabled INTEGER NOT NULL DEFAULT 0,
  disclaimer_acknowledged_at INTEGER
);
''');
  await database.customStatement('''
CREATE TABLE IF NOT EXISTS meal_walk_sessions (
  id TEXT PRIMARY KEY NOT NULL,
  user_id TEXT NOT NULL,
  meal_type TEXT NOT NULL,
  meal_started_at INTEGER NOT NULL,
  walk_prompted_at INTEGER,
  walk_started_at INTEGER,
  walk_completed_at INTEGER,
  walk_duration_sec INTEGER,
  distance_m REAL,
  status TEXT NOT NULL DEFAULT 'pending',
  recording_session_id TEXT
);
''');
  await database.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_meal_walk_user_time '
    'ON meal_walk_sessions(user_id, meal_started_at);',
  );
}
