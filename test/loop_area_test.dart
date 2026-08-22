import 'package:balmi/domain/engines/loop_area.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('closed 100m square is about 1 hectare, open path is 0', () {
    const lat0 = 37.0;
    const lon0 = 127.0;
    const dLat = 100 / 110540;
    const dLon = 100 / (111320 * 0.7986);
    final ring = <GeoPoint>[];
    for (var i = 0; i <= 3; i++) {
      ring.add(GeoPoint(lat0, lon0 + dLon * i / 3));
    }
    for (var i = 1; i <= 3; i++) {
      ring.add(GeoPoint(lat0 + dLat * i / 3, lon0 + dLon));
    }
    for (var i = 1; i <= 3; i++) {
      ring.add(GeoPoint(lat0 + dLat, lon0 + dLon * (1 - i / 3)));
    }
    for (var i = 1; i <= 3; i++) {
      ring.add(GeoPoint(lat0 + dLat * (1 - i / 3), lon0));
    }
    expect(ring.length, greaterThanOrEqualTo(10));
    expect(closedLoopAreaM2(ring), closeTo(10000, 1200));

    final open = [
      for (var i = 0; i < 12; i++) GeoPoint(lat0 + dLat * i / 11, lon0),
    ];
    expect(closedLoopAreaM2(open), 0);
  });
}
