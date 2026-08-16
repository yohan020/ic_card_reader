# Issue reporting specification

## 상태

Supabase 익명 인증, Edge Function, RLS로 보호된 PostgreSQL 테이블을 사용하는 실제 전송 경로를 구현했다. 배포 전에는 `--dart-define` 연결값이 필요하다.

## 화면 흐름

1. 이용내역 상세에서 `문제 신고`를 누른다.
2. 현재 한 건이 선택된 상태에서 문제 유형을 고른다.
3. 역 관련 제보는 올바른 역 이름과 도시·지역을 입력하고 노선명은 선택적으로 입력한다. 버스 회사 미확인은 실제 회사명과 운행 도시·지역을 입력한다. 거래 유형 오류는 하단 팝업 목록에서 선택하거나 목록에 없을 때만 직접 입력한다.
4. 전송할 필드와 제외할 정보를 미리 보여준다.
5. 사용자가 명시적으로 동의한 경우에만 큐에 넣고 전송한다.

앱 화면에서는 역 오류와 역명 미확인을 `역 정보가 없거나 잘못됨`으로 통합한다. 해당하는 역의 이름과 도시·지역은 필수이며 노선명과 추가 설명은 선택이다. 하단 팝업에서 승차역·하차역·둘 다 중 범위를 먼저 선택한다. 기존 앱 버전의 `STATION_NOT_RESOLVED` 제보도 서버와 관리 화면에서 계속 호환한다.

## 문제 유형

현재 앱이 생성하는 제보 유형은 `WRONG_STATION_NAME`, `BUS_COMPANY_NOT_RESOLVED`, `WRONG_TRANSACTION_TYPE`, `WRONG_AMOUNT_OR_BALANCE`, `OTHER`다. 기존 앱의 `STATION_NOT_RESOLVED`, `WRONG_BOARDING_STATION`, `WRONG_ALIGHTING_STATION`, `WRONG_BOTH_STATIONS`도 서버와 관리 화면에서 계속 조회한다.

## API 계약

`POST /v1/ic-card-reports`

```json
{
  "anonymousReportId": "uuid-v4",
  "anonymousRawRecord": "32 uppercase hex characters",
  "issueType": "WRONG_STATION_NAME",
  "regionCode": 1,
  "stationIssueScope": "BOTH",
  "correctedBoardingStation": {"name": "渋谷", "city": "東京都渋谷区", "line": "銀座線"},
  "correctedAlightingStation": {"name": "浅草", "city": "東京都台東区", "line": null},
  "currentTransactionType": "UNKNOWN",
  "suggestedTransactionType": null,
  "customSuggestedTransactionType": null,
  "usageDate": "2026-08-07",
  "balance": 1234,
  "calculatedAmount": null,
  "additionalDescription": null,
  "parserVersion": "p1-unparsed",
  "stationDatabaseVersion": "not-installed",
  "appVersion": "1.0.0+1",
  "platform": "ios",
  "osVersion": "string",
}
```

`currentTransactionType`은 `RAIL`, `BUS`, `PURCHASE`, `CHARGE`, `GATE_WINDOW_PROCESSING`, `REFUND`, `ADJUSTMENT`, `UNKNOWN` 중 하나다. `suggestedTransactionType`은 지원하는 거래 유형 중 하나이거나 `OTHER`이며, `OTHER`일 때만 `customSuggestedTransactionType`을 보낸다. `BUS_COMPANY_NOT_RESOLVED`는 현재 거래 유형이 `BUS`일 때만 허용하며 `suggestedBusCompanyName`, `suggestedBusCompanyCity`를 필수로 보낸다. 노선 번호는 수집하지 않는다. 역 교정 정보에는 카드 IDm·현재 위치·정확한 좌표를 포함하지 않는다.

중복 키는 조작 방지를 위해 클라이언트가 보내지 않고 Edge Function이 정규화된 비개인 교정 필드로 SHA-256을 계산한다. 새 역·버스 회사·거래 유형 교정값이 있는 경우에는 해당 값도 포함하므로, 같은 원시 기록에 서로 다른 교정안을 보내는 경우를 하나로 잘못 묶지 않는다.

성공 응답은 HTTP 202와 `reportId`, `reviewStatus: RECEIVED`를 반환한다. 클라이언트 상태는 `PENDING`, `SUBMITTED`, `FAILED`; 서버 검토 상태는 `RECEIVED`, `REVIEWING`, `VERIFIED`, `APPLIED`, `REJECTED`다.

