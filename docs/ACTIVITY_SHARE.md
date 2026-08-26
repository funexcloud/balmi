# Balmi 활동 공유 구조

- 상태: **제품 방향 명세** + **앱 측 Light MVP** (OS 공유 시트 · 요약 문구 · 딥링크 스텁).  
  웹 Share Page · Universal Link 라우팅 · 서버 발행 공유 ID · SNS 백엔드는 **미구현**.
- 원 기획: *Balmi 활동 공유 구조 기획* (업로드 MD).
- 관련: [`SPEC.md`](SPEC.md) · [`BALMI_SAFETY.md`](BALMI_SAFETY.md) · Record Survival(로컬 기록 우선)

---

## 한 줄

**App → Share → Web → App** — 운동 기록이 자연스러운 성장 루프가 된다. 광고가 아니라 **사용자의 기록**이 Balmi를 알린다.

---

## 역할 분리

| 표면 | 역할 | 카피 축 |
|------|------|---------|
| **Landing** | WHY BALMI | 브랜드·철학 |
| **App** | USE BALMI | 기록·신뢰·무손실 |
| **Share Page** | DISCOVER BALMI | 다른 사람의 기록 발견 → 설치/진입 |

공유의 시작점은 항상 **Balmi App**이다.

```text
Balmi App → 운동 완료 → 활동 결과 → 공유
  → 카카오톡 / 문자 / Instagram / OS Share Sheet
  → Balmi Web Share Page
  → 앱 설치 또는 Balmi 진입
```

---

## 제품 규칙

### 운동 완료 → 결과

종료 후 결과(세션 상세)에서 보여 줄 핵심:

- 헤드라인 톤: **오늘도 기록했습니다.**
- 종목 · 거리 · 시간 · 걸음 · 평균 페이스
- 이동 경로(기기 로컬 트레이스; **OpenStreetMap**, Naver Maps 아님)
- CTA: **공유하기** / 기록 보기(세션 상세 자체)

### 공유 카드 스타일

사용자가 **공개 수준**을 고른다.

| 스타일 | 초점 | MVP |
|--------|------|-----|
| **MAP** | 이동 경로 중심 | 경로 요약 문구 + (선택) 경로 힌트. 실제 지도 이미지 렌더는 후속 |
| **RECORD** | 거리·시간·페이스 | **구현** |
| **MINIMAL** | 숫자 + Balmi | **구현** |
| **VASA** | 건강 관련 데이터가 실제 서비스될 때 | **보류** (의료 과대표현 금지) |

### Balmi 톤 (Strava식 “N km 달렸다”만으로 끝내지 않음)

허용 예시:

- 오늘도 하나의 길을 남겼습니다.
- 걸음은 멈춰도, 기록은 멈추지 않도록.
- 단 한 걸음도 잃어버리지 않도록.

금지:

- 의료·진단·치료 주장 (`저혈당을 고쳤다`, `혈관이 좋아졌다` 등)
- 타사 클라우드/경쟁앱 브랜드명, 장례·동반 표현 (앱 공통 카피 규칙)
- VASA를 임상 점수로 오인하게 하는 공유 카피 (크레딧은 설정/소개에만)

### 활동 공유 vs 트랙 공유

| 종류 | 의미 | 우선순위 |
|------|------|----------|
| **활동 공유** | “내가 오늘 이렇게 걸었다.” | **P0** |
| **트랙 공유** | “너도 이 길을 걸어봐.” → 가져오기 → 따라가기 | **P1** |

성묘길·가족 경로 전달 등은 트랙 공유의 응용(P1). 운동 SNS를 넘어 **경로 전달**이 된다.

---

## 개인정보 보호 (GPS)

집에서 출발·귀가한 경로를 그대로 올리면 **주거 위치가 노출**될 수 있다.

| 옵션 | 기본값 | 설명 |
|------|--------|------|
| **시작·종료 위치 숨기기** | **ON** | 출발/도착 반경 **200–500 m** 구간을 공유 경로에서 제외 |
| **지도 없이 공유** | 스타일/토글 | RECORD·MINIMAL 기본. MAP만 경로 힌트 |

