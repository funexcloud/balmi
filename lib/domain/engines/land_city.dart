/// Rural farm unlocks. Costs are ㎡ spent from the land budget — never cash.
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

  /// Area that must be earned and is spent on 짓기 / 가꾸기.
  double get costM2 => switch (this) {
        pastureFence => 1000,
        barn => 5000,
        farmhouse => 20000,
        villageStore => 50000,
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

  /// Prefer enclosed loops; otherwise the 4 m path strip so 2–3 km walks unlock.
  double get earnedM2 => loopM2 > pathBandM2 ? loopM2 : pathBandM2;

  double get remainingM2 => (earnedM2 - spentM2).clamp(0, double.infinity);

  bool unlocked(FarmKind kind) => earnedM2 + 1e-6 >= kind.costM2;

  bool canBuild(FarmKind kind) => remainingM2 + 1e-6 >= kind.costM2;

  static double pathBandFromDistanceM(double distM) => distM * pathBandWidthM;
}

double spentFromCosts(Iterable<double> costs) =>
    costs.fold<double>(0, (s, c) => s + c);
