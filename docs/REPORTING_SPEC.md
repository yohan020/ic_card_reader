# Issue reporting specification

## 상태

Phase 2용 계약 초안이다. Phase 1 UI에는 연결하지 않았다.

## 화면 흐름

1. 이용내역 상세에서 `문제 신고`를 누른다.
2. 현재 한 건이 선택된 상태에서 문제 유형을 고른다.
3. 올바른 출발/도착역, 거래 유형, 추가 설명을 선택적으로 입력한다.
4. 전송할 필드와 제외할 정보를 미리 보여준다.
5. 사용자가 명시적으로 동의한 경우에만 큐에 넣고 전송한다.

역명 또는 설명은 필수가 아니며 현재 코드와 해석만으로 제출할 수 있다.

## 문제 유형

`WRONG_BOARDING_STATION`, `WRONG_ALIGHTING_STATION`, `STATION_NOT_RESOLVED`, `WRONG_TRANSACTION_TYPE`, `WRONG_AMOUNT_OR_BALANCE`, `OTHER`.

## API 계약

`POST /v1/ic-card-reports`

```json
{
  "anonymousReportId": "uuid-v4",
  "anonymousRawRecord": "32 uppercase hex characters",
  "issueType": "STATION_NOT_RESOLVED",
  "regionCode": 1,
  "boarding": {"lineCode": 165, "stationCode": 164, "currentName": null, "suggestedName": "..."},
  "alighting": {"lineCode": 165, "stationCode": 172, "currentName": null, "suggestedName": null},
  "currentTransactionType": "UNKNOWN",
  "suggestedTransactionType": null,
  "usageDate": "2026-08-07",
  "balance": 1234,
  "calculatedAmount": null,
  "additionalDescription": null,
  "parserVersion": "p1-unparsed",
  "stationDatabaseVersion": "not-installed",
  "appVersion": "0.1.0+1",
  "platform": "ios",
  "osVersion": "string",
  "deduplicationKey": "sha256 of canonical non-personal correction fields"
}
```

성공 응답은 HTTP 202와 `reportId`, `reviewStatus: RECEIVED`를 반환한다. 클라이언트 상태는 `PENDING`, `SUBMITTED`, `FAILED`; 서버 검토 상태는 `RECEIVED`, `REVIEWING`, `VERIFIED`, `APPLIED`, `REJECTED`다.

## 전송/제외 데이터

전송은 선택한 원시 16바이트 레코드 한 건, 코드, 현재/제안 해석, 날짜, 잔액/계산액, 버전, 플랫폼/OS 버전으로 제한한다. 카드 IDm, 다른 이력, 이름·이메일, 기기 고유 ID, 위치, 전체 경로는 전송하지 않는다.

원시 레코드의 어떤 바이트가 개인 식별 가능성을 갖는지 확정되지 않았으므로 UI에서 “원시 카드 이용 기록 1건”임을 명확히 설명하고 동의받는다. 서버 로그에서도 요청 본문 마스킹 정책을 적용한다.

## 오프라인 재시도

동의가 완료된 payload를 SQLite 큐에 `PENDING`으로 저장한다. 지수 backoff와 상한을 적용하며 앱 재시작 후 재개한다. 4xx 계약 오류는 `FAILED`, 네트워크/5xx는 재시도 가능 상태로 남긴다. 사용자는 대기 중 신고를 삭제할 수 있어야 한다. 개발 환경에는 네트워크를 쓰지 않는 mock repository를 둔다.

## 중복 키와 운영 검토

정규화한 `regionCode`, `lineCode`, `stationCode`, 제안 역명, 오류 유형, 파서 버전, 역 DB 버전을 canonical JSON으로 만든 뒤 SHA-256을 계산한다. 서버는 이 키로 유사 신고를 묶되 자동 승인하지 않는다.

관리자가 출처와 복수 신고를 검증해 `VERIFIED`한 뒤 별도 DB migration/release 절차로만 반영한다. 사용자 신고가 운영 역 DB를 직접 수정하는 경로는 두지 않는다.
