import 'package:balmi/domain/engines/sync_backoff.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('backoff 5s → 15s → 60s → 5m and holds', () {
    expect(SyncBackoff.delayFor(0), const Duration(seconds: 5));
    expect(SyncBackoff.delayFor(1), const Duration(seconds: 15));
    expect(SyncBackoff.delayFor(2), const Duration(seconds: 60));
    expect(SyncBackoff.delayFor(3), const Duration(seconds: 300));
    expect(SyncBackoff.delayFor(10), const Duration(seconds: 300));
  });

  test('nextRetryAt adds the delay', () {
    final now = DateTime.utc(2026, 8, 20, 12);
    expect(
      SyncBackoff.nextRetryAt(0, now: now),
      now.add(const Duration(seconds: 5)),
    );
  });
}
