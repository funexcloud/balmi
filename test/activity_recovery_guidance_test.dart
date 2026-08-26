import 'package:balmi/domain/engines/activity_recovery.dart';
import 'package:balmi/domain/models/activity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('guidance safety', () {
    test('every symptom guidance avoids diagnosis phrases', () {
      for (final symptom in RecoverySymptom.values) {
        final g = guidanceFor(
          symptom: symptom,
          metrics: const RecoverySessionMetrics(
            activity: ActivityKind.run,
            distanceM: 5000,
            duration: Duration(minutes: 40),
            avgSpeedKmh: 7.5,
          ),
        );
        expect(guidanceTextIsSafe(g.allText), isTrue, reason: symptom.wire);
        expect(g.allText.contains('저혈당입니다'), isFalse);
        expect(g.allText.contains('당신은 저혈당'), isFalse);
        expect(g.allText.contains('진단합니다'), isFalse);
      }
    });

    test('tremor guidance offers rest water carbs without diagnosing', () {
      final g = guidanceFor(symptom: RecoverySymptom.tremor);
      expect(g.offerFoodIntake, isTrue);
      expect(g.scheduleRecheck, isTrue);
      expect(g.suggestMedicalCare, isTrue);
      expect(g.steps.any((s) => s.contains('쉬')), isTrue);
      expect(g.steps.any((s) => s.contains('물')), isTrue);
      expect(
        g.steps.any((s) => s.contains('바나나') || s.contains('탄수화물')),
        isTrue,
      );
      expect(g.contextNote.contains('에너지 부족'), isTrue);
      expect(guidanceTextIsSafe(g.allText), isTrue);
    });

    test('forbiddenDiagnosisPhrases helper rejects bad copy', () {
      expect(guidanceTextIsSafe('당신은 저혈당입니다'), isFalse);
      expect(guidanceTextIsSafe('이 질환입니다'), isFalse);
      expect(guidanceTextIsSafe('당뇨입니다'), isFalse);
      expect(
        guidanceTextIsSafe('운동 후 에너지 부족 등 여러 원인에서 나타날 수 있는 증상입니다'),
        isTrue,
      );
      expect(
        guidanceTextIsSafe('진단이 아니라 당장 몸을 돌보는 안내예요'),
        isTrue,
      );
    });

    test('recheck ok completes; still bad escalates medically', () {
      final ok = resolveRecheck(
        feelingOk: true,
        original: RecoverySymptom.tremor,
      );
      expect(ok.status, RecoveryCheckStatus.recovered);
      expect(ok.suggestMedicalCare, isFalse);
      expect(guidanceTextIsSafe(ok.message), isTrue);

      final bad = resolveRecheck(
        feelingOk: false,
        original: RecoverySymptom.tremor,
        stillSymptom: RecoverySymptom.dizziness,
      );
      expect(bad.status, RecoveryCheckStatus.stillUnwell);
      expect(bad.suggestMedicalCare, isTrue);
      expect(bad.message.contains('의료기관'), isTrue);
      expect(guidanceTextIsSafe(bad.message), isTrue);
    });
  });

  group('timing', () {
    test('recheck due after delay', () {
      final start = DateTime(2026, 8, 26, 15, 0);
      final due = recheckDueAt(start);
      expect(due.difference(start), recoveryRecheckDelay);
      expect(
        isRecheckDue(
          dueAt: due,
          now: start.add(const Duration(minutes: 11)),
          status: RecoveryCheckStatus.recheckPending,
        ),
        isFalse,
      );
      expect(
        isRecheckDue(
          dueAt: due,
          now: due,
          status: RecoveryCheckStatus.recheckPending,
        ),
        isTrue,
      );
    });
  });

  test('symptom labels match product copy', () {
    expect(RecoverySymptom.normal.label, '정상');
    expect(RecoverySymptom.veryTired.label, '많이 지침');
    expect(RecoverySymptom.tremor.label, '몸이 떨림');
    expect(RecoverySymptom.dizziness.label, '어지러움');
    expect(RecoverySymptom.nausea.label, '메스꺼움');
    expect(RecoverySymptom.musclePain.label, '근육통/통증');
    expect(RecoverySymptom.tremor.recheckPrompt, '떨림은 괜찮아졌나요?');
  });
}
