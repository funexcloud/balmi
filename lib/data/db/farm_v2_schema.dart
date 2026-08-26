import 'package:drift/drift.dart';

/// Farm gamification v2 — master + user state tables (SQLite).
/// Mirrors spec §10, §12, §13.4; adapted for local single-user Drift DB.
Future<void> createFarmV2Tables(GeneratedDatabase database) async {
  await database.customStatement('''
CREATE TABLE IF NOT EXISTS crop_definitions (
  crop_id TEXT PRIMARY KEY NOT NULL,
  name_kr TEXT NOT NULL,
  tier TEXT NOT NULL,
  unlock_type TEXT,
  unlock_value INTEGER,
  hex_tile_requirement INTEGER NOT NULL DEFAULT 1,
  regrow INTEGER NOT NULL DEFAULT 0,
  regrow_water INTEGER,
  regrow_nutrient INTEGER,
  reward_coin INTEGER NOT NULL,
  reward_xp INTEGER NOT NULL,
  reward_item_drop TEXT,
  seasonal_flag TEXT,
  created_at INTEGER NOT NULL
);
''');

  await database.customStatement('''
CREATE TABLE IF NOT EXISTS crop_stages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  crop_id TEXT NOT NULL REFERENCES crop_definitions(crop_id),
  stage_index INTEGER NOT NULL,
  stage_name TEXT NOT NULL,
  water_threshold INTEGER NOT NULL,
  nutrient_threshold INTEGER NOT NULL,
  sprite_asset_key TEXT NOT NULL,
  UNIQUE (crop_id, stage_index)
);
''');

  await database.customStatement('''
CREATE TABLE IF NOT EXISTS animal_definitions (
  animal_id TEXT PRIMARY KEY NOT NULL,
  name_kr TEXT NOT NULL,
  tier TEXT NOT NULL,
  unlock_type TEXT,
  unlock_value INTEGER,
  hex_tile_requirement INTEGER NOT NULL DEFAULT 1,
  yield_type TEXT NOT NULL,
  feed_per_cycle INTEGER NOT NULL,
  cooldown_hours INTEGER NOT NULL,
  starvation_grace_days INTEGER NOT NULL DEFAULT 3,
  reward_coin INTEGER NOT NULL,
  reward_xp INTEGER NOT NULL,
  created_at INTEGER NOT NULL
);
''');

  await database.customStatement('''
CREATE TABLE IF NOT EXISTS animal_stages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  animal_id TEXT NOT NULL REFERENCES animal_definitions(animal_id),
  stage_index INTEGER NOT NULL,
  stage_name TEXT NOT NULL,
  feed_threshold INTEGER NOT NULL,
  sprite_asset_key TEXT NOT NULL,
  UNIQUE (animal_id, stage_index)
);
''');

  await database.customStatement('''
CREATE TABLE IF NOT EXISTS slot_templates (
  slot_id TEXT PRIMARY KEY NOT NULL,
  slot_type TEXT NOT NULL,
  x_pct REAL NOT NULL,
  y_pct REAL NOT NULL,
  z_index INTEGER NOT NULL,
  unlock_tile_count INTEGER NOT NULL DEFAULT 1
);
''');

  await database.customStatement('''
CREATE TABLE IF NOT EXISTS milestone_definitions (
  milestone_id TEXT PRIMARY KEY NOT NULL,
  condition_type TEXT NOT NULL,
  condition_value INTEGER,
  bonus_fxp INTEGER NOT NULL,
  vasa_signal TEXT
);
''');

  await database.customStatement('''
CREATE TABLE IF NOT EXISTS farm_level_definitions (
  farm_level INTEGER PRIMARY KEY NOT NULL,
  required_fxp INTEGER NOT NULL,
  unlock_note TEXT
);
''');

  await database.customStatement('''
CREATE TABLE IF NOT EXISTS user_farm (
  user_id TEXT PRIMARY KEY NOT NULL,
  farm_level INTEGER NOT NULL DEFAULT 1,
  farm_xp INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL
);
''');

  await database.customStatement('''
CREATE TABLE IF NOT EXISTS user_resources (
  user_id TEXT PRIMARY KEY NOT NULL,
  feed_balance INTEGER NOT NULL DEFAULT 0,
  water_balance INTEGER NOT NULL DEFAULT 0,
  nutrient_balance INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL
);
''');

  await database.customStatement('''
CREATE TABLE IF NOT EXISTS resource_transaction_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  run_session_id TEXT NOT NULL,
  feed_raw INTEGER NOT NULL,
  feed_granted INTEGER NOT NULL,
  water_granted INTEGER NOT NULL,
  nutrient_raw INTEGER NOT NULL,
  nutrient_granted INTEGER NOT NULL,
  new_tiles_claimed INTEGER NOT NULL DEFAULT 0,
  streak_days_at_time INTEGER NOT NULL,
  created_at INTEGER NOT NULL
);
''');

  await database.customStatement('''
CREATE TABLE IF NOT EXISTS user_farm_slots (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  slot_id TEXT NOT NULL REFERENCES slot_templates(slot_id),
  occupant_type TEXT,
  crop_id TEXT REFERENCES crop_definitions(crop_id),
  animal_id TEXT REFERENCES animal_definitions(animal_id),
  cumulative_water INTEGER NOT NULL DEFAULT 0,
  cumulative_nutrient INTEGER NOT NULL DEFAULT 0,
  cumulative_feed INTEGER NOT NULL DEFAULT 0,
  current_stage_index INTEGER NOT NULL DEFAULT 0,
  is_dormant INTEGER NOT NULL DEFAULT 0,
  last_yield_at INTEGER,
  planted_at INTEGER NOT NULL,
  UNIQUE (user_id, slot_id)
);
''');

  await database.customStatement('''
CREATE TABLE IF NOT EXISTS user_milestones (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  milestone_id TEXT NOT NULL REFERENCES milestone_definitions(milestone_id),
  achieved_at INTEGER NOT NULL,
  UNIQUE (user_id, milestone_id)
);
''');

  await database.customStatement('''
CREATE TABLE IF NOT EXISTS badge_definitions (
  badge_id TEXT PRIMARY KEY NOT NULL,
  name_kr TEXT NOT NULL,
  tier TEXT NOT NULL,
  milestone_id TEXT REFERENCES milestone_definitions(milestone_id),
  icon_asset_key TEXT NOT NULL,
  description_kr TEXT NOT NULL,
  is_seasonal INTEGER NOT NULL DEFAULT 0,
  season_end_at INTEGER
);
''');

  await database.customStatement('''
CREATE TABLE IF NOT EXISTS user_badges (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  badge_id TEXT NOT NULL REFERENCES badge_definitions(badge_id),
  earned_at INTEGER NOT NULL,
  UNIQUE (user_id, badge_id)
);
''');

  await database.customStatement('''
CREATE TABLE IF NOT EXISTS user_badge_showcase (
  user_id TEXT NOT NULL,
  display_order INTEGER NOT NULL CHECK (display_order BETWEEN 1 AND 3),
  badge_id TEXT NOT NULL REFERENCES badge_definitions(badge_id),
  PRIMARY KEY (user_id, display_order)
);
''');

  await database.customStatement('''
CREATE TABLE IF NOT EXISTS friendships (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id_a TEXT NOT NULL,
  user_id_b TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  requested_at INTEGER NOT NULL,
  accepted_at INTEGER,
  UNIQUE (user_id_a, user_id_b)
);
''');

  await database.customStatement('''
CREATE TABLE IF NOT EXISTS umatchi_actions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  helper_user_id TEXT NOT NULL,
  recipient_user_id TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  amount INTEGER NOT NULL,
  action_date TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  UNIQUE (helper_user_id, recipient_user_id, action_date)
);
''');

  await database.customStatement('''
CREATE TABLE IF NOT EXISTS reaction_definitions (
  reaction_id TEXT PRIMARY KEY NOT NULL,
  text_kr TEXT NOT NULL,
  icon_asset_key TEXT NOT NULL
);
''');

  await database.customStatement('''
CREATE TABLE IF NOT EXISTS reaction_sent_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sender_user_id TEXT NOT NULL,
  recipient_user_id TEXT NOT NULL,
  reaction_id TEXT NOT NULL REFERENCES reaction_definitions(reaction_id),
  created_at INTEGER NOT NULL
);
''');

  await database.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_resource_log_user_time '
    'ON resource_transaction_log(user_id, created_at);',
  );
  await database.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_farm_slots_user '
    'ON user_farm_slots(user_id);',
  );
  await database.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_friendships_a '
    'ON friendships(user_id_a);',
  );
  await database.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_friendships_b '
    'ON friendships(user_id_b);',
  );
  await database.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_umatchi_recipient '
    'ON umatchi_actions(recipient_user_id, action_date);',
  );
}

