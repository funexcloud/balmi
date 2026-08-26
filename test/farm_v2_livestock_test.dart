import 'package:balmi/core/copy.dart';
import 'package:balmi/data/db/app_database.dart';
import 'package:balmi/data/repositories/farm_repository.dart';
import 'package:balmi/domain/engines/farm_animal.dart';
import 'package:balmi/domain/engines/farm_scene_ui.dart';
import 'package:balmi/domain/models/farm/animal.dart';
import 'package:balmi/domain/models/farm/farm_slot.dart';
import 'package:balmi/domain/models/farm/farm_tier.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

AnimalDefinition sheepDef() => AnimalDefinition(
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
        AnimalStage(
          stageIndex: 2,
          stageName: '성체',
          feedThreshold: 900,
          spriteAssetKey: 'animal/sheep/stage_2',
        ),
      ],
    );

AnimalDefinition cowDef() => AnimalDefinition(
      animalId: 'animal_cow_01',
      nameKr: '소',
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
          stageName: '송아지',
          feedThreshold: 0,
          spriteAssetKey: 'animal/cow/stage_0',
        ),
        AnimalStage(
          stageIndex: 1,
          stageName: '성장',
          feedThreshold: 600,
          spriteAssetKey: 'animal/cow/stage_1',
        ),
        AnimalStage(
          stageIndex: 2,
          stageName: '성체',
          feedThreshold: 1800,
          spriteAssetKey: 'animal/cow/stage_2',
        ),
      ],
    );

AnimalDefinition chickenDef() => AnimalDefinition(
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
          stageIndex: 3,
          stageName: '암탉',
          feedThreshold: 120,
          spriteAssetKey: 'animal/chicken/stage_3',
        ),
      ],
    );

