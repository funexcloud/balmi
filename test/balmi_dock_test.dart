import 'package:balmi/core/copy.dart';
import 'package:balmi/widgets/balmi_dock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dock is icon-only with semantics labels', (tester) async {
    var index = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BalmiDock(
            index: index,
            onChanged: (i) => index = i,
          ),
        ),
      ),
    );

    expect(find.text(BalmiCopy.recordTab), findsNothing);
    expect(find.text(BalmiCopy.workoutLogTab), findsNothing);
    expect(find.text(BalmiCopy.mapTab), findsNothing);
    expect(find.text(BalmiCopy.moreTab), findsNothing);
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    expect(find.byIcon(Icons.history_outlined), findsOneWidget);
    expect(find.byIcon(Icons.map_outlined), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(BalmiCopy.mapTab));
    expect(index, 2);
  });
}
