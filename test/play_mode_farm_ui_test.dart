import 'dart:io';

import 'package:balmi/core/copy.dart';
import 'package:balmi/domain/models/activity.dart';
import 'package:balmi/features/recording/recording_controller.dart';
import 'package:balmi/data/db/app_database.dart';
import 'package:balmi/data/repositories/session_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('preferred activity survives set and feeds createSession wire', () async {
    final db = AppDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SessionRepository(db);
    final rec = RecordingController(repo: repo, dbPath: 'mem');
    addTearDown(rec.dispose);

    expect(rec.preferredActivity, ActivityKind.auto);
    rec.setPreferredActivity(ActivityKind.hike);
    expect(rec.preferredActivity, ActivityKind.hike);

    rec.setPreferredActivity(ActivityKind.track, trackSpecM: 600);
    expect(rec.preferredActivity, ActivityKind.track);
    expect(rec.preferredTrackSpecM, 600);

    final session = await repo.createSession(
      trackMode: true,
      trackSpecM: rec.preferredTrackSpecM,
      activity: rec.preferredActivity,
    );
    expect(session.activity, 'track');
    expect(session.trackSpecM, 600);
  });

  test('farm preview is farm-only; no walked path or land guide', () {
    final farm =
        File('lib/features/land/farm_preview_screen.dart').readAsStringSync();
    expect(farm, contains('openFarmPreview'));
    expect(farm, contains('FarmPreviewScreen'));
    expect(farm, contains('BalmiCopy.farmTitle'));
    expect(farm, isNot(contains('landWalkedPath')));
    expect(farm, isNot(contains('landGuide')));
    expect(farm, isNot(contains('OsmTraceMap')));
    expect(farm, isNot(contains('ExpansionTile')));
    expect(farm, isNot(contains(BalmiCopy.landWalkedPath)));
    expect(farm, isNot(contains(BalmiCopy.landGuide)));

    final home = File('lib/features/home/home_screen.dart').readAsStringSync();
    expect(home, contains('openFarmPreview'));

    final more = File('lib/features/more/more_screen.dart').readAsStringSync();
    expect(more, contains('openLandMap'));
    expect(more, contains('openFarmPreview'));

    final map =
        File('lib/features/map/map_explore_screen.dart').readAsStringSync();
    expect(map, contains('openLandMap'));
    expect(map, isNot(contains('openLandPreview')));
  });
}
