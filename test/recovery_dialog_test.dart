import 'package:balmi/core/copy.dart';
import 'package:balmi/core/format.dart';
import 'package:balmi/domain/engines/recovery.dart';
import 'package:balmi/domain/models/sport.dart';
import 'package:balmi/features/recovery/recovery_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('recovery dialog shows stats and survival CTAs', (tester) async {
    final started = DateTime(2026, 8, 26, 19, 10);
    final session = RecoverableSession(
      id: 's',
      status: SessionStatus.recording,
      startedAt: started,
      activity: 'run',
      totalDistM: 4270,
      pointCount: 100,
      lastPointAt: DateTime(2026, 8, 26, 19, 42),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () => showRecoveryDialog(context, session),
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text(BalmiCopy.recoveryTitle), findsOneWidget);
    expect(find.text('달리기'), findsOneWidget);
    expect(find.text('${formatKm(4270)} km'), findsOneWidget);
    expect(find.text(BalmiCopy.resumeRecording), findsOneWidget);
    expect(find.text(BalmiCopy.endHere), findsOneWidget);
    expect(find.text(BalmiCopy.recoveryLastLabel), findsOneWidget);
    expect(find.text('오후 7:42'), findsOneWidget);
  });
}
