import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme.dart';
import '../data/map/device_traces.dart';
import '../domain/engines/land_city.dart';

class FarmMark {
  const FarmMark({required this.point, required this.kind});

  final LatLng point;
  final FarmKind kind;
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

class OsmTraceMap extends StatefulWidget {
  const OsmTraceMap({
    super.key,
    required this.traces,
    this.highlight,
    this.emptyLabel,
    this.buildings = const [],
    this.onTap,
  });

  final DeviceTraces traces;
  final List<LatLng>? highlight;
  final String? emptyLabel;
  final List<FarmMark> buildings;
  final ValueChanged<LatLng>? onTap;

  @override
  State<OsmTraceMap> createState() => _OsmTraceMapState();
}

class _OsmTraceMapState extends State<OsmTraceMap> {
  final _map = MapController();
  var _ready = false;

  @override
  void didUpdateWidget(covariant OsmTraceMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_ready) _fit();
  }

  void _fit() {
    final focus = widget.highlight;
    final pts = <LatLng>[
      if (focus != null && focus.length >= 2) ...focus,
      if (focus == null)
        for (final line in widget.traces.lines)
          if (line.length >= 2) ...line,
      for (final b in widget.buildings) b.point,
    ];
    if (pts.length < 2) {
      _map.move(widget.traces.center, widget.traces.hasLine ? 15 : 11);
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
    return Stack(
      children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: widget.traces.center,
            initialZoom: widget.traces.hasLine ? 14 : 11,
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
                      color: BalmiColors.plum.withValues(alpha: 0.16),
                      borderColor: BalmiColors.plum.withValues(alpha: 0.55),
                      borderStrokeWidth: 1.5,
                    ),
                ],
              ),
            PolylineLayer(
              polylines: [
                for (final line in widget.traces.lines)
                  Polyline(
                    points: line,
                    color: BalmiColors.plumLt,
                    strokeWidth: 3,
                  ),
                if (highlight != null && highlight.length >= 2)
                  Polyline(
                    points: highlight,
                    color: BalmiColors.plum,
                    strokeWidth: 4.5,
                  ),
              ],
            ),
            MarkerLayer(
              markers: [
                for (final b in widget.buildings)
                  Marker(
                    point: b.point,
                    width: 40,
                    height: 44,
                    alignment: Alignment.bottomCenter,
                    child: _FarmSprite(kind: b.kind),
                  ),
              ],
            ),
            SimpleAttributionWidget(
              source: const Text('OpenStreetMap'),
              backgroundColor: BalmiColors.paper.withValues(alpha: 0.82),
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
                  color: BalmiColors.paper.withValues(alpha: 0.92),
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

class _FarmSprite extends StatelessWidget {
  const _FarmSprite({required this.kind});

  final FarmKind kind;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: BalmiColors.paper,
            shape: BoxShape.circle,
            border: Border.all(color: farmTint(kind), width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(farmIcon(kind), size: 18, color: farmTint(kind)),
          ),
        ),
        Text(
          kind.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: BalmiColors.ink,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}
