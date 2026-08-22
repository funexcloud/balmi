import 'package:balmi/domain/engines/farm_life.dart';
import 'package:balmi/domain/engines/farm_water.dart';
import 'package:balmi/domain/engines/land_city.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('progress line is waters and next milestone, not leftover ㎡', () {
    expect(
      evaluateWater(
        watersTotal: 0,
        wateredToday: false,
        qualifyingSessionsToday: 0,
      ).progressLine,
      '물 0회 · 다음 울타리까지 3회',
    );
    expect(
      evaluateWater(
        watersTotal: 3,
        wateredToday: true,
        qualifyingSessionsToday: 1,
      ).progressLine,
      '물 3회 · 다음 헛간까지 7회',
    );
  });

  test('1 qualifying session grants exactly 1 token', () {
    final ledger = evaluateWater(
      watersTotal: 0,
      wateredToday: false,
      qualifyingSessionsToday: 1,
    );
    expect(ledger.canWater, isTrue);
    expect(ledger.unusedTokens, 1);
    expect(ledger.state, WaterState.ready);
  });

  test('2 sessions same day still grant only 1 water', () {
    final before = evaluateWater(
      watersTotal: 0,
      wateredToday: false,
      qualifyingSessionsToday: 2,
    );
    expect(before.unusedTokens, 1);
    expect(before.canWater, isTrue);

    final after = evaluateWater(
      watersTotal: 1,
      wateredToday: true,
      qualifyingSessionsToday: 2,
    );
    expect(after.canWater, isFalse);
    expect(after.unusedTokens, 0);
    expect(after.state, WaterState.alreadyWatered);
  });

  test('indoor 0km session earns no token', () {
    final now = DateTime(2026, 8, 22, 16);
    expect(
      earnedWaterToday([ClosedWalk(endedAt: now, distM: 0)], now),
      isFalse,
    );
    expect(
      earnedWaterToday([ClosedWalk(endedAt: now, distM: 49)], now),
      isFalse,
    );
    expect(
      earnedWaterToday([ClosedWalk(endedAt: now, distM: 50)], now),
      isTrue,
    );
    expect(
      ledgerFromWalks(
        walks: [ClosedWalk(endedAt: now, distM: 0)],
        wateredAt: const [],
        now: now,
      ).state,
      WaterState.needWalk,
    );
  });

  test('3 waters unlock fence, 10 unlock barn', () {
    expect(
      buildingUnlockedByWaters(watersAfter: 2, already: const []),
      isNull,
    );
    expect(
      buildingUnlockedByWaters(watersAfter: 3, already: const []),
      FarmKind.pastureFence,
    );
    expect(
      buildingUnlockedByWaters(
        watersAfter: 3,
        already: const [FarmKind.pastureFence],
      ),
      isNull,
    );
    expect(
      buildingUnlockedByWaters(
        watersAfter: 10,
        already: const [FarmKind.pastureFence],
      ),
      FarmKind.barn,
    );
    expect(
      buildingUnlockedByWaters(
        watersAfter: 25,
        already: const [FarmKind.pastureFence, FarmKind.barn],
      ),
      FarmKind.farmhouse,
    );
    expect(
      buildingUnlockedByWaters(
        watersAfter: 60,
        already: const [
          FarmKind.pastureFence,
          FarmKind.barn,
          FarmKind.farmhouse,
        ],
      ),
      FarmKind.villageStore,
    );
  });

  test('milestone water skips raise; next water grows one sheep', () {
    expect(
      herdRaisedByWater(
        buildings: const [FarmKind.pastureFence],
        existing: const [],
        justUnlocked: FarmKind.pastureFence,
      ),
      isNull,
    );
    expect(
      herdRaisedByWater(
        buildings: const [FarmKind.pastureFence],
        existing: const [],
      ),
      HerdKind.sheep,
    );
    expect(
      herdRaisedByWater(
        buildings: const [FarmKind.pastureFence],
        existing: const [
          HerdKind.sheep,
          HerdKind.sheep,
          HerdKind.sheep,
          HerdKind.sheep,
        ],
      ),
      isNull,
    );
  });

  test('one water raises at most one herd even with many buildings', () {
    expect(
      herdRaisedByWater(
        buildings: FarmKind.tiers,
        existing: const [],
      ),
      HerdKind.sheep,
    );
  });

  test('existing leftover buildings seed waters so fence is not granted twice', () {
    expect(seedWatersFromBuildings(const []), 0);
    expect(seedWatersFromBuildings(const [FarmKind.pastureFence]), 3);
    expect(
      seedWatersFromBuildings(const [FarmKind.pastureFence, FarmKind.barn]),
      10,
    );
  });
}
