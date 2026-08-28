# Dogfooding Decision Log — Balmi Launch

> **원칙**: 출시 과정 중 결정된 핵심 아키텍처 및 계정 정책 선택의 이유를 기록합니다.

---

## 📋 DEC-001: Balmi Play Console 계정 유형 (Account Type) 결정

```text
DECISION ID:
DEC-001

SUBJECT:
Balmi Play Console Account Type Selection

OPTIONS CONSIDERED:
1. Personal (개인 계정)
2. Organization (조직/기업 계정)

DECISION:
Organization (조직 계정)

REASON:
- Balmi는 주식회사 동반의 공식 법인 자산으로 운영 및 보호되어야 함.
- 헬스케어 파트너십 및 B2B 확장 시 법인 명의의 개발자 검증이 필수적임.
- 개인 계정의 경우 20인 14일 테스트 등 무의미한 개인 출시 허들이 발생할 수 있음.

DATE:
2026-08-25

EVIDENCE:
EVI-004 (주식회사 동반 사업자등록증 및 법인 등기부등본)
```

---

## 📋 DEC-002: D-U-N-S 신청 전 사전 검증 및 결제 보류 결정

```text
DECISION ID:
DEC-002

SUBJECT:
NICE D&B 550,000원 즉시 결제 여부

OPTIONS CONSIDERED:
1. 표시된 550,000원 결제 후 유료 신속 처리 진행
2. 결제 보류 후 구글 공식 문의를 통한 무료/표준 발급 경로 확인

DECISION:
Option 2 (결제 보류 후 공식 경로 검증)

REASON:
- 구글 개발자 전용 무료 D-U-N-S 경로가 존재할 가능성이 높음.
- 불필요한 유료 지출 방지 및 향후 B2B 가이드 작성 시 정확한 필수 비용 가이드라인 수립 목적.

DATE:
2026-08-28

EVIDENCE:
ISSUE-001
```
