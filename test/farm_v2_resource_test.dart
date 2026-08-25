import 'package:balmi/domain/engines/farm_resource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('feed (spec §2.2)', () {
    test('8 사료/km with daily cap', () {
      final grant = convertSessionResources(
        const SessionResourceInput(
          distanceKm: 10,
          avgPaceRatio: 1.0,
          streakDays: 0,
          todayFeedGranted: 0,
        ),
      );
      expect(grant.feedRaw, 80);
      expect(grant.feedGranted, 80);
    });

    test('daily cap trims excess feed', () {
      final grant = convertSessionResources(
        const SessionResourceInput(
          distanceKm: 50,
          avgPaceRatio: 1.0,
          streakDays: 0,
          todayFeedGranted: 280,
        ),
      );
      expect(grant.feedRaw, 400);
      expect(grant.feedGranted, 20);
    });

    test('cap at exactly 300 stops further feed', () {
      final grant = convertSessionResources(
        const SessionResourceInput(
          distanceKm: 10,
          avgPaceRatio: 1.0,
          streakDays: 0,
          todayFeedGranted: 300,
        ),
      );
      expect(grant.feedGranted, 0);
    });
  });

  group('water (spec §2.3)', () {
    test('base 40 per session regardless of distance', () {
      final short = convertSessionResources(
        const SessionResourceInput(
          distanceKm: 0.05,
          avgPaceRatio: 1.0,
          streakDays: 0,
        ),
      );
      final long = convertSessionResources(
        const SessionResourceInput(
          distanceKm: 20,
          avgPaceRatio: 1.0,
          streakDays: 0,
        ),
      );
      expect(short.waterGranted, 40);
      expect(long.waterGranted, 40);
    });

    test('streak multiplier capped at 1.6', () {
      final grant = convertSessionResources(
        const SessionResourceInput(
          distanceKm: 5,
          avgPaceRatio: 1.0,
          streakDays: 100,
        ),
      );
      expect(grant.waterGranted, (40 * 1.6).round());
    });

    test('7-day streak gives 1.21x water', () {
      final grant = convertSessionResources(
        const SessionResourceInput(
          distanceKm: 5,
          avgPaceRatio: 1.0,
          streakDays: 7,
        ),
      );
      expect(grant.waterGranted, (40 * 1.21).round());
    });
  });

  group('nutrient (spec §2.4)', () {
    test('faster pace yields more nutrient', () {
      final fast = convertSessionResources(
        const SessionResourceInput(
          distanceKm: 5,
          avgPaceRatio: 0.85,
          streakDays: 0,
        ),
      );
      final slow = convertSessionResources(
        const SessionResourceInput(
          distanceKm: 5,
          avgPaceRatio: 1.15,
          streakDays: 0,
        ),
      );
      expect(fast.nutrientGranted, greaterThan(slow.nutrientGranted));
    });

    test('minimum 15 nutrient even on bad day', () {
      final grant = convertSessionResources(
        const SessionResourceInput(
          distanceKm: 5,
          avgPaceRatio: 2.0,
          streakDays: 0,
        ),
      );
      expect(grant.nutrientGranted, greaterThanOrEqualTo(15));
    });

    test('effort score clamped to ±0.3', () {
      final extreme = convertSessionResources(
        const SessionResourceInput(
          distanceKm: 5,
          avgPaceRatio: 0.1,
          streakDays: 0,
        ),
      );
      expect(extreme.nutrientRaw, 30 + (0.3 * 50).round());
    });
  });

  group('tile bonus (spec §2.5)', () {
    test('new tile grants feed 15 + nutrient 5', () {
      final grant = convertSessionResources(
        const SessionResourceInput(
          distanceKm: 5,
          avgPaceRatio: 1.0,
          streakDays: 0,
          newTilesClaimed: 2,
        ),
      );
      expect(grant.tileBonusFeed, 30);
      expect(grant.tileBonusNutrient, 10);
      expect(grant.totalFeed, grant.feedGranted + 30);
    });
  });
}
