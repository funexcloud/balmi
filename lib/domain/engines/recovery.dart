import '../models/sport.dart';

class RecoverableSession {
  const RecoverableSession({
    required this.id,
    required this.status,
    required this.startedAt,
  });

  final String id;
  final SessionStatus status;
  final DateTime startedAt;
}

/// Finds in-progress recordings after crash / force-stop.
class SessionRecovery {
  static RecoverableSession? lastRecording(Iterable<RecoverableSession> sessions) {
    final open = sessions
        .where((s) => s.status == SessionStatus.recording)
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    if (open.isEmpty) return null;
    return open.first;
  }
}
