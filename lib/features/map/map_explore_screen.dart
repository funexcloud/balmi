import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../data/map/device_traces.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/models/activity.dart';
import '../../widgets/osm_trace_map.dart';
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              BalmiCopy.landOnMapHint,
              style: BalmiTheme.body(size: 11, color: BalmiColors.sub),
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const Scaffold(
                  backgroundColor: BalmiColors.paper,
                  body: SafeArea(child: LandPreviewScreen()),
                ),
              ),
            );
          },
          child: const Text(BalmiCopy.landTab),
        ),
        Expanded(
          flex: 2,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _sessions.length,
            itemBuilder: (context, i) {
              final s = _sessions[i];
              final active = s.id == _selected;
              return ListTile(
                selected: active,
                title: Text(
                  '${formatDateTime(s.startedAt)} · ${ActivityKind.fromWire(s.activity).label}',
                  style: BalmiTheme.body(size: 14, weight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${formatKm(s.totalDistM)}km',
                  style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
                ),
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