Future<void> seedFarmV2MasterData(GeneratedDatabase database) async {
  final now = DateTime.now().millisecondsSinceEpoch;
  final count = await database.customSelect(
    'SELECT COUNT(*) AS c FROM crop_definitions',
  ).getSingle();
  if ((count.read<int>('c')) > 0) return;

  await _seedCrops(database, now);
  await _seedAnimals(database, now);
  await _seedSlots(database);
  await _seedMilestones(database);
  await _seedFarmLevels(database);
  await _seedBadges(database);
  await _seedReactions(database);
}

/// Narrative fix: chicken starts as egg (not 새끼), adult at 120 feed (not 400).
/// Idempotent — no-ops when stage 0 is already 「계란」.
Future<void> patchFarmV2ChickenEggNarrative(GeneratedDatabase db) async {
  final exists = await db.customSelect(
    "SELECT COUNT(*) AS c FROM animal_definitions WHERE animal_id = 'animal_chicken_01'",
  ).getSingle();
  if ((exists.read<int>('c')) == 0) return;

  final stage0 = await db.customSelect(
    '''
SELECT stage_name, feed_threshold FROM animal_stages
WHERE animal_id = 'animal_chicken_01' AND stage_index = 0
''',
  ).getSingleOrNull();
  final adult = await db.customSelect(
    '''
SELECT stage_name, feed_threshold FROM animal_stages
WHERE animal_id = 'animal_chicken_01'
ORDER BY stage_index DESC LIMIT 1
''',
  ).getSingleOrNull();
  final already =
      stage0 != null &&
      stage0.read<String>('stage_name') == '계란' &&
      adult != null &&
      adult.read<String>('stage_name') == '암탉' &&
      adult.read<int>('feed_threshold') == 120;
  if (already) return;

  await db.customStatement(
    "DELETE FROM animal_stages WHERE animal_id = 'animal_chicken_01'",
  );

  const chickenStages = [
    (0, '계란', 0, 'animal/chicken/stage_0'),
    (1, '품는 중', 20, 'animal/chicken/stage_1'),
    (2, '병아리', 60, 'animal/chicken/stage_2'),
    (3, '암탉', 120, 'animal/chicken/stage_3'),
  ];
  for (final s in chickenStages) {
    await db.customStatement(
      '''
INSERT INTO animal_stages (
  animal_id, stage_index, stage_name, feed_threshold, sprite_asset_key
) VALUES ('animal_chicken_01', ?, ?, ?, ?)
''',
      [s.$1, s.$2, s.$3, s.$4],
    );
  }

  // Remap stored stage from cumulative feed under the new thresholds.
  final rows = await db.customSelect(
    '''
SELECT id, cumulative_feed FROM user_farm_slots
WHERE animal_id = 'animal_chicken_01' AND occupant_type = 'livestock'
''',
  ).get();
  for (final r in rows) {
    final feed = r.read<int>('cumulative_feed');
    final stage = feed >= 120
        ? 3
        : feed >= 60
            ? 2
            : feed >= 20
                ? 1
                : 0;
    await db.customStatement(
      'UPDATE user_farm_slots SET current_stage_index = ? WHERE id = ?',
      [stage, r.read<int>('id')],
    );
  }
}

