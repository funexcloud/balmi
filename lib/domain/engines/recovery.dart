import '../models/activity.dart';
import '../models/sport.dart';
import 'session_checkpoint.dart';

class RecoverableSession {
  const RecoverableSession({
    required this.id,
    required this.status,
    required this.startedAt,
    this.activity = 'auto',
    this.totalDistM = 0,
    this.pointCount = 0,
    this.lastPointAt,
    this.checkpoint,
  });

  final String id;
  final SessionStatus status;
  final DateTime startedAt;
  final String activity;
  final double totalDistM;
  final int pointCount;
  final DateTime? lastPointAt;
  final SessionCheckpoint? checkpoint;

  String get activityLabel => ActivityKind.fromWire(activity).label;

  double get displayDistM =>
      checkpoint != null && checkpoint!.distanceM > 0
          ? checkpoint!.distanceM
          : totalDistM;

  Duration get displayElapsed {
    if (checkpoint != null && checkpoint!.elapsedMs > 0) {
      return Duration(milliseconds: checkpoint!.elapsedMs);
    }
    final last = lastPointAt ?? startedAt;
    final d = last.difference(startedAt);
    return d.isNegative ? Duration.zero : d;
  }

  DateTime get lastRecordedAt =>
      lastPointAt ?? checkpoint?.updatedAt ?? startedAt;
}

/// Finds in-progress recordings after crash / force-stop.
class SessionRecovery {
  static RecoverableSession? lastRecording(
    Iterable<RecoverableSession> sessions,
  ) {
    final open = sessions
        .where((s) => s.status == SessionStatus.recording)
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    if (open.isEmpty) return null;
    return open.first;
  }

  /// Crash left an open session — never treat as completed.
  static bool needsRecovery(RecoverableSession? session) {
    if (session == null) return false;
    return session.status == SessionStatus.recording;
  }

  /// Soft integrity: recoverable if we have points and/or a checkpoint.
  static bool isRecoverable(RecoverableSession session) {
    if (session.status != SessionStatus.recording) return false;
    if (session.pointCount > 0) return true;
    if (session.checkpoint != null) return true;
    // Brand-new session with no points yet is still resume-worthy.
    return true;
  }
}
