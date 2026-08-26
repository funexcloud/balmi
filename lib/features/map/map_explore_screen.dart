import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../data/map/device_traces.dart';
import '../../data/map/session_trace_line.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/engines/land_city.dart';
import '../../domain/models/activity.dart';
import '../../widgets/circle_action.dart';
import '../../widgets/osm_trace_map.dart';
import '../../widgets/session_row.dart';
import '../land/land_map_screen.dart';
import '../session_detail/session_detail_screen.dart';

class MapExploreScreen extends StatefulWidget {
  const MapExploreScreen({super.key});

  @override
  State<MapExploreScreen> createState() => _MapExploreScreenState();
}

class _MapExploreScreenState extends State<MapExploreScreen> {
  DeviceTraces _traces = const DeviceTraces(lines: [], loops: [], loopAreaM2: 0);
  List<Session> _sessions = [];
  List<LatLng>? _highlight;
  String? _selected;
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<SessionRepository>();
    final sessions = await repo.closedSessions();
    final traces = await loadDeviceTraces(repo);
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _traces = traces;
      _loaded = true;
    });
    if (sessions.isNotEmpty) {
      await _select(sessions.first.id);
    }
  }

  Future<void> _select(String id) async {
    Session? session;
    for (final s in _sessions) {
      if (s.id == id) session = s;
    }
    if (session != null && !qualifiesForLand(session.totalDistM)) {
      if (!mounted) return;
      setState(() {
        _selected = id;
        _highlight = null;
      });
      return;
    }
    final repo = context.read<SessionRepository>();
    final pts = await repo.pointsForSession(id);
    final line = traceLineFromPoints(pts);
    if (!mounted) return;
    setState(() {
      _selected = id;
      _highlight = line.length >= 2 ? line : null;
    });
  }

  Future<void> _openList() async {
    await showBalmiSheet(
      context: context,
      builder: (ctx) {
        if (_sessions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Text(BalmiCopy.mapEmpty, style: BalmiTheme.body(size: 14, color: BalmiColors.sub)),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            for (final s in _sessions)
              SessionRow(
                startedAt: s.startedAt,
                activityLabel: ActivityKind.fromWire(s.activity).label,
                distM: s.totalDistM,
                selected: s.id == _selected,
                onTap: () {
                  Navigator.pop(ctx);
                  _select(s.id);
                },
                onLongPress: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SessionDetailScreen(sessionId: s.id)),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(BalmiTheme.cardRadius),
              child: !_loaded
                  ? const ColoredBox(
                      color: BalmiColors.mist,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : OsmTraceMap(
                      traces: _traces,
                      highlight: _highlight,
                      emptyLabel: BalmiCopy.mapEmpty,
                    ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Column(
              children: [
                CircleAction(
                  icon: Icons.landscape_outlined,
                  label: BalmiCopy.landTab,
                  onTap: () => openLandMap(context),
                ),
                const SizedBox(height: 10),
                CircleAction(
                  icon: Icons.timeline,
                  label: BalmiCopy.workoutLogTab,
                  onTap: _openList,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