/// Sheep/cow early-stage narrative + rename 젖소→소. Idempotent.
Future<void> patchFarmV2LivestockSheepCowNarrative(GeneratedDatabase db) async {
  final sheep = await db.customSelect(
    "SELECT COUNT(*) AS c FROM animal_definitions WHERE animal_id = 'animal_sheep_01'",
  ).getSingle();
  if (sheep.read<int>('c') == 0) return;

  await db.customStatement(
    "UPDATE animal_definitions SET name_kr = '소' WHERE animal_id = 'animal_cow_01'",
  );
  await db.customStatement(
    "UPDATE farm_level_definitions SET unlock_note = '호박, 소' WHERE farm_level = 8",
  );

  Future<void> replaceStages({
    required String animalId,
    required List<(int, String, int, String)> stages,
  }) async {
    final stage0 = await db.customSelect(
      '''
SELECT stage_name FROM animal_stages
WHERE animal_id = ? AND stage_index = 0
''',
      variables: [Variable.withString(animalId)],
    ).getSingleOrNull();
    if (stage0 != null && stage0.read<String>('stage_name') == stages.first.$2) {
      return;
    }
    await db.customStatement(
      'DELETE FROM animal_stages WHERE animal_id = ?',
      [animalId],
    );
    for (final s in stages) {
      await db.customStatement(
        '''
INSERT INTO animal_stages (
  animal_id, stage_index, stage_name, feed_threshold, sprite_asset_key
) VALUES (?, ?, ?, ?, ?)
''',
        [animalId, s.$1, s.$2, s.$3, s.$4],
      );
    }
    final rows = await db.customSelect(
      '''
SELECT id, cumulative_feed FROM user_farm_slots
WHERE animal_id = ? AND occupant_type = 'livestock'
''',
      variables: [Variable.withString(animalId)],
    ).get();
    for (final r in rows) {
      final feed = r.read<int>('cumulative_feed');
      var stage = 0;
      for (final s in stages) {
        if (feed >= s.$3) stage = s.$1;
      }
      await db.customStatement(
        'UPDATE user_farm_slots SET current_stage_index = ? WHERE id = ?',
        [stage, r.read<int>('id')],
      );
    }
  }

  await replaceStages(
    animalId: 'animal_sheep_01',
    stages: const [
      (0, '새끼양', 0, 'animal/sheep/stage_0'),
      (1, '성장', 300, 'animal/sheep/stage_1'),
      (2, '성체', 900, 'animal/sheep/stage_2'),
    ],
  );
  await replaceStages(
    animalId: 'animal_cow_01',
    stages: const [
      (0, '송아지', 0, 'animal/cow/stage_0'),
      (1, '성장', 600, 'animal/cow/stage_1'),
      (2, '성체', 1800, 'animal/cow/stage_2'),
    ],
  );
}

