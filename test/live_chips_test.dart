import 'package:balmi/core/copy.dart';
import 'package:balmi/data/recording/recording_snapshot.dart';
import 'package:balmi/widgets/locate_fixed_icon.dart';
import 'package:balmi/widgets/status_chips.dart';
import 'package:balmi/widgets/trust_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('live header shows GPS ●●● ±Nm with LocateFixed, not signal bars', (
    tester,
  ) async {
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
    expect(find.text('GPS ●●● ±8m'), findsOneWidget);
    expect(find.byType(LocateFixedIcon), findsOneWidget);
    expect(find.byType(GpsQualityDots), findsNothing);
    expect(find.text(BalmiCopy.trustAlways), findsNothing);
    expect(find.text(BalmiCopy.deviceSaved), findsNothing);
    expect(find.text(BalmiCopy.syncWaiting), findsNothing);
    expect(find.text(BalmiCopy.syncComplete), findsNothing);
    expect(find.textContaining('pt'), findsNothing);
  });

  testWidgets('waiting GPS shows empty dots without accuracy', (tester) async {
    const snap = RecordingSnapshot(
      sessionId: 's',
      pointCount: 0,
      pendingChunks: 0,
      hAccM: null,
      gpsStrength: 'none',
      sport: 'walk',
      totalDistM: 0,
      walkDistM: 0,
      runDistM: 0,
      startedAtMs: 1,
      lapCount: 0,
      trackMode: false,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TrustHeader(snapshot: snap, waiting: true),
        ),
      ),
    );
    expect(find.text('GPS ○○○'), findsOneWidget);
    expect(find.byType(LocateFixedIcon), findsOneWidget);
  });

  test('gps live line and quality labels follow accuracy bands', () {
    expect(BalmiCopy.gpsQuality('strong'), '우수');
    expect(BalmiCopy.gpsQuality('ok'), '양호');
    expect(BalmiCopy.gpsQuality('weak'), '약함');
    expect(BalmiCopy.gpsQuality('poor'), '약함');
    expect(BalmiCopy.gpsQuality('none', waiting: true), '수신 중');
    expect(
      BalmiCopy.gpsLiveLine(strength: 'strong', hAccM: 3),
      'GPS ●●● ±3m',
    );
    expect(
      BalmiCopy.gpsLiveLine(strength: 'ok', hAccM: 15),
      'GPS ●●○ ±15m',
    );
    expect(
      BalmiCopy.gpsLiveLine(strength: 'weak', hAccM: 28),
      'GPS ●○○ ±28m',
    );
    expect(
      BalmiCopy.gpsLiveLine(strength: 'none', waiting: true),
      'GPS ○○○',
    );
  });
}
