import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../data/map/session_trace_line.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/engines/loop_area.dart';
import '../../domain/engines/session_land_reward.dart';
import '../../domain/models/activity.dart';
import '../../domain/models/sport.dart';
import '../../widgets/activity_pills.dart';
import '../../widgets/balmi_app_bar.dart';
import '../../widgets/balmi_wordmark.dart';
import '../../widgets/osm_trace_map.dart';

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
  SessionLandReward _land = SessionLandReward.none;

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
    final pts = await repo.pointsForSession(widget.sessionId);
    final line = traceLineFromPoints(pts);
    LatLng? last;
    if (line.isNotEmpty) {
      last = line.last;
    } else if (pts.isNotEmpty) {
      last = LatLng(pts.last.lat, pts.last.lng);
    }
    final geo = [for (final p in line) GeoPoint(p.latitude, p.longitude)];
    final land = session == null
        ? SessionLandReward.none
        : SessionLandReward.fromSession(
            totalDistM: session.totalDistM,
            path: geo,
          );
    if (!mounted) return;
    setState(() {
      _session = session;
      _line = line;
      _lastPoint = last;
      _segments = segs;
      _laps = laps;
      _walk = durs[Sport.walk] ?? Duration.zero;
      _run = durs[Sport.run] ?? Duration.zero;
      _land = land;
    });
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
                const SizedBox(height: 12),
                SessionTraceMap(
                  points: _line,
                  lastPoint: _lastPoint,
                  emptyLabel: BalmiCopy.mapEmpty,
                  fitToPath: true,
                ),
                const HeartbeatDivider(),
                ..._segments.asMap().entries.map(
                  (e) => _segmentTile(e.value, showLand: e.key == 0),
                ),
                if (_segments.isEmpty) _landRewardCard(),
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

  Widget _segmentTile(Segment seg, {required bool showLand}) {
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
        trailing: showLand ? _landRewardTrailing() : null,
      ),
    );
  }

  Widget _landRewardCard() {
    return Card(
      child: ListTile(
        title: Text(
          BalmiCopy.sessionLandReward,
          style: BalmiTheme.body(size: 15, weight: FontWeight.w800),
        ),
        trailing: _landRewardTrailing(),
      ),
    );
  }

  Widget _landRewardTrailing() {
    if (!_land.qualifies) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            BalmiCopy.sessionLandReward,
            style: BalmiTheme.body(
              size: 13,
              weight: FontWeight.w800,
              color: BalmiColors.potato,
            ),
          ),
          Text(
            BalmiCopy.sessionLandNone,
            style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
          ),
        ],
      );
    }
    final subtitle = _land.cellCount > 0
        ? '+${_land.cellCount}칸 · ${formatAreaM2(_land.earnedM2)}'
        : formatAreaM2(_land.earnedM2);
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          BalmiCopy.sessionLandReward,
          style: BalmiTheme.body(
            size: 13,
            weight: FontWeight.w800,
            color: BalmiColors.potato,
          ),
        ),
        Text(
          subtitle,
          style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
        ),
      ],
    );
  }
}
