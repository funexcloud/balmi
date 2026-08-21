import 'package:balmi/data/recording/recording_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('strength bands', () {
    expect(RecordingSnapshot.strengthFor(null), 'none');
    expect(RecordingSnapshot.strengthFor(8), 'strong');
    expect(RecordingSnapshot.strengthFor(15), 'ok');
    expect(RecordingSnapshot.strengthFor(25), 'weak');
    expect(RecordingSnapshot.strengthFor(40), 'poor');
  });

  test('json round-trip keeps point count', () {
    const snap = RecordingSnapshot(
      sessionId: 's1',
      pointCount: 12,
      pendingChunks: 1,
      hAccM: 18,
      gpsStrength: 'ok',
      sport: 'walk',
      totalDistM: 40,
      walkDistM: 40,
      runDistM: 0,
      startedAtMs: 1,
      lapCount: 0,
      trackMode: false,
    );
    final copy = RecordingSnapshot.fromJson(snap.toJson());
    expect(copy.pointCount, 12);
    expect(copy.gpsStrength, 'ok');
    expect(copy.sessionId, 's1');
  });
}
