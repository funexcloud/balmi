import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme.dart';
import '../data/map/device_traces.dart';
import '../domain/engines/farm_life.dart';
import '../domain/engines/land_city.dart';

class FarmMark {
  const FarmMark({required this.point, required this.kind});

  final LatLng point;
  final FarmKind kind;
}

class HerdMark {
  const HerdMark({required this.point, required this.kind});

  final LatLng point;
  final HerdKind kind;
}

IconData farmIcon(FarmKind kind) => switch (kind) {
      FarmKind.pastureFence => Icons.grass,
      FarmKind.barn => Icons.agriculture,
      FarmKind.farmhouse => Icons.cottage,
      FarmKind.villageStore => Icons.warehouse,
    };

Color farmTint(FarmKind kind) => switch (kind) {
      FarmKind.pastureFence => BalmiColors.sage,
      FarmKind.barn => BalmiColors.amber,
      FarmKind.farmhouse => BalmiColors.plum,
      FarmKind.villageStore => BalmiColors.ink,
    };

IconData herdIcon(HerdKind kind) => switch (kind) {
      HerdKind.sheep => Icons.pets,
      HerdKind.chicken => Icons.emoji_nature,
      HerdKind.garden => Icons.yard,
      HerdKind.cattle => Icons.spa,
    };

Color herdTint(HerdKind kind) => farmTint(kind.requires);

class SessionTraceMap extends StatelessWidget {
  const SessionTraceMap({
    super.key,
    required this.points,
    this.lastPoint,
    this.emptyLabel,
    this.height = 220,
    this.osmKey,
    this.fitToPath = false,
  });

  final List<LatLng> points;
  final LatLng? lastPoint;
  final String? emptyLabel;
  final double? height;
  final GlobalKey<OsmTraceMapState>? osmKey;
  final bool fitToPath;

  @override
  Widget build(BuildContext context) {
    final pin = lastPoint ?? (points.isEmpty ? null : points.last);
    final map = ClipRRect(
      borderRadius: BorderRadius.circular(BalmiTheme.cardRadius),
      child: OsmTraceMap(
        key: osmKey,
        traces: DeviceTraces(
          lines: points.length >= 2 ? [points] : const [],
          loops: const [],
          loopAreaM2: 0,
          lastPoint: pin,
        ),
        highlight: points.length >= 2 ? points : null,
        emptyLabel: pin == null ? emptyLabel : null,
        fitToPath: fitToPath,
      ),
    );
    if (height == null) return map;
    return SizedBox(height: height, child: map);
  }
}

class OsmTraceMap extends StatefulWidget {
  const OsmTraceMap({
    super.key,
    required this.traces,
    this.highlight,
    this.emptyLabel,
    this.buildings = const [],
    this.herds = const [],
    this.onTap,
    this.fitToPath = false,
    this.preferUserLocation = false,
  });

  final DeviceTraces traces;
  final List<LatLng>? highlight;
  final String? emptyLabel;
  final List<FarmMark> buildings;
  final List<HerdMark> herds;
  final ValueChanged<LatLng>? onTap;
  final bool fitToPath;

  /// When true (map tab "내 주변"), center on [DeviceTraces.lastPoint]
  /// instead of fitting historical paths — unless a [highlight] is selected.
  final bool preferUserLocation;

  @override
  State<OsmTraceMap> createState() => OsmTraceMapState();
}

class OsmTraceMapState extends State<OsmTraceMap> {
  final _map = MapController();
  var _ready = false;

  LatLng get _pinOrCenter =>
      widget.traces.lastPoint ?? widget.traces.center;

