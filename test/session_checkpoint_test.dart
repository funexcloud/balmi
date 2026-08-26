import 'package:balmi/domain/engines/session_checkpoint.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('immediate reasons always flush', () {
    for (final reason in CheckpointReason.values) {
      if (reason == CheckpointReason.periodic) {
        expect(CheckpointPolicy.isImmediate(reason), isFalse);
      } else {
        expect(CheckpointPolicy.isImmediate(reason), isTrue);
      }
    }
  });

  test('periodic write respects interval', () {
    final t0 = DateTime.utc(2026, 8, 26, 12);
    expect(
      CheckpointPolicy.shouldPeriodicWrite(now: t0, lastWriteAt: null),
      isTrue,
    );
    expect(
      CheckpointPolicy.shouldPeriodicWrite(
        now: t0.add(const Duration(seconds: 10)),
        lastWriteAt: t0,
      ),
      isFalse,
    );
    expect(
      CheckpointPolicy.shouldPeriodicWrite(
        now: t0.add(const Duration(seconds: 15)),
        lastWriteAt: t0,
      ),
      isTrue,
    );
  });

  test('checkpoint round-trips JSON', () {
    final raw = SessionCheckpoint(
      sessionId: 'abc',
      elapsedMs: 1902000,
      movingMs: 1800000,
      pausedTotalMs: 60000,
      distanceM: 4270,
      steps: 5200,
      activity: 'run',
      lapCount: 2,
      paused: false,
      reason: CheckpointReason.pause,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(1_700_000_000_000),
      lastLatitude: 37.5,
      lastLongitude: 127.0,
      lastGpsTimestampMs: 1_700_000_000_000,
    );
    final back = SessionCheckpoint.fromJson(raw.toJson());
    expect(back.sessionId, 'abc');
    expect(back.elapsedMs, 1902000);
    expect(back.distanceM, 4270);
    expect(back.reason, CheckpointReason.pause);
    expect(back.lastLatitude, 37.5);
    expect(back.reason.wire, 'PAUSE');
  });
}
