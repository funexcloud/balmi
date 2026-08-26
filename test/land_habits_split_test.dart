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
    expect(land, isNot(contains('landTitle')));
    expect(land, isNot(contains('registryEyebrow')));
    expect(land, contains('landEmptyMine'));
    expect(land, contains('landRanking'));
    expect(land, contains('buildLocalLandRanking'));
    expect(farm, isNot(contains('landWalkedPath')));
    expect(farm, isNot(contains('landGuide')));
  });

  test('more menu keeps health habits and settings as separate entries', () {
    final more = File('lib/features/more/more_screen.dart').readAsStringSync();
    final settings =
        File('lib/features/settings/settings_screen.dart').readAsStringSync();
    expect(more, contains('HealthHabitsScreen'));
    expect(more, contains('SettingsScreen'));
    expect(more, contains('mealWalkHealthSection'));
    expect(settings, isNot(contains('MealWalkController')));
    expect(settings, isNot(contains('DailyGoalsPicker')));
    // Separate visual groups — health and settings not one shared list block.
    expect(more, contains('_MoreGroup'));
    expect(more.split('_MoreGroup').length, greaterThan(3));
  });
}
