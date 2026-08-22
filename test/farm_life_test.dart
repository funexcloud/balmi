import 'package:balmi/domain/engines/farm_life.dart';
import 'package:balmi/domain/engines/land_city.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sheep needs a pasture and 400m of today walk', () {
    expect(
      raiseBlock(
        kind: HerdKind.sheep,
        buildings: const [],
        existing: const [],
        remainingFeedM: 2000,
      ),
      RaiseBlock.needBuilding,
    );
    expect(
      raiseBlock(
        kind: HerdKind.sheep,
        buildings: const [FarmKind.pastureFence],
        existing: const [],
        remainingFeedM: 399,
      ),
      RaiseBlock.needFeed,
    );
    expect(
      raiseBlock(
        kind: HerdKind.sheep,
        buildings: const [FarmKind.pastureFence],
        existing: const [],
        remainingFeedM: 400,
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
        remainingFeedM: 2000,
      ),
      RaiseBlock.atCapacity,
    );
  });

  test('cattle needs warehouse and 1.2km feed', () {
    expect(
      raiseBlock(
        kind: HerdKind.cattle,
        buildings: const [FarmKind.pastureFence, FarmKind.barn],
        existing: const [],
        remainingFeedM: 5000,
      ),
      RaiseBlock.needBuilding,
    );
    expect(HerdKind.cattle.feedWalkM, 1200);
    expect(
      raiseBlock(
        kind: HerdKind.cattle,
        buildings: const [FarmKind.villageStore],
        existing: const [],
        remainingFeedM: 1200,
      ),
      RaiseBlock.ok,
    );
  });

  test('raising today spends feed, not area', () {
    final now = DateTime(2026, 8, 22, 15);
    final spent = spentFeedToday(
      [
        HerdFeed(raisedAt: DateTime(2026, 8, 22, 9), feedWalkM: 400),
        HerdFeed(raisedAt: DateTime(2026, 8, 21, 9), feedWalkM: 1200),
      ],
      now,
    );
    expect(spent, 400);
    final feed = FeedBudget(todayWalkM: 900, spentFeedM: spent);
    expect(feed.remainingM, 500);
    expect(feed.caredToday, isTrue);
    expect(
      raiseBlock(
        kind: HerdKind.chicken,
        buildings: const [FarmKind.barn],
        existing: const [],
        remainingFeedM: feed.remainingM,
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

  test('herds are hungry below 300m today', () {
    expect(FeedBudget(todayWalkM: 299, spentFeedM: 0).caredToday, isFalse);
    expect(FeedBudget(todayWalkM: 300, spentFeedM: 0).caredToday, isTrue);
  });
}
