import 'dart:io';

import 'package:balmi/core/copy.dart';
import 'package:balmi/core/format.dart';
import 'package:flutter_test/flutter_test.dart';

const _forbidden = [
  'kyro',
  '트랭글',
  'tranggle',
  'nrc',
  'nike run',
  'run an empire',
  'stepn',
  '캐시워크',
  '런플롯',
  'runplot',
  'funex',
];

void main() {
  test('user-facing copy never uses forbidden terms', () {
    const blob =
        '${BalmiCopy.appName} ${BalmiCopy.slogan} ${BalmiCopy.subcopy} '
        '${BalmiCopy.healthSlogan} ${BalmiCopy.brandPhilosophy} ${BalmiCopy.heroLine} '
        '${BalmiCopy.oneLiner} ${BalmiCopy.positioning} '
        '${BalmiCopy.trustAlways} ${BalmiCopy.recoveryTitle} ${BalmiCopy.recoveryBody} '
        '${BalmiCopy.vasaCredit} ${BalmiCopy.vasaCreditDetail} ${BalmiCopy.waitingGps} '
        '${BalmiCopy.waitingGpsShort} ${BalmiCopy.locationOff} ${BalmiCopy.locationDenied} '
        '${BalmiCopy.locationDeniedForever} ${BalmiCopy.onboardingWelcome} '
        '${BalmiCopy.onboardingTrustTitle} ${BalmiCopy.onboardingPermsTitle} '
        '${BalmiCopy.onboardingBatteryTitle} ${BalmiCopy.onboardingBatteryBody} '
        '${BalmiCopy.landTitle} ${BalmiCopy.landPreview} ${BalmiCopy.landFoot} '
        '${BalmiCopy.about} ${BalmiCopy.versionLabel} '
        '${BalmiCopy.mealWalkDiscover} ${BalmiCopy.mealWalkIntro} '
        '${BalmiCopy.mealWalkDisclaimer} ${BalmiCopy.mealWalkStartPrompt} '
        '${BalmiCopy.mealWalkGo} ${BalmiCopy.mealWalkSkip} ${BalmiCopy.mealWalkBadge} '
        '${BalmiCopy.todaySteps} ${BalmiCopy.recordingSteps} '
        '${BalmiCopy.brandStoryTitle} ${BalmiCopy.brandStoryWhyTitle} '
        '${BalmiCopy.brandStoryHook} ${BalmiCopy.brandStoryBody1} '
        '${BalmiCopy.brandStoryBody2} ${BalmiCopy.brandStoryBody3} '
        '${BalmiCopy.brandStoryBridge} ${BalmiCopy.brandStoryCredit} '
        '${BalmiCopy.shareTitle} ${BalmiCopy.shareSubtitle} ${BalmiCopy.shareAction} '
        '${BalmiCopy.shareHideStartEnd} ${BalmiCopy.recordedToday}';
    final lower = blob.toLowerCase();
    for (final term in _forbidden) {
      expect(
        lower,
        isNot(contains(term)),
        reason: 'copy must not contain "$term"',
      );
    }
    expect(blob, isNot(contains('동반')));
    expect(blob, isNot(contains('장례')));
    expect(blob, isNot(contains('앱이 죽어도')));
    expect(blob, isNot(contains('누구에게나 심장에 좋다')));
    expect(blob, isNot(contains('심장을 치료')));
    expect(BalmiCopy.slogan, '걸음은 멈춰도, 기록은 멈추지 않도록.');
    expect(BalmiCopy.subcopy, '단 한 걸음도 잃어버리지 않도록.');
    expect(BalmiCopy.healthSlogan, '발걸음에서 혈관까지.');
    expect(BalmiCopy.brandPhilosophy, '움직임을 기록하고, 몸의 변화를 이해하다.');
    expect(BalmiCopy.brandStoryHook, '심장이 좋아하는 고구마색');
    expect(
      BalmiCopy.brandStoryBody2,
      contains('심혈관 건강을 위한 식생활에 잘 어울리는'),
    );
    expect(BalmiCopy.positioning, '기록을 잃지 않는 이동 기록');
    expect(BalmiCopy.trustAlways, '인터넷이 끊겨도 기록은 기기에 보존됩니다');
    expect(BalmiCopy.todaySteps, '오늘 걸음');
    expect(BalmiCopy.recordingSteps, '기록 중 걸음');
  });

  test('lib / Android / iOS UI sources do not name competitors', () {
    final files = <File>[
      ..._dartUnder(Directory('lib')),
      ..._xmlUnder(Directory('android/app/src')),
      File('ios/Runner/Info.plist'),
    ].where((f) => f.existsSync());

    for (final file in files) {
      final text = file.readAsStringSync();
      final lower = text.toLowerCase();
      for (final term in _forbidden) {
        expect(
          lower,
          isNot(contains(term)),
          reason: '${file.path} must not contain "$term"',
        );
      }
    }
  });

  test('settings copy does not expose implementation notes', () {
    final settingsCopy =
        '${BalmiCopy.vasaCreditDetail} '
        '${File('lib/features/settings/settings_screen.dart').readAsStringSync()} '
        '${File('lib/features/settings/brand_story_screen.dart').readAsStringSync()}';

    for (final term in [
      '건강 점수',
      '의료 평가',
      'HealthKit',
      'Health Connect',
      'Release 1',
      '누구에게나 심장에 좋다',
    ]) {
      expect(
        settingsCopy,
        isNot(contains(term)),
        reason: 'settings must not expose "$term" as implementation copy',
      );
    }
    expect(settingsCopy, contains('BalmiCopy.brandStoryTitle'));
    expect(settingsCopy, contains('BrandStoryScreen'));
  });

  test('lap TTS and result line format', () {
    expect(formatLapTts(lapNo: 3, lapTimeS: 128), '3바퀴, 2분 08초');
    expect(
      walkRunResultLine(
        walkDuration: const Duration(minutes: 12),
        walkMeters: 1200,
        runDuration: const Duration(minutes: 8),
        runMeters: 2100,
      ),
      '걷기 12m 1.20km / 뛰기 8m 2.10km',
    );
    expect(formatPace(0.4), '--\'--"');
    expect(formatPace(10), '6\'00"');
    expect(formatLapClock(128), '2\'08"');
    expect(
      formatRecordingNotification(
        elapsed: const Duration(minutes: 18, seconds: 5),
        distM: 0,
      ),
      '기록 18:05 · 0.00km',
    );
    expect(
      formatRecordingNotification(
        elapsed: const Duration(hours: 1, minutes: 2, seconds: 3),
        distM: 1540,
      ),
      '기록 1:02:03 · 1.54km',
    );
  });

  test('recording UI never labels GPS samples as 점', () {
    for (final file in _dartUnder(Directory('lib'))) {
      final text = file.readAsStringSync();
      expect(
        text,
        isNot(contains('점 ·')),
        reason: '${file.path} must not use 점 as a sample-count suffix',
      );
      expect(
        RegExp(r'\$\{[^}]*pointCount[^}]*\}점').hasMatch(text),
        isFalse,
        reason: '${file.path} must not suffix pointCount with 점',
      );
    }
  });

  test('session detail hides backend integrity rows', () {
    final detail =
        File('lib/features/session_detail/session_detail_screen.dart')
            .readAsStringSync();
    expect(detail, isNot(contains('integrity')));
    expect(detail, isNot(contains('BalmiCopy.totalPoints')));
    expect(detail, isNot(contains('BalmiCopy.excludedPoints')));
    expect(detail, isNot(contains('BalmiCopy.lastSynced')));
    expect(detail, contains('fitToPath: true'));
  });

  test('session detail shows 내 땅 reward instead of 종목 수정', () {
    final detail =
        File('lib/features/session_detail/session_detail_screen.dart')
            .readAsStringSync();
    expect(detail, isNot(contains('BalmiCopy.overrideSport')));
    expect(detail, isNot(contains('overrideSegmentSport')));
    expect(detail, contains('BalmiCopy.sessionLandReward'));
    expect(detail, contains('SessionLandReward'));
    expect(detail, contains('_landRewardSummary'));
    expect(BalmiCopy.sessionLandReward, '내 땅');
    expect(BalmiCopy.overrideSport, '종목 수정');
  });

  test('recording end surfaces have no 내 땅 보기 / land-map CTA', () {
    final detail =
        File('lib/features/session_detail/session_detail_screen.dart')
            .readAsStringSync();
    final endDialog =
        File('lib/widgets/end_recording_dialog.dart').readAsStringSync();
    final recording =
        File('lib/features/recording/recording_screen.dart').readAsStringSync();
    final copy = File('lib/core/copy.dart').readAsStringSync();

    for (final src in [detail, endDialog, recording, copy]) {
      expect(src, isNot(contains('내 땅 보기')));
      expect(src, isNot(contains('내땅보기')));
    }
    for (final src in [detail, endDialog, recording]) {
      expect(src, isNot(contains('openLandMap')));
      expect(src, isNot(contains('openLandPreview')));
    }
    // Reward summary stays; faux CTA trailing / potato land button does not.
    expect(detail, contains('_landRewardSummary'));
    expect(detail, isNot(contains('_landRewardTrailing')));
    expect(detail, isNot(contains('_landRewardCard')));
    expect(detail, isNot(contains('showLand')));
  });

  test('map OSD has no flutter_map badge; OSM credit lives in settings', () {
    final map = File('lib/widgets/osm_trace_map.dart').readAsStringSync();
    final settings = File('lib/features/settings/settings_screen.dart')
        .readAsStringSync();
    expect(map, isNot(contains('SimpleAttributionWidget')));
    expect(map, isNot(contains('RichAttributionWidget')));
    expect(settings, contains('BalmiCopy.mapCredit'));
    expect(BalmiCopy.mapCredit, contains('OpenStreetMap'));
  });
}

Iterable<File> _dartUnder(Directory dir) {
  if (!dir.existsSync()) return const [];
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'));
}

Iterable<File> _xmlUnder(Directory dir) {
  if (!dir.existsSync()) return const [];
  return dir.listSync(recursive: true).whereType<File>().where((f) {
    final p = f.path.replaceAll('\\', '/');
    return p.endsWith('.xml') && p.contains('/res/');
  });
}