## 전송/제외 데이터

전송은 선택한 원시 16바이트 레코드 한 건, 코드, 현재/제안 해석, 날짜, 잔액/계산액, 버전, 플랫폼/OS 버전으로 제한한다. 카드 IDm, 다른 이력, 이름·이메일, 기기 고유 ID, 위치, 전체 경로는 전송하지 않는다.

원시 레코드의 어떤 바이트가 개인 식별 가능성을 갖는지 확정되지 않았으므로 UI에서 “원시 카드 이용 기록 1건”임을 명확히 설명하고 동의받는다. 서버 로그에서도 요청 본문 마스킹 정책을 적용한다.

## 실패와 재시도

이용내역 영구 저장을 제품 범위에서 제외한 결정에 맞춰 제보도 로컬 큐에 저장하지 않는다. 실패하면 현재 화면에 오류를 표시하고 사용자가 직접 다시 시도할 수 있다. 앱을 종료하면 미전송 제보는 남지 않는다. 테스트에서는 네트워크를 쓰지 않는 fake repository를 사용한다.

## 중복 키와 운영 검토

Edge Function이 정규화한 원시 단건 기록, `regionCode`, `lineCode`, `stationCode`, 오류 유형, 거래 유형, 파서 버전, 역 DB 버전으로 canonical JSON을 만든 뒤 SHA-256을 계산한다. 서버는 이 키로 유사 신고를 묶되 자동 승인하지 않는다.

관리자가 출처와 복수 신고를 검증해 `VERIFIED`한 뒤 별도 DB migration/release 절차로만 반영한다. 사용자 신고가 운영 역 DB를 직접 수정하는 경로는 두지 않는다.

## 운영 정책

- 동일 익명 Auth 사용자는 10분 동안 최대 5건까지 제출할 수 있다. 초과 요청은 HTTP 429와 `Retry-After: 600`으로 거절한다.
- 새 제보의 익명 Auth UUID는 서버 내부에서만 `issue_reports`와 연결한다. 카드 IDm·이메일·기기 고유 ID와 무관하며, 관리자 UI에는 UUID를 표시하지 않는다.
- 관리자는 문의 상세에서 악성 제보자의 익명 Auth UUID를 차단 또는 해제할 수 있다. 활성 차단 상태의 요청은 저장 전에 HTTP 403으로 거절하며, 기존 문의 상태는 자동으로 바꾸지 않는다.
- `APPLIED` 또는 `REJECTED` 문의는 `resolved_at` 기준 1년 뒤 매월 자동 삭제한다. 연결된 검토 이력은 외래 키 cascade로 함께 삭제한다. `RECEIVED`·`REVIEWING`·`VERIFIED`는 자동 삭제하지 않는다.
- 검토 상태는 `RECEIVED` → `REVIEWING` → `VERIFIED` → `APPLIED` 순서로 진행한다. 근거가 부족하거나 적용하지 않는 제보는 `REJECTED`로 종료한다.
- `VERIFIED`는 다른 자료 또는 복수 제보로 사실을 확인한 상태이고, `APPLIED`는 앱 또는 역 데이터 업데이트가 배포된 상태다.
- 무료 DB는 매월 1회 외부 저장소에 수동 백업한다. 백업 파일은 공개 저장소와 앱 패키지에 포함하지 않는다.

## localhost 관리자 검토

- 운영자는 `admin/`의 localhost 전용 페이지에서만 제보 목록을 조회하고 상태·메모·적용 버전을 변경한다.
- 브라우저는 Publishable key와 관리자 JWT만 사용하고, 실제 조회·변경은 관리자 이메일 허용 목록을 검사하는 `issue-report-admin` Edge Function이 수행한다.
- 상태 변경은 `admin_update_issue_report_review` RPC를 통해 처리하며 `issue_report_review_logs`에 이전 상태, 다음 상태, 메모, 적용 버전, 관리자 Auth ID와 시각을 남긴다.
- `APPLIED` 또는 `REJECTED`에서 `resolved_at`을 기록하되 즉시 삭제하지 않고, 해결 시점 기준 1년 보존 정책을 유지한다.
- 관리자 설정과 실행 절차는 [`ISSUE_REPORT_ADMIN.md`](ISSUE_REPORT_ADMIN.md)를 따른다.
