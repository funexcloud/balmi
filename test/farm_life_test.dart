import 'package:balmi/domain/engines/farm_life.dart';
import 'package:balmi/domain/engines/land_city.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sheep needs a pasture, not leftover feed metres', () {
    expect(
      raiseBlock(
        kind: HerdKind.sheep,
        buildings: const [],
        existing: const [],
      ),
      RaiseBlock.needBuilding,
    );
    expect(
      raiseBlock(
        kind: HerdKind.sheep,
        buildings: const [FarmKind.pastureFence],
        existing: const [],
      ),
      RaiseBlock.ok,
    );
  });

  test('one pasture holds four sheep then blocks', () {
    expect(
      raiseBlock(
        kind: HerdKind.sheep,
        buildings: const [FarmKind.pastureFence],
        existing: const [
          HerdKind.sheep,
          HerdKind.sheep,
          HerdKind.sheep,
          HerdKind.sheep,
        ],
      ),
      RaiseBlock.atCapacity,
    );
  });

  test('cattle needs warehouse, not leftover ㎡', () {
    expect(
      raiseBlock(
        kind: HerdKind.cattle,
        buildings: const [FarmKind.pastureFence, FarmKind.barn],
        existing: const [],
      ),
      RaiseBlock.needBuilding,
    );
    expect(
      raiseBlock(
        kind: HerdKind.cattle,
        buildings: const [FarmKind.villageStore],
        existing: const [],
      ),
      RaiseBlock.ok,
    );
  });

  test('stage draws at most eight sheep and no fake zero herds', () {
    expect(herdOnStage(HerdKind.sheep, 0), 0);
    expect(herdOnStage(HerdKind.sheep, 3), 3);
    expect(herdOnStage(HerdKind.sheep, 12), 8);
    expect(herdOnStage(HerdKind.garden, 6), 4);
    expect(herdOnStage(HerdKind.cattle, 1), 1);
    expect(herdOnStage(HerdKind.cattle, 9), 3);
  });
}
