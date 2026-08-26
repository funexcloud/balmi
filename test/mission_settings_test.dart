import 'dart:io';

import 'package:balmi/core/copy.dart';
import 'package:balmi/core/theme.dart';
import 'package:balmi/data/db/app_database.dart';
import 'package:balmi/data/repositories/mission_settings_store.dart';
import 'package:balmi/data/repositories/session_repository.dart';
import 'package:balmi/domain/engines/workout_stats.dart';
import 'package:balmi/features/missions/mission_settings_controller.dart';
import 'package:balmi/features/missions/missions_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  test('mission settings store defaults and persistence', () async {
    final db = AppDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final store = MissionSettingsStore(db);

    expect(await store.loadReminderEnabled(), isFalse);
    expect(await store.loadShowCompleted(), isTrue);
    expect(await store.loadEnabledIds(), unorderedEquals(kKnownMissionIds));

    await store.saveReminderEnabled(true);
    await store.saveShowCompleted(false);
    await store.saveEnabledIds({kMissionToday30m, kMissionWeek15km});

    expect(await store.loadReminderEnabled(), isTrue);
    expect(await store.loadShowCompleted(), isFalse);
    expect(
      await store.loadEnabledIds(),
      unorderedEquals({kMissionToday30m, kMissionWeek15km}),
    );
  });

  test('controller filters completed and disabled mission types', () async {
    final db = AppDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final controller =
        MissionSettingsController(store: MissionSettingsStore(db));
    addTearDown(controller.dispose);
    await controller.bootstrap();

    final presets = [
      const MissionSnapshot(
        id: kMissionToday30m,
        title: '오늘 30분',
        current: 30,
        target: 30,
        unit: '분',
      ),
      const MissionSnapshot(
        id: kMissionWeek15km,
        title: '이번 주 15km',
        current: 5,
        target: 15,
        unit: 'km',
      ),
      const MissionSnapshot(
        id: kMissionTrack10,
        title: '트랙 10바퀴',
        current: 2,
        target: 10,
        unit: '바퀴',
      ),
    ];

    expect(controller.filterMissions(presets).map((m) => m.id), [
      kMissionToday30m,
      kMissionWeek15km,
      kMissionTrack10,
    ]);

    await controller.setShowCompleted(false);
    expect(controller.filterMissions(presets).map((m) => m.id), [
      kMissionWeek15km,
      kMissionTrack10,
    ]);

    await controller.setMissionEnabled(kMissionTrack10, false);
    expect(controller.filterMissions(presets).map((m) => m.id), [
      kMissionWeek15km,
    ]);

    // Cannot disable the last remaining type.
    await controller.setMissionEnabled(kMissionWeek15km, false);
    expect(controller.isMissionEnabled(kMissionWeek15km), isTrue);
  });

  testWidgets('Missions screen has 미션 설정 entry and opens sheet', (tester) async {
    final db = AppDatabase.executor(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = SessionRepository(db);
    final settings =
        MissionSettingsController(store: MissionSettingsStore(db));
    addTearDown(settings.dispose);
    await settings.bootstrap();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SessionRepository>.value(value: repo),
          ChangeNotifierProvider<MissionSettingsController>.value(
            value: settings,
          ),
        ],
        child: MaterialApp(
          theme: BalmiTheme.light(),
          home: const MissionsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(BalmiCopy.missions), findsOneWidget);
    expect(find.text(BalmiCopy.missionSettings), findsWidgets);
    expect(find.text('오늘 30분'), findsOneWidget);
    expect(find.text('이번 주 15km'), findsOneWidget);
    expect(find.text('트랙 10바퀴'), findsOneWidget);

    await tester.tap(find.text(BalmiCopy.missionSettings).first);
    await tester.pumpAndSettle();

    expect(find.text(BalmiCopy.missionReminder), findsOneWidget);
    expect(find.text(BalmiCopy.missionShowCompleted), findsOneWidget);
    expect(find.text(BalmiCopy.missionTypes), findsOneWidget);

    await tester.tap(find.text(BalmiCopy.missionReminder));
    await tester.pumpAndSettle();
    expect(settings.reminderEnabled, isTrue);

    await tester.tap(find.text(BalmiCopy.missionShowCompleted));
    await tester.pumpAndSettle();
    expect(settings.showCompleted, isFalse);
  });

  test('health habits screen source has no mission settings', () {
    final habits = File('lib/features/settings/health_habits_screen.dart')
        .readAsStringSync();
    final settings =
        File('lib/features/settings/settings_screen.dart').readAsStringSync();
    expect(habits, isNot(contains('MissionSettings')));
    expect(habits, isNot(contains('missionSettings')));
    expect(habits, isNot(contains('미션 설정')));
    expect(settings, isNot(contains('MissionSettings')));
    expect(settings, isNot(contains('missionSettings')));
  });
}
