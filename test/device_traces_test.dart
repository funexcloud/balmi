import 'dart:math' as math;

import 'package:balmi/data/db/app_database.dart';
import 'package:balmi/data/map/device_traces.dart';
import 'package:balmi/data/repositories/session_repository.dart';
import 'package:balmi/domain/engines/land_city.dart';
import 'package:balmi/domain/models/sport.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('0km indoor session earns 0㎡ and draws no land line', () async {
    final db = AppDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SessionRepository(db);
    final start = DateTime.utc(2026, 8, 21, 10);
    final session = await repo.createSession(trackMode: false, startedAt: start);
    for (var i = 0; i < 40; i++) {
      final ang = i / 40 * 2 * math.pi;
      await repo.insertPoint(
        sessionId: session.id,
        seq: i + 1,
        ts: start.add(Duration(seconds: i)),
        lat: 37.5665 + 0.00003 * math.cos(ang),
        lng: 126.9780 + 0.00003 * math.sin(ang),
        hAccM: 12,
      );
    }
    await repo.updateDistances(
      sessionId: session.id,
      totalDistM: 0,
      walkDistM: 0,
      runDistM: 0,
    );
    await repo.closeSession(session.id, status: SessionStatus.closed);

    final traces = await loadDeviceTraces(repo);
    expect(traces.lines, isEmpty);
    expect(traces.loops, isEmpty);
    expect(traces.hasLine, isFalse);
    expect(traces.loopAreaM2, 0);
    expect(traces.pathBandM2, 0);
    expect(traces.budget(0).earnedM2, 0);
  });

  test('walk of 80m still counts as land', () async {
    final db = AppDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SessionRepository(db);
    final start = DateTime.utc(2026, 8, 21, 11);
    final session = await repo.createSession(trackMode: false, startedAt: start);
    for (var i = 0; i < 12; i++) {
      await repo.insertPoint(
        sessionId: session.id,
        seq: i + 1,
        ts: start.add(Duration(seconds: i * 8)),
        lat: 37.5665 + i * 0.00008,
        lng: 126.9780,
        hAccM: 10,
      );
    }
    await repo.updateDistances(
      sessionId: session.id,
      totalDistM: 80,
      walkDistM: 80,
      runDistM: 0,
    );
    await repo.closeSession(session.id, status: SessionStatus.closed);

    final traces = await loadDeviceTraces(repo);
    expect(traces.hasLine, isTrue);
    expect(traces.lines.single.length, 12);
    expect(traces.pathBandM2, LandBudget.pathBandFromDistanceM(80));
    expect(traces.budget(0).earnedM2, 320);
  });
}
