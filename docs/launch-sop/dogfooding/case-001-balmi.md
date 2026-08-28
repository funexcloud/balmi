# DOGFOOD-001 — Balmi App Launch Case

> **Case ID**: DOGFOOD-001  
> **Product**: Balmi  
> **Company**: 주식회사 동반  
> **Target Store**: Google Play Store  
> **Developer Type**: Business / Corporation (주식회사)  
> **Account Type**: Organization  
> **Status**: IN PROGRESS (D-U-N-S Cost Verification & Organization Setup Stage)

---

## 1. 프로젝트 요약

Balmi 서비스의 Google Play 스토어 공식 출시를 진행하며 수집된 기업 정보, 결정 사항, 실시간 이슈, D-U-N-S 검색 및 NICE D&B 과정의 실제 경험 데이터를 소급 기록합니다.

---

## 2. 현황 종합 (Current Status Summary)

* **ACCOUNT TYPE**: Organization
* **CURRENT STAGE**: D-U-N-S Number Inquiry & Cost Verification Stage
* **COMPLETED**:
  - [x] 계정 유형 판정 (`Organization` 선택 - 주식회사 동반 명의 앱 자산 관리)
  - [x] 사업자 등록 확인 (주식회사 동반, 사업자등록번호 확보)
  - [x] 기업 영문 정보 정규화 (회사명, 대표자명, 주소)
  - [x] D&B / NICE D&B 검색 경로 진입 (`My business` → `International` → `Google developer` → `Korea`)
* **VERIFIED**:
  - D&B 공식 검색 결과: `주식회사 동반` 관련 기존 매칭 검색 결과 없음 (`No matching results found`).
  - NICE D&B 폼 진입 시 화면 표시 금액: **550,000원 (VAT 포함)**
* **NEEDS REVIEW**:
  - **[ISSUE-001]** NICE D&B 화면에 표시된 550,000원 상품이 Google Play Organization 개발자 등록 시 필수 요구 비용인지, 혹은 무료/대체 취득 경로가 존재하는지 공식 검증 필요. (검증 완료 전 결제 보류 중)
* **ISSUES**:
  - `ISSUE-001`: D-U-N-S 발급 비용(550,000원) 필수 여부 검증 미완료.
* **COSTS**:
  - `NICE D&B 신규 발급`: 500,000 KRW (`DISPLAYED`, `UNPAID`)
  - `VAT`: 50,000 KRW (`DISPLAYED`, `UNPAID`)
  - `Total`: 550,000 KRW (`STATUS: NEEDS REVIEW`)
* **NEXT ACTION**:
  - Google Play Console / D&B 지원 센터 공식 문의를 통해 Google 개발자 전용 무료/표준 D-U-N-S 발급 경로 존재 여부 확인.
  - 결제 절차 확정 후 D-U-N-S 발급 및 Google Payments 프로필 등록 진행.

---

## 3. 계정 유형 결정 (DEC-001)

* **결정**: `ORGANIZATION` (조직 계정)
* **사유**:
  * Balmi 앱은 **주식회사 동반** 법인 소유의 사업 자산으로 배포 및 관리되어야 함.
  * 추후 B2B 헬스케어 파트너십 및 브랜드 신뢰도를 위해 법인 명의 개발자 계정 필수.

---

## 4. 증거 기록 (Evidence List)

* `EVI-001` (LEVEL B): D&B International 검색 페이지 `No matching results found` 화면 캡처 및 로그.
* `EVI-002` (LEVEL B): NICE D&B 신규 신청 화면의 550,000원(VAT 포함) 견적 표시 화면.
