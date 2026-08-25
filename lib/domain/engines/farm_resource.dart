import '../models/farm/farm_tier.dart';

/// Spec §2.5 tuning constants.
abstract final class FarmResourceConstants {
  static const feedRate = 8.0;
  static const dailyFeedCap = 300;
  static const waterPerSession = 40;
  static const nutrientBase = 30;
  static const nutrientEffortWeight = 50;
  static const nutrientMin = 15;
  static const tileBonusFeed = 15;
  static const tileBonusNutrient = 5;
}

class SessionResourceInput {
  const SessionResourceInput({
    required this.distanceKm,
    required this.avgPaceRatio,
    required this.streakDays,
    this.newTilesClaimed = 0,
    this.todayFeedGranted = 0,
  });

  final double distanceKm;
  final double avgPaceRatio;
  final int streakDays;
  final int newTilesClaimed;
  final int todayFeedGranted;
}

class SessionResourceGrant {
  const SessionResourceGrant({
    required this.feedRaw,
    required this.feedGranted,
    required this.waterGranted,
    required this.nutrientRaw,
    required this.nutrientGranted,
    required this.tileBonusFeed,
    required this.tileBonusNutrient,
  });

  final int feedRaw;
  final int feedGranted;
  final int waterGranted;
  final int nutrientRaw;
  final int nutrientGranted;
  final int tileBonusFeed;
  final int tileBonusNutrient;

  int get totalFeed => feedGranted + tileBonusFeed;
  int get totalNutrient => nutrientGranted + tileBonusNutrient;
}

double clampDouble(double value, double min, double max) {
  if (value < min) return min;
  if (value > max) return max;
  return value;
}

/// Spec §2.2–2.4 resource conversion (pure, testable).
SessionResourceGrant convertSessionResources(SessionResourceInput input) {
  final feedRaw = (input.distanceKm * FarmResourceConstants.feedRate).round();
  final feedRoom =
      (FarmResourceConstants.dailyFeedCap - input.todayFeedGranted).clamp(0, 999999);
  final feedGranted = feedRaw > feedRoom ? feedRoom : feedRaw;

  final streakMult = clampDouble(
    1.0 + input.streakDays * 0.03,
    1.0,
    1.6,
  );
  final waterGranted =
      (FarmResourceConstants.waterPerSession * streakMult).round();

  final effortScore = clampDouble(
    1.0 - input.avgPaceRatio,
    -0.3,
    0.3,
  );
  final nutrientRaw = (FarmResourceConstants.nutrientBase +
          effortScore * FarmResourceConstants.nutrientEffortWeight)
      .round();
  final nutrientGranted = nutrientRaw < FarmResourceConstants.nutrientMin
      ? FarmResourceConstants.nutrientMin
      : nutrientRaw;

  final tileBonusFeed = input.newTilesClaimed > 0
      ? FarmResourceConstants.tileBonusFeed * input.newTilesClaimed
      : 0;
  final tileBonusNutrient = input.newTilesClaimed > 0
      ? FarmResourceConstants.tileBonusNutrient * input.newTilesClaimed
      : 0;

  return SessionResourceGrant(
    feedRaw: feedRaw,
    feedGranted: feedGranted,
    waterGranted: waterGranted,
    nutrientRaw: nutrientRaw,
    nutrientGranted: nutrientGranted,
    tileBonusFeed: tileBonusFeed,
    tileBonusNutrient: tileBonusNutrient,
  );
}

bool sameLocalDay(DateTime a, DateTime b) {
  final la = a.toLocal();
  final lb = b.toLocal();
  return la.year == lb.year && la.month == lb.month && la.day == lb.day;
}

String localDateKey(DateTime dt) {
  final l = dt.toLocal();
  return '${l.year.toString().padLeft(4, '0')}-'
      '${l.month.toString().padLeft(2, '0')}-'
      '${l.day.toString().padLeft(2, '0')}';
}
