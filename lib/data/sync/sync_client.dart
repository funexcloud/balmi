import '../db/app_database.dart';

class PointChunk {
  const PointChunk({
    required this.sessionId,
    required this.seqFrom,
    required this.seqTo,
    required this.points,
  });

  final String sessionId;
  final int seqFrom;
  final int seqTo;
  final List<Point> points;
}

/// Upload sink. Swap [OfflineSyncClient] for a real Supabase client later.
abstract class SyncClient {
  Future<bool> upload(PointChunk chunk);
}

/// No credentials: refuse upload so the queue and backoff keep working.
class OfflineSyncClient implements SyncClient {
  const OfflineSyncClient();

  @override
  Future<bool> upload(PointChunk chunk) async {
    // No Supabase URL/key in Release 1. Chunks stay queued.
    return false;
  }
}
