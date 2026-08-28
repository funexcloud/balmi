# Dogfooding Issue Log — Balmi Launch

> **원칙**: 출시 과정 중 모든 막힘, 의문, 판단 보류 사항을 구조화하여 기록합니다.

---

## 🛑 ISSUE-001: NICE D&B 발급 비용 550,000원 필수 여부 검증

```text
ISSUE ID:
ISSUE-001

STEP:
03-duns (D-U-N-S Number Acquisition)

PROBLEM:
Google Developer 경로(International → Asia Pacific → 대한민국 → NICE D&B)로 진입 시
NICE D&B 화면 상에 550,000원(VAT 포함) 신청 옵션이 표시됨.

CAUSE:
D&B 한국 공식 파트너인 NICE D&B의 유료 급속/기업보고서 상품 화면으로 안내되었으나,
Google Play Organization 개발자 검증 용도로 이 비용이 '필수(REQUIRED)'인지
아니면 무료(FREE) 표준 발급 경로가 별도로 존재하는지 불명확함.

EVIDENCE:
EVI-002 (NICE D&B 신청 결제 화면 캡처 및 금액 550,000원 기록)

SOLUTION / ACTION:
1. 결제를 즉시 진행하지 않고 상태를 'NEEDS REVIEW'로 보류.
2. Google Play Console 공식 지원 센터 및 D&B 고객 센터를 통해 Developer 전용 무료/표준 처리 경로 공식 문의.
3. 결과를 확인한 후 필수 비용 여부를 SOP에 반영.

STATUS:
NEEDS REVIEW (In Progress)

REUSABLE LESSON:
화면에 표시된 비용(DISPLAYED)을 검증 없이 필수 비용(REQUIRED)으로 단정하여 SOP에 작성하지 않는다.
```

---

## 🛑 ISSUE-002: Google Play Health Apps Policy 적용 범위 판단

```text
ISSUE ID:
ISSUE-002

STEP:
09-health-app-policy (Health App Policy Review)

PROBLEM:
Balmi 서비스가 '식후 15분 혈당 워킹', '운동 회복 체크' 등의 기능을 포함하고 있어
Google Play의 Health Apps Policy 대상인지 검토 필요.

CAUSE:
구글 플레이 스토어의 최근 건강/의료 앱 정책 강화로 인해 헬스케어 관련 앱에 대한 별도 선언 서식 제출 요구.

EVIDENCE:
EVI-003 (Google Play Console Health Apps Policy 명세 문서)

SOLUTION / ACTION:
1. Balmi는 의료기기(Medical Device)나 질병 치료 목적 앱이 아닌 웰니스/생활습관 형성(Wellness & Habit) 도구임을 명확히 구분.
2. 앱 설명 및 개인정보처리방침에 웰니스 면책조항(Disclaimer) 명시.
3. Play Console 개발자 선언 시 'Health & Wellness' 카테고리 준수 서류 준비.

STATUS:
OPEN (Decision Documented)

REUSABLE LESSON:
사전에 '의료 앱'으로 단정하지 않고, 실제 기능과 구글 정책 정의(Wellness vs Medical)를 기준으로 소명 서류를 조기 준비한다.
```