  @override
  void didUpdateWidget(covariant OsmTraceMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_ready) return;
    if (widget.fitToPath) {
      final oldLen = oldWidget.highlight?.length ?? 0;
      final newLen = widget.highlight?.length ?? 0;
      final pinChanged = oldWidget.traces.lastPoint != widget.traces.lastPoint;
      if (oldLen != newLen || pinChanged) {
        _fit();
      }
      return;
    }
    if (widget.preferUserLocation) {
      final highlightChanged = oldWidget.highlight != widget.highlight;
      final pinAppeared =
          oldWidget.traces.lastPoint == null && widget.traces.lastPoint != null;
      final pinMoved = oldWidget.traces.lastPoint != widget.traces.lastPoint &&
          widget.traces.lastPoint != null &&
          oldWidget.highlight == widget.highlight;
      if (highlightChanged || pinAppeared) {
        _fit();
      } else if (pinMoved && widget.highlight == null) {
        recenterOnUser();
      }
      return;
    }
    final hadPin = oldWidget.traces.lastPoint != null;
    final hasPin = widget.traces.lastPoint != null;
    if (!hadPin && hasPin) recenterOnUser();
  }

  void recenterOnUser() {
    if (!_ready) return;
    _map.move(_pinOrCenter, 16);
  }

  void resetNorth() {
    if (!_ready) return;
    _map.rotate(0);
  }

  void _fit() {
    final focus = widget.highlight;
    if (widget.preferUserLocation) {
      if (focus != null && focus.length >= 2) {
        _map.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(focus),
            padding: const EdgeInsets.all(36),
          ),
        );
        return;
      }
      if (widget.traces.lastPoint != null) {
        _map.move(widget.traces.lastPoint!, 16);
        return;
      }
    }
    final pts = <LatLng>[
      if (focus != null && focus.length >= 2) ...focus,
      if (focus == null)
        for (final line in widget.traces.lines)
          if (line.length >= 2) ...line,
      for (final b in widget.buildings) b.point,
      for (final h in widget.herds) h.point,
    ];
    if (pts.length < 2) {
      final pin = _pinOrCenter;
      _map.move(pin, widget.traces.lastPoint != null ? 16 : 11);
      return;
    }
    _map.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(pts),
        padding: const EdgeInsets.all(36),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final highlight = widget.highlight;
    final initial = widget.preferUserLocation && widget.traces.lastPoint != null
        ? widget.traces.lastPoint!
        : widget.traces.center;
    final initialZoom =
        widget.preferUserLocation && widget.traces.lastPoint != null
            ? 16.0
            : (widget.traces.hasLine ? 14.0 : 11.0);
    return Stack(
      children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: initial,
            initialZoom: initialZoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
            onTap: widget.onTap == null ? null : (pos, latlng) => widget.onTap!(latlng),
            onMapReady: () {
              _ready = true;
              _fit();
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'im.balmi.app',
            ),
            if (widget.traces.loops.isNotEmpty)
              PolygonLayer(
                polygons: [
                  for (final loop in widget.traces.loops)
                    Polygon(
                      points: loop,
                      color: BalmiColors.ink.withValues(alpha: 0.12),
                      borderColor: BalmiColors.ink.withValues(alpha: 0.4),
                      borderStrokeWidth: 1.5,
                    ),
                ],
              ),
            PolylineLayer(
              polylines: [
                for (final line in widget.traces.lines)
                  Polyline(
                    points: line,
                    color: BalmiColors.sub,
                    strokeWidth: 3,
                  ),
                if (highlight != null && highlight.length >= 2)
                  Polyline(
                    points: highlight,
                    color: BalmiColors.ink,
                    strokeWidth: 4.5,
                  ),
              ],
            ),
            MarkerLayer(
              markers: [
                if (widget.traces.lastPoint != null)
                  Marker(
                    point: widget.traces.lastPoint!,
                    width: 18,
                    height: 18,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: BalmiColors.potato,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                for (final b in widget.buildings)
                  Marker(
                    point: b.point,
                    width: 40,
                    height: 44,
                    alignment: Alignment.bottomCenter,
                    child: _FarmSprite(kind: b.kind),
                  ),
                for (final h in widget.herds)
                  Marker(
                    point: h.point,
                    width: 40,
                    height: 44,
                    alignment: Alignment.bottomCenter,
                    child: _HerdSprite(kind: h.kind),
                  ),
              ],
            ),
          ],
        ),
        if (!widget.traces.hasLine && widget.emptyLabel != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BalmiColors.line),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    widget.emptyLabel!,
                    style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HerdSprite extends StatelessWidget {
  const _HerdSprite({required this.kind});

  final HerdKind kind;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: kind.label,
      child: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: herdTint(kind), width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(herdIcon(kind), size: 18, color: herdTint(kind)),
          ),
        ),
      ],
    ),
    );
  }
}

class _FarmSprite extends StatelessWidget {
  const _FarmSprite({required this.kind});

  final FarmKind kind;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: kind.label,
      child: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: farmTint(kind), width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(farmIcon(kind), size: 18, color: farmTint(kind)),
          ),
        ),
      ],
    ),
    );
  }
}
