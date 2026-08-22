import 'package:latlong2/latlong.dart';

import '../../domain/engines/land_city.dart';
import '../../domain/engines/loop_area.dart';
import '../db/app_database.dart';
import '../repositories/session_repository.dart';

class DeviceTraces {
  const DeviceTraces({
    required this.lines,
    required this.loops,
    required this.loopAreaM2,
    this.pathBandM2 = 0,
    this.lastPoint,
    this.centroid,
  });

  static final koreaDefault = LatLng(37.5665, 126.9780);

  final List<List<LatLng>> lines;
  final List<List<LatLng>> loops;
  final double loopAreaM2;
  final double pathBandM2;
  final LatLng? lastPoint;
  final LatLng? centroid;

  bool get hasLine => lines.any((l) => l.length >= 2);
  LatLng get center => centroid ?? lastPoint ?? koreaDefault;

  LandBudget budget(double spentM2) => LandBudget(
        loopM2: loopAreaM2,
        pathBandM2: pathBandM2,
        spentM2: spentM2,
      );
}

Future<DeviceTraces> loadDeviceTraces(SessionRepository repo) async {
  final sessions = await repo.closedSessions();
  final lines = <List<LatLng>>[];
  final loops = <List<LatLng>>[];
  var area = 0.0;
  var distM = 0.0;
  var latSum = 0.0;
  var lngSum = 0.0;
  var n = 0;
  LatLng? last;
  for (final Session s in sessions) {
    if (!qualifiesForLand(s.totalDistM)) continue;
    distM += s.totalDistM;
    final pts = await repo.pointsForSession(s.id);
    final line = <LatLng>[];
    final geo = <GeoPoint>[];
    for (final p in pts) {
      if (p.hAccM != null && p.hAccM! > 40) continue;
      line.add(LatLng(p.lat, p.lng));
      geo.add(GeoPoint(p.lat, p.lng));
      latSum += p.lat;
      lngSum += p.lng;
      n += 1;
    }
    if (line.length < 2) continue;
    lines.add(line);
    last = line.last;
    final loopM2 = closedLoopAreaM2(geo);
    if (loopM2 > 0) {
      loops.add(line);
      area += loopM2;
    }
  }
  return DeviceTraces(
    lines: lines,
    loops: loops,
    loopAreaM2: area,
    pathBandM2: LandBudget.pathBandFromDistanceM(distM),
    lastPoint: last,
    centroid: n == 0 ? null : LatLng(latSum / n, lngSum / n),
  );
}
