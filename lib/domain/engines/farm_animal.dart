import '../models/farm/animal.dart';
import '../models/farm/farm_tier.dart';

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
    AnimalYieldState.growing => animalGrowingStatusLine(
        animal: animal,
        stageIndex: status.stageIndex,
      ),
    AnimalYieldState.readyYield => '${animal.nameKr} · 산출물을 받을 수 있어요',
    AnimalYieldState.cooldown =>
      '${animal.nameKr} · 조금 쉬는 중이에요',
    AnimalYieldState.needFeed => '${animal.nameKr} · 사료가 필요해요',
    AnimalYieldState.dormant => '${animal.nameKr} · 휴면 중이에요',
    AnimalYieldState.starving => '${animal.nameKr} · 사료를 오래 못 줬어요',
  };
}

/// Growth copy without opaque feed totals (e.g. old 「사료 400까지」).
String animalGrowingStatusLine({
  required AnimalDefinition animal,
  required int stageIndex,
}) {
  final stage = animal.stageAt(stageIndex);
  final name = stage?.stageName ?? '';
  if (name == '계란' || name == '품는 중' || name == '알') {
    return '계란을 품고 있어요';
  }
  if (name == '병아리') {
    return '${animal.nameKr} · 병아리가 자라고 있어요';
  }
  if (name == '새끼양' || (animal.animalId.contains('sheep') && name == '새끼')) {
    return '양 · 새끼양이 자라고 있어요';
  }
  if (name == '송아지' || (animal.animalId.contains('cow') && name == '새끼')) {
    return '소 · 송아지가 자라고 있어요';
  }
  if (name == '새끼') {
    return '${animal.nameKr} · 새끼가 자라고 있어요';
  }
  if (name == '성장') {
    return '${animal.nameKr} · 무럭무럭 자라고 있어요';
  }
  return '${animal.nameKr} · 잘 자라고 있어요';
}

/// Toast / snackbar after adopting into an empty livestock slot.
String farmAdoptedCopy(AnimalDefinition animal) {
  if (animal.startsAsEgg) return '계란을 품고 있어요';
  if (animal.animalId.contains('sheep')) return '새끼양을 입양했어요';
  if (animal.animalId.contains('cow')) return '송아지를 입양했어요';
  return '${animal.nameKr} 한 마리를 입양했어요';
}

/// Empty livestock slot CTA — incubate eggs, otherwise adopt young stock.
String emptyLivestockSlotLabel(AnimalDefinition? next) {
  if (next != null && next.startsAsEgg) return '품기';
  return '입양';
}

bool animalUnlockedAtLevel(AnimalDefinition animal, int farmLevel) {
  if (animal.unlockType == UnlockType.level) {
    return farmLevel >= (animal.unlockValue ?? 1);
  }
  return true;
}

/// Prefer unlocked species not yet on the farm; else least-owned unlocked.
AnimalDefinition? pickNextAdoptableAnimal({
  required List<AnimalDefinition> catalog,
  required Iterable<String> occupiedAnimalIds,
  required int farmLevel,
}) {
  final unlocked = catalog
      .where((a) => animalUnlockedAtLevel(a, farmLevel))
      .toList()
    ..sort((a, b) {
      final av = a.unlockValue ?? 0;
      final bv = b.unlockValue ?? 0;
      if (av != bv) return av.compareTo(bv);
      return a.animalId.compareTo(b.animalId);
    });
  if (unlocked.isEmpty) return null;

  final counts = <String, int>{};
  for (final id in occupiedAnimalIds) {
    counts[id] = (counts[id] ?? 0) + 1;
  }

  final missing = unlocked.where((a) => (counts[a.animalId] ?? 0) == 0);
  if (missing.isNotEmpty) return missing.first;

  unlocked.sort((a, b) {
    final ca = counts[a.animalId] ?? 0;
    final cb = counts[b.animalId] ?? 0;
    if (ca != cb) return ca.compareTo(cb);
    return (a.unlockValue ?? 0).compareTo(b.unlockValue ?? 0);
  });
  return unlocked.first;
}
