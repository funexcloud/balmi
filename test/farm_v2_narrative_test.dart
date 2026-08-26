import 'package:balmi/core/copy.dart';
import 'package:balmi/domain/engines/farm_animal.dart';
import 'package:balmi/domain/engines/farm_birth.dart';
import 'package:balmi/domain/engines/farm_life.dart';
import 'package:balmi/domain/engines/farm_crop.dart';
import 'package:balmi/domain/engines/farm_scene_ui.dart';
import 'package:balmi/domain/models/farm/animal.dart';
import 'package:balmi/domain/models/farm/crop.dart';
import 'package:balmi/domain/models/farm/farm_slot.dart';
import 'package:balmi/domain/models/farm/farm_tier.dart';
import 'package:flutter_test/flutter_test.dart';

AnimalDefinition starterChicken() => AnimalDefinition(
      animalId: 'animal_chicken_01',
      nameKr: '닭',
      tier: FarmTier.starter,
      unlockType: UnlockType.level,
      unlockValue: 1,
      hexTileRequirement: 1,
      yieldType: YieldType.egg,
      feedPerCycle: 40,
      cooldownHours: 12,
      starvationGraceDays: 3,
      rewardCoin: 25,
      rewardXp: 15,
      growthStages: const [
        AnimalStage(
          stageIndex: 0,
          stageName: '계란',
          feedThreshold: 0,
          spriteAssetKey: 'animal/chicken/stage_0',
        ),
        AnimalStage(
          stageIndex: 1,
          stageName: '품는 중',
          feedThreshold: 20,
          spriteAssetKey: 'animal/chicken/stage_1',
        ),
        AnimalStage(
          stageIndex: 2,
          stageName: '병아리',
          feedThreshold: 60,
          spriteAssetKey: 'animal/chicken/stage_2',
        ),
        AnimalStage(
          stageIndex: 3,
          stageName: '암탉',
          feedThreshold: 120,
          spriteAssetKey: 'animal/chicken/stage_3',
        ),
      ],
    );

CropDefinition starterCarrot() => CropDefinition(
      cropId: 'crop_carrot_01',
      nameKr: '당근',
      tier: FarmTier.starter,
      unlockType: UnlockType.level,
      unlockValue: 1,
      hexTileRequirement: 1,
      regrow: false,
      rewardCoin: 30,
      rewardXp: 20,
      stages: const [
        CropStage(
          stageIndex: 0,
          stageName: '씨앗',
          waterThreshold: 0,
          nutrientThreshold: 0,
          spriteAssetKey: 'crop/carrot/stage_0',
        ),
        CropStage(
          stageIndex: 1,
          stageName: '새싹',
          waterThreshold: 40,
          nutrientThreshold: 30,
          spriteAssetKey: 'crop/carrot/stage_1',
        ),
        CropStage(
          stageIndex: 2,
          stageName: '성장',
          waterThreshold: 100,
          nutrientThreshold: 80,
          spriteAssetKey: 'crop/carrot/stage_2',
        ),
        CropStage(
          stageIndex: 3,
          stageName: '수확',
          waterThreshold: 180,
          nutrientThreshold: 140,
          spriteAssetKey: 'crop/carrot/stage_3',
        ),
      ],
    );

