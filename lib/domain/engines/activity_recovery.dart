import '../models/activity.dart';

/// Post-workout body-feel check (wellness guidance only — not diagnosis).
enum RecoverySymptom {
  normal,
  veryTired,
  tremor,
  dizziness,
  nausea,
  musclePain;

  String get wire => name;

  String get label => switch (this) {
        normal => '정상',
        veryTired => '많이 지침',
        tremor => '몸이 떨림',
        dizziness => '어지러움',
        nausea => '메스꺼움',
        musclePain => '근육통/통증',
      };

  /// Prompt for the ~10–15 min follow-up.
  String get recheckPrompt => switch (this) {
        normal => '몸은 괜찮으신가요?',
        veryTired => '피곤함은 괜찮아졌나요?',
        tremor => '떨림은 괜찮아졌나요?',
        dizziness => '어지러움은 괜찮아졌나요?',
        nausea => '메스꺼움은 괜찮아졌나요?',
        musclePain => '통증은 괜찮아졌나요?',
      };

  static RecoverySymptom fromWire(String value) {
    return RecoverySymptom.values.firstWhere(
      (e) => e.wire == value,
      orElse: () => RecoverySymptom.normal,
    );
  }

  static const selectable = RecoverySymptom.values;
}

enum RecoveryCheckStatus {
  started,
  guided,
  intakeLogged,
  recheckPending,
  recovered,
  stillUnwell,
  dismissed;

  String get wire => name;

  static RecoveryCheckStatus fromWire(String value) {
    return RecoveryCheckStatus.values.firstWhere(
      (e) => e.wire == value,
      orElse: () => RecoveryCheckStatus.started,
    );
  }

  bool get isTerminal =>
      this == recovered || this == stillUnwell || this == dismissed;
}

enum RecoveryFood {
  milk,
  mango,
  banana,
  juice,
  energyBar,
  waterOnly,
  later;

  String get wire => name;

  String get label => switch (this) {
        milk => '우유',
        mango => '망고',
        banana => '바나나',
        juice => '주스',
        energyBar => '에너지바',
        waterOnly => '물만',
        later => '나중에',
      };

  static RecoveryFood fromWire(String value) {
    return RecoveryFood.values.firstWhere(
      (e) => e.wire == value,
      orElse: () => RecoveryFood.later,
    );
  }

  static const chips = RecoveryFood.values;
}

/// Session metrics used only to tone guidance — never to diagnose.
class RecoverySessionMetrics {
  const RecoverySessionMetrics({
    required this.activity,
    required this.distanceM,
    required this.duration,
    this.avgSpeedKmh,
  });

  final ActivityKind activity;
  final double distanceM;
  final Duration duration;
  final double? avgSpeedKmh;

  double get distanceKm => distanceM / 1000;

  bool get isLongSession =>
      duration.inMinutes >= 45 || distanceM >= 8000;

  bool get isHardEffort {
    final speed = avgSpeedKmh;
    if (speed != null && speed >= 10) return true;
    return activity == ActivityKind.run ||
        activity == ActivityKind.trail ||
        activity == ActivityKind.track ||
        activity == ActivityKind.hike;
  }
}

class RecoveryGuidance {
  const RecoveryGuidance({
    required this.key,
    required this.title,
    required this.contextNote,
    required this.steps,
    required this.suggestMedicalCare,
    required this.offerFoodIntake,
    required this.scheduleRecheck,
    required this.recheckPrompt,
  });

  final String key;
  final String title;
  final String contextNote;
  final List<String> steps;
  final bool suggestMedicalCare;
  final bool offerFoodIntake;
  final bool scheduleRecheck;
  final String recheckPrompt;

  /// Flattened text for safety lint tests.
  String get allText =>
      '$title\n$contextNote\n${steps.join('\n')}\n$recheckPrompt';
}

/// Strings that must never appear as disease-claim language in guidance.
const forbiddenDiagnosisPhrases = <String>[
  '저혈당입니다',
  '당신은 저혈당',
  '진단을 내',
  '진단합니다',
  '질환입니다',
  '병입니다',
  '질병입니다',
  '당뇨입니다',
  '빈혈입니다',
  '의료기기입니다',
  '처방합니다',
];

const recoveryMedicalEscalation =
    '증상이 심하거나 계속되면 가까운 의료기관을 이용해 주세요. '
    '응급이면 119에 연락하세요.';

const recoveryDisclaimer =
    '이 안내는 운동 후 몸을 돌보는 생활 팁이며, 의학적 진단·처방을 대신하지 않습니다.';

/// Default follow-up window after intake / guidance.
const recoveryRecheckDelay = Duration(minutes: 12);

