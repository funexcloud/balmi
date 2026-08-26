import 'package:balmi/data/db/app_database.dart';
import 'package:balmi/data/repositories/farm_repository.dart';
import 'package:balmi/domain/engines/farm_slot_move.dart';
import 'package:balmi/domain/models/farm/farm_slot.dart';
import 'package:balmi/domain/models/farm/farm_tier.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('canRearrangeFarmSlots', () {
    FarmSlotView crop({
      required String id,
      UserFarmSlot? occupant,
      bool unlocked = true,
      int unlock = 1,
    }) =>
        FarmSlotView(
          template: SlotTemplate(
            slotId: id,
            slotType: SlotType.crop,
            xPct: 40,
            yPct: 60,
            zIndex: 1,
            unlockTileCount: unlock,
          ),
          occupant: occupant,
          unlocked: unlocked,
        );

    FarmSlotView livestock({
      required String id,
      UserFarmSlot? occupant,
      bool unlocked = true,
    }) =>
        FarmSlotView(
          template: SlotTemplate(
            slotId: id,
            slotType: SlotType.livestock,
            xPct: 25,
            yPct: 78,
            zIndex: 5,
            unlockTileCount: 1,
          ),
          occupant: occupant,
          unlocked: unlocked,
        );

    UserFarmSlot cropOcc(String slotId, {String cropId = 'crop_carrot_01'}) =>
        UserFarmSlot(
          id: 1,
          slotId: slotId,
          occupantType: OccupantType.crop,
          cropId: cropId,
          cumulativeWater: 10,
          cumulativeNutrient: 5,
          cumulativeFeed: 0,
          currentStageIndex: 1,
          isDormant: false,
          plantedAt: DateTime(2026, 8, 26),
        );

    UserFarmSlot animalOcc(String slotId) => UserFarmSlot(
          id: 2,
          slotId: slotId,
          occupantType: OccupantType.livestock,
          animalId: 'animal_chicken_01',
          cumulativeWater: 0,
          cumulativeNutrient: 0,
          cumulativeFeed: 20,
          currentStageIndex: 1,
          isDormant: false,
          plantedAt: DateTime(2026, 8, 26),
        );

    test('allows crop↔crop and livestock↔livestock', () {
      expect(
        canRearrangeFarmSlots(
          from: crop(id: 'garden_1', occupant: cropOcc('garden_1')),
          to: crop(id: 'garden_2'),
        ),
        isTrue,
      );
      expect(
        canRearrangeFarmSlots(
          from: livestock(id: 'pasture_1', occupant: animalOcc('pasture_1')),
          to: livestock(id: 'pasture_2'),
        ),
        isTrue,
      );
    });

    test('rejects cross-type, locked, empty source, same slot', () {
      expect(
        canRearrangeFarmSlots(
          from: crop(id: 'garden_1', occupant: cropOcc('garden_1')),
          to: livestock(id: 'pasture_1'),
        ),
        isFalse,
      );
      expect(
        canRearrangeFarmSlots(
          from: crop(id: 'garden_1', occupant: cropOcc('garden_1')),
          to: crop(id: 'garden_2', unlocked: false),
        ),
        isFalse,
      );
      expect(
        canRearrangeFarmSlots(
          from: crop(id: 'garden_1'),
          to: crop(id: 'garden_2'),
        ),
        isFalse,
      );
      expect(
        canRearrangeFarmSlots(
          from: crop(id: 'garden_1', occupant: cropOcc('garden_1')),
          to: crop(id: 'garden_1', occupant: cropOcc('garden_1')),
        ),
        isFalse,
      );
    });
  });

  group('FarmRepository.moveOccupantBetweenSlots', () {
    late AppDatabase db;
    late FarmRepository repo;

    setUp(() {
      db = AppDatabase.executor(NativeDatabase.memory());
      repo = FarmRepository(db);
    });

    tearDown(() => db.close());

    test('moves crop to empty garden and persists slot_id', () async {
      await repo.ensureInitialized();
      final planted = await repo.plantCrop(
        slotId: 'garden_1',
        cropId: 'crop_carrot_01',
      );
      expect(planted, isNotNull);

      final ok = await repo.moveOccupantBetweenSlots(
        fromSlotId: 'garden_1',
        toSlotId: 'garden_2',
        ownedTileCount: 12,
      );
      expect(ok, isTrue);

      final slots = await repo.listUserSlots();
      expect(slots.where((s) => !s.isEmpty), hasLength(1));
      final moved = slots.singleWhere((s) => !s.isEmpty);
      expect(moved.slotId, 'garden_2');
      expect(moved.cropId, 'crop_carrot_01');
      expect(moved.cumulativeWater, 0);
    });

    test('swaps two livestock and preserves growth stats', () async {
      await repo.ensureInitialized();
      final a = await repo.adoptAnimal(
        slotId: 'pasture_1',
        animalId: 'animal_chicken_01',
      );
      final b = await repo.adoptAnimal(
        slotId: 'pasture_2',
        animalId: 'animal_sheep_01',
      );
      expect(a, isNotNull);
      expect(b, isNotNull);

      await db.customStatement(
        '''
UPDATE user_farm_slots SET cumulative_feed = 60, current_stage_index = 2
WHERE id = ?
''',
        [a!.id],
      );
      await db.customStatement(
        '''
UPDATE user_farm_slots SET cumulative_feed = 10, current_stage_index = 0
WHERE id = ?
''',
        [b!.id],
      );

      final ok = await repo.moveOccupantBetweenSlots(
        fromSlotId: 'pasture_1',
        toSlotId: 'pasture_2',
        ownedTileCount: 12,
      );
      expect(ok, isTrue);

      final p1 = (await repo.listUserSlots())
          .firstWhere((s) => s.slotId == 'pasture_1');
      final p2 = (await repo.listUserSlots())
          .firstWhere((s) => s.slotId == 'pasture_2');
      expect(p1.animalId, 'animal_sheep_01');
      expect(p1.cumulativeFeed, 10);
      expect(p2.animalId, 'animal_chicken_01');
      expect(p2.cumulativeFeed, 60);
      expect(p2.currentStageIndex, 2);
    });

    test('rejects locked destination and cross-type', () async {
      await repo.ensureInitialized();
      await repo.plantCrop(slotId: 'garden_1', cropId: 'crop_carrot_01');
      await repo.adoptAnimal(
        slotId: 'pasture_1',
        animalId: 'animal_chicken_01',
      );

      // garden_3 unlocks at 8 tiles — locked with ownedTileCount=1
      expect(
        await repo.moveOccupantBetweenSlots(
          fromSlotId: 'garden_1',
          toSlotId: 'garden_3',
          ownedTileCount: 1,
        ),
        isFalse,
      );
      expect(
        await repo.moveOccupantBetweenSlots(
          fromSlotId: 'garden_1',
          toSlotId: 'pasture_2',
          ownedTileCount: 12,
        ),
        isFalse,
      );

      final still = (await repo.listUserSlots())
          .firstWhere((s) => s.slotId == 'garden_1');
      expect(still.cropId, 'crop_carrot_01');
    });
  });
}
