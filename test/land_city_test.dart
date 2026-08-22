import 'package:balmi/domain/engines/land_city.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('four farm tiers spend area, not cash', () {
    expect(FarmKind.pastureFence.label, '울타리 목장');
    expect(FarmKind.barn.label, '헛간');
    expect(FarmKind.farmhouse.label, '농가');
    expect(FarmKind.villageStore.label, '마을 창고');
    expect(FarmKind.pastureFence.costM2, 1000);
    expect(FarmKind.barn.costM2, 5000);
    expect(FarmKind.farmhouse.costM2, 20000);
    expect(FarmKind.villageStore.costM2, 50000);
  });

  test('2.5km path band unlocks fence and barn, not warehouse', () {
    final earned = LandBudget.pathBandFromDistanceM(2500);
    expect(earned, 10000);
    final budget = LandBudget(loopM2: 0, pathBandM2: earned, spentM2: 0);
    expect(budget.canBuild(FarmKind.pastureFence), isTrue);
    expect(budget.canBuild(FarmKind.barn), isTrue);
    expect(budget.canBuild(FarmKind.farmhouse), isFalse);
    expect(budget.canBuild(FarmKind.villageStore), isFalse);
  });

  test('spent area blocks another fence', () {
    final budget = LandBudget(loopM2: 1200, pathBandM2: 400, spentM2: 1000);
    expect(budget.earnedM2, 1200);
    expect(budget.remainingM2, closeTo(200, 0.1));
    expect(budget.canBuild(FarmKind.pastureFence), isFalse);
    expect(budget.unlocked(FarmKind.pastureFence), isTrue);
  });

  test('sessions under 50m do not qualify for land', () {
    expect(minLandSessionDistM, 50);
    expect(qualifiesForLand(0), isFalse);
    expect(qualifiesForLand(49.9), isFalse);
    expect(qualifiesForLand(50), isTrue);
    expect(qualifiesForLand(80), isTrue);
  });

  test('loop wins over smaller path band', () {
    final budget = LandBudget(loopM2: 8000, pathBandM2: 2000, spentM2: 0);
    expect(budget.earnedM2, 8000);
    expect(budget.canBuild(FarmKind.barn), isTrue);
    expect(budget.canBuild(FarmKind.farmhouse), isFalse);
  });
}