Future<void> _seedCrops(GeneratedDatabase db, int now) async {
  const crops = [
    (
      'crop_carrot_01',
      '당근',
      'starter',
      'level',
      1,
      1,
      0,
      null,
      null,
      30,
      20,
    ),
    (
      'crop_tomato_01',
      '토마토',
      'common',
      'level',
      3,
      2,
      1,
      120,
      80,
      80,
      50,
    ),
    (
      'crop_strawberry_01',
      '딸기',
      'common',
      'level',
      5,
      2,
      0,
      null,
      null,
      100,
      60,
    ),
    (
      'crop_pumpkin_01',
      '호박',
      'rare',
      'level',
      8,
      3,
      0,
      null,
      null,
      150,
      90,
    ),
    (
      'crop_golden_rice_01',
      '황금벼',
      'legendary',
      'level',
      12,
      4,
      0,
      null,
      null,
      300,
      200,
    ),
  ];

  for (final c in crops) {
    await db.customStatement(
      '''
INSERT INTO crop_definitions (
  crop_id, name_kr, tier, unlock_type, unlock_value, hex_tile_requirement,
  regrow, regrow_water, regrow_nutrient, reward_coin, reward_xp, created_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
''',
      [
        c.$1,
        c.$2,
        c.$3,
        c.$4,
        c.$5,
        c.$6,
        c.$7,
        c.$8,
        c.$9,
        c.$10,
        c.$11,
        now,
      ],
    );
  }

  // Tomato stages from spec §3.2
  const tomatoStages = [
    (0, '씨앗', 0, 0, 'crop/tomato/stage_0'),
    (1, '새싹', 80, 60, 'crop/tomato/stage_1'),
    (2, '성장', 220, 180, 'crop/tomato/stage_2'),
    (3, '개화', 380, 320, 'crop/tomato/stage_3'),
    (4, '수확', 520, 450, 'crop/tomato/stage_4'),
  ];
  for (final s in tomatoStages) {
    await db.customStatement(
      '''
INSERT INTO crop_stages (
  crop_id, stage_index, stage_name, water_threshold, nutrient_threshold,
  sprite_asset_key
) VALUES ('crop_tomato_01', ?, ?, ?, ?, ?)
''',
      [s.$1, s.$2, s.$3, s.$4, s.$5],
    );
  }

  // Simpler starter crops
  const carrotStages = [
    (0, '씨앗', 0, 0, 'crop/carrot/stage_0'),
    (1, '새싹', 40, 30, 'crop/carrot/stage_1'),
    (2, '성장', 100, 80, 'crop/carrot/stage_2'),
    (3, '수확', 180, 140, 'crop/carrot/stage_3'),
  ];
  for (final s in carrotStages) {
    await db.customStatement(
      '''
INSERT INTO crop_stages (
  crop_id, stage_index, stage_name, water_threshold, nutrient_threshold,
  sprite_asset_key
) VALUES ('crop_carrot_01', ?, ?, ?, ?, ?)
''',
      [s.$1, s.$2, s.$3, s.$4, s.$5],
    );
  }
}

