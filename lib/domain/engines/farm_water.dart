import 'farm_life.dart';
import 'land_city.dart';

enum WaterState { ready, alreadyWatered, needWalk }

class ClosedWalk {
  const ClosedWalk({required this.endedAt, required this.distM});

  final DateTime endedAt;
  final double distM;
}

class WaterLedger {
  const WaterLedger({
    required this.watersTotal,
    required this.wateredToday,
    required this.hasQualifyingWalkToday,
  });

  final int watersTotal;
  final bool wateredToday;
  final bool hasQualifyingWalkToday;

  /// At most one unused token — never a stack from leftover sessions.
  int get unusedTokens => canWater ? 1 : 0;

  bool get canWater => hasQualifyingWalkToday && !wateredToday;

  WaterState get state {
    if (wateredToday) return WaterState.alreadyWatered;
    if (hasQualifyingWalkToday) return WaterState.ready;
    return WaterState.needWalk;
  }

  FarmKind? get nextBuilding {
    for (final k in FarmKind.tiers) {
      if (watersTotal < k.watersNeeded) return k;
    }
    return null;
  }

  int get watersUntilNext {
    final next = nextBuilding;
    if (next == null) return 0;
    return next.watersNeeded - watersTotal;
  }

  /// Tiny status: 물 N회 · 다음 울타리까지 M회
  String get progressLine {
    final next = nextBuilding;
    if (next == null) return '물 $watersTotal회';
    return '물 $watersTotal회 · 다음 ${next.shortLabel}까지 $watersUntilNext회';
  }
}

bool earnedWaterToday(Iterable<ClosedWalk> walks, DateTime now) {
  return walks.any(
    (w) => sameLocalDay(w.endedAt, now) && qualifiesForLand(w.distM),
  );
}

bool wateredOnDay(Iterable<DateTime> wateredAt, DateTime now) {
  return wateredAt.any((t) => sameLocalDay(t, now));
}

WaterLedger evaluateWater({
  required int watersTotal,
  required bool wateredToday,
  required int qualifyingSessionsToday,
}) {
  return WaterLedger(
    watersTotal: watersTotal < 0 ? 0 : watersTotal,
    wateredToday: wateredToday,
    hasQualifyingWalkToday: qualifyingSessionsToday > 0,
  );
}

WaterLedger ledgerFromWalks({
  required Iterable<ClosedWalk> walks,
  required Iterable<DateTime> wateredAt,
  required DateTime now,
}) {
  return WaterLedger(
    watersTotal: wateredAt.length,
    wateredToday: wateredOnDay(wateredAt, now),
    hasQualifyingWalkToday: earnedWaterToday(walks, now),
  );
}

/// Seed past waters so testers who already built with leftover ㎡ keep those buildings.
int seedWatersFromBuildings(Iterable<FarmKind> buildings) {
  var n = 0;
  for (final b in buildings) {
    if (b.watersNeeded > n) n = b.watersNeeded;
  }
  return n;
}

FarmKind? buildingUnlockedByWaters({
  required int watersAfter,
  required Iterable<FarmKind> already,
}) {
  for (final k in FarmKind.tiers) {
    if (k.watersNeeded == watersAfter && !already.contains(k)) return k;
  }
  return null;
}

/// One herd per water, lowest tier with a home and room. Milestone waters skip raise.
class WaterApplyResult {
  const WaterApplyResult({
    required this.ledger,
    this.unlocked,
    this.raised,
    this.applied = false,
  });

  final WaterLedger ledger;
  final FarmKind? unlocked;
  final HerdKind? raised;
  final bool applied;
}

HerdKind? herdRaisedByWater({
  required Iterable<FarmKind> buildings,
  required Iterable<HerdKind> existing,
  FarmKind? justUnlocked,
}) {
  if (justUnlocked != null) return null;
  for (final kind in HerdKind.tiers) {
    if (raiseBlock(kind: kind, buildings: buildings, existing: existing) ==
        RaiseBlock.ok) {
      return kind;
    }
  }
  return null;
}
