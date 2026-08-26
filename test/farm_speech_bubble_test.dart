import 'package:balmi/core/copy.dart';
import 'package:balmi/domain/engines/farm_life.dart';
import 'package:balmi/domain/engines/land_city.dart';
import 'package:balmi/widgets/farm_scene.dart';
import 'package:balmi/widgets/farm_speech_bubble.dart';
import 'package:balmi/widgets/farm_status_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('empty farm shows one caption; tap advances to walk hint',
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
    expect(find.text(BalmiCopy.landEmptyField), findsOneWidget);
  });

  testWidgets('speech bubble tap does not open farm; scene tap does',
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

    // Tap sky area above the bubble to open farm.
    await tester.tapAt(tester.getTopLeft(find.byType(FarmScene)) + const Offset(40, 24));
    await tester.pumpAndSettle();
    expect(opens, 1);
  });

  testWidgets('speech bubble uses soft translucent fill not solid paper',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FarmSpeechBubble(lines: ['테스트 안내']),
        ),
      ),
    );
    final body = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox)).firstWhere(
      (w) {
        final d = w.decoration;
        return d is BoxDecoration && d.color != null;
      },
    );
    final color = (body.decoration as BoxDecoration).color!;
    expect(color.a, lessThan(1.0));
    expect(find.text('테스트 안내'), findsOneWidget);
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
}
