import 'package:balmi/domain/models/farm/crop.dart';
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

  testWidgets('long-press drag calls onSlotMove between crop slots',
      (tester) async {
    final twoCrops = FarmSnapshot(
      farm: snapshot.farm,
      resources: snapshot.resources,
      slots: [
        FarmSlotView(
          template: const SlotTemplate(
            slotId: 'garden_1',
            slotType: SlotType.crop,
            xPct: 30,
            yPct: 50,
            zIndex: 4,
            unlockTileCount: 1,
          ),
          occupant: UserFarmSlot(
            id: 1,
            slotId: 'garden_1',
            occupantType: OccupantType.crop,
            cropId: 'crop_carrot_01',
            cumulativeWater: 0,
            cumulativeNutrient: 0,
            cumulativeFeed: 0,
            currentStageIndex: 0,
            isDormant: false,
            plantedAt: DateTime(2026, 8, 26),
          ),
          unlocked: true,
        ),
        const FarmSlotView(
          template: SlotTemplate(
            slotId: 'garden_2',
            slotType: SlotType.crop,
            xPct: 70,
            yPct: 50,
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

    FarmSlotView? movedFrom;
    FarmSlotView? movedTo;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FarmSceneV2(
            snapshot: twoCrops,
            crops: {
              'crop_carrot_01': CropDefinition(
                cropId: 'crop_carrot_01',
                nameKr: '당근',
                tier: FarmTier.starter,
                unlockType: UnlockType.level,
                unlockValue: 1,
                hexTileRequirement: 1,
                regrow: false,
                rewardCoin: 30,
                rewardXp: 20,
                stages: const [
                  CropStage(
                    stageIndex: 0,
                    stageName: '씨앗',
                    waterThreshold: 0,
                    nutrientThreshold: 0,
                    spriteAssetKey: 'crop/carrot/stage_0',
                  ),
                ],
              ),
            },
            animals: const {},
            buildings: const [],
            herds: const [],
            onSlotMove: (from, to) {
              movedFrom = from;
              movedTo = to;
            },
          ),
        ),
      ),
    );

    final source = find.textContaining('당근');
    expect(source, findsOneWidget);
    final dest = find.text('심기');
    expect(dest, findsOneWidget);

    final gesture = await tester.startGesture(tester.getCenter(source));
    await tester.pump(const Duration(seconds: 1));
    await gesture.moveTo(tester.getCenter(dest));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(movedFrom?.template.slotId, 'garden_1');
    expect(movedTo?.template.slotId, 'garden_2');
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
