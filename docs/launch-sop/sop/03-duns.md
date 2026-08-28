# [SOP-03] D-U-N-S Number Acquisition SOP

> **Gate 조건**: `ACCOUNT_TYPE == ORGANIZATION` 인 경우에만 이 단계를 수행합니다.  
> **개념 정의**: D-U-N-S(Data Universal Numbering System)는 앱 출시 라이선스가 아니라, **Organization 개발자 등록 시 구글/애플이 기업의 법적 실체를 검증하기 위해 사용하는 9자리 글로벌 기업 식별번호**입니다.

---

## 1. D-U-N-S 사전 검증 절차

신규 발급을 신청하기 전 반드시 기존 번호 존재 여부를 검색합니다.

1. **D&B 글로벌 검색 사이트 진입**:  
   `My business` → `International-based business` → `I'm a Google developer` → `Asia Pacific` → `대한민국`
2. **기업 검색 진행**:
   * 영문 회사명 (예: `DONGVAN Co., Ltd.`)
   * 사업자등록번호 / 법인등록번호
3. **결과 해석**:
   * `Search Result Found`: 기존 부여된 9자리 D-U-N-S 번호 즉시 사용 가능 ➔ [05-google-play-organization.md](05-google-play-organization.md) 진입
   * `No matching results found`: 신규 발급 절차 진입

---

## 2. D-U-N-S 발급 비용 검증 및 경고 (Cost Caution)

> ⚠️ **COMMON MISTAKE WARNING**  
> 한국 대행 기관(NICE D&B 등) 신청 화면에서 **550,000원(VAT 포함)** 등의 유료 유료급속/기업보고서 상품 금액이 표시될 수 있습니다.  
> 이 금액이 표시되었다고 해서 Google Developer 등록 시 **필수 지출(REQUIRED)이라고 단정하지 마십시오.**

* **무료 / 표준 지원 경로 확인**:  
  구글 개발자 전용 D&B 무료 지원 양식(Google D-U-N-S Support Form)을 통해 신청할 경우 무료 발급이 가능할 수 있으므로, 결제 전 구글 공식 안내를 확인합니다.

---

## 3. 필요 서류 및 준비 정보

1. **사업자등록증 / 법인등기부등본 (국문/영문)**
2. **정확한 영문 법인명** (사업자등록증 상의 영문 표기와 100% 일치)
3. **정확한 영문 주소** (도로명주소 영문 표기)
4. **대표자 및 담당자 연락처 / 기업 대표 이메일** (도메인 소유 이메일 권장)
