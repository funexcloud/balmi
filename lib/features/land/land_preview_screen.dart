import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../data/map/device_traces.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/stubs/future_features.dart';
import '../../domain/engines/farm_life.dart';
import '../../domain/engines/land_city.dart';
import '../../domain/engines/workout_stats.dart';
import '../../widgets/osm_trace_map.dart';

void openLandPreview(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const Scaffold(
        backgroundColor: BalmiColors.paper,
        body: SafeArea(child: LandPreviewScreen()),
      ),
    ),
  );
}

/// 내가 밟은 땅 — OSM traces + 짓기(㎡) + 기르기(오늘 걸음).
class LandPreviewScreen extends StatefulWidget {
  const LandPreviewScreen({super.key});

  @override
  State<LandPreviewScreen> createState() => _LandPreviewScreenState();
}

class _LandPreviewScreenState extends State<LandPreviewScreen> {
  DeviceTraces _traces = const DeviceTraces(lines: [], loops: [], loopAreaM2: 0);
  List<BuildingRow> _buildings = [];
  List<LivestockRow> _herds = [];
  var _todayWalkM = 0.0;
  FarmKind? _selectedFarm;
  HerdKind? _selectedHerd;
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
    final herds = await repo.listLivestock();
    final workouts = await repo.closedWorkouts();
    final today = summarizePeriod(inLocalDay(workouts, DateTime.now()));
    if (!mounted) return;
    setState(() {
      _traces = traces;
      _buildings = buildings;
      _herds = herds;
      _todayWalkM = today.distM;
      _loaded = true;
    });
  }

  LandBudget get _budget {
    final spent = spentFromCosts(_buildings.map((b) => b.costM2));
    return _traces.budget(spent);
  }

  FeedBudget get _feed {
    final spent = spentFeedToday(
      _herds.map((h) => HerdFeed(raisedAt: h.raisedAt, feedWalkM: h.feedWalkM)),
      DateTime.now(),
    );
    return FeedBudget(todayWalkM: _todayWalkM, spentFeedM: spent);
  }

  Iterable<FarmKind> get _builtKinds =>
      _buildings.map((b) => FarmKind.fromWire(b.type));

  Iterable<HerdKind> get _herdKinds =>
      _herds.map((h) => HerdKind.fromWire(h.kind));

  Future<void> _build(FarmKind kind, {LatLng? at}) async {
    if (!_traces.hasLine && at == null) {
      _toast(BalmiCopy.farmNeedFix);
      return;
    }
    if (!_budget.canBuild(kind)) {
      _toast(BalmiCopy.noBudget);
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

  Future<void> _raise(HerdKind kind, {LatLng? at}) async {
    final block = raiseBlock(
      kind: kind,
      buildings: _builtKinds,
      existing: _herdKinds,
      remainingFeedM: _feed.remainingM,
    );
    if (block != RaiseBlock.ok) {
      _toast(switch (block) {
        RaiseBlock.needBuilding => BalmiCopy.raiseNeedBuilding,
        RaiseBlock.atCapacity => BalmiCopy.raiseAtCapacity,
        RaiseBlock.needFeed => BalmiCopy.raiseNeedFeed,
        RaiseBlock.ok => BalmiCopy.raiseAction,
      });
      return;
    }
    final point = at ?? _herdPoint(kind, _herds.length);
    await context.read<SessionRepository>().insertLivestock(
          kind: kind,
          lat: point.latitude,
          lng: point.longitude,
        );
    await _load();
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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

  LatLng _herdPoint(HerdKind kind, int index) {
    final homes = _buildings
        .where((b) => FarmKind.fromWire(b.type) == kind.requires)
        .toList();
    if (homes.isEmpty) return _placePoint(_buildings.length + index);
    final home = homes[index % homes.length];
    final ang = index * 0.8;
    return LatLng(
      home.lat + 0.00008 * math.cos(ang),
      home.lng + 0.00008 * math.sin(ang),
    );
  }

  void _onMapTap(LatLng at) {
    final herd = _selectedHerd;
    if (herd != null) {
      _raise(herd, at: at);
      return;
    }
    final farm = _selectedFarm;
    if (farm != null) _build(farm, at: at);
  }

  @override
  Widget build(BuildContext context) {
    final budget = _budget;
    final feed = _feed;
    final earned = budget.earnedM2.round();
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(8, 4, 20, 6),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back, color: BalmiColors.ink),
                ),
                Expanded(
                  child: Text(
                    BalmiCopy.landSteppedTitle,
                    style: BalmiTheme.body(size: 20, weight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 300,
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
                    herds: [
                      for (final h in _herds)
                        HerdMark(
                          point: LatLng(h.lat, h.lng),
                          kind: HerdKind.fromWire(h.kind),
                        ),
                    ],
                  ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LandStatsRow(
                  earnedM2: earned,
                  remainingM2: budget.remainingM2.round(),
                  feedKm: formatKm(feed.todayWalkM),
                  feedNote: _herds.isEmpty
                      ? null
                      : (feed.caredToday ? BalmiCopy.herdsFed : BalmiCopy.herdsHungry),
                ),
                const SizedBox(height: 16),
                Text(BalmiCopy.farmTend, style: BalmiTheme.body(size: 15, weight: FontWeight.w800)),
                Text(BalmiCopy.farmPlaceHint, style: BalmiTheme.body(size: 12, color: BalmiColors.sub)),
                const SizedBox(height: 8),
                _FarmGrid(
                  budget: budget,
                  selected: _selectedFarm,
                  onSelect: (k) => setState(() {
                    _selectedFarm = k;
                    _selectedHerd = null;
                  }),
                  onBuild: _build,
                ),
                const SizedBox(height: 14),
                Text(BalmiCopy.raiseAction, style: BalmiTheme.body(size: 15, weight: FontWeight.w800)),
                Text(BalmiCopy.raisePlaceHint, style: BalmiTheme.body(size: 12, color: BalmiColors.sub)),
                const SizedBox(height: 8),
                _HerdGrid(
                  feed: feed,
                  buildings: _builtKinds.toList(),
                  existing: _herdKinds.toList(),
                  selected: _selectedHerd,
                  onSelect: (k) => setState(() {
                    _selectedHerd = k;
                    _selectedFarm = null;
                  }),
                  onRaise: _raise,
                ),
                const SizedBox(height: 14),
                Text(BalmiCopy.myBuildings, style: BalmiTheme.body(size: 14, weight: FontWeight.w800)),
                if (_buildings.isEmpty)
                  Text(BalmiCopy.landEmptyRecent, style: BalmiTheme.body(size: 13, color: BalmiColors.sub)),
                for (final b in _buildings)
                  Text(
                    '${FarmKind.fromWire(b.type).label} · ${b.costM2.round()}㎡',
                    style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
                  ),
                const SizedBox(height: 8),
                Text(BalmiCopy.myHerds, style: BalmiTheme.body(size: 14, weight: FontWeight.w800)),
                if (_herds.isEmpty)
                  Text(BalmiCopy.farmHomeReady, style: BalmiTheme.body(size: 13, color: BalmiColors.sub)),
                for (final h in _herds)
                  Text(
                    '${HerdKind.fromWire(h.kind).label} · ${h.feedWalkM.round()}m',
                    style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
                  ),
                const SizedBox(height: 8),
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    iconColor: BalmiColors.plum,
                    collapsedIconColor: BalmiColors.sub,
                    title: Text(
                      BalmiCopy.landGuide,
                      style: BalmiTheme.body(size: 14, weight: FontWeight.w800),
                    ),
                    children: [
                      _guide(BalmiCopy.landPreview),
                      _guide(BalmiCopy.landFoot),
                      _guide(BalmiCopy.landBudgetHint),
                      _guide(BalmiCopy.farmSpendHint),
                      _guide(BalmiCopy.herdUnlockHint),
                      _guide(BalmiCopy.e01),
                      _guide(BalmiCopy.e02),
                      _guide(BalmiCopy.e03),
                      _guide(BalmiCopy.e04),
                      if (!FutureFeatures.territoryEnabled) const SizedBox(height: 2),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _guide(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: BalmiTheme.body(size: 12, color: BalmiColors.sub, height: 1.45)),
      ),
    );
  }
}

class _LandStatsRow extends StatelessWidget {
  const _LandStatsRow({
    required this.earnedM2,
    required this.remainingM2,
    required this.feedKm,
    this.feedNote,
  });

  final int earnedM2;
  final int remainingM2;
  final String feedKm;
  final String? feedNote;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _cell(
                value: '$earnedM2',
                unit: '㎡',
                label: BalmiCopy.farmBudget,
                primary: true,
              ),
            ),
            Expanded(
              child: _cell(
                value: '$remainingM2',
                unit: '㎡',
                label: BalmiCopy.remainingArea,
              ),
            ),
            Expanded(
              child: _cell(
                value: feedKm,
                unit: 'km',
                label: BalmiCopy.todayFeed,
              ),
            ),
          ],
        ),
        if (feedNote != null) ...[
          const SizedBox(height: 6),
          Text(feedNote!, style: BalmiTheme.body(size: 12, color: BalmiColors.sage)),
        ],
      ],
    );
  }

  Widget _cell({
    required String value,
    required String unit,
    required String label,
    bool primary = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: BalmiTheme.tracked(size: 10, trackingEm: 0.08)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BalmiTheme.num(size: primary ? 28 : 18),
              ),
            ),
            const SizedBox(width: 2),
            Text(unit, style: BalmiTheme.num(size: primary ? 13 : 11, weight: FontWeight.w700)),
          ],
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
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 1.7,
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
          padding: const EdgeInsets.fromLTRB(10, 8, 8, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(farmIcon(kind), size: 18, color: farmTint(kind)),
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
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
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

class _HerdGrid extends StatelessWidget {
  const _HerdGrid({
    required this.feed,
    required this.buildings,
    required this.existing,
    required this.selected,
    required this.onSelect,
    required this.onRaise,
  });

  final FeedBudget feed;
  final List<FarmKind> buildings;
  final List<HerdKind> existing;
  final HerdKind? selected;
  final ValueChanged<HerdKind> onSelect;
  final Future<void> Function(HerdKind kind) onRaise;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 1.7,
      children: [
        for (final k in HerdKind.tiers)
          _HerdTile(
            kind: k,
            block: raiseBlock(
              kind: k,
              buildings: buildings,
              existing: existing,
              remainingFeedM: feed.remainingM,
            ),
            selected: selected == k,
            onSelect: () => onSelect(k),
            onRaise: () => onRaise(k),
          ),
      ],
    );
  }
}

class _HerdTile extends StatelessWidget {
  const _HerdTile({
    required this.kind,
    required this.block,
    required this.selected,
    required this.onSelect,
    required this.onRaise,
  });

  final HerdKind kind;
  final RaiseBlock block;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onRaise;

  @override
  Widget build(BuildContext context) {
    final ready = block == RaiseBlock.ok;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? BalmiColors.sage : BalmiColors.line,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 8, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(herdIcon(kind), size: 18, color: herdTint(kind)),
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
                '${kind.requires.label} · ${kind.feedWalkM.round()}m',
                style: BalmiTheme.body(size: 11, color: BalmiColors.sub),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: ready ? onRaise : null,
                  child: Text(
                    BalmiCopy.raiseAction,
                    style: BalmiTheme.body(
                      size: 13,
                      weight: FontWeight.w800,
                      color: ready ? BalmiColors.sage : BalmiColors.sub,
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
