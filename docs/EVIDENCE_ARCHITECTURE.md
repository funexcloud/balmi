# balmi × VASA — Evidence Architecture

- 상태: **아키텍처 명세** (제품 방향 문서). Evidence DB / Research Repo 파이프라인 / 근거 펼침 UI는 **이 문서만으로 구현하지 않음**.
- 관련: [`SPEC.md`](SPEC.md) · [`개발노트.md`](개발노트.md) · B2B 초안 [`balmi-vasa-wellness-proposal.html`](balmi-vasa-wellness-proposal.html)

---

## 핵심 테제

Balmi × VASA는 **논문 PDF를 많이 보유한 서비스**가 아니라, 연구 근거가 제품 로직까지 **추적 가능한 사슬(traceable chain)**로 연결되는 **연구근거 기반(Evidence-based) 서비스**를 지향한다.

**추적 사슬 (목표):**

1. Research Repo 논문  
2. → 검증된 변수·관계 추출  
3. → Evidence Layer (`faiEvidence` 또는 동등 스키마) 연결  
4. → VASA 평가·계산 로직에 반영  
5. → Balmi가 실사용자 데이터를 측정  
6. → 결과·권고 생성  
7. → **어느 결과가 어느 연구 근거에서 왔는지** 역추적

Research Repo = **Evidence Base** (단순 PDF 아카이브가 아님).

---

## 안전한 표현 (하드 규칙)

문서·마케팅·앱 카피에서 다음을 **선호**한다.

| 선호 | 금지(별도 임상·제품 검증 전까지) |
|------|----------------------------------|
| **연구근거 기반(Evidence-based) 서비스** | 「논문으로 검증된 서비스」 |
| **학술 근거를 추적할 수 있는 평가 시스템** | 제품 자체에 대한 clinical validation 단정 |
| 지표·권고가 **어떤 문헌·변수에 연결되는지** 설명 | 진단·처방 대체 / 의료기기 주장 |

웰니스 범위·진단 금지 규칙은 [`SPEC.md`](SPEC.md) Activity Recovery 절 및 식후 걷기 디스클레이머와 동일 계열이다.

---

## 3계층 구조

| 계층 | 역할 | 제품 측 |
|------|------|---------|
| **Balmi → 측정 (Data)** | 실행·측정 레이어 | GPS·걸음·세션·습관 등 실측 |
| **VASA → 해석·평가 (Model)** | 분석·평가 레이어 | 컴포넌트·스코어·권고 로직 |
| **FUNEX Research / Research Repo → 근거 (Evidence)** | 과학적 근거 레이어 | 논문·변수·`faiEvidence`·근거수준 |

한 줄로: **Balmi가 재고, VASA가 해석하며, Research Repo가 그 해석의 근거를 남긴다.**

현재 앱 코드에는 VASA **크레딧·참여도 시그널**(예: 식후 워크 참여도, `resource_transaction_log`)만 있으며, Evidence Layer·논문 추적 UI는 **미구현**(본 명세의 목표 상태).

---

## 성숙도 사다리 (Maturity ladder)

| Level | 의미 |
|-------|------|
| 논문 PDF/메타만 | 문헌 아카이브 |
| 논문 내용 구조화 | Research DB |
| 변수↔논문 연결 | Evidence DB |
| VASA component↔논문 | 검증근거 평가모델 |
| 계산 결과↔Evidence | Evidence-based VASA |
| Balmi 실사용 재검증 | 연구↔제품↔실사용 검증 루프 |

목표 제품 포지션은 사다리 **상단**(계산 결과↔Evidence + 실사용 재검증)이다.  
논문 편수만 늘리는 것은 아카이브 단계에 머무는 것과 같다.

---

## Research Repo 프로세스 노트

운영·큐레이션 시 다음을 Evidence Base 품질 기준으로 둔다.

1. **논문별 COMPLETE 상태** — 메타만 있는 항목과 구조화 완료를 구분.
2. **빈 필드 채우기** — 추출 변수, 관계, 적용 조건, 근거수준 등.
3. **`faiEvidence` + `researcherNote` 링크** — 변수·관계를 Evidence Layer에 연결하고 연구자 노트를 남김.
4. **후속: `component ↔ paper` 관계** — VASA 컴포넌트와 논문의 명시적 매핑.
5. **성장 지표** — 20 → 50 → 100편 확장은 **논문 수**만이 아니라 **VASA 컴포넌트당 evidence density(근거 밀도)** 증가를 목표로 한다.

### 구현 범위 (이 PR / 현 시점)

- ✅ 본 아키텍처 문서 및 SPEC·README 교차 링크
- ❌ Research Repo 시스템, `faiEvidence` 파이프라인, 근거 펼침 UI — **전체 구현하지 않음** (스캐폴딩이 생기면 별도 작업)
- 📝 코드 측 TODO는 Evidence Layer 도입 시 `faiEvidence` / `component↔paper` / 결과↔evidence 역추적을 우선 설계 포인트로 삼을 것

---

## 목표 UX (문서화만 — 당장 구현하지 않음)

점수만 보여 주지 않는다.

- 표면: 예) 「VASA 점수 72점」(예시; 현재 소비자 UI에 의료형 점수 노출 없음 — [`SPEC.md`](SPEC.md) VASA 크레딧 규칙)
- 펼침(목표): **핵심 지표 N개 / 관련 연구 M편 / 근거수준 / 적용 기준**

사용자는 “왜 이 숫자·권고인가”를 학술 근거로 **추적**할 수 있어야 한다.  
표현은 위 **안전한 표현** 표를 따른다.

---

## Activity Recovery와의 관계 (선택·후속)

[`SPEC.md` Activity Recovery / 회복 체크](SPEC.md)는 Balmi **측정·안내** 프로토콜이다.  
장기적으로는 증상→안내→재확인 규칙도 Evidence Layer에 묶어, “어떤 연구·가이드라인 변수에서 온 생활 안내인지”를 추적할 수 있게 하는 것이 자연스럽다.  
단, MVP는 안전 카피·로컬 영속 중심이며 **지금 Evidence DB에 묶지 않는다**.

---

## 상업화·로드맵 체크리스트 (Evidence)

별도 상업화 체크리스트 파일이 없으므로, B2B·제품화 준비 시 아래를 **Evidence Base 로드맵 항목**으로 둔다.

- [ ] Research Repo를 PDF 아카이브가 아닌 **Evidence Base**로 운영(COMPLETE·빈 필드·`faiEvidence`)
- [ ] VASA component ↔ paper 매핑 초안
- [ ] 계산 결과 ↔ Evidence 역추적 스키마 설계
- [ ] 소비자/B2B 카피: Evidence-based / 추적 가능 평가 — 「논문으로 검증된 서비스」 미사용
- [ ] (후속) 결과 화면 근거 펼침 UX
- [ ] (후속) Balmi 실사용 데이터로 모델·권고 재검증 루프
- [ ] (후속) Activity Recovery 안내 규칙의 evidence 태깅

B2B 제안 톤·동의·집계 원칙은 [`balmi-vasa-wellness-proposal.html`](balmi-vasa-wellness-proposal.html)을 참고하되, 본 문서의 **안전한 표현**이 우선한다.
