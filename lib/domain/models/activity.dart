import 'sport.dart';

/// User-chosen activity. `auto` keeps F2 walk↔run hysteresis.
enum ActivityKind {
  auto,
  walk,
  run,
  hike,
  trail;

  String get wire => name;

  String get label => switch (this) {
        auto => '자동',
        walk => '걷기',
        run => '달리기',
        hike => '등산',
        trail => '트레일 러닝',
      };

  bool get isAuto => this == auto;

  /// Segment sport when the user locks a type. Auto has no lock.
  Sport get lockedSport => switch (this) {
        run || trail => Sport.run,
        _ => Sport.walk,
      };

  static ActivityKind fromWire(String? value) {
    return ActivityKind.values.firstWhere(
      (e) => e.wire == value,
      orElse: () => ActivityKind.auto,
    );
  }

  static const selectable = [
    ActivityKind.auto,
    ActivityKind.walk,
    ActivityKind.run,
    ActivityKind.hike,
    ActivityKind.trail,
  ];
}
