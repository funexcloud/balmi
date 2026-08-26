import 'package:flutter/material.dart' show IconData, Icons;

import '../models/farm/animal.dart';
import '../models/farm/crop.dart';
import '../models/farm/farm_slot.dart';
import '../models/farm/farm_state.dart';
import '../models/farm/farm_tier.dart';
import 'farm_animal.dart';
import 'farm_crop.dart';
import 'farm_resource.dart';

/// Pick the single status sentence shown above farm actions (spec §7.5).
String? primaryFarmStatusLine({
  required FarmSnapshot snapshot,
  required Map<String, CropDefinition> crops,
  required Map<String, AnimalDefinition> animals,
  DateTime? now,
}) {
  final at = now ?? DateTime.now();
  String? best;
  var bestScore = -1.0;

  for (final slot in snapshot.slots) {
    if (!slot.unlocked) continue;
    final occ = slot.occupant;
    if (occ == null || occ.isEmpty || occ.isDormant) continue;

    if (occ.occupantType == OccupantType.crop && occ.cropId != null) {
      final crop = crops[occ.cropId!];
      if (crop == null) continue;
      final hint = cropGrowthHint(
        crop: crop,
        cumulativeWater: occ.cumulativeWater,
        cumulativeNutrient: occ.cumulativeNutrient,
        currentStageIndex: occ.currentStageIndex,
        isDormant: occ.isDormant,
      );
      final score = switch (hint) {
        CropGrowthHint.readyHarvest => 100.0,
        CropGrowthHint.needWater => 80.0,
        CropGrowthHint.needNutrient => 75.0,
        CropGrowthHint.ok => 40.0,
        CropGrowthHint.dormant => 0.0,
      };
      if (score > bestScore) {
        bestScore = score;
        best = cropStatusLine(
          crop: crop,
          cumulativeWater: occ.cumulativeWater,
          cumulativeNutrient: occ.cumulativeNutrient,
          currentStageIndex: occ.currentStageIndex,
          isDormant: occ.isDormant,
        );
      }
    } else if (occ.occupantType == OccupantType.livestock &&
        occ.animalId != null) {
      final animal = animals[occ.animalId!];
      if (animal == null) continue;
      final status = evaluateAnimal(
        animal: animal,
        cumulativeFeed: occ.cumulativeFeed,
        currentStageIndex: occ.currentStageIndex,
        lastYieldAt: occ.lastYieldAt,
        isDormant: occ.isDormant,
        now: at,
      );
      final score = switch (status.state) {
        AnimalYieldState.readyYield => 95.0,
        AnimalYieldState.needFeed => 70.0,
        AnimalYieldState.growing => 50.0,
        AnimalYieldState.cooldown => 20.0,
        AnimalYieldState.dormant => 0.0,
        AnimalYieldState.starving => 65.0,
      };
      if (score > bestScore) {
        bestScore = score;
        best = animalStatusLine(animal: animal, status: status);
      }
    }
  }

  if (best != null) return best;
  if (snapshot.resources.waterBalance > 0 ||
      snapshot.resources.feedBalance > 0 ||
      snapshot.resources.nutrientBalance > 0) {
    return '자원을 나눠 주면 작물과 가축이 자라요';
  }
  return '오늘 걸으면 사료·물·영양제를 받을 수 있어요';
}

/// Default apply amount per resource tap.
const kFarmResourceApplyAmount = 20;

FarmResourceType? resourceNeededBySlot({
  required UserFarmSlot occupant,
  required CropDefinition? crop,
  required AnimalDefinition? animal,
}) {
  if (occupant.isEmpty || occupant.isDormant) return null;
  if (occupant.occupantType == OccupantType.crop && crop != null) {
    final hint = cropGrowthHint(
      crop: crop,
      cumulativeWater: occupant.cumulativeWater,
      cumulativeNutrient: occupant.cumulativeNutrient,
      currentStageIndex: occupant.currentStageIndex,
      isDormant: occupant.isDormant,
    );
    return switch (hint) {
      CropGrowthHint.needWater => FarmResourceType.water,
      CropGrowthHint.needNutrient => FarmResourceType.nutrient,
      CropGrowthHint.readyHarvest => null,
      CropGrowthHint.ok => FarmResourceType.water,
      CropGrowthHint.dormant => null,
    };
  }
  if (occupant.occupantType == OccupantType.livestock && animal != null) {
    return FarmResourceType.feed;
  }
  return null;
}

UserFarmSlot? pickSlotForResource({
  required List<FarmSlotView> slots,
  required FarmResourceType type,
  required Map<String, CropDefinition> crops,
  required Map<String, AnimalDefinition> animals,
}) {
  for (final slot in slots) {
    if (!slot.unlocked) continue;
    final occ = slot.occupant;
    if (occ == null || occ.isEmpty || occ.isDormant) continue;
    final crop = occ.cropId != null ? crops[occ.cropId!] : null;
    final animal = occ.animalId != null ? animals[occ.animalId!] : null;
    final need = resourceNeededBySlot(
      occupant: occ,
      crop: crop,
      animal: animal,
    );
    if (need == type) return occ;
  }
  for (final slot in slots) {
    if (!slot.unlocked) continue;
    final occ = slot.occupant;
    if (occ == null || occ.isEmpty || occ.isDormant) continue;
    if (type == FarmResourceType.feed &&
        occ.occupantType == OccupantType.livestock) {
      return occ;
    }
    if (type != FarmResourceType.feed &&
        occ.occupantType == OccupantType.crop) {
      return occ;
    }
  }
  return null;
}

String slotDisplayLabel({
  required FarmSlotView slot,
  required CropDefinition? crop,
  required AnimalDefinition? animal,
  AnimalDefinition? nextAdoptable,
}) {
  if (!slot.unlocked) return '잠김';
  final occ = slot.occupant;
  if (occ == null || occ.isEmpty) {
    return slot.template.slotType == SlotType.crop
        ? '심기'
        : emptyLivestockSlotLabel(nextAdoptable);
  }
  if (occ.occupantType == OccupantType.crop && crop != null) {
    final stage = crop.stageAt(occ.currentStageIndex);
    return '${crop.nameKr} · ${stage?.stageName ?? "씨앗"}';
  }
  if (occ.occupantType == OccupantType.livestock && animal != null) {
    final stage = animal.stageAt(occ.currentStageIndex);
    final fallback = animal.startsAsEgg
        ? '계란'
        : (animal.animalId.contains('cow')
            ? '송아지'
            : (animal.animalId.contains('sheep') ? '새끼양' : '새끼'));
    return '${animal.nameKr} · ${stage?.stageName ?? fallback}';
  }
  return '비어 있음';
}

IconData slotIcon({
  required FarmSlotView slot,
  required CropDefinition? crop,
  required AnimalDefinition? animal,
}) {
  if (!slot.unlocked) return Icons.lock_outline;
  final occ = slot.occupant;
  if (occ == null || occ.isEmpty) {
    return slot.template.slotType == SlotType.crop
        ? Icons.grass_outlined
        : Icons.pets_outlined;
  }
  if (occ.occupantType == OccupantType.livestock) {
    final id = occ.animalId ?? '';
    if (id.contains('chicken')) return Icons.egg_outlined;
    if (id.contains('cow')) return Icons.agriculture_outlined;
    return Icons.pets_outlined;
  }
  return Icons.eco_outlined;
}
