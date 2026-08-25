enum FarmTier {
  starter,
  common,
  rare,
  epic,
  legendary;

  String get wire => name;

  static FarmTier fromWire(String value) {
    return FarmTier.values.firstWhere(
      (e) => e.wire == value || e.name == value,
      orElse: () => FarmTier.starter,
    );
  }
}

enum BadgeTier {
  bronze,
  silver,
  gold,
  special;

  String get wire => name;

  static BadgeTier fromWire(String value) {
    return BadgeTier.values.firstWhere(
      (e) => e.wire == value || e.name == value,
      orElse: () => BadgeTier.bronze,
    );
  }
}

enum UnlockType {
  level,
  tileCount,
  streakDays,
  event;

  String get wire => switch (this) {
        level => 'level',
        tileCount => 'tile_count',
        streakDays => 'streak_days',
        event => 'event',
      };

  static UnlockType? fromWire(String? value) {
    if (value == null) return null;
    return UnlockType.values.firstWhere(
      (e) => e.wire == value || e.name == value,
      orElse: () => UnlockType.level,
    );
  }
}

enum SlotType {
  livestock,
  crop;

  String get wire => name;

  static SlotType fromWire(String value) {
    return SlotType.values.firstWhere(
      (e) => e.wire == value || e.name == value,
      orElse: () => SlotType.crop,
    );
  }
}

enum OccupantType {
  crop,
  livestock;

  String get wire => name;

  static OccupantType? fromWire(String? value) {
    if (value == null) return null;
    return OccupantType.values.firstWhere(
      (e) => e.wire == value || e.name == value,
      orElse: () => OccupantType.crop,
    );
  }
}

enum FarmResourceType {
  feed,
  water,
  nutrient;

  String get wire => name;

  String get labelKr => switch (this) {
        feed => '사료',
        water => '물',
        nutrient => '영양제',
      };

  static FarmResourceType fromWire(String value) {
    return FarmResourceType.values.firstWhere(
      (e) => e.wire == value || e.name == value,
      orElse: () => FarmResourceType.water,
    );
  }
}

enum YieldType {
  wool,
  milk,
  egg;

  String get wire => name;

  static YieldType fromWire(String value) {
    return YieldType.values.firstWhere(
      (e) => e.wire == value || e.name == value,
      orElse: () => YieldType.egg,
    );
  }
}

enum CropGrowthHint {
  ok,
  needWater,
  needNutrient,
  readyHarvest,
  dormant,
}

enum FriendshipStatus {
  pending,
  accepted,
  blocked;

  String get wire => name;

  static FriendshipStatus fromWire(String value) {
    return FriendshipStatus.values.firstWhere(
      (e) => e.wire == value || e.name == value,
      orElse: () => FriendshipStatus.pending,
    );
  }
}
