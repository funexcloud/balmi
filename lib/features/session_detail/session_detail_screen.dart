import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/format.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/models/sport.dart';

class SessionDetailScreen extends StatefulWidget {
  const SessionDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  Session? _session;
  List<Segment> _segments = [];
  List<Lap> _laps = [];
  Duration _walk = Duration.zero;
  Duration _run = Duration.zero;
  int _totalPoints = 0;
  int _excluded = 0;
  DateTime? _lastSynced;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<SessionRepository>();
    final session = await repo.sessionById(widget.sessionId);
    final segs = await repo.segmentsFor(widget.sessionId);
    final laps = await repo.lapsFor(widget.sessionId);
    final durs = await repo.sportDurations(widget.sessionId);
    final integrity = await repo.integrity(widget.sessionId);
    if (!mounted) return;
    setState(() {
      _session = session;
      _segments = segs;
      _laps = laps;
      _walk = durs[Sport.walk] ?? Duration.zero;
      _run = durs[Sport.run] ?? Duration.zero;
      _totalPoints = integrity.totalPoints;
      _excluded = integrity.excludedLowQuality;
      _lastSynced = integrity.lastSyncedAt;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = _session;
    return Scaffold(
      appBar: AppBar(title: const Text('기록 상세')),
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  walkRunResultLine(
                    walkDuration: _walk,
                    walkMeters: s.walkDistM,
                    runDuration: _run,
                    runMeters: s.runDistM,
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('${formatKm(s.totalDistM)} km · ${formatDateTime(s.startedAt)}'),
                const SizedBox(height: 24),
                Text(BalmiCopy.integrity, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('${BalmiCopy.totalPoints}: $_totalPoints'),
                Text('${BalmiCopy.excludedPoints}: $_excluded'),
                Text(
                  '${BalmiCopy.lastSynced}: ${_lastSynced == null ? BalmiCopy.neverSynced : formatDateTime(_lastSynced!)}',
                ),
                const SizedBox(height: 24),
                Text('구간', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                ..._segments.map(_segmentTile),
                if (_laps.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('랩', style: Theme.of(context).textTheme.titleLarge),
                  ..._laps.map(
                    (l) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${l.lapNo}바퀴 · ${formatLapTts(lapNo: l.lapNo, lapTimeS: l.lapTimeS)}'),
                      subtitle: Text('${l.lapDistM.round()} m'),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _segmentTile(Segment seg) {
    final sport = Sport.fromWire(seg.sport);
    final judged = Sport.fromWire(seg.judgedSport);
    return Card(
      child: ListTile(
        title: Text(sport == Sport.run ? BalmiCopy.run : BalmiCopy.walk),
        subtitle: Text(
          '${formatKm(seg.distM)} km · ${BalmiCopy.originalJudgment}: '
          '${judged == Sport.run ? BalmiCopy.run : BalmiCopy.walk}'
          '${seg.userOverride == 1 ? ' · 수정됨' : ''}',
        ),
        trailing: TextButton(
          onPressed: () async {
            final next = sport == Sport.run ? Sport.walk : Sport.run;
            final repo = context.read<SessionRepository>();
            await repo.overrideSegmentSport(seg.id, next);
            await repo.recomputeWalkRunFromSegments(widget.sessionId);
            if (!mounted) return;
            await _load();
          },
          child: const Text(BalmiCopy.overrideSport),
        ),
      ),
    );
  }
}
