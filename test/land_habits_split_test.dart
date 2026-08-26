import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('land map has no walked-path or deed-guide sections', () {
    final land = File('lib/features/land/land_map_screen.dart').readAsStringSync();
    final farm = File('lib/features/land/farm_preview_screen.dart').readAsStringSync();
    expect(land, isNot(contains('landWalkedPath')));
    expect(land, isNot(contains('landGuide')));
    expect(land, isNot(contains('BalmiCopy.landWalkedPath')));
    expect(land, isNot(contains('BalmiCopy.landGuide')));
    expect(land, contains('landEmptyMine'));
    expect(farm, isNot(contains('landWalkedPath')));
    expect(farm, isNot(contains('landGuide')));
  });

  test('more menu keeps health habits and settings as separate entries', () {
    final more = File('lib/features/more/more_screen.dart').readAsStringSync();
    final settings =
        File('lib/features/settings/settings_screen.dart').readAsStringSync();
    final habits =
        File('lib/features/settings/health_habits_screen.dart').readAsStringSync();
    final missions =
        File('lib/features/missions/missions_screen.dart').readAsStringSync();
    expect(more, contains('HealthHabitsScreen'));
    expect(more, contains('SettingsScreen'));
    expect(more, contains('mealWalkHealthSection'));
    expect(settings, isNot(contains('MealWalkController')));
    expect(settings, isNot(contains('DailyGoalsPicker')));
    expect(habits, isNot(contains('MissionSettings')));
    expect(habits, isNot(contains('missionSettings')));
    expect(missions, contains('missionSettings'));
    expect(missions, contains('openMissionSettingsSheet'));
    // Separate visual groups — health and settings not one shared list block.
    expect(more, contains('_MoreGroup'));
    expect(more.split('_MoreGroup').length, greaterThan(3));
  });
}