void main() {
  group('chicken egg → hen narrative', () {
    final chicken = starterChicken();

    test('adult feed threshold is 120 not legacy 400', () {
      expect(chicken.adultFeedThreshold, 120);
      expect(chicken.startsAsEgg, isTrue);
      expect(chicken.stageAt(0)?.stageName, '계란');
      expect(chicken.stageAt(3)?.stageName, '암탉');
    });

    test('adopt / incubating status says 계란을 품고 있어요!', () {
      final egg = evaluateAnimal(
        animal: chicken,
        cumulativeFeed: 0,
        currentStageIndex: 0,
        lastYieldAt: null,
        isDormant: false,
        now: DateTime(2026, 8, 26, 12),
      );
      expect(egg.state, AnimalYieldState.growing);
      expect(animalStatusLine(animal: chicken, status: egg), '계란을 품고 있어요!');

      final incubating = evaluateAnimal(
        animal: chicken,
        cumulativeFeed: 20,
        currentStageIndex: 1,
        lastYieldAt: null,
        isDormant: false,
        now: DateTime(2026, 8, 26, 12),
      );
      expect(incubating.stageIndex, 1);
      expect(
        animalStatusLine(animal: chicken, status: incubating),
        '계란을 품고 있어요!',
      );
    });

    test('growing copy never exposes opaque feed totals', () {
      final mid = evaluateAnimal(
        animal: chicken,
        cumulativeFeed: 60,
        currentStageIndex: 2,
        lastYieldAt: null,
        isDormant: false,
        now: DateTime(2026, 8, 26, 12),
      );
      final line = animalStatusLine(animal: chicken, status: mid);
      expect(line, contains('병아리'));
      expect(line, isNot(contains('사료')));
      expect(line, isNot(contains('400')));
      expect(line, isNot(contains('120까지')));
    });

    test('slot label starts as 계란; empty livestock is 품기', () {
      final occupied = FarmSlotView(
        template: const SlotTemplate(
          slotId: 'pasture_1',
          slotType: SlotType.livestock,
          xPct: 25,
          yPct: 78,
          zIndex: 5,
          unlockTileCount: 1,
        ),
        occupant: UserFarmSlot(
          id: 1,
          slotId: 'pasture_1',
          occupantType: OccupantType.livestock,
          animalId: 'animal_chicken_01',
          cumulativeWater: 0,
          cumulativeNutrient: 0,
          cumulativeFeed: 0,
          currentStageIndex: 0,
          isDormant: false,
          plantedAt: DateTime(2026, 8, 26),
        ),
        unlocked: true,
      );
      expect(
        slotDisplayLabel(slot: occupied, crop: null, animal: chicken),
        '닭 · 계란',
      );

      final empty = FarmSlotView(
        template: occupied.template,
        occupant: null,
        unlocked: true,
      );
      expect(
        slotDisplayLabel(
          slot: empty,
          crop: null,
          animal: null,
          nextAdoptable: chicken,
        ),
        '품기',
      );
    });

    test('toast / BalmiCopy adopt + plant match story beats', () {
      expect(BalmiCopy.farmV2Adopted, '계란을 품고 있어요!');
      expect(BalmiCopy.farmV2Planted, '씨앗을 뿌렸어요!');
      expect(BalmiCopy.farmBirthSheep, '양이 태어났어요!');
      expect(BalmiCopy.farmBirthCow, '송아지가 태어났어요!');
      expect(BalmiCopy.farmBirthChickenEgg, '계란을 품고 있어요!');
      expect(BalmiCopy.farmBirthCropSeed, '씨앗을 뿌렸어요!');
    });
  });

  group('birth toasts for sheep / cow / chicken / crop', () {
    test('herd water-raise toasts', () {
      expect(farmBirthToastForHerd(HerdKind.sheep), '양이 태어났어요!');
      expect(farmBirthToastForHerd(HerdKind.cattle), '송아지가 태어났어요!');
      expect(farmBirthToastForHerd(HerdKind.chicken), '계란을 품고 있어요!');
      expect(farmBirthToastForHerd(HerdKind.garden), '씨앗을 뿌렸어요!');
    });

    test('v2 animal id toasts', () {
      expect(farmBirthToastForAnimalId('animal_sheep_01'), '양이 태어났어요!');
      expect(farmBirthToastForAnimalId('animal_cow_01'), '송아지가 태어났어요!');
      expect(
        farmBirthToastForAnimalId('animal_chicken_01'),
        '계란을 품고 있어요!',
      );
      expect(farmBirthToastForCrop(), '씨앗을 뿌렸어요!');
    });

    test('livestock adopt prefers chicken then sheep then cow', () {
      expect(
        pickLivestockAnimalId(ownedAnimalIds: const []),
        'animal_chicken_01',
      );
      expect(
        pickLivestockAnimalId(ownedAnimalIds: const ['animal_chicken_01']),
        'animal_sheep_01',
      );
      expect(
        pickLivestockAnimalId(
          ownedAnimalIds: const ['animal_chicken_01', 'animal_sheep_01'],
        ),
        'animal_cow_01',
      );
    });

    test('after all kinds present, prefer sheep/cow livestock', () {
      final id = pickLivestockAnimalId(
        ownedAnimalIds: const [
          'animal_chicken_01',
          'animal_sheep_01',
          'animal_cow_01',
        ],
      );
      expect(id, isNot(equals('animal_chicken_01')));
      expect(id == 'animal_sheep_01' || id == 'animal_cow_01', isTrue);
    });

    test('farmAdoptedCopy matches birth story beats', () {
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
        ],
      );
      final cow = AnimalDefinition(
        animalId: 'animal_cow_01',
        nameKr: '젖소',
        tier: FarmTier.rare,
        unlockType: UnlockType.level,
        unlockValue: 8,
        hexTileRequirement: 3,
        yieldType: YieldType.milk,
        feedPerCycle: 150,
        cooldownHours: 24,
        starvationGraceDays: 3,
        rewardCoin: 120,
        rewardXp: 70,
        growthStages: const [
          AnimalStage(
            stageIndex: 0,
            stageName: '새끼',
            feedThreshold: 0,
            spriteAssetKey: 'animal/cow/stage_0',
          ),
        ],
      );
      expect(farmAdoptedCopy(sheep), '양이 태어났어요!');
      expect(farmAdoptedCopy(cow), '송아지가 태어났어요!');
      expect(farmAdoptedCopy(starterChicken()), '계란을 품고 있어요!');
    });
  });

  group('crop seed narrative', () {
    final carrot = starterCarrot();

    test('just-planted status is 씨앗을 뿌렸어요!', () {
      expect(
        cropStatusLine(
          crop: carrot,
          cumulativeWater: 0,
          cumulativeNutrient: 0,
          currentStageIndex: 0,
          isDormant: false,
        ),
        '씨앗을 뿌렸어요!',
      );
    });

    test('slot label shows 씨앗 at stage 0', () {
      final slot = FarmSlotView(
        template: const SlotTemplate(
          slotId: 'garden_1',
          slotType: SlotType.crop,
          xPct: 72,
          yPct: 68,
          zIndex: 4,
          unlockTileCount: 1,
        ),
        occupant: UserFarmSlot(
          id: 2,
          slotId: 'garden_1',
          occupantType: OccupantType.crop,
          cropId: 'crop_carrot_01',
          cumulativeWater: 0,
          cumulativeNutrient: 0,
          cumulativeFeed: 0,
          currentStageIndex: 0,
          isDormant: false,
          plantedAt: DateTime(2026, 8, 26),
        ),
        unlocked: true,
      );
      expect(
        slotDisplayLabel(slot: slot, crop: carrot, animal: null),
        '당근 · 씨앗',
      );
    });

    test('after water, status can ask for more resources', () {
      final line = cropStatusLine(
        crop: carrot,
        cumulativeWater: 10,
        cumulativeNutrient: 0,
        currentStageIndex: 0,
        isDormant: false,
      );
      expect(line, isNot(equals('씨앗을 뿌렸어요!')));
      expect(line, contains('물'));
    });
  });

  group('causal order: stage-0 / first toast before later beats', () {
    test('crop never shows grow/harvest before plant toast', () {
      final carrot = starterCarrot();
      final planted = cropStatusLine(
        crop: carrot,
        cumulativeWater: 0,
        cumulativeNutrient: 0,
        currentStageIndex: 0,
        isDormant: false,
      );
      expect(planted, BalmiCopy.farmV2Planted);
      expect(planted, isNot(contains('잘 자라고')));
      expect(planted, isNot(contains('수확')));
    });

    test('chicken stage 0 status matches first toast, not chick/hen', () {
      final chicken = starterChicken();
      final egg = evaluateAnimal(
        animal: chicken,
        cumulativeFeed: 0,
        currentStageIndex: 0,
        lastYieldAt: null,
        isDormant: false,
        now: DateTime(2026, 8, 26, 12),
      );
      final line = animalStatusLine(
        animal: chicken,
        status: egg,
        cumulativeFeed: 0,
      );
      expect(line, BalmiCopy.farmV2Adopted);
      expect(line, isNot(contains('병아리')));
      expect(line, isNot(contains('암탉')));
      expect(farmAdoptedCopy(chicken), BalmiCopy.farmV2Adopted);
    });

    test('sheep/cow stage 0 no-feed is birth toast before grow', () {
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
            stageName: '새끼양',
            feedThreshold: 0,
            spriteAssetKey: 'animal/sheep/stage_0',
          ),
          AnimalStage(
            stageIndex: 1,
            stageName: '성장',
            feedThreshold: 300,
            spriteAssetKey: 'animal/sheep/stage_1',
          ),
        ],
      );
      expect(
        animalGrowingStatusLine(
          animal: sheep,
          stageIndex: 0,
          cumulativeFeed: 0,
        ),
        BalmiCopy.farmBirthSheep,
      );
      expect(
        animalGrowingStatusLine(
          animal: sheep,
          stageIndex: 0,
          cumulativeFeed: 10,
        ),
        contains('자라고'),
      );
      expect(farmAdoptedCopy(sheep), BalmiCopy.farmBirthSheep);
    });

    test('first toasts never use later-stage adult gift labels', () {
      expect(farmBirthToastForHerd(HerdKind.sheep), isNot(contains('한 마리')));
      expect(farmBirthToastForHerd(HerdKind.cattle), isNot(contains('한 마리')));
      expect(farmBirthToastForHerd(HerdKind.chicken), isNot(contains('한 마리')));
      expect(farmBirthToastForHerd(HerdKind.garden), BalmiCopy.farmV2Planted);
    });
  });
}
