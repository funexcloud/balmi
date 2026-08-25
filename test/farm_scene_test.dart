import 'package:balmi/core/copy.dart';
import 'package:balmi/domain/engines/farm_life.dart';
import 'package:balmi/domain/engines/land_city.dart';
import 'package:balmi/widgets/farm_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('empty farm shows honest copy and no fake herds', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FarmScene(buildings: [], herds: []),
        ),
      ),
    );
    expect(find.text(BalmiCopy.landEmptyField), findsOneWidget);
    expect(find.text(BalmiCopy.landWalkHint), findsOneWidget);
    expect(find.text(BalmiCopy.landNoPath), findsNothing);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('raised sheep and a fence appear on the stage', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FarmScene(
            buildings: [FarmKind.pastureFence],
            herds: [HerdKind.sheep, HerdKind.sheep],
            caredToday: true,
          ),
        ),
      ),
    );
    expect(find.text(BalmiCopy.landEmptyField), findsNothing);
    expect(find.text(BalmiCopy.landNoPath), findsNothing);
    expect(find.bySemanticsLabel('울타리 목장, 양떼 2'), findsOneWidget);
  });

  testWidgets('watering animation notifies when the pour finishes', (tester) async {
    var done = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: FarmScene(
          buildings: const [FarmKind.pastureFence],
          herds: const [HerdKind.sheep],
          watering: true,
          onWateringComplete: () => done += 1,
        ),
      ),
    );
    await tester.pump();
    expect(done, 0);
    await tester.pump(farmWaterDuration + const Duration(milliseconds: 50));
    expect(done, 1);
  });

  testWidgets('reduced motion skips the watering pour', (tester) async {
    var done = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          );
        },
        home: FarmScene(
          buildings: const [],
          herds: const [],
          watering: true,
          onWateringComplete: () => done += 1,
        ),
      ),
    );
    await tester.pump();
    expect(done, 1);
  });
}
