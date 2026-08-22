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
    const blob = '${BalmiCopy.appName} ${BalmiCopy.oneLiner} ${BalmiCopy.positioning} '
        '${BalmiCopy.trustAlways} ${BalmiCopy.recoveryTitle} ${BalmiCopy.recoveryBody} '
        '${BalmiCopy.vasaCredit} ${BalmiCopy.vasaCreditDetail} ${BalmiCopy.waitingGps} '
        '${BalmiCopy.waitingGpsShort} ${BalmiCopy.locationOff} ${BalmiCopy.locationDenied} '
        '${BalmiCopy.locationDeniedForever} ${BalmiCopy.onboardingWelcome} '
        '${BalmiCopy.onboardingTrustTitle} ${BalmiCopy.onboardingPermsTitle} '
        '${BalmiCopy.onboardingBatteryTitle} ${BalmiCopy.onboardingBatteryBody} '
        '${BalmiCopy.landTitle} ${BalmiCopy.landPreview} ${BalmiCopy.landFoot} '
        '${BalmiCopy.about} ${BalmiCopy.versionLabel}';
    final lower = blob.toLowerCase();
    for (final term in _forbidden) {
      expect(lower, isNot(contains(term)), reason: 'copy must not contain "$term"');
    }
    expect(blob, isNot(contains('동반')));
    expect(blob, isNot(contains('장례')));
    expect(BalmiCopy.positioning, '잃어버리지 않는 기록');
    expect(BalmiCopy.trustAlways, '통신이 끊겨도 기록은 기기에 전부 저장됩니다');
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