Future<void> _seedAnimals(GeneratedDatabase db, int now) async {
  const animals = [
    (
      'animal_sheep_01',
      '양',
      'common',
      'level',
      5,
      2,
      'wool',
      100,
      24,
      3,
      60,
      40,
    ),
    (
      'animal_chicken_01',
      '닭',
      'starter',
      'level',
      1,
      1,
      'egg',
      40,
      12,
      3,
      25,
      15,
    ),
    (
      'animal_cow_01',
      '소',
      'rare',
      'level',
      8,
      3,
      'milk',
      150,
      24,
      3,
      120,
      70,
    ),
  ];

  for (final a in animals) {
    await db.customStatement(
      '''
INSERT INTO animal_definitions (
  animal_id, name_kr, tier, unlock_type, unlock_value, hex_tile_requirement,
  yield_type, feed_per_cycle, cooldown_hours, starvation_grace_days,
  reward_coin, reward_xp, created_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
''',
      [
        a.$1,
        a.$2,
        a.$3,
        a.$4,
        a.$5,
        a.$6,
        a.$7,
        a.$8,
        a.$9,
        a.$10,
        a.$11,
        a.$12,
        now,
      ],
    );
  }

  // Sheep: lamb → growing → adult.
  const sheepStages = [
    (0, '새끼양', 0, 'animal/sheep/stage_0'),
    (1, '성장', 300, 'animal/sheep/stage_1'),
    (2, '성체', 900, 'animal/sheep/stage_2'),
  ];
  for (final s in sheepStages) {
    await db.customStatement(
      '''
INSERT INTO animal_stages (
  animal_id, stage_index, stage_name, feed_threshold, sprite_asset_key
) VALUES ('animal_sheep_01', ?, ?, ?, ?)
''',
      [s.$1, s.$2, s.$3, s.$4],
    );
  }

  // Starter chicken: egg → incubating → chick → hen (not adult-from-day-one).
  // Adult feed 120 (was 400) — under daily feed cap 300, ~6×20 apply taps.
  const chickenStages = [
    (0, '계란', 0, 'animal/chicken/stage_0'),
    (1, '품는 중', 20, 'animal/chicken/stage_1'),
    (2, '병아리', 60, 'animal/chicken/stage_2'),
    (3, '암탉', 120, 'animal/chicken/stage_3'),
  ];
  for (final s in chickenStages) {
    await db.customStatement(
      '''
INSERT INTO animal_stages (
  animal_id, stage_index, stage_name, feed_threshold, sprite_asset_key
) VALUES ('animal_chicken_01', ?, ?, ?, ?)
''',
      [s.$1, s.$2, s.$3, s.$4],
    );
  }

  // Cattle: calf → growing → adult.
  const cowStages = [
    (0, '송아지', 0, 'animal/cow/stage_0'),
    (1, '성장', 600, 'animal/cow/stage_1'),
    (2, '성체', 1800, 'animal/cow/stage_2'),
  ];
  for (final s in cowStages) {
    await db.customStatement(
      '''
INSERT INTO animal_stages (
  animal_id, stage_index, stage_name, feed_threshold, sprite_asset_key
) VALUES ('animal_cow_01', ?, ?, ?, ?)
''',
      [s.$1, s.$2, s.$3, s.$4],
    );
  }
}

Future<void> _seedSlots(GeneratedDatabase db) async {
  const slots = [
    ('pasture_1', 'livestock', 25.0, 78.0, 5, 1),
    ('pasture_2', 'livestock', 55.0, 80.0, 5, 3),
    ('garden_1', 'crop', 72.0, 68.0, 4, 2),
    ('garden_2', 'crop', 40.0, 65.0, 4, 5),
    ('garden_3', 'crop', 85.0, 70.0, 4, 8),
  ];
  for (final s in slots) {
    await db.customStatement(
      '''
INSERT INTO slot_templates (
  slot_id, slot_type, x_pct, y_pct, z_index, unlock_tile_count
) VALUES (?, ?, ?, ?, ?, ?)
''',
      [s.$1, s.$2, s.$3, s.$4, s.$5, s.$6],
    );
  }
}

