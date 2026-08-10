# Issue reporting specification

## 상태

Supabase 익명 인증, Edge Function, RLS로 보호된 PostgreSQL 테이블을 사용하는 실제 전송 경로를 구현했다. 배포 전에는 `--dart-define` 연결값이 필요하다.

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
  "appVersion": "1.0.0+1",
  "platform": "ios",
  "osVersion": "string",
}
```

중복 키는 조작 방지를 위해 클라이언트가 보내지 않고 Edge Function이 정규화된 비개인 교정 필드로 SHA-256을 계산한다.

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
- 제한 확인에 사용하는 익명 Auth ID는 별도 제한 테이블에만 저장하고 `issue_reports`와 연결하지 않는다.
- 제보는 접수 후 최대 1년 보관하고 매월 만료 자료를 삭제한다.
- 익명 Auth 사용자와 제한 기록은 마지막 제보 활동 후 1년이 지나면 매월 정리한다.
- 검토 상태는 `RECEIVED` → `REVIEWING` → `VERIFIED` → `APPLIED` 순서로 진행한다. 근거가 부족하거나 적용하지 않는 제보는 `REJECTED`로 종료한다.
- `VERIFIED`는 다른 자료 또는 복수 제보로 사실을 확인한 상태이고, `APPLIED`는 앱 또는 역 데이터 업데이트가 배포된 상태다.
- 무료 DB는 매월 1회 외부 저장소에 수동 백업한다. 백업 파일은 공개 저장소와 앱 패키지에 포함하지 않는다.
