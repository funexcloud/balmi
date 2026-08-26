import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/copy.dart';

/// Foreground-only location for the map tab (no recording / FGS).
class MapLocation {
  MapLocation._();

  /// Returns a user-facing Korean error, or null if a fix may be requested.
  static Future<String?> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      if (!await Geolocator.isLocationServiceEnabled()) {
        return BalmiCopy.mapLocationOff;
      }
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return BalmiCopy.mapLocationDenied;
    }
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return BalmiCopy.mapLocationDeniedForever;
    }
    return null;
  }

  /// Best-effort current position; falls back to last known.
  static Future<LatLng?> currentLatLng({
    Duration timeLimit = const Duration(seconds: 12),
  }) async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          timeLimit: timeLimit,
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      // fall through to last known
    }
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        return LatLng(last.latitude, last.longitude);
      }
    } catch (_) {
      // ignore
    }
    return null;
  }
}
