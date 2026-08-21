import 'package:balmi/domain/engines/distance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('haversine ~1km north and h_acc>30 is excluded from distance', () {
    const aLat = 37.0;
    const aLon = 127.0;
    const bLat = 37.008983; // ~1000 m
    const bLon = 127.0;

    final acc = DistanceAccumulator(maxHorizontalAccuracyM: 30);
    expect(acc.add(lat: aLat, lon: aLon, hAccM: 8), 0);
    final added = acc.add(lat: bLat, lon: bLon, hAccM: 8);
    expect(added, closeTo(1000, 8));
    expect(acc.meters, closeTo(1000, 8));

    // Poor accuracy: kept out of distance (still would be stored by the DB layer).
    final skipped = acc.add(lat: 37.02, lon: 127.0, hAccM: 31);
    expect(skipped, 0);
    expect(acc.meters, closeTo(1000, 8));
  });
}
