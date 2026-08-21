import 'package:balmi/domain/engines/recovery.dart';
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
}
