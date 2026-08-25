import 'dart:math' as math;

import 'package:balmi/core/format.dart';
import 'package:balmi/data/db/app_database.dart';
import 'package:balmi/data/location/location_engine.dart';
import 'package:balmi/data/recording/recording_pipeline.dart';
import 'package:balmi/data/recording/recording_snapshot.dart';
import 'package:balmi/data/repositories/session_repository.dart';
import 'package:balmi/domain/engines/distance.dart';
import 'package:balmi/domain/engines/motion_filter.dart';
import 'package:balmi/domain/models/activity.dart';
import 'package:balmi/domain/models/sport.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('standing jitter stays still', () {
    final filter = GpsMotionFilter();
    final t0 = DateTime.utc(2026, 8, 22, 2);
    var lat = 37.5665;
    var lon = 126.9780;
    filter.evaluate(
      now: t0,
      lat: lat,
      lon: lon,
      hAccM: 12,
      rawSpeedMs: 8,
      speedAccuracyMs: 5,
      cadenceSpm: null,
    );
    var lastSpeed = 0.0;
    var added = 0.0;
    for (var i = 1; i <= 30; i++) {
      final jitterM = 8.0 + (i % 8);
      lat = 37.5665 + (jitterM / 111000) * ((i.isEven) ? 1 : -1);
      lon = 126.9780 + (jitterM / 88000) * ((i % 3 == 0) ? 1 : -1);
      final d = filter.evaluate(
        now: t0.add(Duration(seconds: i)),
        lat: lat,
        lon: lon,
        hAccM: 10.0 + (i % 10),
        rawSpeedMs: 12,
        speedAccuracyMs: 6,
        cadenceSpm: 20,
      );
      if (d.addDistance) added += d.distanceM;
      lastSpeed = d.filteredSpeedMs ?? lastSpeed;
    }
    expect(added, lessThan(3));
    expect(lastSpeed, closeTo(0, 0.2));
  });

  test('real walk still accumulates distance', () {
    final filter = GpsMotionFilter();
    final t0 = DateTime.utc(2026, 8, 22, 3);
    var lat = 37.0;
    const lon = 127.0;
    filter.evaluate(
      now: t0,
      lat: lat,
      lon: lon,
      hAccM: 8,
      rawSpeedMs: 1.4,
      speedAccuracyMs: 0.5,
      cadenceSpm: 110,
    );
    var added = 0.0;
    for (var i = 1; i <= 40; i++) {
      lat += 1.4 / 111000;
      final d = filter.evaluate(
        now: t0.add(Duration(seconds: i)),
        lat: lat,
        lon: lon,
        hAccM: 8,
        rawSpeedMs: 1.4,
        speedAccuracyMs: 0.4,
        cadenceSpm: 110,
      );
      if (d.addDistance) added += d.distanceM;
    }
    expect(added, greaterThan(20));
    expect(
      haversineMeters(lat1: 37.0, lon1: lon, lat2: lat, lon2: lon),
      closeTo(56, 8),
    );
  });

  test('manual hike does not WALK→RUN on 10 km/h GPS', () async {
    final db = AppDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SessionRepository(db);
    final start = DateTime.utc(2026, 8, 22, 4);
    final session = await repo.createSession(
      trackMode: false,
      startedAt: start,
      activity: ActivityKind.hike,
    );
    final pipe = RecordingPipeline(
      repo: repo,
      sessionId: session.id,
      startedAt: start,
      trackMode: false,
      activity: ActivityKind.hike,
    );
    await pipe.restore();
    var lat = 37.1;
    for (var i = 0; i < 20; i++) {
      lat += 2.8 / 111000;
      pipe
        ..onCadence(160)
        ..onFix(
          LocationFix(
            ts: start.add(Duration(seconds: i)),
            lat: lat,
            lng: 127.1,
            speedMs: 2.78,
            speedAccuracyMs: 4,
            hAccM: 8,
          ),
        );
      await pipe.sampleNow(start.add(Duration(seconds: i)));
    }
    expect(pipe.activity, ActivityKind.hike);
    expect(pipe.classifier.current, Sport.walk);
    expect(pipe.trail.length, greaterThan(5));
    expect(pipe.mapPin, isNotNull);
    final segs = await repo.segmentsFor(session.id);
    expect(segs.every((s) => s.sport != Sport.run.wire), isTrue);
  });

  test('manual track does not RUN→WALK on slow GPS', () async {
    final db = AppDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SessionRepository(db);
    final start = DateTime.utc(2026, 8, 22, 5);
    final session = await repo.createSession(
      trackMode: false,
      startedAt: start,
      activity: ActivityKind.track,
      trackSpecM: 400,
    );
    expect(session.trackMode, isTrue);
    expect(session.activity, 'track');
    final pipe = RecordingPipeline(
      repo: repo,
      sessionId: session.id,
      startedAt: start,
      trackMode: true,
      trackSpecM: 400,
      activity: ActivityKind.track,
    );
    await pipe.restore();
    var lat = 37.2;
    for (var i = 0; i < 20; i++) {
      lat += 0.8 / 111000;
      pipe
        ..onCadence(90)
        ..onFix(
          LocationFix(
            ts: start.add(Duration(seconds: i)),
            lat: lat,
            lng: 127.2,
            speedMs: 0.8,
            speedAccuracyMs: 0.4,
            hAccM: 8,
          ),
        );
      await pipe.sampleNow(start.add(Duration(seconds: i)));
    }
    expect(pipe.activity, ActivityKind.track);
    expect(pipe.trackMode, isTrue);
    expect(pipe.classifier.current, Sport.run);
    final segs = await repo.segmentsFor(session.id);
    expect(segs.every((s) => s.sport == Sport.run.wire), isTrue);
  });

  test('mid-session switch to track arms laps; leaving disables them', () async {
    final db = AppDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SessionRepository(db);
    final start = DateTime.utc(2026, 8, 22, 6);
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
    expect(pipe.trackMode, isFalse);

    pipe.onFix(
      LocationFix(
        ts: start,
        lat: 37.3,
        lng: 127.3,
        speedMs: 2,
        hAccM: 6,
      ),
    );
    await pipe.sampleNow(start);
    expect(pipe.laps.startLat, isNull);

    await pipe.setActivity(ActivityKind.track, start.add(const Duration(seconds: 1)));
    expect(pipe.trackMode, isTrue);
    expect(pipe.activity, ActivityKind.track);
    expect(pipe.trackSpecM, 400);
    var stored = await repo.sessionById(session.id);
    expect(stored!.activity, 'track');
    expect(stored.trackMode, isTrue);
    expect(stored.trackSpecM, 400);

    pipe.onFix(
      LocationFix(
        ts: start.add(const Duration(seconds: 2)),
        lat: 37.3,
        lng: 127.3,
        speedMs: 2,
        hAccM: 6,
      ),
    );
    await pipe.sampleNow(start.add(const Duration(seconds: 2)));
    expect(pipe.laps.startLat, isNotNull);

    await pipe.setActivity(ActivityKind.walk, start.add(const Duration(seconds: 3)));
    expect(pipe.trackMode, isFalse);
    expect(pipe.activity, ActivityKind.walk);
    stored = await repo.sessionById(session.id);
    expect(stored!.activity, 'walk');
    expect(stored.trackMode, isFalse);

    final finishLat = pipe.laps.startLat;
    pipe.onFix(
      LocationFix(
        ts: start.add(const Duration(seconds: 4)),
        lat: 37.4,
        lng: 127.4,
        speedMs: 2,
        hAccM: 6,
      ),
    );
    await pipe.sampleNow(start.add(const Duration(seconds: 4)));
    expect(pipe.laps.startLat, finishLat);
    expect(pipe.laps.lapNo, 0);
  });

  test('indoor still pin does not invent a path', () async {
    final db = AppDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SessionRepository(db);
    final start = DateTime.utc(2026, 8, 22, 7);
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
      filter: GpsMotionFilter(),
    );
    await pipe.restore();
    const lat = 37.5665;
    const lon = 126.9780;
    for (var i = 0; i < 8; i++) {
      pipe.onFix(
        LocationFix(
          ts: start.add(Duration(seconds: i)),
          lat: lat + (i.isEven ? 0.00001 : -0.00001),
          lng: lon,
          speedMs: 8,
          speedAccuracyMs: 6,
          hAccM: 12,
        ),
      );
      await pipe.sampleNow(start.add(Duration(seconds: i)));
    }
    expect(pipe.mapPin, isNotNull);
    expect(pipe.trail, isEmpty);
  });

  test('stale GPS resample does not zero live speed or drop the trail', () async {
    final db = AppDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SessionRepository(db);
    final start = DateTime.utc(2026, 8, 24, 7);
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
    var lat = 35.532;
    const lon = 129.259;
    RecordingSnapshot? snap;
    for (var tick = 0; tick < 60; tick++) {
      if (tick % 4 == 0) {
        lat += 1.4 / 111000;
        pipe
          ..onCadence(null)
          ..onFix(
            LocationFix(
              ts: start.add(Duration(seconds: tick)),
              lat: lat,
              lng: lon,
              speedMs: 1.4,
              speedAccuracyMs: 0.5,
              hAccM: 8,
            ),
          );
      }
      snap = await pipe.sampleNow(start.add(Duration(seconds: tick)));
    }
    expect(snap!.speedKmh, greaterThan(0.5));
    expect(formatPace(snap.speedKmh!), isNot('--\'--"'));
    expect(snap.totalDistM, greaterThan(8));
    expect(pipe.trail.length, greaterThan(5));
    final stored = await repo.pointsForSession(session.id);
    expect(stored.length, 15);
    expect(stored.length, pipe.seq);
  });

  test('GPS gap still plots the next accurate point on the trail', () async {
    final db = AppDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SessionRepository(db);
    final start = DateTime.utc(2026, 8, 24, 8);
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
    var lat = 35.53;
    const lon = 129.26;
    for (var i = 0; i < 25; i++) {
      lat += 1.2 / 111000;
      pipe.onFix(
        LocationFix(
          ts: start.add(Duration(seconds: i)),
          lat: lat,
          lng: lon,
          speedMs: 1.2,
          speedAccuracyMs: 0.4,
          hAccM: 8,
        ),
      );
      await pipe.sampleNow(start.add(Duration(seconds: i)));
    }
    final beforeGap = pipe.trail.length;
    expect(beforeGap, greaterThan(3));

    lat += 80 / 111000;
    pipe.onFix(
      LocationFix(
        ts: start.add(const Duration(seconds: 45)),
        lat: lat,
        lng: lon,
        speedMs: 1.2,
        speedAccuracyMs: 0.4,
        hAccM: 10,
      ),
    );
    final snap = await pipe.sampleNow(start.add(const Duration(seconds: 45)));
    expect(pipe.trail.length, beforeGap + 1);
    expect(pipe.trail.last.latitude, closeTo(lat, 0.000001));
    expect(snap.speedKmh ?? 0, greaterThan(0.5));
  });

  test('8 x 600m laps at walk pace count near 4.8km', () {
    final added = _walkLaps(
      laps: 8,
      lapM: 600,
      speedMs: 4800 / (52 * 60),
      hAccM: 14,
      rawSpeedMs: 0,
      speedAccuracyMs: 0,
      cadenceSpm: 25,
    );
    expect(added, greaterThan(4000));
    expect(added, lessThan(5600));
  });

  test('1Hz clones of one GPS fix do not invent lap distance', () {
    final filter = GpsMotionFilter();
    final t0 = DateTime.utc(2026, 8, 24, 19);
    const lat = 35.532;
    const lon = 129.259;
    filter.evaluate(
      now: t0,
      lat: lat,
      lon: lon,
      hAccM: 10,
      rawSpeedMs: 0,
      speedAccuracyMs: 0,
      cadenceSpm: 25,
    );
    var added = 0.0;
    for (var i = 1; i <= 200; i++) {
      final d = filter.evaluate(
        now: t0.add(Duration(seconds: i)),
        lat: lat,
        lon: lon,
        hAccM: 10,
        rawSpeedMs: 0,
        speedAccuracyMs: 0,
        cadenceSpm: 25,
      );
      if (d.addDistance) added += d.distanceM;
    }
    expect(added, 0);
  });

  test('weak cadence still counts an outdoor walk', () async {
    final db = AppDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SessionRepository(db);
    final start = DateTime.utc(2026, 8, 24, 19, 30);
    final session = await repo.createSession(
      trackMode: false,
      startedAt: start,
      activity: ActivityKind.auto,
    );
    final pipe = RecordingPipeline(
      repo: repo,
      sessionId: session.id,
      startedAt: start,
      trackMode: false,
      activity: ActivityKind.auto,
    );
    await pipe.restore();
    var lat = 35.532;
    const lon = 129.259;
    RecordingSnapshot? snap;
    for (var i = 0; i < 180; i++) {
      lat += 1.5 / 111000;
      pipe
        ..onCadence(25)
        ..onFix(
          LocationFix(
            ts: start.add(Duration(seconds: i)),
            lat: lat,
            lng: lon,
            speedMs: 0,
            speedAccuracyMs: 0,
            hAccM: 14,
          ),
        );
      snap = await pipe.sampleNow(start.add(Duration(seconds: i)));
    }
    expect(snap!.totalDistM, greaterThan(200));
    expect(snap.speedKmh ?? 0, greaterThan(0.5));
  });
}

double _walkLaps({
  required int laps,
  required double lapM,
  required double speedMs,
  required double hAccM,
  required double rawSpeedMs,
  required double speedAccuracyMs,
  required double? cadenceSpm,
}) {
  final filter = GpsMotionFilter();
  final t0 = DateTime.utc(2026, 8, 24, 18);
  const originLat = 35.5324;
  const originLon = 129.2593;
  final radiusM = lapM / (2 * math.pi);
  final seconds = (laps * lapM / speedMs).round();
  var added = 0.0;
  for (var i = 0; i <= seconds; i++) {
    final dist = speedMs * i;
    final ang = (dist / lapM) * 2 * math.pi;
    final lat = originLat + (radiusM * math.cos(ang)) / 111000;
    final lon = originLon +
        (radiusM * math.sin(ang)) /
            (111000 * math.cos(originLat * math.pi / 180));
    final d = filter.evaluate(
      now: t0.add(Duration(seconds: i)),
      lat: lat,
      lon: lon,
      hAccM: hAccM,
      rawSpeedMs: rawSpeedMs,
      speedAccuracyMs: speedAccuracyMs,
      cadenceSpm: cadenceSpm,
    );
    if (d.addDistance) added += d.distanceM;
  }
  return added;
}
