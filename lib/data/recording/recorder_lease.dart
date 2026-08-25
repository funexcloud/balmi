class RecorderLease {
  const RecorderLease({this.takeoverAfter = const Duration(seconds: 6)});

  final Duration takeoverAfter;

  bool shouldTakeOver({required DateTime now, required int? mainHeartbeatMs}) {
    if (mainHeartbeatMs == null || mainHeartbeatMs <= 0) return true;
    final heartbeat = DateTime.fromMillisecondsSinceEpoch(mainHeartbeatMs);
    return now.difference(heartbeat) > takeoverAfter;
  }
}
