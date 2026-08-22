import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/engines/sync_backoff.dart';
import '../../domain/models/sport.dart';
import '../db/app_database.dart';

class IntegrityStats {
  const IntegrityStats({
    required this.totalPoints,
    required this.excludedLowQuality,
    this.lastSyncedAt,
  });

  final int totalPoints;
  final int excludedLowQuality;
  final DateTime? lastSyncedAt;
}

class SessionRepository {
  SessionRepository(this.db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase db;
  final Uuid _uuid;

  String newId() => _uuid.v4();

  Future<void> putKv(String key, String value) {
    return db
        .into(db.appKv)
        .insertOnConflictUpdate(AppKvCompanion.insert(key: key, value: value));
  }

  Future<String?> getKv(String key) async {
    final row = await (db.select(db.appKv)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<Session> createSession({
    required bool trackMode,
    int? trackSpecM,
    DateTime? startedAt,
  }) async {
    final id = newId();
    final start = startedAt ?? DateTime.now();
    await db.into(db.sessions).insert(
          SessionsCompanion.insert(
            id: id,
            startedAt: start,
            status: SessionStatus.recording.wire,
            trackMode: Value(trackMode),
            trackSpecM: Value(trackSpecM),
          ),
        );
    await db.into(db.segments).insert(
          SegmentsCompanion.insert(
            sessionId: id,
            seq: 0,
            sport: Sport.walk.wire,
            judgedSport: Sport.walk.wire,
            startedAt: start,
          ),
        );
    return (await sessionById(id))!;
  }

  Future<Session?> sessionById(String id) {
    return (db.select(db.sessions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<Session?> findRecording() async {
    final rows = await (db.select(db.sessions)
          ..where((t) => t.status.equals(SessionStatus.recording.wire))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .get();
    return rows.isEmpty ? null : rows.first;
  }

  Stream<List<Session>> watchHistory() {
    return (db.select(db.sessions)
          ..where(
            (t) => t.status.isIn([
              SessionStatus.closed.wire,
              SessionStatus.recovered.wire,
            ]),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .watch();
  }

  Future<int> maxSeq(String sessionId) async {
    final expr = db.points.seq.max();
    final q = db.selectOnly(db.points)
      ..addColumns([expr])
      ..where(db.points.sessionId.equals(sessionId));
    final row = await q.getSingle();
    return row.read(expr) ?? 0;
  }

  Future<Point?> lastAccuratePoint(String sessionId, double maxAcc) async {
    final rows = await (db.select(db.points)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([(t) => OrderingTerm.desc(t.seq)])
          ..limit(80))
        .get();
    for (final p in rows) {
      final acc = p.hAccM;
      if (acc != null && acc <= maxAcc) return p;
    }
    return null;
  }

  Future<List<Point>> pointsForSession(String sessionId) {
    return (db.select(db.points)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
        .get();
  }

  Future<void> insertPoint({
    required String sessionId,
    required int seq,
    required DateTime ts,
    required double lat,
    required double lng,
    double? alt,
    double? speedMs,
    double? hAccM,
    double? cadenceSpm,
    int? satCount,
  }) {
    return db.into(db.points).insert(
          PointsCompanion.insert(
            sessionId: sessionId,
            seq: seq,
            ts: ts,
            lat: lat,
            lng: lng,
            alt: Value(alt),
            speedMs: Value(speedMs),
            hAccM: Value(hAccM),
            cadenceSpm: Value(cadenceSpm),
            satCount: Value(satCount),
            synced: const Value(0),
          ),
        );
  }

  Future<void> enqueueChunk({
    required String sessionId,
    required int seqFrom,
    required int seqTo,
    DateTime? now,
  }) {
    return db.into(db.syncQueue).insert(
          SyncQueueCompanion.insert(
            chunkId: newId(),
            sessionId: sessionId,
            seqFrom: seqFrom,
            seqTo: seqTo,
            nextRetryAt: now ?? DateTime.now(),
          ),
        );
  }

  Future<int> maxQueuedSeqTo(String sessionId) async {
    final expr = db.syncQueue.seqTo.max();
    final q = db.selectOnly(db.syncQueue)
      ..addColumns([expr])
      ..where(db.syncQueue.sessionId.equals(sessionId));
    final row = await q.getSingle();
    return row.read(expr) ?? 0;
  }

  Future<void> enqueueLeftover(String sessionId, {DateTime? now}) async {
    final maxSeq = await this.maxSeq(sessionId);
    if (maxSeq <= 0) return;
    final queuedTo = await maxQueuedSeqTo(sessionId);
    if (maxSeq <= queuedTo) return;
    await enqueueChunk(
      sessionId: sessionId,
      seqFrom: queuedTo + 1,
      seqTo: maxSeq,
      now: now,
    );
  }

  Future<List<SyncQueueData>> dueChunks({DateTime? now}) {
    final t = now ?? DateTime.now();
    return (db.select(db.syncQueue)
          ..where((q) => q.nextRetryAt.isSmallerOrEqualValue(t))
          ..orderBy([(q) => OrderingTerm.asc(q.nextRetryAt)]))
        .get();
  }

  Future<int> pendingChunkCount() async {
    final expr = db.syncQueue.chunkId.count();
    final q = db.selectOnly(db.syncQueue)..addColumns([expr]);
    final row = await q.getSingle();
    return row.read(expr) ?? 0;
  }

  Future<int> syncedPointCount(String sessionId) async {
    final expr = db.points.id.count();
    final q = db.selectOnly(db.points)
      ..addColumns([expr])
      ..where(db.points.sessionId.equals(sessionId) & db.points.synced.equals(1));
    final row = await q.getSingle();
    return row.read(expr) ?? 0;
  }

  Future<int> pendingChunkCountFor(String sessionId) async {
    final expr = db.syncQueue.chunkId.count();
    final q = db.selectOnly(db.syncQueue)
      ..addColumns([expr])
      ..where(db.syncQueue.sessionId.equals(sessionId));
    final row = await q.getSingle();
    return row.read(expr) ?? 0;
  }

  Future<List<Point>> pointsInRange(String sessionId, int from, int to) {
    return (db.select(db.points)
          ..where(
            (t) =>
                t.sessionId.equals(sessionId) &
                t.seq.isBiggerOrEqualValue(from) &
                t.seq.isSmallerOrEqualValue(to),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
        .get();
  }

  Future<void> markChunkFailed(SyncQueueData chunk, {DateTime? now}) async {
    final nextCount = chunk.retryCount + 1;
    await (db.update(db.syncQueue)..where((t) => t.chunkId.equals(chunk.chunkId)))
        .write(
      SyncQueueCompanion(
        retryCount: Value(nextCount),
        nextRetryAt: Value(
          SyncBackoff.nextRetryAt(chunk.retryCount, now: now),
        ),
      ),
    );
  }

  Future<void> markChunkSynced(SyncQueueData chunk, {DateTime? now}) async {
    await (db.update(db.points)
          ..where(
            (t) =>
                t.sessionId.equals(chunk.sessionId) &
                t.seq.isBiggerOrEqualValue(chunk.seqFrom) &
                t.seq.isSmallerOrEqualValue(chunk.seqTo),
          ))
        .write(const PointsCompanion(synced: Value(1)));
    await (db.delete(db.syncQueue)
          ..where((t) => t.chunkId.equals(chunk.chunkId)))
        .go();
  }

  Future<List<Segment>> segmentsFor(String sessionId) {
    return (db.select(db.segments)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([(t) => OrderingTerm.asc(t.seq)]))
        .get();
  }

  Future<Segment?> openSegment(String sessionId) async {
    final rows = await (db.select(db.segments)
          ..where(
            (t) => t.sessionId.equals(sessionId) & t.endedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.seq)])
          ..limit(1))
        .get();
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> addToOpenSegment(String sessionId, double deltaM) async {
    final open = await openSegment(sessionId);
    if (open == null) return;
    await (db.update(db.segments)..where((t) => t.id.equals(open.id))).write(
      SegmentsCompanion(distM: Value(open.distM + deltaM)),
    );
  }

  Future<void> splitSegment({
    required String sessionId,
    required Sport newSport,
    required DateTime at,
  }) async {
    final open = await openSegment(sessionId);
    if (open != null) {
      await (db.update(db.segments)..where((t) => t.id.equals(open.id))).write(
        SegmentsCompanion(endedAt: Value(at)),
      );
    }
    final nextSeq = (open?.seq ?? -1) + 1;
    await db.into(db.segments).insert(
          SegmentsCompanion.insert(
            sessionId: sessionId,
            seq: nextSeq,
            sport: newSport.wire,
            judgedSport: newSport.wire,
            startedAt: at,
          ),
        );
  }

  Future<void> overrideSegmentSport(int segmentId, Sport sport) async {
    await (db.update(db.segments)..where((t) => t.id.equals(segmentId))).write(
      SegmentsCompanion(
        sport: Value(sport.wire),
        userOverride: const Value(1),
      ),
    );
  }

  Future<void> insertLap({
    required String sessionId,
    required int lapNo,
    required DateTime crossedAt,
    required double lapTimeS,
    required double lapDistM,
  }) {
    return db.into(db.laps).insert(
          LapsCompanion.insert(
            sessionId: sessionId,
            lapNo: lapNo,
            crossedAt: crossedAt,
            lapTimeS: lapTimeS,
            lapDistM: lapDistM,
          ),
        );
  }

  Future<List<Lap>> lapsFor(String sessionId) {
    return (db.select(db.laps)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([(t) => OrderingTerm.asc(t.lapNo)]))
        .get();
  }

  Future<void> updateDistances({
    required String sessionId,
    required double totalDistM,
    required double walkDistM,
    required double runDistM,
  }) {
    return (db.update(db.sessions)..where((t) => t.id.equals(sessionId))).write(
      SessionsCompanion(
        totalDistM: Value(totalDistM),
        walkDistM: Value(walkDistM),
        runDistM: Value(runDistM),
      ),
    );
  }

  Future<void> recomputeWalkRunFromSegments(String sessionId) async {
    final segs = await segmentsFor(sessionId);
    var walk = 0.0;
    var run = 0.0;
    for (final s in segs) {
      if (s.sport == Sport.run.wire) {
        run += s.distM;
      } else {
        walk += s.distM;
      }
    }
    final session = await sessionById(sessionId);
    final total = session?.totalDistM ?? (walk + run);
    await updateDistances(
      sessionId: sessionId,
      totalDistM: total,
      walkDistM: walk,
      runDistM: run,
    );
  }

  Future<void> closeSession(
    String sessionId, {
    required SessionStatus status,
    DateTime? endedAt,
  }) async {
    final at = endedAt ?? DateTime.now();
    final open = await openSegment(sessionId);
    if (open != null) {
      await (db.update(db.segments)..where((t) => t.id.equals(open.id))).write(
        SegmentsCompanion(endedAt: Value(at)),
      );
    }
    await enqueueLeftover(sessionId, now: at);
    await (db.update(db.sessions)..where((t) => t.id.equals(sessionId))).write(
      SessionsCompanion(
        status: Value(status.wire),
        endedAt: Value(at),
      ),
    );
  }

  Future<IntegrityStats> integrity(String sessionId) async {
    final all = await pointsForSession(sessionId);
    final excluded = all.where((p) {
      final acc = p.hAccM;
      return acc == null || acc > 30;
    }).length;
    DateTime? last;
    for (final p in all) {
      if (p.synced == 1) {
        if (last == null || p.ts.isAfter(last)) last = p.ts;
      }
    }
    return IntegrityStats(
      totalPoints: all.length,
      excludedLowQuality: excluded,
      lastSyncedAt: last,
    );
  }

  Future<Map<Sport, Duration>> sportDurations(String sessionId) async {
    final segs = await segmentsFor(sessionId);
    final out = {Sport.walk: Duration.zero, Sport.run: Duration.zero};
    for (final s in segs) {
      final end = s.endedAt ?? DateTime.now();
      final d = end.difference(s.startedAt);
      final sport = Sport.fromWire(s.sport);
      out[sport] = (out[sport] ?? Duration.zero) + d;
    }
    return out;
  }
}
