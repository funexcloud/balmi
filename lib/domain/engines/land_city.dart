/// Rural farm unlocks. Buildings appear after cumulative 물주기 — never leftover ㎡.
enum FarmKind {
  pastureFence,
  barn,
  farmhouse,
  villageStore;

  String get wire => switch (this) {
        pastureFence => 'pasture_fence',
        barn => 'barn',
        farmhouse => 'farmhouse',
        villageStore => 'village_store',
      };

  String get label => switch (this) {
        pastureFence => '울타리 목장',
        barn => '헛간',
        farmhouse => '농가',
        villageStore => '마을 창고',
      };

  String get shortLabel => switch (this) {
        pastureFence => '울타리',
        barn => '헛간',
        farmhouse => '농가',
        villageStore => '창고',
      };

  /// Honest deed size stored on the row — not a shop price.
  double get costM2 => switch (this) {
        pastureFence => 1000,
        barn => 5000,
        farmhouse => 20000,
        villageStore => 50000,
      };

  /// Cumulative 물주기 needed before this building appears.
  int get watersNeeded => switch (this) {
        pastureFence => 3,
        barn => 10,
        farmhouse => 25,
        villageStore => 60,
      };

  static FarmKind fromWire(String value) {
    return FarmKind.values.firstWhere(
      (e) => e.wire == value || e.name == value,
      orElse: () => FarmKind.pastureFence,
    );
  }

  static const tiers = FarmKind.values;
}

/// Width of the “밟은 띠” used when there is no closed loop yet.
const pathBandWidthM = 4.0;

/// Indoor / standing sessions below this do not draw on 내 땅 or earn ㎡.
/// House GPS jitter can scribble a tiny loop without a real walk.
const minLandSessionDistM = 50.0;

bool qualifiesForLand(double totalDistM) =>
    totalDistM + 1e-6 >= minLandSessionDistM;

class LandBudget {
  const LandBudget({
    required this.loopM2,
    required this.pathBandM2,
    required this.spentM2,
  });

  final double loopM2;
  final double pathBandM2;
  final double spentM2;

  /// Prefer enclosed loops; otherwise the 4 m path strip. Display only — not cash.
  double get earnedM2 => loopM2 > pathBandM2 ? loopM2 : pathBandM2;

  double get remainingM2 => (earnedM2 - spentM2).clamp(0, double.infinity);

  /// Area never unlocks or buys a building.
  bool unlocked(FarmKind kind) => false;

  /// Leftover ㎡ cannot be spent. Buildings come from 물주기 milestones.
  bool canBuild(FarmKind kind) => false;

  static double pathBandFromDistanceM(double distM) => distM * pathBandWidthM;
}

double spentFromCosts(Iterable<double> costs) =>
    costs.fold<double>(0, (s, c) => s + c);
