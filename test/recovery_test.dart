import 'package:balmi/domain/engines/recovery.dart';
import 'package:balmi/domain/engines/session_checkpoint.dart';
import 'package:balmi/domain/models/sport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('picks the latest recording session', () {
    final t0 = DateTime.utc(2026, 8, 20);
    final found = SessionRecovery.lastRecording([
      RecoverableSession(
        id: 'closed',
        status: SessionStatus.closed,
        startedAt: t0.add(const Duration(hours: 2)),
      ),
      RecoverableSession(
        id: 'old',
        status: SessionStatus.recording,
        startedAt: t0,
      ),
      RecoverableSession(
        id: 'fresh',
        status: SessionStatus.recording,
        startedAt: t0.add(const Duration(hours: 1)),
      ),
    ]);
    expect(found?.id, 'fresh');
  });

  test('returns null when nothing is recording', () {
    expect(
      SessionRecovery.lastRecording([
        RecoverableSession(
          id: 'a',
          status: SessionStatus.closed,
          startedAt: DateTime.utc(2026, 8, 20),
        ),
      ]),
      isNull,
    );
  });

  test('needsRecovery only for unfinished recording', () {
    expect(
      SessionRecovery.needsRecovery(
        RecoverableSession(
          id: 'r',
          status: SessionStatus.recording,
          startedAt: DateTime.utc(2026, 8, 20),
        ),
      ),
      isTrue,
    );
    expect(
      SessionRecovery.needsRecovery(
        RecoverableSession(
          id: 'c',
          status: SessionStatus.closed,
          startedAt: DateTime.utc(2026, 8, 20),
        ),
      ),
      isFalse,
    );
    expect(SessionRecovery.needsRecovery(null), isFalse);
  });

  test('recoverable summary prefers checkpoint distance and elapsed', () {
    final started = DateTime.utc(2026, 8, 20, 10);
    final session = RecoverableSession(
      id: 's1',
      status: SessionStatus.recording,
      startedAt: started,
      activity: 'run',
      totalDistM: 100,
      pointCount: 40,
      lastPointAt: started.add(const Duration(minutes: 30)),
      checkpoint: SessionCheckpoint(
        sessionId: 's1',
        elapsedMs: const Duration(minutes: 31, seconds: 42).inMilliseconds,
        movingMs: 1800000,
        pausedTotalMs: 0,
        distanceM: 4270,
        steps: 5000,
        activity: 'run',
        lapCount: 0,
        paused: false,
        reason: CheckpointReason.periodic,
        updatedAt: started.add(const Duration(minutes: 31)),
      ),
    );
    expect(SessionRecovery.isRecoverable(session), isTrue);
    expect(session.activityLabel, '달리기');
    expect(session.displayDistM, 4270);
    expect(session.displayElapsed.inSeconds, 31 * 60 + 42);
  });
}
