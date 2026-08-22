import 'land_city.dart';

/// Walk-fed livestock. One 물주기 may raise one herd if the required building exists.
enum HerdKind {
  sheep,
  chicken,
  garden,
  cattle;

  String get wire => switch (this) {
        sheep => 'sheep',
        chicken => 'chicken',
        garden => 'garden',
        cattle => 'cattle',
      };

  String get label => switch (this) {
        sheep => '양떼',
        chicken => '닭',
        garden => '텃밭',
        cattle => '한우',
      };

  FarmKind get requires => switch (this) {
        sheep => FarmKind.pastureFence,
        chicken => FarmKind.barn,
        garden => FarmKind.farmhouse,
        cattle => FarmKind.villageStore,
      };

  /// Metres of today's walk consumed when 기르기 is tapped.
  double get feedWalkM => switch (this) {
        sheep => 400,
        chicken => 250,
        garden => 600,
        cattle => 1200,
      };

  int get maxPerBuilding => switch (this) {
        sheep => 4,
        chicken => 6,
        garden => 1,
        cattle => 1,
      };

  static const tiers = HerdKind.values;

  static HerdKind fromWire(String value) {
    return HerdKind.values.firstWhere(
      (e) => e.wire == value || e.name == value,
      orElse: () => HerdKind.sheep,
    );
  }
}

/// How many of [raised] actually appear on the farm stage (visual cap).
int herdOnStage(HerdKind kind, int raised) {
  final cap = switch (kind) {
    HerdKind.sheep => 8,
    HerdKind.chicken => 8,
    HerdKind.garden => 4,
    HerdKind.cattle => 3,
  };
  if (raised <= 0) return 0;
  return raised > cap ? cap : raised;
}

/// Closed-session metres needed today so existing herds are "배불러요".
const dailyCareWalkM = 300.0;

bool sameLocalDay(DateTime a, DateTime b) {
  final la = a.toLocal();
  final lb = b.toLocal();
  return la.year == lb.year && la.month == lb.month && la.day == lb.day;
}

class HerdFeed {
  const HerdFeed({required this.raisedAt, required this.feedWalkM});

  final DateTime raisedAt;
  final double feedWalkM;
}

class FeedBudget {
  const FeedBudget({
    required this.todayWalkM,
    required this.spentFeedM,
  });

  final double todayWalkM;
  final double spentFeedM;

  double get remainingM => (todayWalkM - spentFeedM).clamp(0, double.infinity);

  bool get caredToday => todayWalkM + 1e-6 >= dailyCareWalkM;
}

double spentFeedToday(Iterable<HerdFeed> rows, DateTime now) {
  return rows
      .where((r) => sameLocalDay(r.raisedAt, now))
      .fold<double>(0, (s, r) => s + r.feedWalkM);
}

enum RaiseBlock { ok, needBuilding, atCapacity }

RaiseBlock raiseBlock({
  required HerdKind kind,
  required Iterable<FarmKind> buildings,
  required Iterable<HerdKind> existing,
}) {
  final homes = buildings.where((b) => b == kind.requires).length;
  if (homes == 0) return RaiseBlock.needBuilding;
  final cap = homes * kind.maxPerBuilding;
  final have = existing.where((h) => h == kind).length;
  if (have >= cap) return RaiseBlock.atCapacity;
  return RaiseBlock.ok;
}