서버에 원본 GPS를 올리지 않는 Light MVP에서는:

- 공유 문구·딥링크 스텁만 OS 시트로 전달한다.
- 경로 좌표를 외부로 보내지 않는다.
- 향후 Web Share Page가 경로를 그릴 때는 **반드시** 적색 처리된 좌표만 업로드한다.

---

## 공유 링크 · 딥링크

목표 URL 형태:

`https://balmi.im/a/XXXXXXXX`

| 수신자 | 동작 |
|--------|------|
| 앱 미설치 | Web Share Page (요약 + CTA **Balmi 시작하기**) |
| 앱 설치 | Universal Link / App Link → 해당 활동 |

**Light MVP (현재 코드)**

- 클라이언트에서 `sessionId` 기반 **스텁 토큰**으로 URL만 조립한다.
- 웹 페이지·링크 해석·서버 저장은 **없음**. 링크를 열어도 랜딩/404일 수 있다.
- Universal Link / App Link 설정은 후속.

웹 Share Page 초안 카피:

- `{이름}님의 걷기` · 거리 · 시간 · (적색) 지도
- 하단: **당신의 발걸음도 기록해보세요.** → **Balmi 시작하기**

---

## 데이터 형태 (목표 / 향후 API)

서버 없이도 도메인이 고정할 공유 요약 스키마:

```text
ActivityShareSummary
  shareId          string   // public token (balmi.im/a/…)
  sessionId        string   // local / future server id (never required on web alone)
  kind             activity | track
  style            map | record | minimal | vasa
  activityLabel    string   // 걷기, 달리기, …
  distanceM        number
  durationS        number
  steps            int?
  avgPaceLabel     string?  // 12'48"
  headline         string
  tagline          string
  privacy
    hideStartEnd   bool     // default true
    hideRadiusM    number   // 200–500
    includeMap     bool
  pathRedacted?    [{lat, lng}, …]  // only if includeMap; start/end trimmed
  createdAt        iso8601
```

트랙 공유(P1) 추가 필드: `trackImportToken`, GPX optional, follow-route payload.

---

## Growth Loop

```text
운동 → 기록 → 공유 → 친구가 확인 → Balmi 인지
  → 앱 진입 → 새 사용자 → 운동 → 다시 공유
```

---

## 구현 우선순위

### P0

- [x] 운동 결과에서 공유 진입 (세션 상세)
- [x] OS Share Sheet (`share_plus`)
- [x] 공유 요약 문구 + 브랜드 태그라인
- [x] 스타일 선택 (RECORD / MINIMAL; MAP·VASA UI만)
- [x] 개인정보: 시작·종료 숨김 기본 ON · 경로 적색 유틸
- [x] Deep Link **스텁** URL
- [ ] 공유 카드 **이미지(PNG)** 생성
- [ ] Web Share Page
- [ ] Universal / App Links

### P1

- 트랙 공유 · 트랙 가져오기 · 따라가기
- GPX 공유
- 공유 링크 관리(삭제·만료)

### P2

- VASA 결과 공유 (실데이터 + 비의료 카피만)
- 챌린지 · 친구 · 기록 비교 · 그룹 활동

---

## 코드 맵 (MVP)

| Path | Role |
|------|------|
| `lib/domain/engines/activity_share.dart` | 스타일·프라이버시·딥링크 스텁·공유 문구·경로 적색 |
| `lib/features/share/activity_share_sheet.dart` | 세션 상세 공유 시트 |
| `lib/core/copy.dart` | 공유 카피 |
| `docs/ACTIVITY_SHARE.md` | 본 명세 |

---

## 수용 기준 (Light MVP)

1. 닫힌 세션 상세에 **공유하기**가 있다.
2. 시트에서 RECORD/MINIMAL을 고르고 OS 공유로 텍스트+스텁 URL이 전달된다.
3. 시작·종료 숨김 기본값이 ON이며, 적색 유틸이 반경 내 점을 제거한다.
4. 공유 문구에 의료 과대표현·Naver Maps·금지 브랜드가 없다.
5. 소셜 그래프·친구 서버·Web Share 호스팅을 요구하지 않는다.
