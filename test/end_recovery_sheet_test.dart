import 'package:balmi/core/copy.dart';
import 'package:balmi/core/theme.dart';
import 'package:balmi/data/db/app_database.dart';
import 'package:balmi/data/notifications/activity_recovery_alarms.dart';
import 'package:balmi/data/repositories/activity_recovery_store.dart';
import 'package:balmi/data/repositories/session_repository.dart';
import 'package:balmi/domain/engines/activity_recovery.dart';
import 'package:balmi/domain/models/activity.dart';
import 'package:balmi/features/activity_recovery/activity_recovery_controller.dart';
import 'package:balmi/features/session_detail/session_detail_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<String> _closedSession(SessionRepository repo) async {
    final s = await repo.createSession(
      trackMode: false,
      activity: ActivityKind.walk,
    );
    await repo.closeSession(s.id);
    return s.id;
  }

  testWidgets('autoOpenRecovery presents 회복 체크 sheet after end', (tester) async {
    final db = AppDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SessionRepository(db);
    final recovery = ActivityRecoveryController(
      store: ActivityRecoveryStore(db, newId: () => 'rec-1'),
      alarms: SilentActivityRecoveryAlarms(),
    );
    addTearDown(recovery.dispose);
    await recovery.bootstrap();

    final id = await _closedSession(repo);

    await tester.pumpWidget(
      MaterialApp(
        theme: BalmiTheme.light(),
        home: MultiProvider(
          providers: [
            Provider<SessionRepository>.value(value: repo),
            ChangeNotifierProvider<ActivityRecoveryController>.value(
              value: recovery,
            ),
          ],
          child: SessionDetailScreen(
            sessionId: id,
            autoOpenRecovery: true,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(find.text(BalmiCopy.activityRecoveryTitle), findsWidgets);
    expect(find.text(BalmiCopy.activityRecoveryHowFeel), findsOneWidget);
    expect(find.text(RecoverySymptom.normal.label), findsOneWidget);
  });

  testWidgets('autoOpenRecovery skipped when check already terminal', (tester) async {
    final db = AppDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SessionRepository(db);
    final store = ActivityRecoveryStore(db, newId: () => 'rec-done');
    final recovery = ActivityRecoveryController(
      store: store,
      alarms: SilentActivityRecoveryAlarms(),
    );
    addTearDown(recovery.dispose);
    await recovery.bootstrap();

    final id = await _closedSession(repo);
    final started = await store.startCheck(
      workoutSessionId: id,
      metrics: const RecoverySessionMetrics(
        activity: ActivityKind.walk,
        distanceM: 1000,
        duration: Duration(seconds: 600),
      ),
      symptom: RecoverySymptom.normal,
    );
    await store.completeRecheck(
      id: started.id,
      feelingOk: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: BalmiTheme.light(),
        home: MultiProvider(
          providers: [
            Provider<SessionRepository>.value(value: repo),
            ChangeNotifierProvider<ActivityRecoveryController>.value(
              value: recovery,
            ),
          ],
          child: SessionDetailScreen(
            sessionId: id,
            autoOpenRecovery: true,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(find.text(BalmiCopy.activityRecoveryHowFeel), findsNothing);
    expect(find.text(BalmiCopy.activityRecoveryDoneHint), findsOneWidget);
  });
}
