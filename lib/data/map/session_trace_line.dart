import 'package:latlong2/latlong.dart';

import '../../domain/engines/distance.dart';
import '../db/app_database.dart';

const kTraceMaxHAccM = 40.0;

/// Accurate unique GPS samples in time order.
/// Consecutive duplicates (1Hz reuse of a stale fix) are dropped so the
/// polyline does not stack thousands of identical vertices.
List<LatLng> traceLineFromPoints(
  Iterable<Point> pts, {
  double maxHAccM = kTraceMaxHAccM,
}) {
  final line = <LatLng>[];
  for (final p in pts) {
    final acc = p.hAccM;
    if (acc != null && acc > maxHAccM) continue;
    final next = LatLng(p.lat, p.lng);
    if (line.isNotEmpty &&
        line.last.latitude == next.latitude &&
        line.last.longitude == next.longitude) {
      continue;
    }
    line.add(next);
  }
  return line;
}
