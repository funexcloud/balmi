import 'package:balmi/domain/engines/activity_share.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('activityShareId / deep link stub', () {
    test('uses first 8 hex chars of uuid without dashes', () {
      expect(
        activityShareIdFromSession('a1b2c3d4-e5f6-7890-abcd-ef1234567890'),
        'A1B2C3D4',
      );
      expect(
        activityShareDeepLink('A1B2C3D4'),
        'https://balmi.im/a/A1B2C3D4',
      );
    });

    test('pads short ids', () {
      expect(activityShareIdFromSession('ab'), 'AB000000');
    });
  });

  group('buildActivityShareSummary', () {
    test('record style builds brand headline and stub link', () {
      final s = buildActivityShareSummary(
        sessionId: '11111111-2222-3333-4444-555555555555',
        style: ActivityShareStyle.record,
        activityLabel: '걷기',
        distanceM: 5820,
        duration: const Duration(hours: 1, minutes: 14, seconds: 32),
        steps: 8421,
      );
      expect(s.shareId, '11111111');
      expect(s.headline, '오늘 5.82 km 걷기했습니다.');
      expect(s.tagline, contains('기록은 멈추지 않도록'));
      expect(s.deepLink, 'https://balmi.im/a/11111111');
      expect(s.hideStartEnd, isTrue);
      expect(s.includeMap, isFalse);
      expect(s.avgPaceLabel, isNotNull);
    });

    test('vasa falls back to record availability', () {
      final s = buildActivityShareSummary(
        sessionId: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        style: ActivityShareStyle.vasa,
        activityLabel: '달리기',
        distanceM: 10000,
        duration: const Duration(minutes: 50),
        steps: 0,
      );
      expect(s.style, ActivityShareStyle.record);
      expect(ActivityShareStyle.vasa.isAvailable, isFalse);
    });

    test('map style enables includeMap by default', () {
      final s = buildActivityShareSummary(
        sessionId: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        style: ActivityShareStyle.map,
        activityLabel: '걷기',
        distanceM: 3000,
        duration: const Duration(minutes: 40),
        steps: 4000,
      );
      expect(s.includeMap, isTrue);
      expect(s.headline, '오늘도 하나의 길을 남겼습니다.');
    });
  });

  group('buildActivityShareText', () {
    test('includes balmi, stats, tagline, and deep link', () {
      final s = buildActivityShareSummary(
        sessionId: 'deadbeef-0000-0000-0000-000000000000',
        style: ActivityShareStyle.minimal,
        activityLabel: '걷기',
        distanceM: 5820,
        duration: const Duration(hours: 1, minutes: 14, seconds: 32),
        steps: 8421,
      );
      final text = buildActivityShareText(s);
      expect(text, contains('balmi'));
      expect(text, contains('5.82 km'));
      expect(text, contains('1:14:32'));
      expect(text, contains('8,421걸음'));
      expect(text, contains('https://balmi.im/a/DEADBEEF'));
      expect(text.toLowerCase(), isNot(contains('저혈당')));
      expect(text.toLowerCase(), isNot(contains('naver')));
    });
  });

  group('redactSharePathStartEnd', () {
    test('drops points near start and end within radius', () {
      // Roughly 1° lat ≈ 111 km. Use small offsets along a line.
      const start = ShareLatLng(37.0, 127.0);
      final mid = ShareLatLng(37.01, 127.0); // ~1.1 km north
      const end = ShareLatLng(37.02, 127.0);
      // Points very close to start/end (~50 m via tiny delta)
      final nearStart = ShareLatLng(37.0003, 127.0);
      final nearEnd = ShareLatLng(37.0197, 127.0);
      final path = [start, nearStart, mid, nearEnd, end];
      final redacted = redactSharePathStartEnd(path, radiusM: 200);
      expect(redacted, isNotEmpty);
      expect(redacted.first.lat, greaterThan(start.lat));
      expect(redacted.last.lat, lessThan(end.lat));
      // Midpoint should survive 200 m redaction on a 2+ km path.
      expect(redacted.any((p) => (p.lat - mid.lat).abs() < 1e-9), isTrue);
    });

    test('returns empty for tiny paths', () {
      expect(
        redactSharePathStartEnd([
          const ShareLatLng(1, 1),
          const ShareLatLng(1.0001, 1),
        ], radiusM: 300),
        isEmpty,
      );
    });
  });
}