RecoveryGuidance guidanceFor({
  required RecoverySymptom symptom,
  RecoverySessionMetrics? metrics,
}) {
  final long = metrics?.isLongSession == true;
  final hard = metrics?.isHardEffort == true;
  final effortHint = long || hard
      ? '이번 활동이 길거나 다소 힘들었을 수 있어요. '
      : '';

  switch (symptom) {
    case RecoverySymptom.normal:
      return RecoveryGuidance(
        key: 'normal',
        title: '몸이 괜찮다면 가볍게 정리해 보세요',
        contextNote:
            '${effortHint}무리하지 않는 선에서 스트레칭과 수분 보충이면 충분할 때가 많아요.',
        steps: const [
          '편한 자세로 호흡을 고르세요',
          '물을 천천히 마시세요',
          '가벼운 스트레칭으로 몸을 풀어 주세요',
        ],
        suggestMedicalCare: false,
        offerFoodIntake: false,
        scheduleRecheck: false,
        recheckPrompt: symptom.recheckPrompt,
      );
    case RecoverySymptom.veryTired:
      return RecoveryGuidance(
        key: 'very_tired',
        title: '많이 지침 — 잠시 쉬어 보세요',
        contextNote:
            '${effortHint}운동 후 에너지가 떨어져 나타날 수 있는 느낌입니다. '
            '여러 원인이 있을 수 있어요.',
        steps: const [
          '앉거나 기대어 5–10분 쉬세요',
          '물을 천천히 마시세요',
          '가능하면 가벼운 탄수화물 간식을 드세요',
        ],
        suggestMedicalCare: false,
        offerFoodIntake: true,
        scheduleRecheck: true,
        recheckPrompt: symptom.recheckPrompt,
      );
    case RecoverySymptom.tremor:
      return RecoveryGuidance(
        key: 'tremor',
        title: '몸이 떨릴 때 — 우선 안전하게',
        contextNote:
            '${effortHint}운동 후 에너지 부족 등 여러 원인에서 나타날 수 있는 증상입니다. '
            '진단이 아니라 당장 몸을 돌보는 안내예요.',
        steps: const [
          '앉거나 누워서 쉬세요',
          '물을 조금씩 마시세요',
          '바나나·우유·주스 등 탄수화물 간식을 드세요',
          '혼자 서 있지 말고 안전한 곳에서 기다리세요',
        ],
        suggestMedicalCare: true,
        offerFoodIntake: true,
        scheduleRecheck: true,
        recheckPrompt: symptom.recheckPrompt,
      );
    case RecoverySymptom.dizziness:
      return RecoveryGuidance(
        key: 'dizziness',
        title: '어지러울 때 — 넘어지지 않게',
        contextNote:
            '${effortHint}운동 후 탈수·피로 등 여러 원인에서 나타날 수 있는 증상입니다.',
        steps: const [
          '앉거나 누워서 머리를 낮추세요',
          '갑자기 일어서지 마세요',
          '물을 천천히 마시세요',
          '주변이 있으면 도움을 요청하세요',
        ],
        suggestMedicalCare: true,
        offerFoodIntake: true,
        scheduleRecheck: true,
        recheckPrompt: symptom.recheckPrompt,
      );
    case RecoverySymptom.nausea:
      return RecoveryGuidance(
        key: 'nausea',
        title: '메스꺼움이 있을 때',
        contextNote:
            '${effortHint}운동 직후 속이 불편할 수 있어요. 무리한 섭취는 피하세요.',
        steps: const [
          '앉아서 천천히 호흡하세요',
          '차가운 물을 소량만 마시세요',
          '속이 가라앉을 때까지 억지로 먹지 마세요',
          '심해지면 활동을 멈추고 쉬세요',
        ],
        suggestMedicalCare: true,
        offerFoodIntake: true,
        scheduleRecheck: true,
        recheckPrompt: symptom.recheckPrompt,
      );
    case RecoverySymptom.musclePain:
      return RecoveryGuidance(
        key: 'muscle_pain',
        title: '근육통·통증이 있을 때',
        contextNote:
            '${effortHint}운동 후 근육 피로로 느껴질 때가 많아요. '
            '날카롭거나 붓는 통증은 더 주의가 필요해요.',
        steps: const [
          '통증 부위를 무리하게 쓰지 마세요',
          '편한 자세로 쉬세요',
          '가벼운 스트레칭만 하세요 (통증 심하면 중단)',
          '붓거나 움직임이 어렵면 의료기관을 이용해 주세요',
        ],
        suggestMedicalCare: true,
        offerFoodIntake: false,
        scheduleRecheck: true,
        recheckPrompt: symptom.recheckPrompt,
      );
  }
}

/// Recheck outcome → next status / medical nudge.
({RecoveryCheckStatus status, bool suggestMedicalCare, String message})
    resolveRecheck({
  required bool feelingOk,
  required RecoverySymptom original,
  RecoverySymptom? stillSymptom,
}) {
  if (feelingOk) {
    return (
      status: RecoveryCheckStatus.recovered,
      suggestMedicalCare: false,
      message: '회복 체크를 마쳤어요. 무리하지 말고 하루를 이어 가세요.',
    );
  }
  final again = stillSymptom ?? original;
  final guide = guidanceFor(symptom: again);
  return (
    status: RecoveryCheckStatus.stillUnwell,
    suggestMedicalCare: true,
    message:
        '${again.label}이(가) 계속된다면 더 쉬고, 필요하면 의료기관을 이용해 주세요.\n'
        '${guide.contextNote}',
  );
}

DateTime recheckDueAt(DateTime from, {Duration delay = recoveryRecheckDelay}) {
  return from.add(delay);
}

bool isRecheckDue({
  required DateTime? dueAt,
  required DateTime now,
  required RecoveryCheckStatus status,
}) {
  if (status != RecoveryCheckStatus.recheckPending) return false;
  if (dueAt == null) return false;
  return !now.isBefore(dueAt);
}

bool guidanceTextIsSafe(String text) {
  final lower = text.toLowerCase();
  for (final phrase in forbiddenDiagnosisPhrases) {
    if (text.contains(phrase) || lower.contains(phrase.toLowerCase())) {
      return false;
    }
  }
  return true;
}
