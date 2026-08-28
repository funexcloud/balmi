# App Launch SOP & Dogfooding System

> **Dogfood it. Document it. Standardize it. Then automate it.**

---

## 📌 개요

본 시스템은 **Balmi (주식회사 동반)**를 Google Play에 실제 출시하는 과정(Dogfooding Case #001)에서 수집한 실제 경험(Real Experience), 공식 증거(Official Evidence), 결정 기록(Decisions), 이슈(Issues)를 구조화하여 향후 개인사업자 및 법인이 활용할 수 있는 **표준 기업 앱 출시 SOP (App Launch SOP)**로 발전시키기 위한 프레임워크입니다.

---

## 📂 파일 구조 (Directory Structure)

```text
docs/launch-sop/
├── README.md                           # 본 인덱스 문서
│
├── dogfooding/                         # 실제 Dogfooding 케이스 기록
│   ├── case-001-balmi.md               # [DOGFOOD-001] Balmi 출시 사례
│   ├── timeline.md                     # 일자별 실시간 진행 타임라인
│   ├── issues.md                       # ISSUE-001 등 막힘/장애 로그
│   ├── decisions.md                    # DEC-001 등 의사결정 로그
│   └── costs.md                        # 비용 로그 (DISPLAYED/REQUIRED/PAID)
│
├── sop/                                # 표준 절차 가이드 (SOP)
│   ├── 00-account-type-decision.md    # [Gate 00] 계정 유형 판정 (Personal vs Organization)
│   ├── 01-developer-readiness.md       # 개발자 준비도
│   ├── 02-company-readiness.md        # 기업/사업자 준비도
│   ├── 03-duns.md                      # [Gate 03] D-U-N-S 기업 식별번호 발급 및 검색
│   ├── 04-google-payments-profile.md   # Google Payments 결제 프로필
│   ├── 05-google-play-organization.md  # Play Console 조직 계정 생성
│   ├── 06-play-console-verification.md # 조직 실체 및 권한 검증
│   ├── 07-app-registration.md          # 앱 생성 및 기본 정보 설정
│   ├── 08-policy-compliance.md        # Google Play 스토어 정책 준수
│   ├── 09-health-app-policy.md         # 헬스케어/건강 앱 정책 검토 (Wellness vs Medical)
│   ├── 10-store-listing.md             # 스토어 등록 정보 및 그래픽 자산
│   ├── 11-testing.md                   # 비공개/공개 테스트 및 20인 테스트
│   └── 12-production-release.md        # 프로덕션 심사 제출 및 출시
│
├── personal/                           # 개인 개발자 전용 가이드
│   ├── personal-account.md             # 개인 계정 생성
│   ├── personal-verification.md        # 개인 신원 확인 (Identity Verification)
│   └── testing-requirements.md         # 개인 계정 20인 14일 테스트 요구사항
│
├── organization/                       # 조직/사업자 개발자 전용 가이드
│   ├── sole-proprietor.md              # 개인사업자 출시 경로 (Individual vs Organization)
│   ├── corporation.md                  # 법인 주식회사 출시 경로
│   └── organization-verification.md    # 조직 검증 서류 및 D-U-N-S 제출
│
├── checklists/                         # 실전 점검 체크리스트
│   ├── account-type-checklist.md       # 계정 유형 결정 체크리스트
│   ├── personal-launch-checklist.md    # 개인 출시 체크리스트
│   ├── business-readiness.md           # 사업자 준비도 체크리스트
│   ├── duns-checklist.md               # D-U-N-S 신청 체크리스트
│   ├── google-play-checklist.md        # Play Console 준비 체크리스트
│   └── release-checklist.md            # 최종 출시 체크리스트
│
├── templates/                          # 템플릿 및 문의 서식
│   ├── duns-inquiry.md                 # D-U-N-S / NICE D&B 문의 양식
│   ├── company-info-sheet.md           # 기업 영문 정보 입력 시트
│   ├── verification-response.md        # 구글 소명 서한 템플릿
│   └── privacy-policy-checklist.md     # 개인정보처리방침 체크리스트
│
└── knowledge/                          # 누적 지식 및 가치 자산
    ├── errors-and-solutions.md         # 오류 및 해결책 DB
    ├── glossary.md                     # 스토어 출시 용어집
    ├── official-links.md               # Level A/B 공식 문서 링크
    └── automation-candidates.md        # 향후 B2B 지원 및 SaaS 자동화 후보
```

---

## 🎯 핵심 원칙

1. **D-U-N-S는 모든 출시자의 필수 조건이 아니다.**
   * 반드시 **[00-account-type-decision.md](sop/00-account-type-decision.md)**를 통해 계정 유형(Personal vs Organization)을 선판정합니다.
2. **경험(Experienced)과 공식 요구사항(Official Requirement)을 엄격히 구분한다.**
   * LEVEL A (공식 문서) ~ LEVEL D (블로그 후기) 출처 등급을 명시합니다.
3. **추측으로 비용을 정의하지 않는다.**
   * 화면에 표시된 금액(`DISPLAYED`)과 실제 필수 금액(`REQUIRED`)을 구분하여 검증(`NEEDS REVIEW`)합니다.
4. **Dogfooding과 SOP를 분리한다.**
   * 우리가 경험한 실질적 착오/시행착오는 `dogfooding/issues.md`에 기록하고, 표준 `sop/` 가이드에는 정석 경로와 `COMMON MISTAKE` 방지 팁만 수록합니다.
