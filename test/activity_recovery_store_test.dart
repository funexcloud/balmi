import 'package:balmi/data/db/activity_recovery_schema.dart';
import 'package:balmi/data/db/app_database.dart';
import 'package:balmi/data/repositories/activity_recovery_store.dart';
import 'package:balmi/domain/engines/activity_recovery.dart';
import 'package:balmi/domain/models/activity.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ActivityRecoveryStore store;
  var seq = 0;

  setUp(() async {
    db = AppDatabase.executor(NativeDatabase.memory());
    await createActivityRecoveryTables(db);
    store = ActivityRecoveryStore(db, newId: () => 'rec-${++seq}');
  });

  tearDown(() async {
    await db.close();
  });

  test('persists workout → symptom → intake → recheck outcome', () async {
    final started = DateTime(2026, 8, 26, 16, 0);
    final created = await store.startCheck(
      workoutSessionId: 'sess-1',
      metrics: const RecoverySessionMetrics(
        activity: ActivityKind.walk,
        distanceM: 3200,
        duration: Duration(minutes: 35),
        avgSpeedKmh: 5.5,
      ),
      symptom: RecoverySymptom.tremor,
      at: started,
    );
    expect(created.id, 'rec-1');
    expect(created.status, RecoveryCheckStatus.guided);
    expect(created.guidanceKey, 'tremor');

    final afterFood = await store.logIntake(
      id: created.id,
      food: RecoveryFood.banana,
      at: started.add(const Duration(minutes: 1)),
      recheckDelay: const Duration(minutes: 12),
    );
    expect(afterFood.foodChoice, RecoveryFood.banana);
    expect(afterFood.status, RecoveryCheckStatus.recheckPending);
    expect(afterFood.recheckDueAt, isNotNull);

    final pendingEarly = await store.pendingRechecks(
      now: started.add(const Duration(minutes: 5)),
    );
    expect(pendingEarly, isEmpty);

    final pending = await store.pendingRechecks(
      now: started.add(const Duration(minutes: 15)),
    );
    expect(pending.map((e) => e.id), ['rec-1']);

    final done = await store.completeRecheck(
      id: created.id,
      feelingOk: true,
      at: started.add(const Duration(minutes: 16)),
    );
    expect(done.status, RecoveryCheckStatus.recovered);
    expect(done.outcome, RecoveryCheckStatus.recovered.wire);

    final latest = await store.latestForWorkout('sess-1');
    expect(latest?.status, RecoveryCheckStatus.recovered);
  });

  test('still-unwell recheck stores symptom and medical note', () async {
    final row = await store.startCheck(
      workoutSessionId: 'sess-2',
      metrics: const RecoverySessionMetrics(
        activity: ActivityKind.run,
        distanceM: 8000,
        duration: Duration(minutes: 50),
        avgSpeedKmh: 9.6,
      ),
      symptom: RecoverySymptom.dizziness,
    );
    await store.skipIntakeScheduleRecheck(
      id: row.id,
      at: DateTime(2026, 8, 26, 17),
      recheckDelay: Duration.zero,
    );
    final done = await store.completeRecheck(
      id: row.id,
      feelingOk: false,
      stillSymptom: RecoverySymptom.nausea,
    );
    expect(done.status, RecoveryCheckStatus.stillUnwell);
    expect(done.recheckSymptom, RecoverySymptom.nausea);
    expect(done.notes?.contains('의료기관'), isTrue);
  });
}
