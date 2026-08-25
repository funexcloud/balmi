import 'package:balmi/data/db/app_database.dart';
import 'package:balmi/data/location/location_engine.dart';
import 'package:balmi/data/recording/recording_pipeline.dart';
import 'package:balmi/data/recording/recording_snapshot.dart';
import 'package:balmi/data/repositories/session_repository.dart';
import 'package:balmi/domain/engines/step_distance.dart';
import 'package:balmi/domain/models/activity.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stale GPS with walk cadence keeps adding step metres', () {
    final fill = StepDistanceIntegrator();
    final t0 = DateTime.utc(2026, 8, 25, 10);
    fill.markGps(t0, totalSteps: 0);
    var added = 0.0;
    for (var i = 1; i <= 20; i++) {
      added += fill.sampleWhileGpsStale(
        now: t0.add(Duration(seconds: i)),
        totalSteps: 0,
        cadenceSpm: 110,
        running: false,
      );
    }
    // 17 stale seconds after the 3s grace: 17 * 110/60 * 0.72 ≈ 22.4
    expect(added, greaterThan(18));
    expect(added, lessThan(28));
  });

  test('GPS clones without steps do not invent metres', () {
    final fill = StepDistanceIntegrator();
    final t0 = DateTime.utc(2026, 8, 25, 11);
    fill.markGps(t0, totalSteps: 40);
    var added = 0.0;
    for (var i = 1; i <= 30; i++) {
      added += fill.sampleWhileGpsStale(
        now: t0.add(Duration(seconds: i)),
        totalSteps: 40,
        cadenceSpm: 25,
        running: false,
      );
    }
    expect(added, 0);
  });

  test('GPS jump after a step-filled gap is not double-counted', () {
    final fill = StepDistanceIntegrator();
    final t0 = DateTime.utc(2026, 8, 25, 12);
    fill.markGps(t0, totalSteps: 0);
    var added = 0.0;
    for (var i = 1; i <= 70; i++) {
      added += fill.sampleWhileGpsStale(
        now: t0.add(Duration(seconds: i)),
        totalSteps: i * 2,
        cadenceSpm: 110,
        running: false,
      );
    }
    expect(added, greaterThan(80));
    final gpsChord = fill.takeGpsMeters(80);
    expect(gpsChord, 0);
    expect(fill.uncountedStepM, 0);
    expect(added + gpsChord, added);
  });

  test('GPS that saw more than steps still adds the remainder', () {
    final fill = StepDistanceIntegrator();
    final t0 = DateTime.utc(2026, 8, 25, 13);
    fill.markGps(t0, totalSteps: 0);
    fill.sampleWhileGpsStale(
      now: t0.add(const Duration(seconds: 4)),
      totalSteps: 4,
      cadenceSpm: 110,
      running: false,
    );
    // 4 steps * 0.72 = 2.88m, GPS chord 20m
    expect(fill.takeGpsMeters(20), closeTo(17.12, 0.05));
  });

  test('fresh GPS ticks do not mix in cadence metres', () {
    final fill = StepDistanceIntegrator();
    final t0 = DateTime.utc(2026, 8, 25, 14);
    var added = 0.0;
    for (var i = 0; i < 10; i++) {
      fill.markGps(t0.add(Duration(seconds: i)), totalSteps: i * 2);
      added += fill.sampleWhileGpsStale(
        now: t0.add(Duration(seconds: i)),
        totalSteps: i * 2,
        cadenceSpm: 110,
        running: false,
      );
    }
    expect(added, 0);
  });

  test('pipeline keeps recording during a GPS outage from steps', () async {
    final db = AppDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SessionRepository(db);
    final start = DateTime.utc(2026, 8, 25, 15);
    final session = await repo.createSession(
      trackMode: false,
      startedAt: start,
      activity: ActivityKind.walk,
    );
    final pipe = RecordingPipeline(
      repo: repo,
      sessionId: session.id,
      startedAt: start,
      trackMode: false,
      activity: ActivityKind.walk,
    );
    await pipe.restore();
    const lat = 35.532;
    const lon = 129.259;
    pipe
      ..onCadence(110)
      ..onFix(
        LocationFix(
          ts: start,
          lat: lat,
          lng: lon,
          speedMs: 1.4,
          speedAccuracyMs: 0.4,
          hAccM: 8,
        ),
      );
    await pipe.sampleNow(start);
    final afterLock = pipe.distance.meters;

    pipe.recordingSteps = 0;
    RecordingSnapshot? snap;
    for (var i = 1; i <= 50; i++) {
      pipe
        ..onCadence(110)
        ..recordingSteps = i * 2;
      snap = await pipe.sampleNow(start.add(Duration(seconds: i)));
    }
    expect(snap!.totalDistM, greaterThan(afterLock + 50));
    expect(pipe.trail.length, lessThan(3));

    pipe.onFix(
      LocationFix(
        ts: start.add(const Duration(seconds: 51)),
        lat: lat + 40 / 111000,
        lng: lon,
        speedMs: 1.4,
        speedAccuracyMs: 0.4,
        hAccM: 10,
      ),
    );
    final afterJump = await pipe.sampleNow(
      start.add(const Duration(seconds: 51)),
    );
    expect(afterJump.totalDistM, closeTo(snap.totalDistM, 1));
  });
}
