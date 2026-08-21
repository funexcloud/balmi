/// Upload retry delay: 5s → 15s → 60s → 5m, then stay at 5m.
class SyncBackoff {
  static const stepsSeconds = [5, 15, 60, 300];

  static Duration delayFor(int retryCount) {
    if (retryCount < 0) return Duration(seconds: stepsSeconds.first);
    final i = retryCount >= stepsSeconds.length
        ? stepsSeconds.length - 1
        : retryCount;
    return Duration(seconds: stepsSeconds[i]);
  }

  static DateTime nextRetryAt(int retryCount, {DateTime? now}) {
    return (now ?? DateTime.now()).add(delayFor(retryCount));
  }
}
