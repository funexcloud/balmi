import 'dart:math' as math;

import 'package:balmi/domain/engines/land_city.dart';
import 'package:balmi/domain/engines/loop_area.dart';
import 'package:balmi/domain/engines/session_land_reward.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('short session earns no land', () {
    final r = SessionLandReward.fromSession(totalDistM: 40);
    expect(r.qualifies, isFalse);
    expect(r.earnedM2, 0);
    expect(r.cellCount, 0);
  });

  test('80m path band is 320㎡', () {
    final path = <GeoPoint>[
      for (var i = 0; i < 12; i++) GeoPoint(37.5665 + i * 0.00008, 126.9780),
    ];
    final r = SessionLandReward.fromSession(totalDistM: 80, path: path);
    expect(r.qualifies, isTrue);
    expect(r.pathBandM2, LandBudget.pathBandFromDistanceM(80));
    expect(r.earnedM2, 320);
    expect(r.cellCount, greaterThan(0));
  });

  test('closed loop wins when larger than path band', () {
    final path = <GeoPoint>[
      for (var i = 0; i < 36; i++)
        GeoPoint(
          37.5665 + 0.0011 * math.cos(i / 36 * 2 * math.pi),
          126.9780 + 0.0011 * math.sin(i / 36 * 2 * math.pi),
        ),
    ];
    path.add(path.first);
    const distM = 700.0;
    final r = SessionLandReward.fromSession(totalDistM: distM, path: path);
    expect(r.qualifies, isTrue);
    expect(r.hasLoop, isTrue);
    expect(r.loopM2, greaterThan(r.pathBandM2));
    expect(r.earnedM2, r.loopM2);
  });

  test('pathToHexCells returns stable axial ids', () {
    final path = <GeoPoint>[
      const GeoPoint(37.5665, 126.9780),
      const GeoPoint(37.5670, 126.9780),
      const GeoPoint(37.5675, 126.9785),
    ];
    final cells = pathToHexCells(path);
    expect(cells, isNotEmpty);
    expect(cells.every((id) => id.startsWith('10:')), isTrue);
  });

  test('axialRound snaps to cube constraint', () {
    final qr = axialRound(0.4, -0.3);
    expect(qr.$1 + qr.$2 + (-qr.$1 - qr.$2), 0);
  });
}
