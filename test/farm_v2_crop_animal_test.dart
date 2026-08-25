import 'package:balmi/domain/engines/farm_animal.dart';
import 'package:balmi/domain/engines/farm_crop.dart';
import 'package:balmi/domain/models/farm/animal.dart';
import 'package:balmi/domain/models/farm/crop.dart';
import 'package:balmi/domain/models/farm/farm_tier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tomato = CropDefinition(
    cropId: 'crop_tomato_01',
    nameKr: '토마토',
    tier: FarmTier.common,
    unlockType: UnlockType.level,
    unlockValue: 3,
    hexTileRequirement: 2,
    regrow: true,
    regrowWater: 120,
    regrowNutrient: 80,
    rewardCoin: 80,
    rewardXp: 50,
    stages: const [
      CropStage(
        stageIndex: 0,
        stageName: '씨앗',
        waterThreshold: 0,
        nutrientThreshold: 0,
        spriteAssetKey: 'crop/tomato/stage_0',
      ),
      CropStage(
        stageIndex: 1,
        stageName: '새싹',
        waterThreshold: 80,
        nutrientThreshold: 60,
        spriteAssetKey: 'crop/tomato/stage_1',
      ),
      CropStage(
        stageIndex: 2,
        stageName: '성장',
        waterThreshold: 220,
        nutrientThreshold: 180,
        spriteAssetKey: 'crop/tomato/stage_2',
      ),
      CropStage(
        stageIndex: 4,
        stageName: '수확',
        waterThreshold: 520,
        nutrientThreshold: 450,
        spriteAssetKey: 'crop/tomato/stage_4',
      ),
    ],
  );

  group('crop dual gauge (spec §3)', () {
    test('both gauges required for next stage', () {
      expect(
        cropGrowthHint(
          crop: tomato,
          cumulativeWater: 80,
          cumulativeNutrient: 30,
          currentStageIndex: 0,
          isDormant: false,
        ),
        CropGrowthHint.needNutrient,
      );
      expect(
        cropGrowthHint(
          crop: tomato,
          cumulativeWater: 50,
          cumulativeNutrient: 60,
          currentStageIndex: 0,
          isDormant: false,
        ),
        CropGrowthHint.needWater,
      );
    });

    test('advances stage when both thresholds met', () {
      expect(
        cropStageAfterResources(
          crop: tomato,
          cumulativeWater: 80,
          cumulativeNutrient: 60,
          currentStageIndex: 0,
        ),
        1,
      );
    });

    test('ready harvest at final thresholds', () {
      expect(
        cropGrowthHint(
          crop: tomato,
          cumulativeWater: 520,
          cumulativeNutrient: 450,
          currentStageIndex: 2,
          isDormant: false,
        ),
        CropGrowthHint.readyHarvest,
      );
    });

    test('dormant slot shows dormant hint', () {
      expect(
        cropGrowthHint(
          crop: tomato,
          cumulativeWater: 520,
          cumulativeNutrient: 450,
          currentStageIndex: 2,
          isDormant: true,
        ),
        CropGrowthHint.dormant,
      );
    });
  });

  group('animal yield (spec §4)', () {
    final sheep = AnimalDefinition(
      animalId: 'animal_sheep_01',
      nameKr: '양',
      tier: FarmTier.common,
      unlockType: UnlockType.level,
      unlockValue: 5,
      hexTileRequirement: 2,
      yieldType: YieldType.wool,
      feedPerCycle: 100,
      cooldownHours: 24,
      starvationGraceDays: 3,
      rewardCoin: 60,
      rewardXp: 40,
      growthStages: const [
        AnimalStage(
          stageIndex: 0,
          stageName: '새끼',
          feedThreshold: 0,
          spriteAssetKey: 'animal/sheep/stage_0',
        ),
        AnimalStage(
          stageIndex: 2,
          stageName: '성체',
          feedThreshold: 900,
          spriteAssetKey: 'animal/sheep/stage_2',
        ),
      ],
    );

    test('growing until adult feed threshold', () {
      final status = evaluateAnimal(
        animal: sheep,
        cumulativeFeed: 400,
        currentStageIndex: 0,
        lastYieldAt: null,
        isDormant: false,
        now: DateTime(2026, 8, 25, 12),
      );
      expect(status.state, AnimalYieldState.growing);
      expect(status.canCollect, isFalse);
    });

    test('adult ready for first yield', () {
      final status = evaluateAnimal(
        animal: sheep,
        cumulativeFeed: 900,
        currentStageIndex: 2,
        lastYieldAt: null,
        isDormant: false,
        now: DateTime(2026, 8, 25, 12),
      );
      expect(status.state, AnimalYieldState.readyYield);
      expect(status.canCollect, isTrue);
    });

    test('cooldown blocks yield within 24h', () {
      final now = DateTime(2026, 8, 25, 12);
      final status = evaluateAnimal(
        animal: sheep,
        cumulativeFeed: 1000,
        currentStageIndex: 2,
        lastYieldAt: now.subtract(const Duration(hours: 6)),
        isDormant: false,
        now: now,
      );
      expect(status.state, AnimalYieldState.cooldown);
      expect(status.canCollect, isFalse);
    });

    test('starvation reduces yield penalty flag', () {
      final now = DateTime(2026, 8, 25, 12);
      final status = evaluateAnimal(
        animal: sheep,
        cumulativeFeed: 1000,
        currentStageIndex: 2,
        lastYieldAt: now.subtract(const Duration(days: 2)),
        isDormant: false,
        now: now,
        daysSinceLastFeed: 5,
      );
      expect(status.yieldPenalty, 0.5);
    });
  });
}
