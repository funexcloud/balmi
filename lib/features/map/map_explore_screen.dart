import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../data/map/device_traces.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/models/activity.dart';
import '../../widgets/osm_trace_map.dart';
import '../../widgets/session_row.dart';
import '../land/land_preview_screen.dart';
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
    final repo = context.read<SessionRepository>();
    final pts = await repo.pointsForSession(id);
    final line = [
      for (final p in pts)
        if (p.hAccM == null || p.hAccM! <= 40) LatLng(p.lat, p.lng),
    ];
    if (!mounted) return;
    setState(() {
      _selected = id;
      _highlight = line.length >= 2 ? line : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: !_loaded
              ? const Center(child: CircularProgressIndicator(color: BalmiColors.plum))
              : OsmTraceMap(
                  traces: _traces,
                  highlight: _highlight,
                  emptyLabel: BalmiCopy.mapEmpty,
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  BalmiCopy.mapExplore,
                  style: BalmiTheme.body(size: 15, weight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: () => openLandPreview(context),
                child: const Text(BalmiCopy.landTab),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            itemCount: _sessions.length,
            separatorBuilder: (_, _) => const Divider(height: 1, color: BalmiColors.line),
            itemBuilder: (context, i) {
              final s = _sessions[i];
              return SessionRow(
                startedAt: s.startedAt,
                activityLabel: ActivityKind.fromWire(s.activity).label,
                distM: s.totalDistM,
                selected: s.id == _selected,
                onTap: () => _select(s.id),
                onLongPress: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SessionDetailScreen(sessionId: s.id)),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
