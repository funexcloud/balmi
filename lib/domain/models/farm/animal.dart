import 'farm_tier.dart';

class AnimalStage {
  const AnimalStage({
    required this.stageIndex,
    required this.stageName,
    required this.feedThreshold,
    required this.spriteAssetKey,
  });

  final int stageIndex;
  final String stageName;
  final int feedThreshold;
  final String spriteAssetKey;
}

class AnimalDefinition {
  const AnimalDefinition({
    required this.animalId,
    required this.nameKr,
    required this.tier,
    this.unlockType,
    this.unlockValue,
    required this.hexTileRequirement,
    required this.yieldType,
    required this.feedPerCycle,
    required this.cooldownHours,
    required this.starvationGraceDays,
    required this.rewardCoin,
    required this.rewardXp,
    required this.growthStages,
  });

  final String animalId;
  final String nameKr;
  final FarmTier tier;
  final UnlockType? unlockType;
  final int? unlockValue;
  final int hexTileRequirement;
  final YieldType yieldType;
  final int feedPerCycle;
  final int cooldownHours;
  final int starvationGraceDays;
  final int rewardCoin;
  final int rewardXp;
  final List<AnimalStage> growthStages;

  AnimalStage? stageAt(int index) {
    for (final s in growthStages) {
      if (s.stageIndex == index) return s;
    }
    return null;
  }

  int get adultFeedThreshold {
    final adult = growthStages.where(
      (s) =>
          s.stageName == '성체' ||
          s.stageName == '암탉' ||
          s.stageName == '다 큰 양' ||
          s.stageName == '다 큰 소',
    );
    if (adult.isNotEmpty) return adult.first.feedThreshold;
    return growthStages.isEmpty ? 0 : growthStages.last.feedThreshold;
  }

  /// True for egg / incubating stages (chicken narrative starts here).
  bool get startsAsEgg {
    final first = stageAt(0);
    if (first == null) return false;
    return first.stageName == '계란' || first.stageName == '알';
  }

  /// Young livestock (lamb / calf) — not adult spawn.
  bool get startsAsYoung {
    final first = stageAt(0);
    if (first == null) return false;
    final name = first.stageName;
    return name == '새끼' ||
        name == '새끼양' ||
        name == '송아지' ||
        name == '병아리';
  }

  int get maxStageIndex => growthStages.fold<int>(
        0,
        (m, s) => s.stageIndex > m ? s.stageIndex : m,
      );
}
