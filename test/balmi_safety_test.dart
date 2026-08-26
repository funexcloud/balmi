import 'package:balmi/domain/engines/balmi_safety.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SafetyScoreLevel ladder order matches product docs', () {
    expect(BalmiSafety.escalationOrder.map(BalmiSafety.labelKo).toList(), [
      '정상',
      '주의',
      '회복 필요',
      '안전 확인',
      '긴급',
    ]);
  });

  test('escalate walks the ladder without skipping to emergency from caution', () {
    expect(BalmiSafety.escalate(SafetyScoreLevel.normal), SafetyScoreLevel.caution);
    expect(
      BalmiSafety.escalate(SafetyScoreLevel.caution),
      SafetyScoreLevel.needsRecovery,
    );
    expect(
      BalmiSafety.escalate(SafetyScoreLevel.needsRecovery),
      SafetyScoreLevel.safetyCheck,
    );
    expect(
      BalmiSafety.escalate(SafetyScoreLevel.safetyCheck),
      SafetyScoreLevel.emergency,
    );
    expect(BalmiSafety.escalate(SafetyScoreLevel.emergency), isNull);
  });

  test('user confirm actions map without diagnosing hypoglycemia', () {
    expect(
      BalmiSafety.afterUserOk(SafetyScoreLevel.safetyCheck),
      SafetyScoreLevel.normal,
    );
    expect(
      BalmiSafety.afterUserNeedsHelp(SafetyScoreLevel.caution),
      SafetyScoreLevel.emergency,
    );
    expect(
      BalmiSafety.containsForbiddenHypoglycemiaClaim(BalmiSafety.anomalyFramingKo),
      isFalse,
    );
    expect(
      BalmiSafety.containsForbiddenHypoglycemiaClaim(BalmiSafety.userConfirmPromptKo),
      isFalse,
    );
    expect(
      BalmiSafety.containsForbiddenHypoglycemiaClaim('저혈당인가요?'),
      isTrue,
    );
  });
}
