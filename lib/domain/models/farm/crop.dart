import 'farm_tier.dart';

class CropStage {
  const CropStage({
    required this.stageIndex,
    required this.stageName,
    required this.waterThreshold,
    required this.nutrientThreshold,
    required this.spriteAssetKey,
  });

  final int stageIndex;
  final String stageName;
  final int waterThreshold;
  final int nutrientThreshold;
  final String spriteAssetKey;
}

class CropDefinition {
  const CropDefinition({
    required this.cropId,
    required this.nameKr,
    required this.tier,
    this.unlockType,
    this.unlockValue,
    required this.hexTileRequirement,
    required this.regrow,
    this.regrowWater,
    this.regrowNutrient,
    required this.rewardCoin,
    required this.rewardXp,
    this.rewardItemDrop,
    this.seasonalFlag,
    required this.stages,
  });

  final String cropId;
  final String nameKr;
  final FarmTier tier;
  final UnlockType? unlockType;
  final int? unlockValue;
  final int hexTileRequirement;
  final bool regrow;
  final int? regrowWater;
  final int? regrowNutrient;
  final int rewardCoin;
  final int rewardXp;
  final String? rewardItemDrop;
  final String? seasonalFlag;
  final List<CropStage> stages;

  CropStage? stageAt(int index) {
    for (final s in stages) {
      if (s.stageIndex == index) return s;
    }
    return null;
  }

  CropStage? get harvestStage {
    for (final s in stages) {
      if (s.stageName == '수확') return s;
    }
    return stages.isEmpty ? null : stages.last;
  }

  int get maxStageIndex =>
      stages.fold<int>(0, (m, s) => s.stageIndex > m ? s.stageIndex : m);
}
