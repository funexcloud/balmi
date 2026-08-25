import 'package:balmi/data/db/app_database.dart';
import 'package:balmi/data/repositories/farm_repository.dart';
import 'package:balmi/data/repositories/session_repository.dart';
import 'package:balmi/domain/models/activity.dart';
import 'package:balmi/domain/models/sport.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SessionRepository sessions;
  late FarmRepository farm;

  setUp(() {
    db = AppDatabase.executor(NativeDatabase.memory());
    sessions = SessionRepository(db);
    farm = FarmRepository(db);
  });

  tearDown(() => db.close());

  test('closeSession grants farm v2 resources once', () async {
    final session = await sessions.createSession(trackMode: false);
    await sessions.updateDistances(
      sessionId: session.id,
      totalDistM: 5000,
      walkDistM: 5000,
      runDistM: 0,
    );

    await sessions.closeSession(
      session.id,
      status: SessionStatus.closed,
      endedAt: session.startedAt.add(const Duration(minutes: 40)),
    );

    final balances = await farm.loadResources();
    expect(balances.feedBalance, greaterThan(0));
    expect(balances.waterBalance, greaterThan(0));
    expect(balances.nutrientBalance, greaterThan(0));

    final log = await farm.listResourceLog();
    expect(log, hasLength(1));
    expect(log.first.runSessionId, session.id);

    await sessions.closeSession(
      session.id,
      status: SessionStatus.closed,
      endedAt: DateTime(2026, 8, 25, 17, 40),
    );
    expect(await farm.listResourceLog(), hasLength(1));
  });

  test('closeSession skips grant below qualifying distance', () async {
    final session = await sessions.createSession(trackMode: false);
    await db.customStatement(
      'UPDATE sessions SET total_dist_m = ? WHERE id = ?',
      [30.0, session.id],
    );

    await sessions.closeSession(
      session.id,
      status: SessionStatus.closed,
      endedAt: DateTime(2026, 8, 25, 12),
    );

    final balances = await farm.loadResources();
    expect(balances.feedBalance, 0);
    expect(balances.waterBalance, 0);
    expect(await farm.listResourceLog(), isEmpty);
  });
}
