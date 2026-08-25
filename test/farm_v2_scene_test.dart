import 'package:balmi/domain/models/farm/farm_slot.dart';
import 'package:balmi/domain/models/farm/farm_state.dart';
import 'package:balmi/domain/models/farm/farm_tier.dart';
import 'package:balmi/widgets/farm_resource_bar.dart';
import 'package:balmi/widgets/farm_scene_v2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final snapshot = FarmSnapshot(
    farm: UserFarmState(
      farmLevel: 2,
      farmXp: 120,
      updatedAt: DateTime(2026, 8, 25),
    ),
    resources: UserResourceBalances(
      feedBalance: 80,
      waterBalance: 40,
      nutrientBalance: 30,
      updatedAt: DateTime(2026, 8, 25),
    ),
    slots: const [
      FarmSlotView(
        template: SlotTemplate(
          slotId: 'garden_1',
          slotType: SlotType.crop,
          xPct: 72,
          yPct: 68,
          zIndex: 4,
          unlockTileCount: 1,
        ),
        occupant: null,
        unlocked: true,
      ),
    ],
    milestones: const [],
    badges: const [],
  );

  testWidgets('FarmSceneV2 shows level badge and slot label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FarmSceneV2(
            snapshot: snapshot,
            crops: const {},
            animals: const {},
            buildings: const [],
            herds: const [],
          ),
        ),
      ),
    );

    expect(find.text('농장 Lv.2'), findsOneWidget);
    expect(find.text('심기'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('FarmResourceBar shows three resource labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FarmResourceBar(
            balances: snapshot.resources,
            onApply: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('물'), findsOneWidget);
    expect(find.text('사료'), findsOneWidget);
    expect(find.text('영양제'), findsOneWidget);
    expect(find.text('80'), findsOneWidget);
    expect(find.text('40'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
  });
}
