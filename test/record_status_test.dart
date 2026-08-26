import 'package:balmi/domain/engines/record_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('status language never exposes storage jargon', () {
    const status = RecordSurvivalStatus(
      recording: true,
      gps: GpsLink.good,
      network: RecordLink.offline,
      sync: SyncLink.pending,
      hAccM: 7,
    );
    expect(status.primaryLine, '오프라인 기록 중');
    expect(status.saveLine, '동기화 대기');
    expect(status.gpsLine, 'GPS 양호 · ±7m');
    expect(status.primaryLine.toLowerCase(), isNot(contains('sqlite')));
    expect(status.saveLine.toLowerCase(), isNot(contains('buffer')));
    expect(status.gpsOkWithoutNetwork, isTrue);
  });

  test('recovery and recording lines', () {
    expect(
      const RecordSurvivalStatus(
        recording: true,
        justRecovered: true,
        gps: GpsLink.good,
        network: RecordLink.online,
        sync: SyncLink.local,
      ).primaryLine,
      '기록 복구 완료',
    );
    expect(
      const RecordSurvivalStatus(
        recording: true,
        gps: GpsLink.excellent,
        network: RecordLink.online,
        sync: SyncLink.local,
      ).primaryLine,
      '기록 중',
    );
    expect(
      const RecordSurvivalStatus(
        recording: true,
        gps: GpsLink.excellent,
        network: RecordLink.online,
        sync: SyncLink.local,
      ).saveLine,
      '기기에 안전하게 저장 중',
    );
  });

  test('gps and network are independent', () {
    const onlineNoGps = RecordSurvivalStatus(
      recording: true,
      gps: GpsLink.lost,
      network: RecordLink.online,
      sync: SyncLink.local,
    );
    expect(onlineNoGps.networkOkWithoutGps, isTrue);
    expect(onlineNoGps.gpsLine, 'GPS 신호를 찾는 중');
  });

  test('gps accuracy bands', () {
    expect(RecordSurvivalStatus.gpsFromAccuracy(3), GpsLink.excellent);
    expect(RecordSurvivalStatus.gpsFromAccuracy(8), GpsLink.good);
    expect(RecordSurvivalStatus.gpsFromAccuracy(15), GpsLink.fair);
    expect(RecordSurvivalStatus.gpsFromAccuracy(40), GpsLink.weak);
    expect(RecordSurvivalStatus.gpsFromAccuracy(80), GpsLink.lost);
    expect(
      RecordSurvivalStatus.gpsFromAccuracy(null, hasRecentFix: false),
      GpsLink.searching,
    );
  });
}
