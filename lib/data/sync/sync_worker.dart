import 'dart:async';

import '../repositories/session_repository.dart';
import 'sync_client.dart';

/// Drains [sync_queue] with backoff. Call [resume] on app start.
class SyncWorker {
  SyncWorker(this.repo, {this.client = const OfflineSyncClient()});

  final SessionRepository repo;
  final SyncClient client;

  Timer? _timer;
  bool _busy = false;

  void start({Duration tick = const Duration(seconds: 5)}) {
    _timer?.cancel();
    _timer = Timer.periodic(tick, (_) => tickOnce());
    unawaited(tickOnce());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> tickOnce() async {
    if (_busy) return;
    _busy = true;
    try {
      final due = await repo.dueChunks();
      for (final chunk in due) {
        final points =
            await repo.pointsInRange(chunk.sessionId, chunk.seqFrom, chunk.seqTo);
        final ok = await client.upload(
          PointChunk(
            sessionId: chunk.sessionId,
            seqFrom: chunk.seqFrom,
            seqTo: chunk.seqTo,
            points: points,
          ),
        );
        if (ok) {
          await repo.markChunkSynced(chunk);
        } else {
          await repo.markChunkFailed(chunk);
        }
      }
    } finally {
      _busy = false;
    }
  }
}
