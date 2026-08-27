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

  test('settings nests OEM battery among about/app-info, not top or bottom dump',
      () {
    final settings =
        File('lib/features/settings/settings_screen.dart').readAsStringSync();
    final about = settings.indexOf('BalmiCopy.about,');
    final version = settings.indexOf('BalmiCopy.versionLabel');
    final oem = settings.indexOf('BalmiCopy.oemSettings');
    final ignore = settings.indexOf('BalmiCopy.ignoreBattery');
    final brand = settings.indexOf('BalmiCopy.brandStoryTitle');
    final map = settings.indexOf('BalmiCopy.mapCredit');
    final vasa = settings.indexOf('BalmiCopy.vasaCredit');
    expect(about, greaterThan(-1));
    expect(version, greaterThan(about));
    // Among about items — after version/about, before brand/credits.
    expect(oem, greaterThan(version));
    expect(ignore, greaterThan(oem));
    expect(brand, greaterThan(ignore));
    expect(map, greaterThan(brand));
    expect(vasa, greaterThan(map));
    // Not a trailing dump after credits.
    expect(oem, lessThan(vasa));
  });
}
