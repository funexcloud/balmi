import 'package:balmi/core/copy.dart';
import 'package:balmi/data/map/device_traces.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('DeviceTraces falls back to Seoul only without pin or centroid', () {
    const empty = DeviceTraces(lines: [], loops: [], loopAreaM2: 0);
    expect(empty.center, DeviceTraces.koreaDefault);
    expect(empty.lastPoint, isNull);
  });

  test('map around-me pin uses GPS lastPoint over Seoul default', () {
    final here = LatLng(35.1796, 129.0756); // Busan, not Seoul
    final aroundMe = DeviceTraces(
      lines: const [],
      loops: const [],
      loopAreaM2: 0,
      lastPoint: here,
      centroid: DeviceTraces.koreaDefault,
    );
    expect(aroundMe.center, DeviceTraces.koreaDefault);
    expect(aroundMe.lastPoint, here);
    // recenter / preferUserLocation path uses lastPoint when present
    expect(aroundMe.lastPoint ?? aroundMe.center, here);
  });

  test('GPS pin overrides session trail endpoint for map marker', () {
    final trailEnd = LatLng(37.57, 126.98);
    final gps = LatLng(35.16, 129.06);
    final stored = DeviceTraces(
      lines: [
        [LatLng(37.56, 126.97), trailEnd],
      ],
      loops: const [],
      loopAreaM2: 0,
      lastPoint: trailEnd,
      centroid: LatLng(37.565, 126.975),
    );
    // Map explore rebuilds traces with GPS as lastPoint only.
    final shown = DeviceTraces(
      lines: stored.lines,
      loops: stored.loops,
      loopAreaM2: stored.loopAreaM2,
      pathBandM2: stored.pathBandM2,
      lastPoint: gps,
      centroid: stored.centroid,
    );
    expect(shown.lastPoint, gps);
    expect(shown.hasLine, isTrue);
    expect(shown.lastPoint, isNot(trailEnd));
  });

  test('map location copy is distinct from recording copy', () {
    expect(BalmiCopy.mapLocationDenied, isNot(BalmiCopy.locationDenied));
    expect(BalmiCopy.mapWaitingLocation, isNotEmpty);
    expect(BalmiCopy.mapLocationUnavailable, isNotEmpty);
    expect(BalmiCopy.recenterMap, '내 위치로');
  });
}
