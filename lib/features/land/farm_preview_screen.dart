import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/copy.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../data/map/device_traces.dart';
import '../../data/repositories/farm_repository.dart';
import '../../data/repositories/session_repository.dart';
import '../../domain/engines/farm_animal.dart';
import '../../domain/engines/farm_birth.dart';
import '../../domain/engines/farm_crop.dart';
import '../../domain/engines/farm_life.dart';
import '../../domain/engines/farm_scene_ui.dart';
import '../../domain/engines/farm_slot_move.dart';
import '../../domain/engines/farm_water.dart';
import '../../domain/engines/land_city.dart';
import '../../domain/models/farm/animal.dart';
import '../../domain/models/farm/crop.dart';
import '../../domain/models/farm/farm_slot.dart';
import '../../domain/models/farm/farm_state.dart';
import '../../domain/models/farm/farm_tier.dart';
import '../../widgets/farm_resource_bar.dart';
import '../../widgets/farm_scene_v2.dart';

void openFarmPreview(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const Scaffold(
        backgroundColor: BalmiColors.paper,
        body: SafeArea(child: FarmPreviewScreen()),
      ),
    ),
  );
}

/// Farm only — no land path map, no registration guide.
class FarmPreviewScreen extends StatefulWidget {
  const FarmPreviewScreen({super.key});

  @override
  State<FarmPreviewScreen> createState() => _FarmPreviewScreenState();
}

class _FarmPreviewScreenState extends State<FarmPreviewScreen> {
  DeviceTraces _traces = const DeviceTraces(lines: [], loops: [], loopAreaM2: 0);
  List<BuildingRow> _buildings = [];
  List<LivestockRow> _herds = [];
  WaterLedger _water = const WaterLedger(
    watersTotal: 0,
    wateredToday: false,
    hasQualifyingWalkToday: false,
  );
  FarmSnapshot? _farm;
  Map<String, CropDefinition> _crops = {};
  Map<String, AnimalDefinition> _animals = {};
  var _loaded = false;
  var _busy = false;
  var _watering = false;
  WaterApplyResult? _pendingWater;

