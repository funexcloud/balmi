import 'package:balmi/core/copy.dart';
import 'package:balmi/data/recording/recording_snapshot.dart';
import 'package:balmi/widgets/trust_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('live header shows GPS and trust, not save/sync chips', (tester) async {
    const snap = RecordingSnapshot(
      sessionId: 's',
      pointCount: 12,
      pendingChunks: 1,
      hAccM: 8,
      gpsStrength: 'strong',
      sport: 'walk',
      totalDistM: 40,
      walkDistM: 40,
      runDistM: 0,
      startedAtMs: 1,
      lapCount: 0,
      trackMode: false,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TrustHeader(snapshot: snap)),
      ),
    );
    expect(find.textContaining('GPS'), findsOneWidget);
    expect(find.text(BalmiCopy.trustAlways), findsOneWidget);
    expect(find.text(BalmiCopy.deviceSaved), findsNothing);
    expect(find.text(BalmiCopy.syncWaiting), findsNothing);
    expect(find.text(BalmiCopy.syncComplete), findsNothing);
    expect(find.textContaining('pt'), findsNothing);
  });
}
