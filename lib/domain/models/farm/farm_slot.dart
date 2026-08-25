import 'farm_tier.dart';

class SlotTemplate {
  const SlotTemplate({
    required this.slotId,
    required this.slotType,
    required this.xPct,
    required this.yPct,
    required this.zIndex,
    required this.unlockTileCount,
  });

  final String slotId;
  final SlotType slotType;
  final double xPct;
  final double yPct;
  final int zIndex;
  final int unlockTileCount;
}

class UserFarmSlot {
  const UserFarmSlot({
    required this.id,
    required this.slotId,
    this.occupantType,
    this.cropId,
    this.animalId,
    required this.cumulativeWater,
    required this.cumulativeNutrient,
    required this.cumulativeFeed,
    required this.currentStageIndex,
    required this.isDormant,
    this.lastYieldAt,
    required this.plantedAt,
  });

  final int id;
  final String slotId;
  final OccupantType? occupantType;
  final String? cropId;
  final String? animalId;
  final int cumulativeWater;
  final int cumulativeNutrient;
  final int cumulativeFeed;
  final int currentStageIndex;
  final bool isDormant;
  final DateTime? lastYieldAt;
  final DateTime plantedAt;

  bool get isEmpty => occupantType == null;
}

class FarmSlotView {
  const FarmSlotView({
    required this.template,
    required this.occupant,
    required this.unlocked,
  });

  final SlotTemplate template;
  final UserFarmSlot? occupant;
  final bool unlocked;
}
