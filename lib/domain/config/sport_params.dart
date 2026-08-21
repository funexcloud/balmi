/// Remote-config-shaped sport hysteresis. Defaults live in code; maps override.
class SportParams {
  const SportParams({
    this.walkToRunSpeedKmh = 9.0,
    this.runToWalkSpeedKmh = 7.0,
    this.walkToRunCadenceSpm = 140,
    this.holdSeconds = 15,
    this.maxHorizontalAccuracyM = 30,
  });

  final double walkToRunSpeedKmh;
  final double runToWalkSpeedKmh;
  final double walkToRunCadenceSpm;
  final int holdSeconds;
  final double maxHorizontalAccuracyM;

  Duration get hold => Duration(seconds: holdSeconds);

  static const defaults = SportParams();

  factory SportParams.fromRemoteConfig(Map<String, Object?> map) {
    int asInt(Object? v, int fallback) {
      if (v is int) return v;
      if (v is num) return v.round();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    double asDouble(Object? v, double fallback) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? fallback;
      return fallback;
    }

    return SportParams(
      walkToRunSpeedKmh: asDouble(map['walk_to_run_speed_kmh'], 9.0),
      runToWalkSpeedKmh: asDouble(map['run_to_walk_speed_kmh'], 7.0),
      walkToRunCadenceSpm: asDouble(map['walk_to_run_cadence_spm'], 140),
      holdSeconds: asInt(map['hold_seconds'], 15),
      maxHorizontalAccuracyM: asDouble(map['max_horizontal_accuracy_m'], 30),
    );
  }

  Map<String, Object?> toRemoteConfig() => {
        'walk_to_run_speed_kmh': walkToRunSpeedKmh,
        'run_to_walk_speed_kmh': runToWalkSpeedKmh,
        'walk_to_run_cadence_spm': walkToRunCadenceSpm,
        'hold_seconds': holdSeconds,
        'max_horizontal_accuracy_m': maxHorizontalAccuracyM,
      };

  SportParams copyWith({
    double? walkToRunSpeedKmh,
    double? runToWalkSpeedKmh,
    double? walkToRunCadenceSpm,
    int? holdSeconds,
    double? maxHorizontalAccuracyM,
  }) {
    return SportParams(
      walkToRunSpeedKmh: walkToRunSpeedKmh ?? this.walkToRunSpeedKmh,
      runToWalkSpeedKmh: runToWalkSpeedKmh ?? this.runToWalkSpeedKmh,
      walkToRunCadenceSpm: walkToRunCadenceSpm ?? this.walkToRunCadenceSpm,
      holdSeconds: holdSeconds ?? this.holdSeconds,
      maxHorizontalAccuracyM:
          maxHorizontalAccuracyM ?? this.maxHorizontalAccuracyM,
    );
  }
}
