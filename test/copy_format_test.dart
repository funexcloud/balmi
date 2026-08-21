import 'package:balmi/core/copy.dart';
import 'package:balmi/core/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('user-facing copy never uses forbidden terms', () {
    const blob = '${BalmiCopy.appName} ${BalmiCopy.oneLiner} ${BalmiCopy.positioning} '
        '${BalmiCopy.trustAlways} ${BalmiCopy.recoveryBody} ${BalmiCopy.vasaCreditDetail} '
        '${BalmiCopy.waitingGps} ${BalmiCopy.locationOff} ${BalmiCopy.locationDenied}';
    expect(blob.toLowerCase(), isNot(contains('funex')));
    expect(blob, isNot(contains('동반')));
    expect(blob, isNot(contains('장례')));
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
  });
}
