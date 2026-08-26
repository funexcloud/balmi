# Balmi Brand Color & Story

제품 브랜드 정체성 문서. 사용자 온보딩에 칼륨 주의 등 의료·영양 경고를 싣지 않는다.  
앱 카피 축: [`lib/core/copy.dart`](../lib/core/copy.dart) · 색 토큰: [`lib/core/theme.dart`](../lib/core/theme.dart)

---

## 1. Balmi의 시작

Balmi는 처음부터 단순한 러닝 앱으로 시작한 이름이 아니다.

**byme** — 나를 위한 움직임에서 시작해  
**balmi** — 나의 발걸음과 움직임을 기록하는 서비스로 발전했다.

그 움직임의 데이터는 **VASA Engine**으로 연결된다.

| | 역할 |
|---|---|
| **Balmi** | 움직임을 **기록**한다 (걷기 · 달리기 · 트랙 · 경로) |
| **VASA** | 움직임의 의미를 **해석**한다 (심박 · 활동 패턴 · 회복 · 관련 지표 방향) |

**BALMI → RECORD** · **VASA → INTERPRET**

---

## 2. 왜 고구마색인가? (브랜드 스토리)

Balmi의 컬러는 단순한 브라운이나 버건디가 아니다. **고구마에서 시작한 색**이다.

공식 브랜드 스토리 한 줄:

> **심장이 좋아하는 고구마색**

이것은 **브랜드 내러티브**이지 의학적 효능 주장이 아니다.

### 사용자용 카피 (설정 · About · 브랜드 스토리 화면)

```text
왜 Balmi는 고구마색일까요?

걷고 달리는 발걸음은 심장을 움직입니다.
그리고 고구마는 칼륨과 식이섬유를 함유한,
심혈관 건강을 위한 식생활에 잘 어울리는 식품입니다.
그래서 Balmi는 심장이 좋아하는 고구마색에서 시작했습니다.

발걸음에서 심장으로, 심장에서 혈관까지.
Balmi × VASA
```

### 카피 안전 규칙 (Hard)

| 금지 | 허용 |
|---|---|
| 「고구마는 누구에게나 심장에 좋다」 등 **절대·보편 효능** | 「심혈관 건강을 위한 식생활에 잘 어울리는 고구마」(형식·정보성) |
| 「고구마가 심장을 치료한다」 등 의료 클레임 | 브랜드 톤: **심장이 좋아하는 고구마색** |
| 온보딩에 칼륨/신장 질환 경고로 사용자를 겁주기 | 본 문서에만 아래 **참고**를 짧게 남김 |

### 참고 (문서 전용 — UI/온보딩에 넣지 않음)

고구마는 칼륨이 비교적 풍부한 식품으로 알려져 있다.  
일부 신장 질환·칼륨 제한이 필요한 분은 의료진·영양 가이드(예: AHA 등 공신력 있는 식생활 안내의 칼륨 주의)를 따르는 것이 일반적이다.  
Balmi는 식품·영양을 **처방하거나 진단하지 않으며**, 색 선택의 브랜드 스토리만 전한다.

---

## 3. Color Identity

기존 고구마색을 **Balmi Primary**로 유지·명명한다. 화면의 오렌지는 제거하지 않고 **Active Movement** 액센트로 역할을 분리한다.

### Primary — Balmi Sweet Potato

토큰: `BalmiColors.potato` / `potatoDk` (`#D9774A` / `#C45E32`) · 경로: `trackPath`

용도:

- Balmi 로고 · 심박선
- GPS track / 경로선 (`trackPath`)
- 기록 시작·정지 CTA
- 활성 Navigation · 선택 상태
- 핵심 CTA · 주요 데이터 강조

### Secondary — Balmi Active Orange

토큰: `BalmiColors.activeOrange` (`amber` 별칭, `#E39A3B`) · `locationPin`

용도:

- 활동 중 상태 · Running Indicator
- 현재 위치 location pin (`locationPin`)
- 진행/프로그레스 액센트
- 작은 Status Dot

요약: **고구마 = Balmi (브랜드)** · **오렌지 = 움직임 (액티비티)**

### 상태 언어

| 토큰 | 역할 |
|---|---|
| Sweet Potato | Brand / Heart / VASA |
| Active Orange | Movement / Activity |
| Sage | GPS Good / Healthy / Connected |
| Attention yellow | GPS Weak |
| Critical red | SOS / Critical |

---

## 4. 로고의 심박선

`balmi` 아래 심박선은 유지한다. 장식이 아니라:

**발걸음 → 움직임 → 심박 → 혈관 → VASA**

를 잇는 그래픽 언어다. 지도 경로선과 심박선은 모두 Sweet Potato 계열로 시각적으로 연결한다.

---

## 5. 메시지 축

| 축 | 카피 키 | 문구 |
|---|---|---|
| RECORD | `slogan` | 걸음은 멈춰도, 기록은 멈추지 않도록. |
| HEALTH | `healthSlogan` | 발걸음에서 혈관까지. |
| Philosophy | `brandPhilosophy` | 움직임을 기록하고, 몸의 변화를 이해하다. |

최상위: **Balmi × VASA** · Movement & Health Recording Platform (Balmi) + Health Intelligence Engine 방향 (VASA).

---

## 6. 온보딩과의 관계

온보딩은 **기록 신뢰(MOVE → OFFLINE → RECOVERY → PROMISE)** 가 우선이다.  
고구마색·칼륨 이야기는 **설정 / About / 선택적 브랜드 스토리 화면**에 두고, 첫 실행 권한 플로우를 무겁게 만들지 않는다.

VASA 비트를 온보딩에 넣을 때는 「발걸음에서 혈관까지」 수준의 **브랜드 약속**만 쓰고, 식품·효능 클레임은 넣지 않는다.

---

## 7. Brand Architecture

```text
                 BALMI
                   │
          ┌────────┴────────┐
          │                 │
       RECORD              VASA
          │                 │
       움직임 기록          데이터 해석
          │                 │
  Walk / Run / Track    Heart / Vascular
          │                 │
          └────────┬────────┘
                   │
             PERSONAL HEALTH
```

#Balmi #VASA #BalmiSweetPotato #BrandColor #BrandIdentity
