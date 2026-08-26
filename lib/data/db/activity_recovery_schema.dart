import 'package:drift/drift.dart';

/// Local recovery-check ledger (workout → symptom → intake → outcome).
Future<void> createActivityRecoveryTables(GeneratedDatabase database) async {
  await database.customStatement('''
CREATE TABLE IF NOT EXISTS activity_recovery_checks (
  id TEXT PRIMARY KEY NOT NULL,
  workout_session_id TEXT NOT NULL,
  activity TEXT NOT NULL,
  distance_m REAL NOT NULL DEFAULT 0,
  duration_sec INTEGER NOT NULL DEFAULT 0,
  avg_speed_kmh REAL,
  symptom TEXT NOT NULL,
  status TEXT NOT NULL,
  food_choice TEXT,
  guidance_key TEXT,
  started_at INTEGER NOT NULL,
  intake_at INTEGER,
  recheck_at INTEGER,
  recheck_due_at INTEGER,
  recheck_symptom TEXT,
  outcome TEXT,
  notes TEXT
);
''');
  await database.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_recovery_workout '
    'ON activity_recovery_checks(workout_session_id);',
  );
  await database.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_recovery_status_due '
    'ON activity_recovery_checks(status, recheck_due_at);',
  );
}
