import 'dart:math' as math;

const earthRadiusM = 6371000.0;

double _rad(double deg) => deg * math.pi / 180.0;

double _deg(double rad) => rad * 180.0 / math.pi;

double haversineMeters({
  required double lat1,
  required double lon1,
  required double lat2,
  required double lon2,
}) {
  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(lat1)) *
          math.cos(_rad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusM * c;
}

/// Initial bearing in degrees [0, 360).
double bearingDegrees({
  required double lat1,
  required double lon1,
  required double lat2,
  required double lon2,
}) {
  final y = math.sin(_rad(lon2 - lon1)) * math.cos(_rad(lat2));
  final x = math.cos(_rad(lat1)) * math.sin(_rad(lat2)) -
      math.sin(_rad(lat1)) * math.cos(_rad(lat2)) * math.cos(_rad(lon2 - lon1));
  return (_deg(math.atan2(y, x)) + 360.0) % 360.0;
}

/// Smallest absolute heading difference in degrees [0, 180].
double headingDeltaDeg(double a, double b) {
  var d = (a - b).abs() % 360.0;
  if (d > 180.0) d = 360.0 - d;
  return d;
}

bool isAccurateEnough(double? hAccM, double maxM) {
  if (hAccM == null) return false;
  return hAccM <= maxM;
}

class DistanceAccumulator {
  DistanceAccumulator({this.maxHorizontalAccuracyM = 30});

  final double maxHorizontalAccuracyM;

  double meters = 0;
  double? _lat;
  double? _lon;

  void reset() {
    meters = 0;
    _lat = null;
    _lon = null;
  }

  /// Adds a point. Inaccurate points are ignored for distance but do not
  /// reset the last good coordinate (so the next good point still chains).
  double add({
    required double lat,
    required double lon,
    required double? hAccM,
  }) {
    if (!isAccurateEnough(hAccM, maxHorizontalAccuracyM)) {
      return 0;
    }
    if (_lat == null || _lon == null) {
      _lat = lat;
      _lon = lon;
      return 0;
    }
    final d = haversineMeters(lat1: _lat!, lon1: _lon!, lat2: lat, lon2: lon);
    _lat = lat;
    _lon = lon;
    meters += d;
    return d;
  }

  void restoreLast({required double lat, required double lon, required double meters}) {
    _lat = lat;
    _lon = lon;
    this.meters = meters;
  }
}
