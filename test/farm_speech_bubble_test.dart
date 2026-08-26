import 'package:balmi/core/copy.dart';
import 'package:balmi/domain/engines/farm_life.dart';
import 'package:balmi/domain/engines/land_city.dart';
import 'package:balmi/widgets/farm_scene.dart';
import 'package:balmi/widgets/farm_speech_bubble.dart';
import 'package:balmi/widgets/farm_status_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(FarmSpeechBubbleSession.clearForTest);

  testWidgets('empty farm shows one caption; tap advances then dismisses',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FarmScene(buildings: [], herds: []),
        ),
      ),
    );
    expect(find.text(BalmiCopy.landEmptyField), findsOneWidget);
    expect(find.text(BalmiCopy.landWalkHint), findsNothing);
    expect(find.byType(FarmSpeechBubble), findsOneWidget);

    await tester.tap(find.byType(FarmSpeechBubble));
    await tester.pumpAndSettle();
    expect(find.text(BalmiCopy.landWalkHint), findsOneWidget);
    expect(find.text(BalmiCopy.landEmptyField), findsNothing);

    await tester.tap(find.byType(FarmSpeechBubble));
    await tester.pumpAndSettle();
    expect(find.text(BalmiCopy.landEmptyField), findsNothing);
    expect(find.text(BalmiCopy.landWalkHint), findsNothing);
    expect(find.byType(FarmSpeechBubble), findsNothing);
  });

  testWidgets('dismissed tip set stays hidden when farm is rebuilt',
      (tester) async {
    Widget scene() => const MaterialApp(
          home: Scaffold(
            body: FarmScene(buildings: [], herds: []),
          ),
        );

    await tester.pumpWidget(scene());
    await tester.tap(find.byType(FarmSpeechBubble));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FarmSpeechBubble));
    await tester.pumpAndSettle();
    expect(find.byType(FarmSpeechBubble), findsNothing);

    await tester.pumpWidget(scene());
    await tester.pumpAndSettle();
    expect(find.byType(FarmSpeechBubble), findsNothing);
    expect(find.text(BalmiCopy.landEmptyField), findsNothing);
  });

  testWidgets('new tip set shows again after farm state changes',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FarmScene(buildings: [], herds: []),
        ),
      ),
    );
    await tester.tap(find.byType(FarmSpeechBubble));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FarmSpeechBubble));
    await tester.pumpAndSettle();
    expect(find.byType(FarmSpeechBubble), findsNothing);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FarmScene(
            buildings: [FarmKind.pastureFence],
            herds: [HerdKind.sheep],
            caredToday: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FarmSpeechBubble), findsOneWidget);
    expect(find.text(BalmiCopy.herdsFed), findsOneWidget);
  });

  testWidgets('speech bubble tap does not open land; scene tap does',
      (tester) async {
    var opens = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FarmStatusCard(
            buildings: const [],
            herds: const [],
            caredToday: false,
            onOpen: () => opens += 1,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(FarmSpeechBubble));
    await tester.pumpAndSettle();
    expect(opens, 0);
    expect(find.text(BalmiCopy.landWalkHint), findsOneWidget);

    // Tap sky area above the bubble to open land.
    await tester.tapAt(
        tester.getTopLeft(find.byType(FarmScene)) + const Offset(40, 24));
    await tester.pumpAndSettle();
    expect(opens, 1);
  });

  testWidgets('non-empty farm still paints and shows speech captions',
      (tester) async {
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
    expect(find.text(BalmiCopy.herdsFed), findsOneWidget);
    expect(find.bySemanticsLabel('울타리 목장, 양떼 2'), findsOneWidget);
  });

  testWidgets('single-line bubble dismisses on tap', (tester) async {
    var dismissed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FarmSpeechBubble(
            lines: const ['한 줄만'],
            onDismissed: () => dismissed += 1,
          ),
        ),
      ),
    );
    expect(find.text('한 줄만'), findsOneWidget);
    await tester.tap(find.byType(FarmSpeechBubble));
    await tester.pumpAndSettle();
    expect(find.text('한 줄만'), findsNothing);
    expect(dismissed, 1);
  });
}
