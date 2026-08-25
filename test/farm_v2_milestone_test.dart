import 'package:balmi/domain/engines/farm_milestone.dart';
import 'package:balmi/domain/models/farm/milestone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const defs = [
    MilestoneDefinition(
      milestoneId: 'first_harvest',
      conditionType: 'first_harvest',
      bonusFxp: 50,
    ),
    MilestoneDefinition(
      milestoneId: 'water_streak_7',
      conditionType: 'water_streak',
      conditionValue: 7,
      bonusFxp: 100,
    ),
    MilestoneDefinition(
      milestoneId: 'crop_diversity_5',
      conditionType: 'crop_diversity',
      conditionValue: 5,
      bonusFxp: 200,
    ),
    MilestoneDefinition(
      milestoneId: 'farm_lv10',
      conditionType: 'farm_level',
      conditionValue: 10,
      bonusFxp: 300,
    ),
  ];

  test('first harvest milestone', () {
    expect(
      milestoneMet(
        defs.first,
        const MilestoneContext(harvestCount: 1),
      ),
      isTrue,
    );
    expect(
      milestoneMet(
        defs.first,
        const MilestoneContext(harvestCount: 0),
      ),
      isFalse,
    );
  });

  test('water streak milestone', () {
    final def = defs[1];
    expect(
      milestoneMet(def, const MilestoneContext(waterStreakDays: 7)),
      isTrue,
    );
    expect(
      milestoneMet(def, const MilestoneContext(waterStreakDays: 6)),
      isFalse,
    );
  });

  test('newly earned skips already achieved', () {
    final fresh = newlyEarnedMilestones(
      definitions: defs,
      alreadyEarned: {'first_harvest'},
      ctx: const MilestoneContext(harvestCount: 2, waterStreakDays: 7),
    );
    expect(fresh.map((m) => m.milestoneId), ['water_streak_7']);
  });
}
