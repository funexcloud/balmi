/// Balmi Safety — product direction skeleton (docs: `docs/BALMI_SAFETY.md`).
///
/// HARD RULES (do not weaken in callers):
/// - Do NOT diagnose hypoglycemia from watch HR / tremor / motion alone.
/// - Do NOT ship UX: `저혈당인가요? → 119` direct jump.
/// - Framing: anomaly + safety check — never 「저혈당입니다」 without measured
///   CGM/glucose + careful clinical claims.
/// - Detection / SOS escalation is NOT a medical diagnosis.
/// - CGM glucose-aware logic only when actual measured glucose is integrated.
///
/// This file is a state-label skeleton only. No auto-dial, no fake glucose
/// inference, no production SOS UI.
library;

/// Safety Score levels: `정상 → 주의 → 회복 필요 → 안전 확인 → 긴급`.
enum SafetyScoreLevel {
  /// 이상 신호 없음.
  normal,

  /// 약한 이상 신호 (운동 직후 HR·모션·증상 힌트 등).
  caution,

  /// Recovery 안내 권장 (의식 있는 응답 + 증상).
  needsRecovery,

  /// 확인 UI·카운트다운 대기.
  safetyCheck,

  /// SOS·보호자·119 안내 경로 (구현 deferred).
  emergency,
}

/// Pure helpers for Safety Score labels / transitions.
///
/// Does not detect sensors, dial emergency services, or name diagnoses.
class BalmiSafety {
  BalmiSafety._();

  /// Canonical Korean label for UI copy tables (not a clinical diagnosis).
  static String labelKo(SafetyScoreLevel level) {
    switch (level) {
      case SafetyScoreLevel.normal:
        return '정상';
      case SafetyScoreLevel.caution:
        return '주의';
      case SafetyScoreLevel.needsRecovery:
        return '회복 필요';
      case SafetyScoreLevel.safetyCheck:
        return '안전 확인';
      case SafetyScoreLevel.emergency:
        return '긴급';
    }
  }

  /// Allowed anomaly framing — never a hypoglycemia diagnosis.
  static const anomalyFramingKo = '이상 신호가 있습니다. 안전을 확인하겠습니다.';

  /// User-confirm prompt (no diagnosis names).
  static const userConfirmPromptKo =
      '평소와 다른 신체 반응이 감지되었습니다. 괜찮으신가요?';

  /// Ordered escalation ladder (documentation + future wiring).
  static const escalationOrder = <SafetyScoreLevel>[
    SafetyScoreLevel.normal,
    SafetyScoreLevel.caution,
    SafetyScoreLevel.needsRecovery,
    SafetyScoreLevel.safetyCheck,
    SafetyScoreLevel.emergency,
  ];

  /// Next level on the documented ladder, or null at [SafetyScoreLevel.emergency].
  static SafetyScoreLevel? escalate(SafetyScoreLevel current) {
    final i = escalationOrder.indexOf(current);
    if (i < 0 || i >= escalationOrder.length - 1) return null;
    return escalationOrder[i + 1];
  }

  /// User tapped 「괜찮아요」 — drop to normal (skeleton policy).
  static SafetyScoreLevel afterUserOk(SafetyScoreLevel _) =>
      SafetyScoreLevel.normal;

  /// User tapped 「도움이 필요해요」 — go to emergency path (no auto-dial here).
  static SafetyScoreLevel afterUserNeedsHelp(SafetyScoreLevel _) =>
      SafetyScoreLevel.emergency;

  /// Forbidden diagnosis phrasing helpers for copy lint / tests.
  static bool containsForbiddenHypoglycemiaClaim(String text) {
    final t = text.replaceAll(' ', '');
    return t.contains('저혈당입니다') ||
        t.contains('저혈당인가요') ||
        t.contains('당신은저혈당');
  }
}
