import 'package:balmi/core/copy.dart';
import 'package:balmi/domain/engines/land_city.dart';
import 'package:balmi/widgets/end_recording_dialog.dart';
import 'package:balmi/widgets/live_stats_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('end dialog asks to finish and warns only when walk is short', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EndRecordingDialog(distM: minLandSessionDistM - 1),
        ),
      ),
    );
    expect(find.text(BalmiCopy.endConfirmTitle), findsOneWidget);
    expect(find.text(BalmiCopy.endShortWalk), findsOneWidget);
    expect(find.textContaining('100m'), findsNothing);
    expect(find.text(BalmiCopy.endConfirmBack), findsOneWidget);
    expect(find.text(BalmiCopy.endConfirmYes), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EndRecordingDialog(distM: 800),
        ),
      ),
    );
    expect(find.text(BalmiCopy.endShortWalk), findsNothing);
  });

  testWidgets('collapsed sheet shows time and distance; pause shows 종료 and 재시작', (tester) async {
    var paused = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setLocal) {
              return LiveStatsSheet(
                expanded: false,
                onToggle: () {},
                elapsed: const Duration(seconds: 12),
                distM: 40,
                speedKmh: 8,
                paused: paused,
                onPause: () => setLocal(() => paused = true),
                onResume: () => setLocal(() => paused = false),
                onEnd: () {},
              );
            },
          ),
        ),
      ),
    );
    expect(find.text(BalmiCopy.statTime), findsOneWidget);
    expect(find.text(BalmiCopy.statDistance), findsOneWidget);
    expect(find.text(BalmiCopy.pauseShort), findsOneWidget);
    expect(find.text(BalmiCopy.statSpeed), findsNothing);

    await tester.tap(find.text(BalmiCopy.pauseShort));
    await tester.pump();
    expect(find.text(BalmiCopy.stopShort), findsOneWidget);
    expect(find.text(BalmiCopy.resumeShort), findsOneWidget);
  });

  testWidgets('expanded sheet adds speed and pace, never kcal', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LiveStatsSheet(
            expanded: true,
            onToggle: _noop,
            elapsed: Duration(minutes: 10),
            distM: 1200,
            speedKmh: 9,
            paused: false,
            onPause: _noop,
            onResume: _noop,
            onEnd: _noop,
            altM: 38,
          ),
        ),
      ),
    );
    expect(find.text(BalmiCopy.statSpeed), findsOneWidget);
    expect(find.text(BalmiCopy.currentPace), findsOneWidget);
    expect(find.textContaining('38m'), findsOneWidget);
    expect(find.textContaining('kcal'), findsNothing);
    expect(find.textContaining('칼로리'), findsNothing);
  });
}

void _noop() {}
