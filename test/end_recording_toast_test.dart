import 'package:balmi/core/copy.dart';
import 'package:balmi/domain/models/activity.dart';
import 'package:balmi/features/recording/recording_screen.dart';
import 'package:balmi/widgets/circle_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('auto activity semantics omit live 걷기/뛰기', () {
    expect(
      recordingActivitySemanticsLabel(ActivityKind.auto),
      BalmiCopy.activityAuto,
    );
    expect(
      recordingActivitySemanticsLabel(ActivityKind.auto),
      isNot(contains(BalmiCopy.run)),
    );
    expect(
      recordingActivitySemanticsLabel(ActivityKind.auto),
      isNot(contains(BalmiCopy.walk)),
    );
    expect(
      recordingActivitySemanticsLabel(ActivityKind.run),
      ActivityKind.run.label,
    );
    expect(
      recordingActivitySemanticsLabel(ActivityKind.walk),
      ActivityKind.walk.label,
    );
  });

  testWidgets('auto CircleAction does not expose 뛰기 semantics', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CircleAction(
            icon: Icons.directions_run,
            label: recordingActivitySemanticsLabel(ActivityKind.auto),
            onTap: () {},
          ),
        ),
      ),
    );
    final node = tester.getSemantics(find.byType(CircleAction));
    expect(node.label, BalmiCopy.activityAuto);
    expect(node.label, isNot(contains(BalmiCopy.run)));
    expect(find.bySemanticsLabel(BalmiCopy.run), findsNothing);
  });

  testWidgets('clearSnackBars removes stray 뛰기 toast after end', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Column(
                children: [
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text(BalmiCopy.run)),
                      );
                    },
                    child: const Text('queue'),
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).clearSnackBars();
                    },
                    child: const Text('clear'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('queue'));
    await tester.pump();
    expect(find.text(BalmiCopy.run), findsOneWidget);

    await tester.tap(find.text('clear'));
    await tester.pump();
    expect(find.text(BalmiCopy.run), findsNothing);
  });
}
