import 'package:balmi/data/db/app_database.dart';
import 'package:balmi/data/repositories/session_repository.dart';
import 'package:balmi/domain/engines/recovery.dart';
import 'package:balmi/domain/engines/session_checkpoint.dart';
import 'package:balmi/domain/models/sport.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SessionRepository repo;

  setUp(() {
    db = AppDatabase.executor(NativeDatabase.memory());
    repo = SessionRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('save/load checkpoint and recoverable recording', () async {
    final session = await repo.createSession(trackMode: false);
    await repo.insertPoint(
      sessionId: session.id,
      seq: 1,
      ts: DateTime.utc(2026, 8, 26, 10, 30),
      lat: 37.5,
      lng: 127.0,
      hAccM: 8,
    );
    await repo.updateDistances(
      sessionId: session.id,
      totalDistM: 1200,
      walkDistM: 1200,
      runDistM: 0,
    );

    final cp = SessionCheckpoint(
      sessionId: session.id,
      elapsedMs: 600000,
      movingMs: 540000,
      pausedTotalMs: 0,
      distanceM: 1200,
      steps: 1400,
      activity: 'walk',
      lapCount: 0,
      paused: false,
      reason: CheckpointReason.pause,
      updatedAt: DateTime.utc(2026, 8, 26, 10, 40),
      lastLatitude: 37.5,
      lastLongitude: 127.0,
      lastGpsTimestampMs: DateTime.utc(2026, 8, 26, 10, 30).millisecondsSinceEpoch,
    );
    await repo.saveCheckpoint(cp);

    final loaded = await repo.loadCheckpoint(session.id);
    expect(loaded?.reason, CheckpointReason.pause);
    expect(loaded?.distanceM, 1200);

    final recoverable = await repo.loadRecoverableRecording();
    expect(recoverable, isNotNull);
    expect(SessionRecovery.needsRecovery(recoverable), isTrue);
    expect(recoverable!.pointCount, 1);
    expect(recoverable.displayDistM, 1200);
    expect(recoverable.checkpoint?.reason.wire, 'PAUSE');

    await repo.closeSession(session.id, status: SessionStatus.closed);
    expect(await repo.loadCheckpoint(session.id), isNull);
    expect(await repo.loadRecoverableRecording(), isNull);
  });
}
