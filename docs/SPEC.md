# balmi 제품 스펙 v2.0

- 일자: 2026-08-20
- 앱 표시 이름: **balmi**
- 조직/번들: `im.balmi.app` (Android applicationId / iOS bundle)
- Release 1 범위: **F1–F4만**. F5 영역(territory) / F6 크루는 범위 밖(빈 스텁·주석만). 현금 리워드 없음.

## 한 줄

통신이 끊겨도, 앱이 죽어도, 단 한 걸음도 잃어버리지 않는 걷기·달리기 기록 앱.

## 포지셔닝

재미는 KYRO, 신뢰는 balmi.

사용자에게 보이는 문구에 타사 클라우드 브랜드명, 동반, 장례 표현을 넣지 않는다.

---

## F1 무손실 기록

### R1

GPS 포인트를 **1초마다** 로컬 SQLite에 **즉시** 저장한다. 서버 유무와 관계없이 기록이 완성된다.

### R2

`sync_queue`는 기록 테이블과 **분리**한다. 업로드는 **60포인트 청크**. 실패 시 백오프 **5초 → 15초 → 60초 → 5분**. 앱 시작 시 남은 큐를 재개한다.

Supabase 클라이언트가 없거나 자격 증명이 없으면 **no-op / 오프라인 어댑터**여도 된다. 큐와 리포지토리는 반드시 구현한다.

### R3

화면이 꺼지거나 백그라운드여도 기록이 이어진다.

- Android: Foreground Service + partial WakeLock
- iOS: background location 모드 (Info.plist 키)

유료 플러그인 `flutter_background_geolocation`(라이선스)은 **추가하지 않는다**. `LocationEngine` 인터페이스 위에 `geolocator` + `flutter_foreground_task`(또는 동등한 유지보수 패키지)를 쓴다. 교체 지점은 짧은 주석으로 남긴다.

### R4

크래시/강제 종료 후 실행 시 마지막 `recording` 세션을 감지하고 대화상자 **「이어서 기록 / 여기서 종료」**. 종료해도 포인트는 모두 남긴다.

### R5

OEM 배터리 최적화 여부를 감지하고, 온보딩에서 제조사별 설정으로 딥링크한다. (Samsung / Xiaomi / Huawei / Oppo / Vivo / Pixel 등 가능한 범위)

### R6

`h_acc_m`을 저장한다. 위성 수(`sat_count`)는 가능하면 nullable로 저장. **h_acc > 30m** 포인트는 거리 합산에서 **제외**하되 DB에는 **보관**한다.

---

## F2 걷기 ↔ 뛰기

입력:

- 속도: GPS 도플러(`speed`) 우선, 없으면 좌표 미분
- 케이던스: 가속도계 (`sensors_plus`)

히스테리시스:

- WALK→RUN: 속도 ≥ 9.0 km/h **그리고** 케이던스 ≥ 140 spm 이 **15초 연속**
- RUN→WALK: 속도 ≤ 7.0 km/h 이 **15초 연속**
- h_acc > 30m: **현재 종목을 유지**

파라미터는 원격 설정 형태의 클래스(코드 기본값, 덮어쓰기 가능).

종목 전환 시 `segments`를 분할한다.

결과 화면: **「걷기 Xm Ykm / 뛰기 Xm Ykm」** (X=분, Y=km).

정지 후 사용자가 세그먼트 종목을 고칠 수 있다. **원래 판정은 유지**한다.

---

## F3 트랙 랩

트랙 모드 ON → 처음 **200m 궤적**이 출발(가상 피니시)을 정의한다.

랩 조건:

- 출발점 **18m 반경** 진입
- 진행 방향이 첫 통과 헤딩의 **±60°** 이내
- 직전 랩 이후 **60초 이상**

`lap_time`을 기록하고 TTS: **「3바퀴, 2분 08초」** (`flutter_tts`).

트랙 규격: **400 / 300 / 200 / 자유(m)**. 규격이 선택된 경우 거리 = **랩 수 × 규격** (GPS 과소 측정 보정).

학교·공원 트랙 등 **이름 없는 코스**에서도 동작해야 한다. (명명된 코스 DB 없음)

---

## F4 신뢰 UI

기록 화면 헤더는 항상:

- GPS 강도
- 로컬 포인트 수
- 동기화 대기
- 동기화 완료 체크

카피 (온보딩 **및** 기록 화면):

> 통신이 끊겨도 기록은 기기에 전부 저장됩니다

세션 상세 **기록 무결성**: 총 포인트, 저품질(제외) 포인트, 마지막 동기화 시각.

---

## 데이터 (Drift SQLite, 향후 Supabase와 같은 형태)

