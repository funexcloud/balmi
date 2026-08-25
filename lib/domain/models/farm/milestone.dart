class MilestoneDefinition {
  const MilestoneDefinition({
    required this.milestoneId,
    required this.conditionType,
    this.conditionValue,
    required this.bonusFxp,
    this.vasaSignal,
  });

  final String milestoneId;
  final String conditionType;
  final int? conditionValue;
  final int bonusFxp;
  final String? vasaSignal;
}

class FarmLevelDefinition {
  const FarmLevelDefinition({
    required this.farmLevel,
    required this.requiredFxp,
    this.unlockNote,
  });

  final int farmLevel;
  final int requiredFxp;
  final String? unlockNote;
}

class UserMilestone {
  const UserMilestone({
    required this.milestoneId,
    required this.achievedAt,
  });

  final String milestoneId;
  final DateTime achievedAt;
}

class BadgeDefinition {
  const BadgeDefinition({
    required this.badgeId,
    required this.nameKr,
    required this.tier,
    this.milestoneId,
    required this.iconAssetKey,
    required this.descriptionKr,
    required this.isSeasonal,
    this.seasonEndAt,
  });

  final String badgeId;
  final String nameKr;
  final String tier;
  final String? milestoneId;
  final String iconAssetKey;
  final String descriptionKr;
  final bool isSeasonal;
  final DateTime? seasonEndAt;
}

class UserBadge {
  const UserBadge({
    required this.badgeId,
    required this.earnedAt,
  });

  final String badgeId;
  final DateTime earnedAt;
}
