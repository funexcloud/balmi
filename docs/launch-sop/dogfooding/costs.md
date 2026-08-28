# Dogfooding Cost Tracking Log — Balmi Launch

> **비용 구분 상태**:
> - `DISPLAYED`: 화면에 표시되었으나 확정되지 않음
> - `REQUIRED`: 필수 지출로 확정됨
> - `OPTIONAL`: 선택적 지출
> - `PAID`: 실제 지출 완료
> - `REFUNDED`: 환불됨
> - `UNKNOWN`: 미정

---

## 💰 비용 집계표 (Balmi Case #001)

| 항목 | 금액 (원) | 상태 | 실제 결제 여부 | 출처 / 비고 |
| :--- | ---: | :--- | :--- | :--- |
| **NICE D&B D-U-N-S 신규 발급** | 500,000 | `DISPLAYED` | ❌ NO | NICE D&B 신청 폼 화면 표시 금액 |
| **NICE D&B 부가세 (VAT)** | 50,000 | `DISPLAYED` | ❌ NO | 10% VAT |
| **Google Play 개발자 계정 등록비** | $25 (~34,000원) | `REQUIRED` | ⏳ PENDING | Play Console 최초 계정 등록 일시금 |
| **사업자등록증 / 법인등기부 발급** | ~2,000 | `REQUIRED` | ✅ YES | 정부24 / 대법원 인터넷등기소 |
| **도메인 (`balmi.im`) 보유비** | ~40,000 / 년 | `REQUIRED` | ✅ YES | 기업 웹사이트 및 개인정보방침 호스팅 |

---

## 🔍 비용 검증 가이드 (NEEDS REVIEW)

* **NICE D&B 550,000원**:  
  구글 전용 무료 D-U-N-S 신청 경로(D&B Google Support Form) 확인 후 `REQUIRED` 또는 `OPTIONAL`로 최종 상태 재분류 예정.
