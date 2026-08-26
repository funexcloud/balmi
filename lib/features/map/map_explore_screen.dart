import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../data/location/map_location.dart';
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
  final _mapKey = GlobalKey<OsmTraceMapState>();
  DeviceTraces _traces = const DeviceTraces(lines: [], loops: [], loopAreaM2: 0);
  List<Session> _sessions = [];
  List<LatLng>? _highlight;
  String? _selected;
  LatLng? _userLocation;
  String? _locationHint;
  var _loaded = false;
  var _locating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.wait([_loadTraces(), _resolveLocation()]);
    if (!mounted) return;
    // Keep first session selected in the log list, but do not highlight/fit
    // it on open — the map tab should open on 내 주변 (GPS).
    setState(() {
      _loaded = true;
      if (_sessions.isNotEmpty) _selected = _sessions.first.id;
    });
  }

  Future<void> _loadTraces() async {
    final repo = context.read<SessionRepository>();
    final sessions = await repo.closedSessions();
    final traces = await loadDeviceTraces(repo);
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _traces = traces;
    });
  }

  /// GPS pin for "내 주변". Session trail endpoints are not used as the pin.
  DeviceTraces get _mapTraces => DeviceTraces(
        lines: _traces.lines,
        loops: _traces.loops,
        loopAreaM2: _traces.loopAreaM2,
        pathBandM2: _traces.pathBandM2,
        lastPoint: _userLocation,
        centroid: _traces.centroid,
      );

  Future<void> _resolveLocation({bool fromUser = false}) async {
    if (_locating) return;
    setState(() {
      _locating = true;
      if (_userLocation == null) {
        _locationHint = BalmiCopy.mapWaitingLocation;
      }
    });
    try {
      final err = await MapLocation.ensurePermission();
      if (!mounted) return;
      if (err != null) {
        setState(() {
          _locationHint = err;
          _locating = false;
        });
        return;
      }
      final pos = await MapLocation.currentLatLng();
      if (!mounted) return;
      if (pos == null) {
        setState(() {
          _locationHint = BalmiCopy.mapLocationUnavailable;
          _locating = false;
        });
        return;
      }
      setState(() {
        _userLocation = pos;
        _locationHint = null;
        _locating = false;
      });
      if (fromUser || _highlight == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapKey.currentState?.recenterOnUser();
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationHint = BalmiCopy.mapLocationUnavailable;
        _locating = false;
      });
    }
  }

  Future<void> _recenter() async {
    if (_userLocation == null) {
      await _resolveLocation(fromUser: true);
      return;
    }
    _mapKey.currentState?.recenterOnUser();
    // Refresh fix in background so the next recenter is fresher.
    unawaited(_resolveLocation(fromUser: true));
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
    final emptyLabel = !_traces.hasLine
        ? (_locationHint ?? BalmiCopy.mapEmpty)
        : _locationHint;

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
                      key: _mapKey,
                      traces: _mapTraces,
                      highlight: _highlight,
                      emptyLabel: emptyLabel,
                      preferUserLocation: true,
                    ),
            ),
          ),
          if (_traces.hasLine && _locationHint != null)
            Positioned(
              left: 12,
              right: 72,
              bottom: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BalmiColors.line),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    _locationHint!,
                    style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Column(
              children: [
                CircleAction(
                  icon: _locating ? Icons.gps_not_fixed : Icons.gps_fixed,
                  label: BalmiCopy.recenterMap,
                  onTap: _recenter,
                ),
                const SizedBox(height: 10),
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
