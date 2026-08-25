import 'package:balmi/data/db/app_database.dart';
import 'package:balmi/data/repositories/farm_repository.dart';
import 'package:balmi/domain/engines/farm_milestone.dart';
import 'package:balmi/domain/engines/farm_resource.dart';
import 'package:balmi/domain/models/farm/farm_tier.dart';
import 'package:balmi/domain/models/farm/milestone.dart';
import 'package:balmi/domain/models/farm/social.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late FarmRepository repo;

  setUp(() {
    db = AppDatabase.executor(NativeDatabase.memory());
    repo = FarmRepository(db);
  });

  tearDown(() => db.close());

  test('migration v7 creates master crop and animal definitions', () async {
    await repo.ensureInitialized();
    final crops = await repo.listCropDefinitions();
    final animals = await repo.listAnimalDefinitions();
    expect(crops.any((c) => c.cropId == 'crop_tomato_01'), isTrue);
    expect(crops.firstWhere((c) => c.cropId == 'crop_tomato_01').stages.length, 5);
    expect(animals.any((a) => a.animalId == 'animal_sheep_01'), isTrue);
    expect(await repo.listSlotTemplates(), isNotEmpty);
    expect(await repo.listMilestoneDefinitions(), isNotEmpty);
  });

  test('grantSessionResources logs VASA raw + granted values', () async {
    await repo.ensureInitialized();
    final grant = await repo.grantSessionResources(
      sessionId: 'sess-1',
      input: const SessionResourceInput(
        distanceKm: 5,
        avgPaceRatio: 0.95,
        streakDays: 3,
      ),
    );
    expect(grant.feedRaw, 40);
    expect(grant.waterGranted, greaterThan(40));

    final balances = await repo.loadResources();
    expect(balances.feedBalance, grant.totalFeed);
    expect(balances.waterBalance, grant.waterGranted);
    expect(balances.nutrientBalance, grant.totalNutrient);

    final log = await repo.listResourceLog();
    expect(log, hasLength(1));
    expect(log.first.runSessionId, 'sess-1');
    expect(log.first.feedRaw, grant.feedRaw);
    expect(log.first.feedGranted, grant.feedGranted);
  });

  test('plant crop, apply water+nutrient, harvest awards milestone', () async {
    await repo.ensureInitialized();
    for (var i = 0; i < 5; i++) {
      await repo.grantSessionResources(
        sessionId: 'sess-walk-$i',
        input: const SessionResourceInput(
          distanceKm: 10,
          avgPaceRatio: 1.0,
          streakDays: 0,
        ),
      );
    }

    final planted = await repo.plantCrop(
      slotId: 'garden_1',
      cropId: 'crop_carrot_01',
    );
    expect(planted, isNotNull);

    final crop = await repo.cropById('crop_carrot_01');
    expect(crop, isNotNull);
    final harvest = crop!.harvestStage!;
    await repo.applyResourceToSlot(
      slotRowId: planted!.id,
      type: FarmResourceType.water,
      amount: harvest.waterThreshold,
    );
    await repo.applyResourceToSlot(
      slotRowId: planted.id,
      type: FarmResourceType.nutrient,
      amount: harvest.nutrientThreshold,
    );

    final result = await repo.harvestCrop(planted.id);
    expect(result, isNotNull);
    expect(result!.newMilestones.any((m) => m.milestoneId == 'first_harvest'), isTrue);

    final badges = await repo.listUserBadges();
    expect(badges.any((b) => b.badgeId == 'badge_first_harvest'), isTrue);
  });

  test('adopt animal and collect yield after cooldown', () async {
    await repo.ensureInitialized();
    await repo.grantSessionResources(
      sessionId: 'sess-feed',
      input: const SessionResourceInput(
        distanceKm: 50,
        avgPaceRatio: 1.0,
        streakDays: 0,
      ),
    );
    await db.customStatement(
      'UPDATE user_resources SET feed_balance = 500 WHERE user_id = ?',
      [kFarmLocalUserId],
    );

    final adopted = await repo.adoptAnimal(
      slotId: 'pasture_1',
      animalId: 'animal_chicken_01',
    );
    expect(adopted, isNotNull);

    final animal = (await repo.animalById('animal_chicken_01'))!;
    await repo.applyResourceToSlot(
      slotRowId: adopted!.id,
      type: FarmResourceType.feed,
      amount: animal.adultFeedThreshold,
    );

    final yield1 = await repo.collectAnimalYield(adopted.id);
    expect(yield1, isNotNull);

    final yield2 = await repo.collectAnimalYield(adopted.id);
    expect(yield2, isNull);
  });

  test('umatchi once per friend per day', () async {
    await repo.ensureInitialized();
    await repo.grantSessionResources(
      sessionId: 'sess-gift',
      input: const SessionResourceInput(
        distanceKm: 10,
        avgPaceRatio: 1.0,
        streakDays: 0,
      ),
    );

    final at = DateTime(2026, 8, 25, 14);
    final ok1 = await repo.sendUmatchi(
      helperUserId: kFarmLocalUserId,
      recipientUserId: 'friend-a',
      resourceType: FarmResourceType.water,
      now: at,
    );
    final ok2 = await repo.sendUmatchi(
      helperUserId: kFarmLocalUserId,
      recipientUserId: 'friend-a',
      resourceType: FarmResourceType.water,
      now: at.add(const Duration(hours: 2)),
    );
    expect(ok1, isTrue);
    expect(ok2, isFalse);
  });

  test('farm level from FXP ladder', () {
    const levels = [
      FarmLevelDefinition(farmLevel: 1, requiredFxp: 0),
      FarmLevelDefinition(farmLevel: 3, requiredFxp: 500),
      FarmLevelDefinition(farmLevel: 5, requiredFxp: 1500),
    ];
    expect(farmLevelForXp(0, levels), 1);
    expect(farmLevelForXp(500, levels), 3);
    expect(farmLevelForXp(1499, levels), 3);
    expect(farmLevelForXp(1500, levels), 5);
  });

  test('social helpers enforce daily caps', () {
    final prior = [
      UmatchiAction(
        id: 1,
        helperUserId: 'a',
        recipientUserId: 'local',
        resourceType: FarmResourceType.water,
        amount: 20,
        actionDate: '2026-08-25',
        createdAt: DateTime(2026, 8, 25),
      ),
    ];
    expect(
      canSendUmatchi(
        helperId: 'b',
        recipientId: 'local',
        todayKey: '2026-08-25',
        prior: prior,
      ),
      isTrue,
    );
    expect(
      recipientUnderDailyCap(
        recipientId: 'local',
        todayKey: '2026-08-25',
        prior: List.generate(
          5,
          (i) => UmatchiAction(
            id: i,
            helperUserId: 'x$i',
            recipientUserId: 'local',
            resourceType: FarmResourceType.water,
            amount: 20,
            actionDate: '2026-08-25',
            createdAt: DateTime(2026, 8, 25),
          ),
        ),
      ),
      isFalse,
    );
  });
}
