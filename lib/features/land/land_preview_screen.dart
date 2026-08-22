import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../data/map/device_traces.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/stubs/future_features.dart';
import '../../domain/engines/farm_life.dart';
import '../../domain/engines/farm_water.dart';
import '../../domain/engines/land_city.dart';
import '../../widgets/farm_scene.dart';
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

/// 내가 밟은 땅 — farm scene + one daily 물주기, not a leftover-㎡ shop.
class LandPreviewScreen extends StatefulWidget {
  const LandPreviewScreen({super.key});

  @override
  State<LandPreviewScreen> createState() => _LandPreviewScreenState();
}

class _LandPreviewScreenState extends State<LandPreviewScreen> {
  DeviceTraces _traces = const DeviceTraces(lines: [], loops: [], loopAreaM2: 0);
  List<BuildingRow> _buildings = [];
  List<LivestockRow> _herds = [];
  WaterLedger _water = const WaterLedger(
    watersTotal: 0,
    wateredToday: false,
    hasQualifyingWalkToday: false,
  );
  var _loaded = false;
  var _busy = false;

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
    final water = await repo.loadWaterLedger();
    if (!mounted) return;
    setState(() {
      _traces = traces;
      _buildings = buildings;
      _herds = herds;
      _water = water;
      _loaded = true;
    });
  }

  Iterable<FarmKind> get _builtKinds =>
      _buildings.map((b) => FarmKind.fromWire(b.type));

  Iterable<HerdKind> get _herdKinds =>
      _herds.map((h) => HerdKind.fromWire(h.kind));

  Future<void> _waterFarm() async {
    if (_busy || !_water.canWater) return;
    setState(() => _busy = true);
    final center = _traces.center;
    final result = await context.read<SessionRepository>().applyWater(
          lat: center.latitude,
          lng: center.longitude,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    await _load();
    if (!result.applied) {
      _toast(switch (_water.state) {
        WaterState.alreadyWatered => BalmiCopy.wateredToday,
        WaterState.needWalk => BalmiCopy.waterNeedWalk,
        WaterState.ready => BalmiCopy.waterNeedWalk,
      });
      return;
    }
    if (result.unlocked != null) {
      _toast('${result.unlocked!.label} · ${BalmiCopy.waterDone}');
    } else if (result.raised != null) {
      _toast('${result.raised!.label} · ${BalmiCopy.waterDone}');
    } else {
      _toast(BalmiCopy.waterDone);
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String get _waterHint {
    return switch (_water.state) {
      WaterState.ready => BalmiCopy.farmPlaceHint,
      WaterState.alreadyWatered => BalmiCopy.wateredToday,
      WaterState.needWalk => BalmiCopy.waterNeedWalk,
    };
  }

  String get _nextLine => _water.progressLine;

  @override
  Widget build(BuildContext context) {
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
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          sliver: SliverToBoxAdapter(
            child: !_loaded
                ? const SizedBox(
                    height: 240,
                    child: Center(
                      child: CircularProgressIndicator(color: BalmiColors.plum),
                    ),
                  )
                : FarmScene(
                    buildings: _builtKinds.toList(),
                    herds: _herdKinds.toList(),
                    caredToday: _water.wateredToday,
                    height: 268,
                  ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _nextLine,
                  textAlign: TextAlign.center,
                  style: BalmiTheme.body(size: 14, weight: FontWeight.w800, color: BalmiColors.sage),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _water.canWater && !_busy ? _waterFarm : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: BalmiColors.sage,
                    disabledBackgroundColor: BalmiColors.line,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: BalmiColors.sub,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    BalmiCopy.waterAction,
                    style: BalmiTheme.body(
                      size: 18,
                      weight: FontWeight.w800,
                      color: _water.canWater ? Colors.white : BalmiColors.sub,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _waterHint,
                  textAlign: TextAlign.center,
                  style: BalmiTheme.body(size: 13, color: BalmiColors.sub),
                ),
                const SizedBox(height: 20),
                Text(
                  BalmiCopy.landWalkedPath,
                  style: BalmiTheme.body(size: 14, weight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 140,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: OsmTraceMap(
                      traces: _traces,
                      emptyLabel: BalmiCopy.landNoPath,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
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
                      _guide(BalmiCopy.farmSpendHint),
                      _guide(BalmiCopy.herdUnlockHint),
                      _guide(BalmiCopy.areaNotCash),
                      if (_buildings.isNotEmpty)
                        _guide(
                          '${BalmiCopy.myBuildings} · ${_buildings.map((b) => FarmKind.fromWire(b.type).label).join(', ')}',
                        ),
                      if (_herds.isNotEmpty)
                        _guide(
                          '${BalmiCopy.myHerds} · ${_herds.map((h) => HerdKind.fromWire(h.kind).label).join(', ')}',
                        ),
                      _guide(BalmiCopy.landFoot),
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
