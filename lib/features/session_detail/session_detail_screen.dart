import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../data/map/session_trace_line.dart';
import '../../data/repositories/activity_recovery_store.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/models/activity.dart';
import '../../domain/models/sport.dart';
import '../../widgets/activity_pills.dart';
import '../../widgets/balmi_app_bar.dart';
import '../../widgets/balmi_wordmark.dart';
import '../../widgets/osm_trace_map.dart';
import '../activity_recovery/activity_recovery_controller.dart';
import '../activity_recovery/activity_recovery_flow.dart';

class SessionDetailScreen extends StatefulWidget {
  const SessionDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  Session? _session;
  List<LatLng> _line = [];
  LatLng? _lastPoint;
  List<Segment> _segments = [];
  List<Lap> _laps = [];
  Duration _walk = Duration.zero;
  Duration _run = Duration.zero;
  ActivityRecoveryRecord? _recovery;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<SessionRepository>();
    final recovery = context.read<ActivityRecoveryController>();
    final session = await repo.sessionById(widget.sessionId);
    final segs = await repo.segmentsFor(widget.sessionId);
    final laps = await repo.lapsFor(widget.sessionId);
    final durs = await repo.sportDurations(widget.sessionId);
    final pts = await repo.pointsForSession(widget.sessionId);
    final line = traceLineFromPoints(pts);
    final recoveryRow = await recovery.latestForWorkout(widget.sessionId);
    LatLng? last;
    if (line.isNotEmpty) {
      last = line.last;
    } else if (pts.isNotEmpty) {
      last = LatLng(pts.last.lat, pts.last.lng);
    }
    if (!mounted) return;
    setState(() {
      _session = session;
      _line = line;
      _lastPoint = last;
      _segments = segs;
      _laps = laps;
      _walk = durs[Sport.walk] ?? Duration.zero;
      _run = durs[Sport.run] ?? Duration.zero;
      _recovery = recoveryRow;
    });
  }

  Duration _sessionDuration(Session s) {
    final end = s.endedAt ?? DateTime.now();
    final d = end.difference(s.startedAt);
    return d.isNegative ? Duration.zero : d;
  }

  double? _avgSpeedKmh(Session s, Duration duration) {
    final h = duration.inMilliseconds / 3600000.0;
    if (h <= 0 || s.totalDistM <= 0) return null;
    return (s.totalDistM / 1000) / h;
  }

  Future<void> _openRecovery() async {
    final s = _session;
    if (s == null) return;
    final duration = _sessionDuration(s);
    await openActivityRecoveryFlow(
      context,
      workoutSessionId: s.id,
      activity: ActivityKind.fromWire(s.activity),
      distanceM: s.totalDistM,
      duration: duration,
      avgSpeedKmh: _avgSpeedKmh(s, duration),
      resumeCheckId: _recovery?.id,
    );
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = _session;
    return Scaffold(
      backgroundColor: BalmiColors.paper,
      appBar: const BalmiAppBar(),
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: ActivityPills.glyphOf(
                    ActivityKind.fromWire(s.activity),
                    color: BalmiColors.ink,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  walkRunResultLine(
                    walkDuration: _walk,
                    walkMeters: s.walkDistM,
                    runDuration: _run,
                    runMeters: s.runDistM,
                  ),
                  style: BalmiTheme.body(size: 16, weight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  '${formatKm(s.totalDistM)} km · ${formatDateTime(s.startedAt)}',
                  style: BalmiTheme.body(size: 14, color: BalmiColors.sub),
                ),
                if (s.endedAt != null) ...[
                  const SizedBox(height: 14),
                  ActivityRecoveryEntryCard(
                    workoutSessionId: s.id,
                    activity: ActivityKind.fromWire(s.activity),
                    distanceM: s.totalDistM,
                    duration: _sessionDuration(s),
                    avgSpeedKmh: _avgSpeedKmh(s, _sessionDuration(s)),
                    existingStatus: _recovery?.status,
                    onStart: _openRecovery,
                    onContinue: _openRecovery,
                  ),
                ],
                const SizedBox(height: 12),
                SessionTraceMap(
                  points: _line,
                  lastPoint: _lastPoint,
                  emptyLabel: BalmiCopy.mapEmpty,
                  fitToPath: true,
                ),
                const HeartbeatDivider(),
                ..._segments.map(_segmentTile),
                if (_laps.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ..._laps.map(
                    (l) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${l.lapNo}바퀴 · ${formatLapTts(lapNo: l.lapNo, lapTimeS: l.lapTimeS)}',
                        style: BalmiTheme.body(size: 15, weight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        '${l.lapDistM.round()} m',
                        style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
                      ),
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
        title: Text(
          sport == Sport.run ? BalmiCopy.run : BalmiCopy.walk,
          style: BalmiTheme.body(size: 15, weight: FontWeight.w800),
        ),
        subtitle: Text(
          '${formatKm(seg.distM)} km · ${BalmiCopy.originalJudgment}: '
          '${judged == Sport.run ? BalmiCopy.run : BalmiCopy.walk}'
          '${seg.userOverride == 1 ? ' · 수정됨' : ''}',
          style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
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
