import 'dart:io';

import 'package:balmi/data/db/app_database.dart';
import 'package:balmi/data/repositories/session_repository.dart';
import 'package:balmi/domain/models/activity.dart';
import 'package:balmi/features/recording/recording_controller.dart';
import 'package:balmi/widgets/activity_pills.dart';
import 'package:balmi/widgets/circle_action.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('setPreferredActivity keeps explicit track meters including 자유', () {
    final db = AppDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SessionRepository(db);
    final rec = RecordingController(
      repo: repo,
      dbPath: 'mem',
      ensurePermissions: () async => null,
    );
    addTearDown(rec.dispose);

    rec.setPreferredActivity(ActivityKind.track, trackSpecM: 600);
    expect(rec.preferredActivity, ActivityKind.track);
    expect(rec.preferredTrackSpecM, 600);

    // Explicit null must stick (자유) — old `??` coalescing dropped this.
    rec.setPreferredActivity(ActivityKind.track, trackSpecM: null);
    expect(rec.preferredTrackSpecM, isNull);
  });

  test('startPreferred(track, meters) sets preferred and creates track session',
      () async {
    final db = AppDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SessionRepository(db);
    final rec = RecordingController(
      repo: repo,
      dbPath: 'mem',
      ensurePermissions: () async => null,
    );
    addTearDown(rec.dispose);

    await rec.startPreferred(ActivityKind.track, trackSpecM: 600);
    expect(rec.preferredActivity, ActivityKind.track);
    expect(rec.preferredTrackSpecM, 600);

    // createSession runs before GPS/_begin; row must be track + 600m even if
    // the VM cannot complete the location pipeline.
    final open = await repo.findRecording();
    expect(open, isNotNull);
    expect(open!.activity, 'track');
    expect(open.trackMode, isTrue);
    expect(open.trackSpecM, 600);
  });

  testWidgets('track meter sheet pop carries selected meters to caller',
      (tester) async {
    _SheetSpec? chosen;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    chosen = await showBalmiSheet<_SheetSpec>(
                      context: context,
                      builder: (ctx) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                          child: TrackSpecPills(
                            value: 400,
                            onChanged: (v) {
                              Navigator.of(ctx).pop(_SheetSpec(v));
                            },
                          ),
                        );
                      },
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('600'), findsOneWidget);

    await tester.tap(find.text('600'));
    await tester.pumpAndSettle();
    expect(chosen?.specM, 600);
  });

  test('home track flow: meter select calls startPreferred with choice.specM', () {
    final home = File('lib/features/home/home_screen.dart').readAsStringSync();
    expect(home, contains('startPreferred'));
    expect(home, contains('ActivityKind.track'));
    expect(home, contains('_TrackSpecChoice'));
    expect(home, contains('trackSpecM: choice.specM'));
    expect(home, contains('if (choice == null) return'));
    expect(home, contains('showBalmiSheet<_TrackSpecChoice>'));
  });
}

class _SheetSpec {
  const _SheetSpec(this.specM);
  final int? specM;
}