Future<void> _seedMilestones(GeneratedDatabase db) async {
  const milestones = [
    ('first_harvest', 'first_harvest', null, 50, 'onboarding_complete'),
    ('water_streak_7', 'water_streak', 7, 100, 'consistency'),
    ('water_streak_30', 'water_streak', 30, 500, 'long_consistency'),
    ('crop_diversity_5', 'crop_diversity', 5, 200, 'diversity'),
    ('livestock_owner_3', 'livestock_owner', 3, 150, 'retention_loop'),
    ('farm_lv10', 'farm_level', 10, 300, 'engagement'),
  ];
  for (final m in milestones) {
    await db.customStatement(
      '''
INSERT INTO milestone_definitions (
  milestone_id, condition_type, condition_value, bonus_fxp, vasa_signal
) VALUES (?, ?, ?, ?, ?)
''',
      [m.$1, m.$2, m.$3, m.$4, m.$5],
    );
  }
}

Future<void> _seedFarmLevels(GeneratedDatabase db) async {
  const levels = [
    (1, 0, '당근, 닭'),
    (3, 500, '토마토'),
    (5, 1500, '딸기, 양'),
    (8, 4000, '호박, 소'),
    (12, 10000, '황금벼(시즌 한정 슬롯)'),
    (15, 20000, '코스메틱·농장 꾸미기'),
  ];
  for (final l in levels) {
    await db.customStatement(
      '''
INSERT INTO farm_level_definitions (farm_level, required_fxp, unlock_note)
VALUES (?, ?, ?)
''',
      [l.$1, l.$2, l.$3],
    );
  }
}

Future<void> _seedBadges(GeneratedDatabase db) async {
  const badges = [
    (
      'badge_first_harvest',
      '첫 수확',
      'bronze',
      'first_harvest',
      'badge/first_harvest',
      '첫 작물을 수확했어요',
    ),
    (
      'badge_water_7',
      '물 7일',
      'silver',
      'water_streak_7',
      'badge/water_7',
      '7일 연속 물을 받았어요',
    ),
    (
      'badge_water_30',
      '물 30일',
      'gold',
      'water_streak_30',
      'badge/water_30',
      '30일 연속 물을 받았어요',
    ),
    (
      'badge_diversity',
      '다양한 텃밭',
      'silver',
      'crop_diversity_5',
      'badge/diversity',
      '서로 다른 작물 5종을 수확했어요',
    ),
    (
      'badge_livestock',
      '목장 주인',
      'bronze',
      'livestock_owner_3',
      'badge/livestock',
      '가축 3마리 이상을 키우고 있어요',
    ),
    (
      'badge_farm_lv10',
      '농장 10레벨',
      'gold',
      'farm_lv10',
      'badge/farm_lv10',
      '농장 레벨 10에 도달했어요',
    ),
  ];
  for (final b in badges) {
    await db.customStatement(
      '''
INSERT INTO badge_definitions (
  badge_id, name_kr, tier, milestone_id, icon_asset_key, description_kr
) VALUES (?, ?, ?, ?, ?, ?)
''',
      [b.$1, b.$2, b.$3, b.$4, b.$5, b.$6],
    );
  }
}

Future<void> _seedReactions(GeneratedDatabase db) async {
  const reactions = [
    ('react_cheering', '화이팅!', 'react/cheering'),
    ('react_nice_grow', '잘 자랐네요!', 'react/nice_grow'),
    ('react_jealous', '부럽다 🌾', 'react/jealous'),
    ('react_thanks', '고마워요', 'react/thanks'),
    ('react_seedling', '🌱', 'react/seedling'),
    ('react_thumbs', '👍', 'react/thumbs'),
  ];
  for (final r in reactions) {
    await db.customStatement(
      '''
INSERT INTO reaction_definitions (reaction_id, text_kr, icon_asset_key)
VALUES (?, ?, ?)
''',
      [r.$1, r.$2, r.$3],
    );
  }
}