  FarmRepository get _farmRepo => FarmRepository(context.read<AppDatabase>());

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
    final farmRepo = _farmRepo;
    await farmRepo.ensureInitialized();
    final cropList = await farmRepo.listCropDefinitions();
    final animalList = await farmRepo.listAnimalDefinitions();
    final ownedTiles = _ownedTileCount(buildings.length, traces);
    final snapshot = await farmRepo.loadSnapshot(ownedTileCount: ownedTiles);
    if (!mounted) return;
    setState(() {
      _traces = traces;
      _buildings = buildings;
      _herds = herds;
      _water = water;
      _farm = snapshot;
      _crops = {for (final c in cropList) c.cropId: c};
      _animals = {for (final a in animalList) a.animalId: a};
      _loaded = true;
    });
  }

  int _ownedTileCount(int buildingCount, DeviceTraces traces) {
    final fromLoops = traces.loops.isNotEmpty ? 2 : 0;
    return (buildingCount + fromLoops).clamp(1, 12);
  }

  Iterable<FarmKind> get _builtKinds =>
      _buildings.map((b) => FarmKind.fromWire(b.type));

  Iterable<HerdKind> get _herdKinds =>
      _herds.map((h) => HerdKind.fromWire(h.kind));

  Future<void> _waterFarm() async {
    if (_busy || _watering || !_water.canWater) return;
    setState(() => _busy = true);
    final center = _traces.center;
    final result = await context.read<SessionRepository>().applyWater(
          lat: center.latitude,
          lng: center.longitude,
        );
    if (!mounted) return;
    if (!result.applied) {
      setState(() => _busy = false);
      _toast(switch (_water.state) {
        WaterState.alreadyWatered => BalmiCopy.wateredToday,
        WaterState.needWalk => BalmiCopy.waterNeedWalk,
        WaterState.ready => BalmiCopy.waterNeedWalk,
      });
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      await _revealWater(result);
      return;
    }
    _pendingWater = result;
    setState(() => _watering = true);
  }

  Future<void> _onWateringComplete() async {
    final result = _pendingWater;
    _pendingWater = null;
    if (result == null) return;
    await _revealWater(result);
  }

  Future<void> _revealWater(WaterApplyResult result) async {
    await _load();
    if (!mounted) return;
    setState(() {
      _watering = false;
      _busy = false;
    });
    if (result.raised != null) {
      final raised = result.raised!;
      _toast(switch (raised) {
        HerdKind.sheep => BalmiCopy.farmFieldSheep,
        HerdKind.cattle => BalmiCopy.farmFieldCow,
        _ => farmBirthToastForHerd(raised),
      });
    } else if (result.unlocked != null) {
      _toast('${result.unlocked!.label} · ${BalmiCopy.waterDone}');
    } else {
      _toast(BalmiCopy.waterDone);
    }
  }

  Future<void> _applyResource(FarmResourceType type) async {
    final farm = _farm;
    if (farm == null || _busy) return;
    final amount = kFarmResourceApplyAmount;
    final balance = switch (type) {
      FarmResourceType.water => farm.resources.waterBalance,
      FarmResourceType.feed => farm.resources.feedBalance,
      FarmResourceType.nutrient => farm.resources.nutrientBalance,
    };
    if (balance < amount) {
      _toast(BalmiCopy.farmV2NeedResource);
      return;
    }

    final slot = pickSlotForResource(
      slots: farm.slots,
      type: type,
      crops: _crops,
      animals: _animals,
    );
    if (slot == null) {
      _toast(BalmiCopy.farmV2NoSlot);
      return;
    }

    setState(() => _busy = true);
    final updated = await _farmRepo.applyResourceToSlot(
      slotRowId: slot.id,
      type: type,
      amount: amount,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (updated == null) {
      _toast(BalmiCopy.farmV2ApplyFailed);
      return;
    }
    await _load();
    _toast(BalmiCopy.farmV2Applied);
  }

  Future<void> _onSlotTap(FarmSlotView slot) async {
    if (_busy || !slot.unlocked) return;
    final occ = slot.occupant;
    if (occ != null && !occ.isEmpty) {
      if (occ.occupantType == OccupantType.crop && occ.cropId != null) {
        final crop = _crops[occ.cropId!];
        if (crop != null) {
          final hint = cropGrowthHint(
            crop: crop,
            cumulativeWater: occ.cumulativeWater,
            cumulativeNutrient: occ.cumulativeNutrient,
            currentStageIndex: occ.currentStageIndex,
            isDormant: occ.isDormant,
          );
          if (hint == CropGrowthHint.readyHarvest) {
            setState(() => _busy = true);
            final result = await _farmRepo.harvestCrop(occ.id);
            if (!mounted) return;
            setState(() => _busy = false);
            if (result != null) {
              await _load();
              _toast('${crop.nameKr} 수확 · 코인 ${result.coin}');
            }
          }
        }
      } else if (occ.occupantType == OccupantType.livestock) {
        setState(() => _busy = true);
        final result = await _farmRepo.collectAnimalYield(occ.id);
        if (!mounted) return;
        setState(() => _busy = false);
        if (result != null) {
          await _load();
          final animal = _animals[result.animalId];
          _toast('${animal?.nameKr ?? "가축"} 산출 · 코인 ${result.coin}');
        }
      }
      return;
    }

    setState(() => _busy = true);
    late final String toast;
    if (slot.template.slotType == SlotType.crop) {
      await _farmRepo.plantCrop(
        slotId: slot.template.slotId,
        cropId: 'crop_carrot_01',
      );
      toast = farmBirthToastForCrop();
    } else {
      final owned = _farm?.slots
              .map((s) => s.occupant?.animalId)
              .whereType<String>() ??
          const <String>[];
      final next = pickNextAdoptableAnimal(
        catalog: _animals.values.toList(),
        occupiedAnimalIds: owned,
        farmLevel: _farm?.farm.farmLevel ?? 1,
      );
      if (next == null) {
        setState(() => _busy = false);
        _toast(BalmiCopy.farmV2NoAdoptable);
        return;
      }
      await _farmRepo.adoptAnimal(
        slotId: slot.template.slotId,
        animalId: next.animalId,
      );
      toast = farmBirthToastForAnimal(next);
    }
    if (!mounted) return;
    setState(() => _busy = false);
    await _load();
    _toast(toast);
  }

  Future<void> _onSlotMove(FarmSlotView from, FarmSlotView to) async {
    if (_busy) return;
    if (!canRearrangeFarmSlots(from: from, to: to)) {
      _toast(BalmiCopy.farmV2MoveFailed);
      return;
    }
    final owned = _ownedTileCount(_buildings.length, _traces);
    setState(() => _busy = true);
    final ok = await _farmRepo.moveOccupantBetweenSlots(
      fromSlotId: from.template.slotId,
      toSlotId: to.template.slotId,
      ownedTileCount: owned,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      _toast(BalmiCopy.farmV2MoveFailed);
      return;
    }
    await _load();
    _toast(BalmiCopy.farmV2Moved);
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

  String get _statusLine {
    final farm = _farm;
    if (farm == null) return _water.progressLine;
    return primaryFarmStatusLine(
          snapshot: farm,
          crops: _crops,
          animals: _animals,
        ) ??
        _water.progressLine;
  }

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
                    BalmiCopy.farmTitle,
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
            child: !_loaded || _farm == null
                ? const SizedBox(
                    height: 240,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : FarmSceneV2(
                    snapshot: _farm!,
                    crops: _crops,
                    animals: _animals,
                    buildings: _builtKinds.toList(),
                    herds: _herdKinds.toList(),
                    caredToday: _water.wateredToday,
                    watering: _watering,
                    onWateringComplete: _onWateringComplete,
                    onSlotTap: _onSlotTap,
                    onSlotMove: _onSlotMove,
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
                if (_farm != null) ...[
                  FarmResourceBar(
                    balances: _farm!.resources,
                    busy: _busy,
                    onApply: _applyResource,
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  _statusLine,
                  textAlign: TextAlign.center,
                  style: BalmiTheme.body(
                    size: 14,
                    weight: FontWeight.w800,
                    color: BalmiColors.sage,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed:
                      _water.canWater && !_busy && !_watering ? _waterFarm : null,
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}
