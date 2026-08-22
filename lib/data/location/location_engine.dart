/// GPS fix used by the recording pipeline.
class LocationFix {
  const LocationFix({
    required this.ts,
    required this.lat,
    required this.lng,
    this.alt,
    this.speedMs,
    this.speedAccuracyMs,
    this.hAccM,
    this.headingDeg,
    this.satCount,
  });

  final DateTime ts;
  final double lat;
  final double lng;
  final double? alt;
  final double? speedMs;
  final double? speedAccuracyMs;
  final double? hAccM;
  final double? headingDeg;

  /// Rarely available via geolocator; kept nullable (R6).
  final int? satCount;
}

/// Swap point for a licensed plugin such as flutter_background_geolocation.
/// Release 1 uses [GeolocatorLocationEngine] + flutter_foreground_task instead.
abstract class LocationEngine {
  Stream<LocationFix> get fixes;
  String? get lastError;
  bool get hasFix;
  Future<void> start();
  Future<void> stop();

  /// Retry a one-shot fix (app resumed, still waiting on GPS).
  Future<void> nudge();
}
