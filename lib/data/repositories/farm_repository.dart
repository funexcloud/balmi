import 'package:drift/drift.dart';

import '../../domain/engines/farm_animal.dart';
import '../../domain/engines/farm_crop.dart';
import '../../domain/engines/farm_milestone.dart';
import '../../domain/engines/farm_resource.dart';
import '../../domain/models/farm/animal.dart';
import '../../domain/models/farm/crop.dart';
import '../../domain/models/farm/farm_slot.dart';
import '../../domain/models/farm/farm_state.dart';
import '../../domain/models/farm/farm_tier.dart';
import '../../domain/models/farm/milestone.dart';
import '../../domain/models/farm/social.dart';
import '../db/app_database.dart';
import '../db/farm_v2_schema.dart';

const kFarmLocalUserId = 'local';
const kFarmUmatchiDailyCap = 5;

class FarmRepository {
  FarmRepository(this.db);

  final AppDatabase db;

  Future<void> ensureInitialized() async {
    await createFarmV2Tables(db);
    await seedFarmV2MasterData(db);
    await patchFarmV2ChickenEggNarrative(db);
    await patchFarmV2LivestockSheepCowNarrative(db);
    final now = DateTime.now();
    final ms = now.millisecondsSinceEpoch;
    await db.customStatement(
      '''
INSERT INTO user_farm (user_id, farm_level, farm_xp, updated_at)
VALUES (?, 1, 0, ?)
ON CONFLICT(user_id) DO NOTHING
''',
      [kFarmLocalUserId, ms],
    );
    await db.customStatement(
      '''
INSERT INTO user_resources (
  user_id, feed_balance, water_balance, nutrient_balance, updated_at
) VALUES (?, 0, 0, 0, ?)
ON CONFLICT(user_id) DO NOTHING
''',
      [kFarmLocalUserId, ms],
    );
  }

