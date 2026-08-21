/// User-visible Korean copy. Keep this file free of unrelated brand/funeral wording.
abstract final class BalmiCopy {
  static const appName = 'balmi';
  static const oneLiner = '통신이 끊겨도, 앱이 죽어도, 단 한 걸음도 잃어버리지 않는 걷기·달리기 기록 앱.';
  static const positioning = '재미는 KYRO, 신뢰는 balmi.';
  static const trustAlways = '통신이 끊겨도 기록은 기기에 전부 저장됩니다';

  static const resumeRecording = '이어서 기록';
  static const endHere = '여기서 종료';
  static const recoveryTitle = '기록이 끝나지 않았어요';
  static const recoveryBody = '이전에 시작했던 걷기가 기기에 그대로 남아 있습니다. 이어서 기록할까요, 여기서 종료할까요? 종료해도 저장된 점은 사라지지 않습니다.';

  static const start = '기록 시작';
  static const starting = '기록 준비 중…';
  static const stop = '기록 종료';
  static const locationOff = '위치 서비스가 꺼져 있어요. 설정에서 위치를 켠 뒤 다시 시작해 주세요.';
  static const locationDenied = '위치 권한이 없어 기록할 수 없어요. 정확한 위치를 허용해 주세요.';
  static const locationDeniedForever =
      '위치 권한이 거부되어 있어요. 앱 설정에서 위치를 허용한 뒤 다시 시작해 주세요.';
  static const waitingGps =
      'GPS 수신 대기 중이에요. 실내에서는 1–2분이 걸릴 수 있어요. 포인트 수가 오르면 기록이 되고 있는 겁니다.';
  static const waitingGpsShort = 'GPS 수신 대기 중';
  static const keepAliveFailed = '백그라운드 알림을 못 켰어요. 화면을 켜 둔 동안은 기록을 이어갑니다.';
  static const startFailed = '기록을 시작하지 못했어요';
  static const history = '지난 기록';
  static const settings = '설정';
  static const trackMode = '트랙 모드';
  static const trackSpec = '트랙 규격';
  static const specFree = '자유';
  static const walk = '걷기';
  static const run = '뛰기';

  static const gps = 'GPS';
  static const localPoints = '로컬';
  static const syncPending = '대기';
  static const syncDone = '동기화';

  static const integrity = '기록 무결성';
  static const totalPoints = '전체 포인트';
  static const excludedPoints = '저품질(거리 제외, 보관됨)';
  static const lastSynced = '마지막 동기화';
  static const neverSynced = '아직 없음';
  static const originalJudgment = '원래 판정';
  static const overrideSport = '종목 수정';

  static const onboardingWelcome = '안녕하세요, balmi예요';
  static const onboardingTrustTitle = '한 걸음도 기기에서 잃지 않아요';
  static const onboardingPermsTitle = '기록이 끊기지 않게 권한을 켜 주세요';
  static const onboardingBatteryTitle = '배터리 최적화만 꺼 주세요';
  static const onboardingBatteryBody =
      '일부 휴대폰은 절전 때문에 백그라운드 기록을 멈춥니다. 아래 제조사 설정에서 balmi를 예외로 두세요.';
  static const continueLabel = '계속';
  static const done = '시작하기';
  static const locationPermission = '정확한 위치';
  static const alwaysLocation = '항상 위치 (화면이 꺼져도)';
  static const notificationPermission = '알림 (기록 중 표시)';
  static const ignoreBattery = '배터리 최적화 제외';
  static const oemSettings = '제조사 절전 설정 열기';

  static const vasaCredit = '× VASA';
  static const vasaCreditDetail = '움직임 기록 기술 크레딧입니다. 건강 점수나 의료 평가가 아닙니다.';
  static const about = '이 앱 정보';

  static String gpsStrength(String code) {
    switch (code) {
      case 'strong':
        return '강함';
      case 'ok':
        return '보통';
      case 'weak':
        return '약함';
      case 'poor':
        return '불량';
      default:
        return '없음';
    }
  }
}
