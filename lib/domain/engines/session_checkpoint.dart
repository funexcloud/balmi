/// Event that should flush a session checkpoint immediately.
enum CheckpointReason {
  start,
  pause,
  resume,
  lap,
  activity,
  gpsLost,
  gpsRestored,
  background,
  stop,
  periodic,
}

extension CheckpointReasonWire on CheckpointReason {
  String get wire => switch (this) {
        CheckpointReason.start => 'START',
        CheckpointReason.pause => 'PAUSE',
        CheckpointReason.resume => 'RESUME',
        CheckpointReason.lap => 'LAP',
        CheckpointReason.activity => 'ACTIVITY',
        CheckpointReason.gpsLost => 'GPS_LOST',
        CheckpointReason.gpsRestored => 'GPS_RESTORED',
        CheckpointReason.background => 'BACKGROUND',
        CheckpointReason.stop => 'STOP',
        CheckpointReason.periodic => 'PERIODIC',
      };

  static CheckpointReason fromWire(String? value) {
    return switch (value) {
      'PAUSE' => CheckpointReason.pause,
      'RESUME' => CheckpointReason.resume,
      'LAP' => CheckpointReason.lap,
      'ACTIVITY' => CheckpointReason.activity,
      'GPS_LOST' => CheckpointReason.gpsLost,
      'GPS_RESTORED' => CheckpointReason.gpsRestored,
      'BACKGROUND' => CheckpointReason.background,
      'STOP' => CheckpointReason.stop,
      'PERIODIC' => CheckpointReason.periodic,
      _ => CheckpointReason.start,
    };
  }
}

/// Durable snapshot of live recording state (separate from raw GPS points).
class SessionCheckpoint {
  const SessionCheckpoint({
    required this.sessionId,
    required this.elapsedMs,
    required this.movingMs,
    required this.pausedTotalMs,
    required this.distanceM,
    required this.steps,
    required this.activity,
    required this.lapCount,
    required this.paused,
    required this.reason,
    required this.updatedAt,
    this.lastLatitude,
    this.lastLongitude,
    this.lastGpsTimestampMs,
  });

  final String sessionId;
  final int elapsedMs;
  final int movingMs;
  final int pausedTotalMs;
  final double distanceM;
  final int steps;
  final String activity;
  final int lapCount;
  final bool paused;
  final CheckpointReason reason;
  final DateTime updatedAt;
  final double? lastLatitude;
  final double? lastLongitude;
  final int? lastGpsTimestampMs;

  Map<String, Object?> toJson() => {
        'sessionId': sessionId,
        'elapsedMs': elapsedMs,
        'movingMs': movingMs,
        'pausedTotalMs': pausedTotalMs,
        'distanceM': distanceM,
        'steps': steps,
        'activity': activity,
        'lapCount': lapCount,
        'paused': paused,
        'reason': reason.wire,
        'updatedAtMs': updatedAt.millisecondsSinceEpoch,
        'lastLatitude': lastLatitude,
        'lastLongitude': lastLongitude,
        'lastGpsTimestampMs': lastGpsTimestampMs,
      };

  factory SessionCheckpoint.fromJson(Map<String, Object?> json) {
    double? d(Object? v) => v is num ? v.toDouble() : null;
    int i(Object? v) => v is num ? v.round() : 0;

    return SessionCheckpoint(
      sessionId: '${json['sessionId'] ?? ''}',
      elapsedMs: i(json['elapsedMs']),
      movingMs: i(json['movingMs']),
      pausedTotalMs: i(json['pausedTotalMs']),
      distanceM: d(json['distanceM']) ?? 0,
      steps: i(json['steps']),
      activity: '${json['activity'] ?? 'auto'}',
      lapCount: i(json['lapCount']),
      paused: json['paused'] == true,
      reason: CheckpointReasonWire.fromWire(json['reason'] as String?),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        i(json['updatedAtMs']),
        isUtc: false,
      ),
      lastLatitude: d(json['lastLatitude']),
      lastLongitude: d(json['lastLongitude']),
      lastGpsTimestampMs: json['lastGpsTimestampMs'] is num
          ? (json['lastGpsTimestampMs'] as num).round()
          : null,
    );
  }
}

/// Event-first checkpoint policy with a short periodic fallback.
abstract final class CheckpointPolicy {
  static const periodicEvery = Duration(seconds: 15);

  /// Important state changes always write immediately.
  static bool isImmediate(CheckpointReason reason) =>
      reason != CheckpointReason.periodic;

  /// Periodic writes only when [every] has elapsed since [lastWriteAt].
  static bool shouldPeriodicWrite({
    required DateTime now,
    required DateTime? lastWriteAt,
    Duration every = periodicEvery,
  }) {
    if (lastWriteAt == null) return true;
    return !now.isBefore(lastWriteAt.add(every));
  }
}