```
sessions   (id, started_at, ended_at, status[recording|closed|recovered],
            track_mode, track_spec_m, total_dist_m, walk_dist_m, run_dist_m)
points     (session_id, seq, ts, lat, lng, alt, speed_ms, h_acc_m,
            cadence_spm, synced[0|1], sat_count?)
segments   (session_id, seq, sport[walk|run], started_at, ended_at,
            dist_m, user_override[0|1], judged_sport)
laps       (session_id, lap_no, crossed_at, lap_time_s, lap_dist_m)
sync_queue (chunk_id, session_id, seq_from, seq_to, retry_count, next_retry_at)
```

UUID/text id 허용. `sat_count`는 nullable. `judged_sport`는 사용자 수정 시 원래 판정을 남기기 위한 컬럼.

---

## 아키텍처

도메인 엔진은 **순수 Dart + 유닛 테스트** (Flutter import 없음):

- 거리 (haversine, h_acc>30 스킵)
- 종목 히스테리시스 분류기
- 트랙 랩 감지기
- 동기화 백오프
- recording 세션 복구

기능 화면: 온보딩, 기록, 복구 대화상자, 히스토리, 세션 상세(무결성 + 세그먼트 수정).

브랜드 UI: 부드럽고 친근한 한국어. 의료/장례 톤 아님. 이름 **balmi**. 설정/소개에만 작은 **× VASA** 기술 크레딧(의료 점수가 아님).

---

## 패키지

flutter, drift, sqlite3_flutter_libs, path_provider, geolocator, permission_handler, flutter_foreground_task, sensors_plus, flutter_tts, provider, intl.

상태 관리는 **provider**로 통일.

### Android 권한

FOREGROUND_SERVICE, FOREGROUND_SERVICE_LOCATION, ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION, ACCESS_BACKGROUND_LOCATION, POST_NOTIFICATIONS, WAKE_LOCK.

Foreground service type: **location**. 가능하면 배터리 최적화 제외 인텐트.

### iOS

NSLocationWhenInUse, NSLocationAlwaysAndWhenInUse, UIBackgroundModes location.

---

## 범위 밖 (Release 1)

- **F5 territory**: 영역/코스 점유. 구현하지 않음.
- **F6 crew**: 크루. 구현하지 않음.
- 현금 리워드 없음.
- HealthKit / Health Connect (W1): 스텁만.
- 유료 `flutter_background_geolocation`: 사용하지 않음. `LocationEngine`에서 교체 가능.

---

## Activity Recovery / 회복 체크 (웰니스 MVP)

제품 흐름: **운동 종료 → 회복 체크 → 맞춤 행동 안내**.

정식 제품 기능이며, 자유형 AI 채팅이 아니다. 의료기기·진단이 아니다.

### 사용자 흐름 (MVP)

1. 세션 종료/상세 화면에 **「회복 체크」** 카드(최소 진입점).
2. **“현재 몸 상태는 어떤가요?”** — 정상 / 많이 지침 / 몸이 떨림 / 어지러움 / 메스꺼움 / 근육통·통증.
3. 선택 + 세션 지표(거리·시간·평균 속도·활동 종류)로 **안전한 생활 안내** 표시.
   - 예(떨림): 앉아서 쉬기 → 물 마시기 → 탄수화물 간식.  
     표현: “운동 후 에너지 부족 등 여러 원인에서 나타날 수 있는 증상입니다”.  
     **금지**: “당신은 저혈당입니다” 등 진단 문장.
   - 위험·지속 증상 → **의료기관 이용 / 119** 안내.
4. 후속: **“지금 먹을 수 있는 음식은?”** — 칩 목록(우유·망고·바나나·주스·에너지바·물만·나중에).  
   사진 입력은 MVP에서 제외(후속).
5. 약 10–15분 뒤(로컬 알림 + 앱 재오픈 시 대기 재확인): 증상별 **“떨림은 괜찮아졌나요?”**  
   - OK → 회복 완료  
   - 아직 안 좋음 → 증상 재선택 + 의료 안내
6. 로컬 영속: `workout_session_id → symptom → intake → recheck → outcome`  
   (장기 패턴 인사이트 UI는 후속; 데이터 모델은 지금 마련).

### 안전 규칙 (하드)

- 질병 진단 언어 금지.
- 조심스러운 원인 서술만 허용.
- 심하거나 지속되면 의료기관 안내를 분명히.
- 의료기기·처방 대체 주장 금지. 화면 디스클레이머 필수.

### 통합

- 세션 상세(종료 후) 진입. 농장/게이미피케이션과 **독립**(차단하지 않음).
- 로컬 알림은 식후 걷기와 동일 계열(`flutter_local_notifications`).
- 스키마: Drift `schemaVersion` 8 + `activity_recovery_checks` 테이블.

### 의도적 후속 (deferred)

- 음식 **사진** 입력
- 장기 **패턴 인사이트** UI
- 워치/심박 연동

---

## 테스트

분류기, 랩 감지기, 거리 제외, 백오프 유닛 테스트. `flutter test` 녹색 목표.

## 실행

Flutter SDK: `D:\flutter` (3.47.1). Android SDK: `D:\Android\sdk`. 자세한 내용은 저장소 `README.md`.