  Future<UserFarmState> loadFarm() async {
    await ensureInitialized();
    final row = await db.customSelect(
      'SELECT * FROM user_farm WHERE user_id = ?',
      variables: [Variable.withString(kFarmLocalUserId)],
    ).getSingle();
    return UserFarmState(
      farmLevel: row.read<int>('farm_level'),
      farmXp: row.read<int>('farm_xp'),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.read<int>('updated_at')),
    );
  }

  Future<UserResourceBalances> loadResources() async {
    await ensureInitialized();
    final row = await db.customSelect(
      'SELECT * FROM user_resources WHERE user_id = ?',
      variables: [Variable.withString(kFarmLocalUserId)],
    ).getSingle();
    return UserResourceBalances(
      feedBalance: row.read<int>('feed_balance'),
      waterBalance: row.read<int>('water_balance'),
      nutrientBalance: row.read<int>('nutrient_balance'),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.read<int>('updated_at')),
    );
  }

  Future<int> todayFeedGranted({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final dayStart = DateTime(at.year, at.month, at.day);
    final rows = await db.customSelect(
      '''
SELECT COALESCE(SUM(feed_granted), 0) AS total
FROM resource_transaction_log
WHERE user_id = ? AND created_at >= ?
''',
      variables: [
        Variable.withString(kFarmLocalUserId),
        Variable.withInt(dayStart.millisecondsSinceEpoch),
      ],
    ).getSingle();
    return rows.read<int>('total');
  }

  Future<bool> hasSessionGrant(String sessionId) async {
    await ensureInitialized();
    final row = await db.customSelect(
      '''
SELECT 1 AS ok FROM resource_transaction_log
WHERE user_id = ? AND run_session_id = ?
LIMIT 1
''',
      variables: [
        Variable.withString(kFarmLocalUserId),
        Variable.withString(sessionId),
      ],
    ).getSingleOrNull();
    return row != null;
  }

  Future<SessionResourceGrant> grantSessionResources({
    required String sessionId,
    required SessionResourceInput input,
    DateTime? now,
  }) async {
    await ensureInitialized();
    if (await hasSessionGrant(sessionId)) {
      return convertSessionResources(input);
    }
    final at = now ?? DateTime.now();
    final todayFeed = await todayFeedGranted(now: at);
    final grant = convertSessionResources(
      SessionResourceInput(
        distanceKm: input.distanceKm,
        avgPaceRatio: input.avgPaceRatio,
        streakDays: input.streakDays,
        newTilesClaimed: input.newTilesClaimed,
        todayFeedGranted: todayFeed,
      ),
    );

    await db.customStatement(
      '''
INSERT INTO resource_transaction_log (
  user_id, run_session_id, feed_raw, feed_granted, water_granted,
  nutrient_raw, nutrient_granted, new_tiles_claimed, streak_days_at_time,
  created_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
''',
      [
        kFarmLocalUserId,
        sessionId,
        grant.feedRaw,
        grant.feedGranted,
        grant.waterGranted,
        grant.nutrientRaw,
        grant.nutrientGranted,
        input.newTilesClaimed,
        input.streakDays,
        at.millisecondsSinceEpoch,
      ],
    );

    await db.customStatement(
      '''
UPDATE user_resources SET
  feed_balance = feed_balance + ?,
  water_balance = water_balance + ?,
  nutrient_balance = nutrient_balance + ?,
  updated_at = ?
WHERE user_id = ?
''',
      [
        grant.totalFeed,
        grant.waterGranted,
        grant.totalNutrient,
        at.millisecondsSinceEpoch,
        kFarmLocalUserId,
      ],
    );

    if (grant.waterGranted > 0) {
      await _updateWaterResourceStreak(at);
    }

    return grant;
  }

  Future<void> _updateWaterResourceStreak(DateTime at) async {
    final todayKey = localDateKey(at);
    final lastRow = await db.customSelect(
      "SELECT value FROM app_kv WHERE key = 'farm_v2_last_water_grant_day'",
    ).getSingleOrNull();
    if (lastRow?.read<String>('value') == todayKey) return;

    final streakRow = await db.customSelect(
      "SELECT value FROM app_kv WHERE key = 'farm_v2_water_streak'",
    ).getSingleOrNull();
    final current =
        int.tryParse(streakRow?.readNullable<String>('value') ?? '') ?? 0;

    var newStreak = 1;
    final lastKey = lastRow?.readNullable<String>('value');
    if (lastKey != null && lastKey.isNotEmpty) {
      final yesterday = at.toLocal().subtract(const Duration(days: 1));
      if (lastKey == localDateKey(yesterday)) {
        newStreak = current + 1;
      }
    }

    await db.into(db.appKv).insertOnConflictUpdate(
          AppKvCompanion.insert(
            key: 'farm_v2_last_water_grant_day',
            value: todayKey,
          ),
        );
    await db.into(db.appKv).insertOnConflictUpdate(
          AppKvCompanion.insert(
            key: 'farm_v2_water_streak',
            value: '$newStreak',
          ),
        );
  }

  Future<bool> spendResource({
    required FarmResourceType type,
    required int amount,
    DateTime? now,
  }) async {
    if (amount <= 0) return false;
    final balances = await loadResources();
    final current = switch (type) {
      FarmResourceType.feed => balances.feedBalance,
      FarmResourceType.water => balances.waterBalance,
      FarmResourceType.nutrient => balances.nutrientBalance,
    };
    if (current < amount) return false;

    final at = now ?? DateTime.now();
    final col = switch (type) {
      FarmResourceType.feed => 'feed_balance',
      FarmResourceType.water => 'water_balance',
      FarmResourceType.nutrient => 'nutrient_balance',
    };
    await db.customStatement(
      '''
UPDATE user_resources SET $col = $col - ?, updated_at = ?
WHERE user_id = ? AND $col >= ?
''',
      [amount, at.millisecondsSinceEpoch, kFarmLocalUserId, amount],
    );
    return true;
  }

  Future<List<CropDefinition>> listCropDefinitions() async {
    await ensureInitialized();
    final crops = await db.customSelect(
      'SELECT * FROM crop_definitions ORDER BY crop_id',
    ).get();
    final out = <CropDefinition>[];
    for (final c in crops) {
      final stages = await db.customSelect(
        '''
SELECT * FROM crop_stages WHERE crop_id = ? ORDER BY stage_index
''',
        variables: [Variable.withString(c.read<String>('crop_id'))],
      ).get();
      out.add(_cropFromRow(c, stages));
    }
    return out;
  }

  Future<CropDefinition?> cropById(String cropId) async {
    final all = await listCropDefinitions();
    for (final c in all) {
      if (c.cropId == cropId) return c;
    }
    return null;
  }

  Future<List<AnimalDefinition>> listAnimalDefinitions() async {
    await ensureInitialized();
    final animals = await db.customSelect(
      'SELECT * FROM animal_definitions ORDER BY animal_id',
    ).get();
    final out = <AnimalDefinition>[];
    for (final a in animals) {
      final stages = await db.customSelect(
        '''
SELECT * FROM animal_stages WHERE animal_id = ? ORDER BY stage_index
''',
        variables: [Variable.withString(a.read<String>('animal_id'))],
      ).get();
      out.add(_animalFromRow(a, stages));
    }
    return out;
  }

  Future<AnimalDefinition?> animalById(String animalId) async {
    final all = await listAnimalDefinitions();
    for (final a in all) {
      if (a.animalId == animalId) return a;
    }
    return null;
  }

  Future<List<SlotTemplate>> listSlotTemplates() async {
    await ensureInitialized();
    final rows = await db.customSelect(
      'SELECT * FROM slot_templates ORDER BY z_index, slot_id',
    ).get();
    return rows.map(_slotTemplateFromRow).toList();
  }

  Future<List<UserFarmSlot>> listUserSlots() async {
    await ensureInitialized();
    final rows = await db.customSelect(
      '''
SELECT * FROM user_farm_slots WHERE user_id = ? ORDER BY slot_id
''',
      variables: [Variable.withString(kFarmLocalUserId)],
    ).get();
    return rows.map(_userSlotFromRow).toList();
  }

  Future<List<FarmSlotView>> loadSlotViews({required int ownedTileCount}) async {
    final templates = await listSlotTemplates();
    final occupants = await listUserSlots();
    final bySlot = {for (final o in occupants) o.slotId: o};
    return [
      for (final t in templates)
        FarmSlotView(
          template: t,
          occupant: bySlot[t.slotId],
          unlocked: ownedTileCount >= t.unlockTileCount,
        ),
    ];
  }

  Future<FarmSnapshot> loadSnapshot({int ownedTileCount = 1}) async {
    final farm = await loadFarm();
    final resources = await loadResources();
    final slots = await loadSlotViews(ownedTileCount: ownedTileCount);
    final milestones = await listUserMilestones();
    final badges = await listUserBadges();
    return FarmSnapshot(
      farm: farm,
      resources: resources,
      slots: slots,
      milestones: milestones,
      badges: badges,
    );
  }

  Future<UserFarmSlot?> plantCrop({
    required String slotId,
    required String cropId,
    DateTime? now,
  }) async {
    await ensureInitialized();
    final template = (await listSlotTemplates())
        .where((t) => t.slotId == slotId)
        .firstOrNull;
    if (template == null || template.slotType != SlotType.crop) return null;

    final existing = await _slotOccupant(slotId);
    if (existing != null && !existing.isEmpty) return null;

    final at = now ?? DateTime.now();
    await db.customStatement(
      '''
INSERT INTO user_farm_slots (
  user_id, slot_id, occupant_type, crop_id, planted_at
) VALUES (?, ?, 'crop', ?, ?)
ON CONFLICT(user_id, slot_id) DO UPDATE SET
  occupant_type = 'crop',
  crop_id = excluded.crop_id,
  animal_id = NULL,
  cumulative_water = 0,
  cumulative_nutrient = 0,
  cumulative_feed = 0,
  current_stage_index = 0,
  is_dormant = 0,
  last_yield_at = NULL,
  planted_at = excluded.planted_at
''',
      [kFarmLocalUserId, slotId, cropId, at.millisecondsSinceEpoch],
    );
    return _slotOccupant(slotId);
  }

  Future<UserFarmSlot?> adoptAnimal({
    required String slotId,
    required String animalId,
    DateTime? now,
  }) async {
    await ensureInitialized();
    final template = (await listSlotTemplates())
        .where((t) => t.slotId == slotId)
        .firstOrNull;
    if (template == null || template.slotType != SlotType.livestock) {
      return null;
    }

    final existing = await _slotOccupant(slotId);
    if (existing != null && !existing.isEmpty) return null;

    final at = now ?? DateTime.now();
    await db.customStatement(
      '''
INSERT INTO user_farm_slots (
  user_id, slot_id, occupant_type, animal_id, planted_at
) VALUES (?, ?, 'livestock', ?, ?)
ON CONFLICT(user_id, slot_id) DO UPDATE SET
  occupant_type = 'livestock',
  animal_id = excluded.animal_id,
  crop_id = NULL,
  cumulative_water = 0,
  cumulative_nutrient = 0,
  cumulative_feed = 0,
  current_stage_index = 0,
  is_dormant = 0,
  last_yield_at = NULL,
  planted_at = excluded.planted_at
''',
      [kFarmLocalUserId, slotId, animalId, at.millisecondsSinceEpoch],
    );
    return _slotOccupant(slotId);
  }

  Future<UserFarmSlot?> applyResourceToSlot({
    required int slotRowId,
    required FarmResourceType type,
    required int amount,
    DateTime? now,
  }) async {
    if (amount <= 0) return null;
    final spent = await spendResource(type: type, amount: amount, now: now);
    if (!spent) return null;

    final slot = await _slotById(slotRowId);
    if (slot == null || slot.isEmpty || slot.isDormant) return null;

    final col = switch (type) {
      FarmResourceType.water => 'cumulative_water',
      FarmResourceType.nutrient => 'cumulative_nutrient',
      FarmResourceType.feed => 'cumulative_feed',
    };

    await db.customStatement(
      'UPDATE user_farm_slots SET $col = $col + ? WHERE id = ?',
      [amount, slotRowId],
    );

    final updated = (await _slotById(slotRowId))!;
    if (updated.occupantType == OccupantType.crop && updated.cropId != null) {
      final crop = await cropById(updated.cropId!);
      if (crop != null) {
        final newStage = cropStageAfterResources(
          crop: crop,
          cumulativeWater: updated.cumulativeWater,
          cumulativeNutrient: updated.cumulativeNutrient,
          currentStageIndex: updated.currentStageIndex,
        );
        if (newStage != updated.currentStageIndex) {
          await db.customStatement(
            '''
UPDATE user_farm_slots SET current_stage_index = ? WHERE id = ?
''',
            [newStage, slotRowId],
          );
        }
      }
    } else if (updated.occupantType == OccupantType.livestock &&
        updated.animalId != null) {
      final animal = await animalById(updated.animalId!);
      if (animal != null && type == FarmResourceType.feed) {
        final newStage = animalStageAfterFeed(
          animal: animal,
          cumulativeFeed: updated.cumulativeFeed,
          currentStageIndex: updated.currentStageIndex,
        );
        if (newStage != updated.currentStageIndex) {
          await db.customStatement(
            '''
UPDATE user_farm_slots SET current_stage_index = ? WHERE id = ?
''',
            [newStage, slotRowId],
          );
        }
      }
    }

    return _slotById(slotRowId);
  }

  Future<HarvestResult?> harvestCrop(int slotRowId, {DateTime? now}) async {
    final slot = await _slotById(slotRowId);
    if (slot == null ||
        slot.occupantType != OccupantType.crop ||
        slot.cropId == null) {
      return null;
    }
    final crop = await cropById(slot.cropId!);
    if (crop == null) return null;

    final hint = cropGrowthHint(
      crop: crop,
      cumulativeWater: slot.cumulativeWater,
      cumulativeNutrient: slot.cumulativeNutrient,
      currentStageIndex: slot.currentStageIndex,
      isDormant: slot.isDormant,
    );
    if (hint != CropGrowthHint.readyHarvest) return null;

    final at = now ?? DateTime.now();
    await _addFarmXp(crop.rewardXp, at);

    if (crop.regrow && crop.regrowWater != null && crop.regrowNutrient != null) {
      await db.customStatement(
        '''
UPDATE user_farm_slots SET
  cumulative_water = cumulative_water - ?,
  cumulative_nutrient = cumulative_nutrient - ?,
  current_stage_index = (
    SELECT MAX(stage_index) FROM crop_stages
    WHERE crop_id = ? AND stage_name != '수확'
  )
WHERE id = ?
''',
        [crop.regrowWater, crop.regrowNutrient, crop.cropId, slotRowId],
      );
    } else {
      await db.customStatement(
        '''
UPDATE user_farm_slots SET
  occupant_type = NULL,
  crop_id = NULL,
  cumulative_water = 0,
  cumulative_nutrient = 0,
  current_stage_index = 0
WHERE id = ?
''',
        [slotRowId],
      );
    }

    await _incrementHarvestStats(crop.cropId);
    final earned = await checkAndAwardMilestones(now: at);
    return HarvestResult(
      coin: crop.rewardCoin,
      xp: crop.rewardXp,
      cropId: crop.cropId,
      newMilestones: earned,
    );
  }

  Future<YieldResult?> collectAnimalYield(int slotRowId, {DateTime? now}) async {
    final slot = await _slotById(slotRowId);
    if (slot == null ||
        slot.occupantType != OccupantType.livestock ||
        slot.animalId == null) {
      return null;
    }
    final animal = await animalById(slot.animalId!);
    if (animal == null) return null;

    final at = now ?? DateTime.now();
    final status = evaluateAnimal(
      animal: animal,
      cumulativeFeed: slot.cumulativeFeed,
      currentStageIndex: slot.currentStageIndex,
      lastYieldAt: slot.lastYieldAt,
      isDormant: slot.isDormant,
      now: at,
    );
    if (!status.canCollect) return null;

    final feedOk = await spendResource(
      type: FarmResourceType.feed,
      amount: animal.feedPerCycle,
      now: at,
    );
    if (!feedOk) return null;

    await db.customStatement(
      '''
UPDATE user_farm_slots SET
  cumulative_feed = cumulative_feed - ?,
  last_yield_at = ?
WHERE id = ?
''',
      [animal.feedPerCycle, at.millisecondsSinceEpoch, slotRowId],
    );

    final coin = (animal.rewardCoin * status.yieldPenalty).round();
    final xp = (animal.rewardXp * status.yieldPenalty).round();
    await _addFarmXp(xp, at);

    final earned = await checkAndAwardMilestones(now: at);
    return YieldResult(
      coin: coin,
      xp: xp,
      animalId: animal.animalId,
      yieldPenalty: status.yieldPenalty,
      newMilestones: earned,
    );
  }

  Future<void> setSlotDormant(int slotRowId, bool dormant) async {
    await db.customStatement(
      'UPDATE user_farm_slots SET is_dormant = ? WHERE id = ?',
      [dormant ? 1 : 0, slotRowId],
    );
  }

  Future<List<MilestoneDefinition>> listMilestoneDefinitions() async {
    await ensureInitialized();
    final rows = await db.customSelect(
      'SELECT * FROM milestone_definitions ORDER BY milestone_id',
    ).get();
    return rows
        .map(
          (r) => MilestoneDefinition(
            milestoneId: r.read<String>('milestone_id'),
            conditionType: r.read<String>('condition_type'),
            conditionValue: r.readNullable<int>('condition_value'),
            bonusFxp: r.read<int>('bonus_fxp'),
            vasaSignal: r.readNullable<String>('vasa_signal'),
          ),
        )
        .toList();
  }

  Future<List<FarmLevelDefinition>> listFarmLevelDefinitions() async {
    await ensureInitialized();
    final rows = await db.customSelect(
      'SELECT * FROM farm_level_definitions ORDER BY farm_level',
    ).get();
    return rows
        .map(
          (r) => FarmLevelDefinition(
            farmLevel: r.read<int>('farm_level'),
            requiredFxp: r.read<int>('required_fxp'),
            unlockNote: r.readNullable<String>('unlock_note'),
          ),
        )
        .toList();
  }

  Future<List<UserMilestone>> listUserMilestones() async {
    await ensureInitialized();
    final rows = await db.customSelect(
      '''
SELECT milestone_id, achieved_at FROM user_milestones
WHERE user_id = ? ORDER BY achieved_at
''',
      variables: [Variable.withString(kFarmLocalUserId)],
    ).get();
    return rows
        .map(
          (r) => UserMilestone(
            milestoneId: r.read<String>('milestone_id'),
            achievedAt: DateTime.fromMillisecondsSinceEpoch(
              r.read<int>('achieved_at'),
            ),
          ),
        )
        .toList();
  }

  Future<List<UserBadge>> listUserBadges() async {
    await ensureInitialized();
    final rows = await db.customSelect(
      '''
SELECT badge_id, earned_at FROM user_badges
WHERE user_id = ? ORDER BY earned_at
''',
      variables: [Variable.withString(kFarmLocalUserId)],
    ).get();
    return rows
        .map(
          (r) => UserBadge(
            badgeId: r.read<String>('badge_id'),
            earnedAt: DateTime.fromMillisecondsSinceEpoch(
              r.read<int>('earned_at'),
            ),
          ),
        )
        .toList();
  }

  Future<List<MilestoneDefinition>> checkAndAwardMilestones({
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    final defs = await listMilestoneDefinitions();
    final earned = await listUserMilestones();
    final earnedIds = earned.map((e) => e.milestoneId).toSet();
    final ctx = await _milestoneContext();
    final fresh = newlyEarnedMilestones(
      definitions: defs,
      alreadyEarned: earnedIds,
      ctx: ctx,
    );

    for (final m in fresh) {
      await db.customStatement(
        '''
INSERT INTO user_milestones (user_id, milestone_id, achieved_at)
VALUES (?, ?, ?)
ON CONFLICT(user_id, milestone_id) DO NOTHING
''',
        [kFarmLocalUserId, m.milestoneId, at.millisecondsSinceEpoch],
      );
      await _addFarmXp(m.bonusFxp, at);

      await db.customStatement(
        '''
INSERT INTO user_badges (user_id, badge_id, earned_at)
SELECT ?, badge_id, ?
FROM badge_definitions WHERE milestone_id = ?
ON CONFLICT(user_id, badge_id) DO NOTHING
''',
        [kFarmLocalUserId, at.millisecondsSinceEpoch, m.milestoneId],
      );
    }

    if (fresh.isNotEmpty) {
      await _refreshFarmLevel(at);
    }
    return fresh;
  }

  Future<List<ResourceTransaction>> listResourceLog({int limit = 50}) async {
    await ensureInitialized();
    final rows = await db.customSelect(
      '''
SELECT * FROM resource_transaction_log
WHERE user_id = ?
ORDER BY created_at DESC
LIMIT ?
''',
      variables: [
        Variable.withString(kFarmLocalUserId),
        Variable.withInt(limit),
      ],
    ).get();
    return rows
        .map(
          (r) => ResourceTransaction(
            id: r.read<int>('id'),
            runSessionId: r.read<String>('run_session_id'),
            feedRaw: r.read<int>('feed_raw'),
            feedGranted: r.read<int>('feed_granted'),
            waterGranted: r.read<int>('water_granted'),
            nutrientRaw: r.read<int>('nutrient_raw'),
            nutrientGranted: r.read<int>('nutrient_granted'),
            newTilesClaimed: r.read<int>('new_tiles_claimed'),
            streakDaysAtTime: r.read<int>('streak_days_at_time'),
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              r.read<int>('created_at'),
            ),
          ),
        )
        .toList();
  }

  // --- Social (spec §13.4) ---

  Future<bool> sendUmatchi({
    required String helperUserId,
    required String recipientUserId,
    required FarmResourceType resourceType,
    int amount = umatchiDefaultAmount,
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    final dayKey = localDateKey(at);
    final prior = await listUmatchiActions(sinceDays: 2);
    if (!canSendUmatchi(
      helperId: helperUserId,
      recipientId: recipientUserId,
      todayKey: dayKey,
      prior: prior,
    )) {
      return false;
    }
    if (!recipientUnderDailyCap(
      recipientId: recipientUserId,
      todayKey: dayKey,
      prior: prior,
      maxPerDay: kFarmUmatchiDailyCap,
    )) {
      return false;
    }

    if (helperUserId == kFarmLocalUserId) {
      final ok = await spendResource(type: resourceType, amount: amount, now: at);
      if (!ok) return false;
    }

    await db.customStatement(
      '''
INSERT INTO umatchi_actions (
  helper_user_id, recipient_user_id, resource_type, amount, action_date, created_at
) VALUES (?, ?, ?, ?, ?, ?)
''',
      [
        helperUserId,
        recipientUserId,
        resourceType.wire,
        amount,
        dayKey,
        at.millisecondsSinceEpoch,
      ],
    );

    if (recipientUserId == kFarmLocalUserId) {
      final col = switch (resourceType) {
        FarmResourceType.feed => 'feed_balance',
        FarmResourceType.water => 'water_balance',
        FarmResourceType.nutrient => 'nutrient_balance',
      };
      await db.customStatement(
        '''
UPDATE user_resources SET $col = $col + ?, updated_at = ?
WHERE user_id = ?
''',
        [amount, at.millisecondsSinceEpoch, kFarmLocalUserId],
      );
    }

    if (helperUserId == kFarmLocalUserId) {
      await _addFarmXp(umatchiHelperFxpReward, at);
    }
    return true;
  }

  Future<List<UmatchiAction>> listUmatchiActions({int sinceDays = 30}) async {
    await ensureInitialized();
    final since = DateTime.now()
        .subtract(Duration(days: sinceDays))
        .millisecondsSinceEpoch;
    final rows = await db.customSelect(
      '''
SELECT * FROM umatchi_actions WHERE created_at >= ? ORDER BY created_at DESC
''',
      variables: [Variable.withInt(since)],
    ).get();
    return rows.map(_umatchiFromRow).toList();
  }

  Future<List<ReactionDefinition>> listReactionDefinitions() async {
    await ensureInitialized();
    final rows = await db.customSelect(
      'SELECT * FROM reaction_definitions ORDER BY reaction_id',
    ).get();
    return rows
        .map(
          (r) => ReactionDefinition(
            reactionId: r.read<String>('reaction_id'),
            textKr: r.read<String>('text_kr'),
            iconAssetKey: r.read<String>('icon_asset_key'),
          ),
        )
        .toList();
  }

  Future<void> sendReaction({
    required String senderUserId,
    required String recipientUserId,
    required String reactionId,
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    await db.customStatement(
      '''
INSERT INTO reaction_sent_log (
  sender_user_id, recipient_user_id, reaction_id, created_at
) VALUES (?, ?, ?, ?)
''',
      [
        senderUserId,
        recipientUserId,
        reactionId,
        at.millisecondsSinceEpoch,
      ],
    );
  }

  Future<UserFarmSlot?> _slotOccupant(String slotId) async {
    final rows = await db.customSelect(
      '''
SELECT * FROM user_farm_slots
WHERE user_id = ? AND slot_id = ?
''',
      variables: [
        Variable.withString(kFarmLocalUserId),
        Variable.withString(slotId),
      ],
    ).get();
    if (rows.isEmpty) return null;
    return _userSlotFromRow(rows.first);
  }

  Future<UserFarmSlot?> _slotById(int id) async {
    final rows = await db.customSelect(
      'SELECT * FROM user_farm_slots WHERE id = ?',
      variables: [Variable.withInt(id)],
    ).get();
    if (rows.isEmpty) return null;
    return _userSlotFromRow(rows.first);
  }

  Future<void> _addFarmXp(int xp, DateTime at) async {
    if (xp <= 0) return;
    await db.customStatement(
      '''
UPDATE user_farm SET farm_xp = farm_xp + ?, updated_at = ?
WHERE user_id = ?
''',
      [xp, at.millisecondsSinceEpoch, kFarmLocalUserId],
    );
    await _refreshFarmLevel(at);
  }

  Future<void> _refreshFarmLevel(DateTime at) async {
    final farm = await loadFarm();
    final levels = await listFarmLevelDefinitions();
    final newLevel = farmLevelForXp(farm.farmXp, levels);
    if (newLevel != farm.farmLevel) {
      await db.customStatement(
        '''
UPDATE user_farm SET farm_level = ?, updated_at = ? WHERE user_id = ?
''',
        [newLevel, at.millisecondsSinceEpoch, kFarmLocalUserId],
      );
    }
  }

  Future<MilestoneContext> _milestoneContext() async {
    final farm = await loadFarm();
    final harvestRow = await db.customSelect(
      '''
SELECT value FROM app_kv WHERE key = 'farm_v2_harvest_count'
''',
    ).getSingleOrNull();
    final diversityRow = await db.customSelect(
      '''
SELECT value FROM app_kv WHERE key = 'farm_v2_crop_diversity'
''',
    ).getSingleOrNull();
    final streakRow = await db.customSelect(
      '''
SELECT value FROM app_kv WHERE key = 'farm_v2_water_streak'
''',
    ).getSingleOrNull();

    final slots = await listUserSlots();
    final livestock = slots.where(
      (s) => s.occupantType == OccupantType.livestock && !s.isEmpty,
    );

    return MilestoneContext(
      harvestCount: int.tryParse(harvestRow?.read<String>('value') ?? '') ?? 0,
      distinctCropsHarvested:
          int.tryParse(diversityRow?.read<String>('value') ?? '') ?? 0,
      waterStreakDays: int.tryParse(streakRow?.read<String>('value') ?? '') ?? 0,
      livestockCount: livestock.length,
      farmLevel: farm.farmLevel,
    );
  }

  Future<void> _incrementHarvestStats(String cropId) async {
    final harvestRow = await db.customSelect(
      "SELECT value FROM app_kv WHERE key = 'farm_v2_harvest_count'",
    ).getSingleOrNull();
    final count = (int.tryParse(harvestRow?.read<String>('value') ?? '') ?? 0) + 1;
    await db.into(db.appKv).insertOnConflictUpdate(
          AppKvCompanion.insert(
            key: 'farm_v2_harvest_count',
            value: '$count',
          ),
        );

    final cropsRow = await db.customSelect(
      "SELECT value FROM app_kv WHERE key = 'farm_v2_harvested_crops'",
    ).getSingleOrNull();
    final set = <String>{};
    final raw = cropsRow?.readNullable<String>('value');
    if (raw != null && raw.isNotEmpty) {
      set.addAll(raw.split(','));
    }
    set.add(cropId);
    await db.into(db.appKv).insertOnConflictUpdate(
          AppKvCompanion.insert(
            key: 'farm_v2_harvested_crops',
            value: set.join(','),
          ),
        );
    await db.into(db.appKv).insertOnConflictUpdate(
          AppKvCompanion.insert(
            key: 'farm_v2_crop_diversity',
            value: '${set.length}',
          ),
        );
  }

  CropDefinition _cropFromRow(QueryRow c, List<QueryRow> stages) {
    return CropDefinition(
      cropId: c.read<String>('crop_id'),
      nameKr: c.read<String>('name_kr'),
      tier: FarmTier.fromWire(c.read<String>('tier')),
      unlockType: UnlockType.fromWire(c.readNullable<String>('unlock_type')),
      unlockValue: c.readNullable<int>('unlock_value'),
      hexTileRequirement: c.read<int>('hex_tile_requirement'),
      regrow: c.read<int>('regrow') != 0,
      regrowWater: c.readNullable<int>('regrow_water'),
      regrowNutrient: c.readNullable<int>('regrow_nutrient'),
      rewardCoin: c.read<int>('reward_coin'),
      rewardXp: c.read<int>('reward_xp'),
      rewardItemDrop: c.readNullable<String>('reward_item_drop'),
      seasonalFlag: c.readNullable<String>('seasonal_flag'),
      stages: [
        for (final s in stages)
          CropStage(
            stageIndex: s.read<int>('stage_index'),
            stageName: s.read<String>('stage_name'),
            waterThreshold: s.read<int>('water_threshold'),
            nutrientThreshold: s.read<int>('nutrient_threshold'),
            spriteAssetKey: s.read<String>('sprite_asset_key'),
          ),
      ],
    );
  }

  AnimalDefinition _animalFromRow(QueryRow a, List<QueryRow> stages) {
    return AnimalDefinition(
      animalId: a.read<String>('animal_id'),
      nameKr: a.read<String>('name_kr'),
      tier: FarmTier.fromWire(a.read<String>('tier')),
      unlockType: UnlockType.fromWire(a.readNullable<String>('unlock_type')),
      unlockValue: a.readNullable<int>('unlock_value'),
      hexTileRequirement: a.read<int>('hex_tile_requirement'),
      yieldType: YieldType.fromWire(a.read<String>('yield_type')),
      feedPerCycle: a.read<int>('feed_per_cycle'),
      cooldownHours: a.read<int>('cooldown_hours'),
      starvationGraceDays: a.read<int>('starvation_grace_days'),
      rewardCoin: a.read<int>('reward_coin'),
      rewardXp: a.read<int>('reward_xp'),
      growthStages: [
        for (final s in stages)
          AnimalStage(
            stageIndex: s.read<int>('stage_index'),
            stageName: s.read<String>('stage_name'),
            feedThreshold: s.read<int>('feed_threshold'),
            spriteAssetKey: s.read<String>('sprite_asset_key'),
          ),
      ],
    );
  }

  SlotTemplate _slotTemplateFromRow(QueryRow r) {
    return SlotTemplate(
      slotId: r.read<String>('slot_id'),
      slotType: SlotType.fromWire(r.read<String>('slot_type')),
      xPct: r.read<double>('x_pct'),
      yPct: r.read<double>('y_pct'),
      zIndex: r.read<int>('z_index'),
      unlockTileCount: r.read<int>('unlock_tile_count'),
    );
  }

  UserFarmSlot _userSlotFromRow(QueryRow r) {
    return UserFarmSlot(
      id: r.read<int>('id'),
      slotId: r.read<String>('slot_id'),
      occupantType: OccupantType.fromWire(r.readNullable<String>('occupant_type')),
      cropId: r.readNullable<String>('crop_id'),
      animalId: r.readNullable<String>('animal_id'),
      cumulativeWater: r.read<int>('cumulative_water'),
      cumulativeNutrient: r.read<int>('cumulative_nutrient'),
      cumulativeFeed: r.read<int>('cumulative_feed'),
      currentStageIndex: r.read<int>('current_stage_index'),
      isDormant: r.read<int>('is_dormant') != 0,
      lastYieldAt: _dt(r.readNullable<int>('last_yield_at')),
      plantedAt: DateTime.fromMillisecondsSinceEpoch(r.read<int>('planted_at')),
    );
  }

  UmatchiAction _umatchiFromRow(QueryRow r) {
    return UmatchiAction(
      id: r.read<int>('id'),
      helperUserId: r.read<String>('helper_user_id'),
      recipientUserId: r.read<String>('recipient_user_id'),
      resourceType: FarmResourceType.fromWire(r.read<String>('resource_type')),
      amount: r.read<int>('amount'),
      actionDate: r.read<String>('action_date'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(r.read<int>('created_at')),
    );
  }

  DateTime? _dt(int? ms) =>
      ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
}

class HarvestResult {
  const HarvestResult({
    required this.coin,
    required this.xp,
    required this.cropId,
    required this.newMilestones,
  });

  final int coin;
  final int xp;
  final String cropId;
  final List<MilestoneDefinition> newMilestones;
}

class YieldResult {
  const YieldResult({
    required this.coin,
    required this.xp,
    required this.animalId,
    required this.yieldPenalty,
    required this.newMilestones,
  });

  final int coin;
  final int xp;
  final String animalId;
  final double yieldPenalty;
  final List<MilestoneDefinition> newMilestones;
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
