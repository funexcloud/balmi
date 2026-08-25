import '../models/farm/crop.dart';
import '../models/farm/farm_tier.dart';

/// Spec §3 — dual-gauge crop progression.
CropGrowthHint cropGrowthHint({
  required CropDefinition crop,
  required int cumulativeWater,
  required int cumulativeNutrient,
  required int currentStageIndex,
  required bool isDormant,
}) {
  if (isDormant) return CropGrowthHint.dormant;

  final nextIndex = currentStageIndex + 1;
  final next = crop.stageAt(nextIndex);
  if (next == null) {
    final harvest = crop.harvestStage;
    if (harvest != null &&
        cumulativeWater >= harvest.waterThreshold &&
        cumulativeNutrient >= harvest.nutrientThreshold) {
      return CropGrowthHint.readyHarvest;
    }
    return CropGrowthHint.ok;
  }

  final waterOk = cumulativeWater >= next.waterThreshold;
  final nutrientOk = cumulativeNutrient >= next.nutrientThreshold;

  if (waterOk && nutrientOk) {
    return next.stageName == '수확'
        ? CropGrowthHint.readyHarvest
        : CropGrowthHint.ok;
  }
  if (!waterOk && nutrientOk) return CropGrowthHint.needWater;
  if (waterOk && !nutrientOk) return CropGrowthHint.needNutrient;
  return CropGrowthHint.needWater;
}

/// Returns new stage index after applying resources (does not mutate).
int cropStageAfterResources({
  required CropDefinition crop,
  required int cumulativeWater,
  required int cumulativeNutrient,
  required int currentStageIndex,
}) {
  var stage = currentStageIndex;
  while (true) {
    final nextIndex = stage + 1;
    final next = crop.stageAt(nextIndex);
    if (next == null) break;
    if (cumulativeWater >= next.waterThreshold &&
        cumulativeNutrient >= next.nutrientThreshold) {
      stage = nextIndex;
      continue;
    }
    break;
  }
  return stage;
}

double cropProgressToNext({
  required CropDefinition crop,
  required int cumulativeWater,
  required int cumulativeNutrient,
  required int currentStageIndex,
}) {
  final next = crop.stageAt(currentStageIndex + 1);
  if (next == null) return 1.0;

  final waterNeed = (next.waterThreshold -
          (crop.stageAt(currentStageIndex)?.waterThreshold ?? 0))
      .clamp(1, 999999);
  final nutrientNeed = (next.nutrientThreshold -
          (crop.stageAt(currentStageIndex)?.nutrientThreshold ?? 0))
      .clamp(1, 999999);

  final prevWater =
      crop.stageAt(currentStageIndex)?.waterThreshold ?? 0;
  final prevNutrient =
      crop.stageAt(currentStageIndex)?.nutrientThreshold ?? 0;

  final waterPct =
      ((cumulativeWater - prevWater) / waterNeed).clamp(0.0, 1.0);
  final nutrientPct =
      ((cumulativeNutrient - prevNutrient) / nutrientNeed).clamp(0.0, 1.0);
  return waterPct < nutrientPct ? waterPct : nutrientPct;
}

/// Status sentence for 중장년층-friendly UI (spec §7.5).
String cropStatusLine({
  required CropDefinition crop,
  required int cumulativeWater,
  required int cumulativeNutrient,
  required int currentStageIndex,
  required bool isDormant,
}) {
  if (isDormant) return '${crop.nameKr} · 휴면 중이에요';

  final hint = cropGrowthHint(
    crop: crop,
    cumulativeWater: cumulativeWater,
    cumulativeNutrient: cumulativeNutrient,
    currentStageIndex: currentStageIndex,
    isDormant: isDormant,
  );

  return switch (hint) {
    CropGrowthHint.readyHarvest => '${crop.nameKr} · 수확할 수 있어요',
    CropGrowthHint.needWater =>
      '${crop.nameKr} · 물이 더 필요해요 (${cumulativeWater}/${crop.stageAt(currentStageIndex + 1)?.waterThreshold ?? "—"})',
    CropGrowthHint.needNutrient =>
      '${crop.nameKr} · 영양제가 더 필요해요 (${cumulativeNutrient}/${crop.stageAt(currentStageIndex + 1)?.nutrientThreshold ?? "—"})',
    CropGrowthHint.dormant => '${crop.nameKr} · 휴면 중이에요',
    CropGrowthHint.ok => '${crop.nameKr} · 잘 자라고 있어요',
  };
}
