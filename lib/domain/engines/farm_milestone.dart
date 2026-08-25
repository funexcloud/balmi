import '../models/farm/milestone.dart';

class MilestoneProgress {
  const MilestoneProgress({
    required this.definition,
    required this.achieved,
    this.achievedAt,
  });

  final MilestoneDefinition definition;
  final bool achieved;
  final DateTime? achievedAt;
}

class MilestoneContext {
  const MilestoneContext({
    this.harvestCount = 0,
    this.distinctCropsHarvested = 0,
    this.waterStreakDays = 0,
    this.livestockCount = 0,
    this.farmLevel = 1,
  });

  final int harvestCount;
  final int distinctCropsHarvested;
  final int waterStreakDays;
  final int livestockCount;
  final int farmLevel;
}

/// Spec §5.2 — evaluate whether a milestone is newly earned.
bool milestoneMet(MilestoneDefinition def, MilestoneContext ctx) {
  return switch (def.conditionType) {
    'first_harvest' => ctx.harvestCount >= 1,
    'water_streak' =>
      ctx.waterStreakDays >= (def.conditionValue ?? 0),
    'crop_diversity' =>
      ctx.distinctCropsHarvested >= (def.conditionValue ?? 0),
    'livestock_owner' =>
      ctx.livestockCount >= (def.conditionValue ?? 0),
    'farm_level' => ctx.farmLevel >= (def.conditionValue ?? 0),
    _ => false,
  };
}

List<MilestoneDefinition> newlyEarnedMilestones({
  required Iterable<MilestoneDefinition> definitions,
  required Set<String> alreadyEarned,
  required MilestoneContext ctx,
}) {
  return [
    for (final d in definitions)
      if (!alreadyEarned.contains(d.milestoneId) && milestoneMet(d, ctx)) d,
  ];
}

/// Farm level from cumulative FXP using definition ladder.
int farmLevelForXp(int fxp, List<FarmLevelDefinition> levels) {
  if (levels.isEmpty) return 1;
  final sorted = [...levels]..sort((a, b) => b.farmLevel.compareTo(a.farmLevel));
  for (final l in sorted) {
    if (fxp >= l.requiredFxp) return l.farmLevel;
  }
  return 1;
}

int xpToNextLevel(int fxp, int currentLevel, List<FarmLevelDefinition> levels) {
  final sorted = [...levels]..sort((a, b) => a.farmLevel.compareTo(b.farmLevel));
  for (final l in sorted) {
    if (l.farmLevel > currentLevel) {
      return (l.requiredFxp - fxp).clamp(0, 999999);
    }
  }
  return 0;
}
