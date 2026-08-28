# [SOP-00] Account Type Decision (계정 유형 판정 가이드)

> **Level A/B Evidence Based Standard Operating Procedure**  
> **관문 목표**: 앱 출시를 준비하는 개발자/기업이 가장 먼저 자신의 계정 유형(Personal vs Organization)을 선판정하도록 구동합니다.

---

## 1. 계정 유형 결정의 중요성

Google Play 콘솔 계정은 크게 **개인(Personal)**과 **조직(Organization)**으로 나뉩니다.
모든 고객을 동일한 D-U-N-S 신청 절차로 보내는 것은 심각한 오류입니다.

* **Personal (개인 계정)**: D-U-N-S가 필요 없습니다. 개인 신원 확인(운전면허증/여권 등)과 20인 14일 테스트 요구사항이 적용됩니다.
* **Organization (조직 계정)**: D-U-N-S 번호와 법인/사업자 실체 검증, 공식 서류 제출이 적용됩니다.

---

## 2. 계정 유형 판정 로직 (Decision Flowchart)

```text
                    APP LAUNCH
                         │
                 Account Type
                         │
            ┌────────────┴────────────┐
            │                         │
        PERSONAL                 ORGANIZATION
            │                         │
      개인 신원 확인                사업자/조직
                                      │
                                    D-U-N-S
                                      │
                                Organization
                                 Verification
```

### 2.1 세부 개발자 분류 (Developer Taxonomy)
1. `INDIVIDUAL`: 학생, 취미 개발자, 비사업 목적 프로젝트 ➔ **PERSONAL**
2. `SOLE_PROPRIETOR`: 개인사업자 (사업체 명의 상업 앱 출시 여부에 따라 분기) ➔ **ORGANIZATION / PERSONAL**
3. `CORPORATION`: 주식회사, 유한회사 등 법인 ➔ **ORGANIZATION**
4. `NONPROFIT`: 비영리 법인 ➔ **ORGANIZATION**
5. `PUBLIC_ORGANIZATION`: 공공 기관 ➔ **ORGANIZATION**
6. `OTHER_ORGANIZATION`: 기타 공식 단체 ➔ **ORGANIZATION**

---

## 3. 계정 유형 판정 질문지 (Decision Matrix)

다음 질문을 통해 판정 결과를 산출합니다:

```text
Q1. 앱을 출시하는 주체는 누구인가요?
    [ ] 개인 (학생/아마추어) ➔ PERSONAL 권장
    [ ] 개인사업자 ➔ Q2로 이동
    [ ] 법인 (주식회사/유한회사 등) ➔ ORGANIZATION 권장
    [ ] 공공기관 / 비영리단체 ➔ ORGANIZATION 권장

Q2. 앱이 사업 또는 상업적 목적으로 제공되거나 결제/유료 서비스가 포함되어 있나요?
    [ ] YES ➔ ORGANIZATION 권장
    [ ] NO  ➔ PERSONAL 가능

Q3. 회사의 브랜드나 사업자 명의로 스토어에 출시하고자 하나요?
    [ ] YES ➔ ORGANIZATION 권장
    [ ] NO  ➔ PERSONAL 가능

Q4. 구글 정책상 Organization 계정이 필수인 앱 카테고리인가요? (Health, Finance, Government, VPN 등)
    [ ] YES ➔ ORGANIZATION 필수
    [ ] NO  ➔ 자율 선택
```

---

## 4. 결과 출력 및 다음 단계

* **RECOMMENDED: PERSONAL**  
  👉 [personal-account.md](../personal/personal-account.md)로 진입 (D-U-N-S 불필요)

* **RECOMMENDED: ORGANIZATION**  
  👉 [03-duns.md](03-duns.md) D-U-N-S 관문으로 진입

* **RECOMMENDED: MANUAL_REVIEW**  
  👉 개인사업자 특수 경로 [sole-proprietor.md](../organization/sole-proprietor.md) 검토