void main() {
  group('sheep & cow narrative', () {
    test('sheep starts as lamb, grows with feed', () {
      final sheep = sheepDef();
      expect(sheep.startsAsYoung, isTrue);
      expect(sheep.startsAsEgg, isFalse);
      expect(sheep.adultFeedThreshold, 900);

      final young = evaluateAnimal(
        animal: sheep,
        cumulativeFeed: 0,
        currentStageIndex: 0,
        lastYieldAt: null,
        isDormant: false,
        now: DateTime(2026, 8, 26),
      );
      expect(young.state, AnimalYieldState.growing);
      expect(animalGrowingStatusLine(animal: sheep, stageIndex: 0),
          '양 · 새끼양이 자라고 있어요');
      expect(farmAdoptedCopy(sheep), BalmiCopy.farmBirthSheep);

      expect(
        animalStageAfterFeed(
          animal: sheep,
          cumulativeFeed: 300,
          currentStageIndex: 0,
        ),
        1,
      );
      expect(
        animalStageAfterFeed(
          animal: sheep,
          cumulativeFeed: 900,
          currentStageIndex: 1,
        ),
        2,
      );
    });

    test('cow starts as calf named 소', () {
      final cow = cowDef();
      expect(cow.nameKr, '소');
      expect(cow.startsAsYoung, isTrue);
      expect(animalGrowingStatusLine(animal: cow, stageIndex: 0),
          '소 · 송아지가 자라고 있어요');
      expect(farmAdoptedCopy(cow), BalmiCopy.farmBirthCow);
    });

    test('empty slot CTA is 품기 for egg, 입양 for sheep/cow', () {
      expect(emptyLivestockSlotLabel(chickenDef()), '품기');
      expect(emptyLivestockSlotLabel(sheepDef()), '입양');
      expect(emptyLivestockSlotLabel(cowDef()), '입양');

      const empty = FarmSlotView(
        template: SlotTemplate(
          slotId: 'pasture_1',
          slotType: SlotType.livestock,
          xPct: 25,
          yPct: 78,
          zIndex: 5,
          unlockTileCount: 1,
        ),
        occupant: null,
        unlocked: true,
      );
      expect(
        slotDisplayLabel(
          slot: empty,
          crop: null,
          animal: null,
          nextAdoptable: sheepDef(),
        ),
        '입양',
      );
    });

    test('pickNextAdoptableAnimal prefers missing unlocked species', () {
      final catalog = [chickenDef(), sheepDef(), cowDef()];
      expect(
        pickNextAdoptableAnimal(
          catalog: catalog,
          occupiedAnimalIds: const [],
          farmLevel: 1,
        )?.animalId,
        'animal_chicken_01',
      );
      expect(
        pickNextAdoptableAnimal(
          catalog: catalog,
          occupiedAnimalIds: const ['animal_chicken_01'],
          farmLevel: 5,
        )?.animalId,
        'animal_sheep_01',
      );
      expect(
        pickNextAdoptableAnimal(
          catalog: catalog,
          occupiedAnimalIds: const ['animal_chicken_01', 'animal_sheep_01'],
          farmLevel: 8,
        )?.animalId,
        'animal_cow_01',
      );
      // Level 1 cannot unlock sheep yet.
      expect(
        pickNextAdoptableAnimal(
          catalog: catalog,
          occupiedAnimalIds: const ['animal_chicken_01'],
          farmLevel: 1,
        )?.animalId,
        'animal_chicken_01',
      );
    });
  });

  group('repository sheep/cow', () {
    late AppDatabase db;
    late FarmRepository repo;

    setUp(() {
      db = AppDatabase.executor(NativeDatabase.memory());
      repo = FarmRepository(db);
    });

    tearDown(() => db.close());

    test('seed includes sheep and cow with young stages', () async {
      await repo.ensureInitialized();
      final animals = await repo.listAnimalDefinitions();
      final sheep = animals.firstWhere((a) => a.animalId == 'animal_sheep_01');
      final cow = animals.firstWhere((a) => a.animalId == 'animal_cow_01');
      expect(sheep.nameKr, '양');
      expect(sheep.stageAt(0)?.stageName, '새끼양');
      expect(cow.nameKr, '소');
      expect(cow.stageAt(0)?.stageName, '송아지');
    });

    test('adopt sheep and apply feed advances stage', () async {
      await repo.ensureInitialized();
      await db.customStatement(
        'UPDATE user_resources SET feed_balance = 2000 WHERE user_id = ?',
        [kFarmLocalUserId],
      );
      await db.customStatement(
        'UPDATE user_farm SET farm_level = 5 WHERE user_id = ?',
        [kFarmLocalUserId],
      );

      final adopted = await repo.adoptAnimal(
        slotId: 'pasture_1',
        animalId: 'animal_sheep_01',
      );
      expect(adopted, isNotNull);
      expect(adopted!.currentStageIndex, 0);

      final grown = await repo.applyResourceToSlot(
        slotRowId: adopted.id,
        type: FarmResourceType.feed,
        amount: 300,
      );
      expect(grown, isNotNull);
      expect(grown!.currentStageIndex, 1);
      expect(grown.cumulativeFeed, 300);
    });

    test('adopt cow and apply feed advances toward adult', () async {
      await repo.ensureInitialized();
      await db.customStatement(
        'UPDATE user_resources SET feed_balance = 5000 WHERE user_id = ?',
        [kFarmLocalUserId],
      );

      final adopted = await repo.adoptAnimal(
        slotId: 'pasture_2',
        animalId: 'animal_cow_01',
      );
      expect(adopted, isNotNull);

      final mid = await repo.applyResourceToSlot(
        slotRowId: adopted!.id,
        type: FarmResourceType.feed,
        amount: 600,
      );
      expect(mid!.currentStageIndex, 1);

      final adult = await repo.applyResourceToSlot(
        slotRowId: adopted.id,
        type: FarmResourceType.feed,
        amount: 1200,
      );
      expect(adult!.currentStageIndex, 2);
      expect(adult.cumulativeFeed, 1800);
    });
  });
}
