import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../data/map/device_traces.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/stubs/future_features.dart';
import '../../domain/engines/land_city.dart';
import '../../widgets/osm_trace_map.dart';

/// 내가 밟은 땅 — OSM traces + farm 가꾸기 from earned ㎡.
class LandPreviewScreen extends StatefulWidget {
  const LandPreviewScreen({super.key});

  @override
  State<LandPreviewScreen> createState() => _LandPreviewScreenState();
}

class _LandPreviewScreenState extends State<LandPreviewScreen> {
  DeviceTraces _traces = const DeviceTraces(lines: [], loops: [], loopAreaM2: 0);
  List<BuildingRow> _buildings = [];
  FarmKind? _selected;
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<SessionRepository>();
    final traces = await loadDeviceTraces(repo);
    final buildings = await repo.listBuildings();
    if (!mounted) return;
    setState(() {
      _traces = traces;
      _buildings = buildings;
      _loaded = true;
    });
  }

  LandBudget get _budget {
    final spent = spentFromCosts(_buildings.map((b) => b.costM2));
    return _traces.budget(spent);
  }

  Future<void> _build(FarmKind kind, {LatLng? at}) async {
    if (!_traces.hasLine && at == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(BalmiCopy.farmNeedFix)),
      );
      return;
    }
    if (!_budget.canBuild(kind)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(BalmiCopy.noBudget)),
      );
      return;
    }
    final point = at ?? _placePoint(_buildings.length);
    await context.read<SessionRepository>().insertBuilding(
          kind: kind,
          lat: point.latitude,
          lng: point.longitude,
        );
    await _load();
  }

  LatLng _placePoint(int index) {
    final c = _traces.center;
    final ang = index * 0.95;
    final d = 0.00014 * (1 + index ~/ 4);
    return LatLng(
      c.latitude + d * math.cos(ang),
      c.longitude + d * math.sin(ang),
    );
  }

  void _onMapTap(LatLng at) {
    final kind = _selected;
    if (kind == null) return;
    _build(kind, at: at);
  }

  @override
  Widget build(BuildContext context) {
    final budget = _budget;
    final earned = budget.earnedM2.round();
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  BalmiCopy.registryKicker,
                  style: BalmiTheme.tracked(
                    size: 11,
                    trackingEm: 0.28,
                    color: BalmiColors.plum,
                    weight: FontWeight.w800,
                  ),
                ),
                Text(BalmiCopy.farmOwner, style: BalmiTheme.body(size: 13, color: BalmiColors.sage)),
                Text(BalmiCopy.landSteppedTitle, style: BalmiTheme.body(size: 22, weight: FontWeight.w800)),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('$earned', style: BalmiTheme.num(size: 36)),
                    Text('㎡', style: BalmiTheme.num(size: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        earned > 0 ? BalmiCopy.farmBudget : BalmiCopy.landEmptyArea,
                        style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${BalmiCopy.remainingArea} ${budget.remainingM2.round()}㎡',
                  style: BalmiTheme.body(size: 13, color: BalmiColors.plum),
                ),
                const SizedBox(height: 4),
                Text(
                  earned > 0 ? BalmiCopy.landBudgetHint : BalmiCopy.landEmptyArea,
                  style: BalmiTheme.body(size: 11, color: BalmiColors.sub),
                ),
                Text(BalmiCopy.farmSpendHint, style: BalmiTheme.body(size: 11, color: BalmiColors.sub)),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 280,
            child: !_loaded
                ? const Center(child: CircularProgressIndicator(color: BalmiColors.plum))
                : OsmTraceMap(
                    traces: _traces,
                    emptyLabel: BalmiCopy.landNoPath,
                    onTap: _onMapTap,
                    buildings: [
                      for (final b in _buildings)
                        FarmMark(
                          point: LatLng(b.lat, b.lng),
                          kind: FarmKind.fromWire(b.type),
                        ),
                    ],
                  ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(BalmiCopy.farmTend, style: BalmiTheme.body(size: 16, weight: FontWeight.w800)),
                Text(BalmiCopy.farmPlaceHint, style: BalmiTheme.body(size: 12, color: BalmiColors.sub)),
                const SizedBox(height: 8),
                _FarmGrid(
                  budget: budget,
                  selected: _selected,
                  onSelect: (k) => setState(() => _selected = k),
                  onBuild: _build,
                ),
                const SizedBox(height: 12),
                Text(BalmiCopy.myBuildings, style: BalmiTheme.body(size: 15, weight: FontWeight.w800)),
                if (_buildings.isEmpty)
                  Text(BalmiCopy.landEmptyRecent, style: BalmiTheme.body(size: 13, color: BalmiColors.sub)),
                for (final b in _buildings)
                  Text(
                    '${FarmKind.fromWire(b.type).label} · ${b.costM2.round()}㎡',
                    style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
                  ),
                const SizedBox(height: 8),
                Text(
                  _traces.hasLine ? BalmiCopy.landTracesHint : BalmiCopy.landNoPath,
                  style: BalmiTheme.body(size: 12, color: BalmiColors.sub),
                ),
                Text(BalmiCopy.landPreview, style: BalmiTheme.body(size: 11, color: BalmiColors.sub)),
                Text(BalmiCopy.landFoot, style: BalmiTheme.body(size: 11, color: BalmiColors.sub, height: 1.5)),
                Text(BalmiCopy.e01, style: BalmiTheme.body(size: 11, color: BalmiColors.sub)),
                Text(BalmiCopy.e02, style: BalmiTheme.body(size: 11, color: BalmiColors.sub)),
                Text(BalmiCopy.e03, style: BalmiTheme.body(size: 11, color: BalmiColors.sub)),
                Text(BalmiCopy.e04, style: BalmiTheme.body(size: 11, color: BalmiColors.sub)),
                if (!FutureFeatures.territoryEnabled) const SizedBox(height: 2),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FarmGrid extends StatelessWidget {
  const _FarmGrid({
    required this.budget,
    required this.selected,
    required this.onSelect,
    required this.onBuild,
  });

  final LandBudget budget;
  final FarmKind? selected;
  final ValueChanged<FarmKind> onSelect;
  final Future<void> Function(FarmKind kind) onBuild;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.35,
      children: [
        for (final k in FarmKind.tiers)
          _FarmTile(
            kind: k,
            budget: budget,
            selected: selected == k,
            onSelect: () => onSelect(k),
            onBuild: () => onBuild(k),
          ),
      ],
    );
  }
}

class _FarmTile extends StatelessWidget {
  const _FarmTile({
    required this.kind,
    required this.budget,
    required this.selected,
    required this.onSelect,
    required this.onBuild,
  });

  final FarmKind kind;
  final LandBudget budget;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    final open = budget.unlocked(kind);
    final ready = budget.canBuild(kind);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? BalmiColors.plum : BalmiColors.line,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(farmIcon(kind), size: 20, color: farmTint(kind)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      kind.label,
                      style: BalmiTheme.body(size: 13, weight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              Text(
                '${kind.costM2.round()}㎡ · ${open ? BalmiCopy.farmUnlocked : BalmiCopy.farmLocked}',
                style: BalmiTheme.body(size: 11, color: BalmiColors.sub),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: ready ? onBuild : null,
                  child: Text(
                    BalmiCopy.buildAction,
                    style: BalmiTheme.body(
                      size: 13,
                      weight: FontWeight.w800,
                      color: ready ? BalmiColors.plum : BalmiColors.sub,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
