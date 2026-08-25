import 'package:balmi/data/recording/recorder_lease.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const lease = RecorderLease(takeoverAfter: Duration(seconds: 6));
  final now = DateTime(2026, 8, 23, 12);

  test('main heartbeat keeps the foreground backup idle', () {
    expect(
      lease.shouldTakeOver(
        now: now,
        mainHeartbeatMs: now
            .subtract(const Duration(seconds: 5))
            .millisecondsSinceEpoch,
      ),
      isFalse,
    );
  });

  test('foreground backup takes over after the main isolate goes silent', () {
    expect(
      lease.shouldTakeOver(
        now: now,
        mainHeartbeatMs: now
            .subtract(const Duration(seconds: 7))
            .millisecondsSinceEpoch,
      ),
      isTrue,
    );
  });

  test('missing heartbeat allows recovery after a service restart', () {
    expect(lease.shouldTakeOver(now: now, mainHeartbeatMs: null), isTrue);
  });
}
