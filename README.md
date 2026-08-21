# balmi

통신이 끊겨도, 앱이 죽어도, 단 한 걸음도 잃어버리지 않는 걷기·달리기 기록 앱.

포지셔닝: **재미는 KYRO, 신뢰는 balmi.**

Release 1 = F1–F4 (무손실 기록, 걷기↔뛰기, 트랙 랩, 신뢰 UI). 제품 스펙은 [`docs/SPEC.md`](docs/SPEC.md).

## 다운로드

- 저장소: https://github.com/funexcloud/balmi
- **ZIP**: GitHub 페이지의 **Code → Download ZIP**, 또는  
  https://github.com/funexcloud/balmi/archive/refs/heads/main.zip
- **클론**: `git clone https://github.com/funexcloud/balmi.git`
- **Android APK** (사이드로드): [Releases](https://github.com/funexcloud/balmi/releases)에서 `app-debug.apk`를 받아 설치합니다. 휴대폰에서 **알 수 없는 출처** 설치를 허용해야 합니다.
- 이 Windows 빌드에는 **iOS IPA가 없습니다.** iOS는 macOS에서 `flutter build ipa`가 필요합니다.

## 요구 환경

- Flutter SDK: `D:\flutter` (이 프로젝트는 3.47.1에서 생성)
- Android SDK: `D:\Android\sdk`
- PATH에 `D:\flutter\bin`을 앞에 둡니다. C: 드라이브 Docker/VS를 건드리지 마세요.

Windows Git Bash 예시:

```bash
export PATH="/d/flutter/bin:$PATH"
export ANDROID_HOME="/d/Android/sdk"
export ANDROID_SDK_ROOT="/d/Android/sdk"
cd "/d/APP/balmi+VASA"
flutter pub get
flutter analyze
flutter test
flutter run
```

PowerShell:

```powershell
$env:PATH = "D:\flutter\bin;" + $env:PATH
$env:ANDROID_HOME = "D:\Android\sdk"
$env:ANDROID_SDK_ROOT = "D:\Android\sdk"
cd D:\APP\balmi+VASA
flutter pub get
flutter run
```

## Drift 코드 생성

스키마를 바꾼 뒤:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 스텁 / 의도적 비구현

- **Supabase**: `OfflineSyncClient`가 자격 증명 없이 업로드를 거부(큐·백오프는 동작).
- **HealthKit / Health Connect (W1)**: `HealthBridge` 스텁.
- **유료 위치 플러그인**: 사용하지 않음. `LocationEngine` 주석이 교체 지점.
- **F5 territory / F6 crew**: 주석 스텁만.
