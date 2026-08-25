import 'package:balmi/domain/engines/session_farm_grant.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('session_farm_grant', () {
    test('avgPaceRatio faster than 30-day average', () {
      final ratio = avgPaceRatioForSession(
        sessionDistM: 5000,
        sessionDuration: const Duration(minutes: 25),
        prior30Days: const [
          SessionPaceSample(
            distM: 10000,
            duration: Duration(minutes: 60),
          ),
        ],
      );
      expect(ratio, lessThan(1.0));
    });

    test('activity streak counts consecutive days', () {
      final streak = activityStreakDays(
        sessionDay: DateTime(2026, 8, 25),
        activeLocalDayKeys: {'2026-08-25', '2026-08-24', '2026-08-23'},
      );
      expect(streak, 3);
    });

    test('buildSessionResourceInput uses distance km', () {
      final input = buildSessionResourceInput(
        totalDistM: 5000,
        duration: const Duration(minutes: 40),
        prior30Days: const [],
        activeLocalDayKeys: {'2026-08-25'},
        sessionEndedAt: DateTime(2026, 8, 25, 18),
      );
      expect(input.distanceKm, 5.0);
      expect(input.streakDays, 1);
    });

    test('sessionQualifiesForFarmGrant matches land threshold', () {
      expect(sessionQualifiesForFarmGrant(49), isFalse);
      expect(sessionQualifiesForFarmGrant(50), isTrue);
    });
  });
}
