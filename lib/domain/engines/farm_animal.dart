import '../models/farm/animal.dart';

enum AnimalYieldState {
  growing,
  readyYield,
  cooldown,
  needFeed,
  dormant,
  starving,
}

class AnimalStatus {
  const AnimalStatus({
    required this.state,
    required this.stageIndex,
    required this.canCollect,
    this.hoursUntilYield,
    this.yieldPenalty = 1.0,
  });

  final AnimalYieldState state;
  final int stageIndex;
  final bool canCollect;
  final int? hoursUntilYield;
  final double yieldPenalty;
}

/// Spec §4 — feed-based growth + periodic yield.
AnimalStatus evaluateAnimal({
  required AnimalDefinition animal,
  required int cumulativeFeed,
  required int currentStageIndex,
  required DateTime? lastYieldAt,
  required bool isDormant,
  required DateTime now,
  int? daysSinceLastFeed,
}) {
  if (isDormant) {
    return AnimalStatus(
      state: AnimalYieldState.dormant,
      stageIndex: currentStageIndex,
      canCollect: false,
    );
  }

  final adultThreshold = animal.adultFeedThreshold;
  var stage = currentStageIndex;
  for (final s in animal.growthStages) {
    if (cumulativeFeed >= s.feedThreshold && s.stageIndex > stage) {
      stage = s.stageIndex;
    }
  }

  if (cumulativeFeed < adultThreshold) {
    return AnimalStatus(
      state: AnimalYieldState.growing,
      stageIndex: stage,
      canCollect: false,
    );
  }

  final grace = animal.starvationGraceDays;
  final starving = daysSinceLastFeed != null && daysSinceLastFeed > grace;
  final penalty = starving
      ? 0.5
      : (daysSinceLastFeed != null && daysSinceLastFeed > grace ~/ 2)
          ? 0.75
          : 1.0;

  if (lastYieldAt == null) {
    return AnimalStatus(
      state: AnimalYieldState.readyYield,
      stageIndex: stage,
      canCollect: true,
      yieldPenalty: penalty,
    );
  }

  final elapsed = now.difference(lastYieldAt);
  final cooldown = Duration(hours: animal.cooldownHours);
  if (elapsed >= cooldown) {
    if (cumulativeFeed < animal.feedPerCycle) {
      return AnimalStatus(
        state: AnimalYieldState.needFeed,
        stageIndex: stage,
        canCollect: false,
        yieldPenalty: penalty,
      );
    }
    return AnimalStatus(
      state: AnimalYieldState.readyYield,
      stageIndex: stage,
      canCollect: true,
      yieldPenalty: penalty,
    );
  }

  final remaining = cooldown - elapsed;
  return AnimalStatus(
    state: AnimalYieldState.cooldown,
    stageIndex: stage,
    canCollect: false,
    hoursUntilYield: remaining.inHours + (remaining.inMinutes % 60 > 0 ? 1 : 0),
    yieldPenalty: penalty,
  );
}

int animalStageAfterFeed({
  required AnimalDefinition animal,
  required int cumulativeFeed,
  required int currentStageIndex,
}) {
  var stage = currentStageIndex;
  for (final s in animal.growthStages) {
    if (cumulativeFeed >= s.feedThreshold && s.stageIndex > stage) {
      stage = s.stageIndex;
    }
  }
  return stage;
}

String animalStatusLine({
  required AnimalDefinition animal,
  required AnimalStatus status,
}) {
  return switch (status.state) {
    AnimalYieldState.growing =>
      '${animal.nameKr} · 자라는 중이에요 (사료 ${animal.adultFeedThreshold}까지)',
    AnimalYieldState.readyYield => '${animal.nameKr} · 산출물을 받을 수 있어요',
    AnimalYieldState.cooldown =>
      '${animal.nameKr} · 조금 쉬는 중이에요',
    AnimalYieldState.needFeed => '${animal.nameKr} · 사료가 필요해요',
    AnimalYieldState.dormant => '${animal.nameKr} · 휴면 중이에요',
    AnimalYieldState.starving => '${animal.nameKr} · 사료를 오래 못 줬어요',
  };
}
