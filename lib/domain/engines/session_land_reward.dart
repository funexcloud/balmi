import 'dart:math' as math;

import 'land_city.dart';
import 'loop_area.dart';

/// What this closed session contributed to 「내 땅」.
///
/// Reuses the same rules as [DeviceTraces] / [LandBudget]:
/// sessions under [minLandSessionDistM] earn nothing; otherwise prefer closed
/// loop area when larger than the 4 m path band.
class SessionLandReward {
  const SessionLandReward({
    required this.qualifies,
    required this.loopM2,
    required this.pathBandM2,
    required this.cellCount,
  });

  final bool qualifies;
  final double loopM2;
  final double pathBandM2;

  /// Approximate path cells crossed (H3-style axial hex, not Uber H3).
  final int cellCount;

  double get earnedM2 {
    if (!qualifies) return 0;
    return LandBudget(
      loopM2: loopM2,
      pathBandM2: pathBandM2,
      spentM2: 0,
    ).earnedM2;
  }

  bool get hasLoop => loopM2 > 0;

  static const none = SessionLandReward(
    qualifies: false,
    loopM2: 0,
    pathBandM2: 0,
    cellCount: 0,
  );

  /// [totalDistM] is the session distance used for the path band.
  /// [path] optional GPS polyline for loop area + cell count.
  factory SessionLandReward.fromSession({
    required double totalDistM,
    List<GeoPoint> path = const [],
  }) {
    if (!qualifiesForLand(totalDistM)) {
      return SessionLandReward.none;
    }
    final pathBand = LandBudget.pathBandFromDistanceM(totalDistM);
    final loop = path.length >= 2 ? closedLoopAreaM2(path) : 0.0;
    final cells = pathToHexCells(path).length;
    return SessionLandReward(
      qualifies: true,
      loopM2: loop,
      pathBandM2: pathBand,
      cellCount: cells,
    );
  }
}

/// Hex edge length in meters for display cell counts (≈ path-scale cells).
const hexCellEdgeM = 40.0;

/// Axial hex cells touched by [path]. Ids are `{res}:{q}:{r}` with res=10.
Set<String> pathToHexCells(
  List<GeoPoint> path, {
  int res = 10,
  double edgeM = hexCellEdgeM,
}) {
  if (path.length < 2 || edgeM <= 0) return const {};
  var lat0 = 0.0;
  var lon0 = 0.0;
  for (final p in path) {
    lat0 += p.lat;
    lon0 += p.lon;
  }
  lat0 /= path.length;
  lon0 /= path.length;
  final cosLat = math.cos(lat0 * math.pi / 180.0);
  const mPerDegLat = 110540.0;
  const mPerDegLon = 111320.0;
  final cells = <String>{};
  for (final p in path) {
    final x = (p.lon - lon0) * mPerDegLon * cosLat;
    final y = (p.lat - lat0) * mPerDegLat;
    final qr = axialFromMeters(x, y, edgeM);
    cells.add('$res:${qr.$1}:${qr.$2}');
  }
  return cells;
}

(int, int) axialFromMeters(double x, double y, double edgeM) {
  // Pointy-top axial: q = (√3/3·x - 1/3·y) / size, r = (2/3·y) / size
  final size = edgeM;
  final qf = (math.sqrt(3) / 3 * x - 1 / 3 * y) / size;
  final rf = (2 / 3 * y) / size;
  return axialRound(qf, rf);
}

(int, int) axialRound(double q, double r) {
  final s = -q - r;
  var rq = q.round();
  var rr = r.round();
  final rs = s.round();
  final qDiff = (rq - q).abs();
  final rDiff = (rr - r).abs();
  final sDiff = (rs - s).abs();
  if (qDiff > rDiff && qDiff > sDiff) {
    rq = -rr - rs;
  } else if (rDiff > sDiff) {
    rr = -rq - rs;
  }
  return (rq, rr);
}
