import 'dart:math' as math;

import 'distance.dart';

class GeoPoint {
  const GeoPoint(this.lat, this.lon);

  final double lat;
  final double lon;
}

/// Equirectangular shoelace in m². Returns 0 if the path is not a usable loop.
double closedLoopAreaM2(
  List<GeoPoint> points, {
  double closeGapM = 40,
  double minPathM = 80,
  double minAreaM2 = 50,
  int minPoints = 10,
}) {
  if (points.length < minPoints) return 0;
  final gap = haversineMeters(
    lat1: points.first.lat,
    lon1: points.first.lon,
    lat2: points.last.lat,
    lon2: points.last.lon,
  );
  if (gap > closeGapM) return 0;
  var path = 0.0;
  for (var i = 1; i < points.length; i++) {
    path += haversineMeters(
      lat1: points[i - 1].lat,
      lon1: points[i - 1].lon,
      lat2: points[i].lat,
      lon2: points[i].lon,
    );
  }
  if (path < minPathM) return 0;

  var lat0 = 0.0;
  var lon0 = 0.0;
  for (final p in points) {
    lat0 += p.lat;
    lon0 += p.lon;
  }
  lat0 /= points.length;
  lon0 /= points.length;
  final cosLat = math.cos(lat0 * math.pi / 180.0);
  const mPerDegLat = 110540.0;
  const mPerDegLon = 111320.0;

  var sum = 0.0;
  for (var i = 0; i < points.length; i++) {
    final a = points[i];
    final b = points[(i + 1) % points.length];
    final ax = (a.lon - lon0) * mPerDegLon * cosLat;
    final ay = (a.lat - lat0) * mPerDegLat;
    final bx = (b.lon - lon0) * mPerDegLon * cosLat;
    final by = (b.lat - lat0) * mPerDegLat;
    sum += ax * by - bx * ay;
  }
  final area = sum.abs() / 2;
  if (area < minAreaM2) return 0;
  return area;
}
