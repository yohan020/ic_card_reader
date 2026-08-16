# localhost 문의 관리 페이지

## 목적

`admin/`은 Supabase `issue_reports`에 접수된 익명 오류 제보를 한 명의 운영자가 localhost에서 검토하는 별도 웹 도구다. Android 앱과 별도로 실행되며 AAB에 포함되지 않는다. 외부 웹 호스팅은 필요하지 않다.

현재 요구 범위의 구현은 완료되었다. 이후 운영 환경을 새로 구성하거나 migration이 추가된 경우 아래 배포 절차를 다시 실행한다.

## 보안 구조

```text
localhost 웹(Publishable key + 관리자 세션)
  -> issue-report-admin Edge Function(이메일 허용 목록 검사)
    -> service role로 비공개 테이블 조회·RPC 실행
```

- 브라우저에는 공개 가능한 Project URL과 Publishable key만 들어 있다.
- `service_role`은 Supabase Edge Function 환경에만 존재하며 프론트엔드로 전달하지 않는다.
- Edge Function은 `http://localhost`와 `http://127.0.0.1` Origin만 허용한다.
- 기본 관리자 이메일은 `iccardreader10@gmail.com`이다. 다른 계정은 HTTP 403으로 거부한다.
- 앱의 익명 사용자는 기존처럼 제보 제출만 가능하며 제보 목록·검토 로그에는 접근할 수 없다.
- 새 버전 앱의 제보는 서버 내부에서만 익명 Auth UUID를 연결한다. UUID 자체는 관리 화면에 표시하지 않으며, 상세의 차단·해제 버튼만 이 값을 사용한다.
- 관리자 세션은 `sessionStorage`만 사용하므로 브라우저 탭을 닫으면 사라진다.

## 최초 설정 및 배포

프로젝트 루트에서 새 migration과 관리자 함수를 배포한다.

```powershell
npx supabase db push
npx supabase functions deploy issue-report-admin
```

문의 목록은 `admin_list_issue_reports` RPC가 최대 100건을 JSON 값 하나로
집계해 반환한다. 따라서 Supabase REST API의 Max Rows가 1로 설정되어도
관리 페이지 목록은 잘리지 않는다.

관리 목록 요청은 timestamp를 붙이고 브라우저와 Edge Function 양쪽에서
캐시를 금지한다. 목록 배지는 필터 결과와 서버 전체 건수가 다르면
`표시 N / 전체 M건`으로 표시해 응답 문제를 바로 구분한다.
조회 URL에 `limit`이 없으면 기본값 100을 사용하며, null이 숫자 0으로
변환되어 1건으로 제한되지 않도록 별도 파라미터 테스트로 검증한다.

## 상태 일괄 변경

- `모든 상태`에서는 일괄 변경을 제공하지 않는다.
- `신규 접수`, `확인 중` 등 특정 상태를 선택하면 각 목록 항목에 체크박스가
  나타나며, 현재 검색어와 문의 유형 필터 안에서 체크한 문의만 대상이 된다.
- `전체 선택`은 현재 필터 결과에 표시된 문의를 모두 체크하거나 해제하며,
  일부만 체크된 경우 중간 선택 상태로 표시한다.
- 검색어·상태·문의 유형 필터를 바꾸면 기존 체크를 해제해 화면에서 사라진
  문의가 실수로 변경되지 않게 한다.
- 목록은 빠른 분류에 필요한 목록 번호, 문의 유형, 접수 날짜만 표시하고
  원본 기록과 제안 내용은 항목을 눌러 상세 패널에서 확인한다.
- 체크한 문의를 한 번에 최대 100건까지 다른 상태로 변경할 수 있다.
- 확인 모달에서 대상 건수와 이전·다음 상태를 확인한 뒤 실행한다.
- 기존 관리자 메모와 적용 앱 버전은 유지한다.
- DB 트랜잭션 하나로 전체 상태를 변경하고 각 문의의 이전·다음 상태를
  `issue_report_review_logs`에 개별 기록한다.

관리자 이메일을 변경하거나 여러 개 허용하려면 쉼표로 구분해 secret을 설정한 뒤 함수를 다시 배포한다.

```powershell
npx supabase secrets set ISSUE_REPORT_ADMIN_EMAILS=iccardreader10@gmail.com
npx supabase functions deploy issue-report-admin
```

Supabase Dashboard의 **Authentication → Users → Add user**에서 다음 사용자를 만든다.

- 이메일: `iccardreader10@gmail.com`
- 비밀번호: 운영자만 아는 강한 비밀번호
- 이메일 확인: 생성 과정에서 확인 처리

비밀번호와 `service_role`은 저장소·문서·채팅에 기록하지 않는다.

## 실행

프로젝트 루트에서 다음 명령을 실행한다. 외부 패키지 설치는 필요하지 않다.

```powershell
node admin/server.mjs
```

브라우저에서 다음 주소를 연다.

```text
http://127.0.0.1:4173
```

포트를 바꾸려면 해당 PowerShell 세션에서만 환경 변수를 지정한다.

```powershell
$env:IC_CARD_ADMIN_PORT = "4174"
node admin/server.mjs
```

서버는 `127.0.0.1`에만 바인딩되며 같은 네트워크의 다른 기기에서는 접속할 수 없다. 종료는 터미널에서 `Ctrl+C`를 누른다.

## 상태 운영

| 상태 | 의미 |
|---|---|
| `RECEIVED` | 새로 접수됨 |
| `REVIEWING` | 운영자가 원인 확인 중 |
| `VERIFIED` | 실제 문제임을 확인하고 수정하기로 결정 |
| `APPLIED` | 수정된 앱 또는 데이터가 배포됨 |
| `REJECTED` | 근거 부족, 재현 불가 또는 오류가 아님 |

관리 페이지에서 상태, 관리자 메모, 적용 앱 버전을 저장하면 `reviewed_at`, `resolved_at`, `updated_at`이 서버에서 갱신되고 `issue_report_review_logs`에 변경 이력이 남는다. 해결된 제보는 바로 삭제하지 않고 기존 1년 보존 정책에 따라 정리한다.

문의 상세의 **파서 확인 승차역**·**파서 확인 하차역**은 제보를 보낸 앱이 당시 파싱한 `currentBoardingStation`·`currentAlightingStation` snapshot이다. 서버에서 역 코드를 다시 추측하지 않으며, 값이 없던 이전 문의 또는 미확인 거래는 `null`로 표시한다.

## 악성 제보 차단과 자동 정리

- 상세 화면의 **제보자 차단**은 현재 문의를 보낸 익명 Auth 사용자만 서버에서 차단한다. 이후 제보 요청은 저장 전에 거절되며, 현재 문의의 처리 상태는 자동으로 변경하지 않는다.
- 잘못 차단했거나 재검토가 필요하면 같은 위치의 **제보자 차단 해제**를 사용한다.
- 이전 버전의 문의는 익명 UUID를 제보 내용과 연결하지 않았으므로 차단 버튼이 비활성화된다.
- 매월 1일 03:20 UTC에 `issue-report-monthly-retention` Cron 작업이 실행된다. `APPLIED`·`REJECTED` 문의 중 해결 시점부터 1년이 지난 자료와 연결된 검토 이력만 삭제하며, 진행 중인 제보는 삭제하지 않는다.
- Supabase Dashboard의 **Integrations → Cron**에서 작업과 실행 결과를 확인할 수 있다.

## 검증 명령

```powershell
node --test admin/test/*.test.mjs
```

추가 확인:

1. 허용된 계정으로 로그인해 목록이 보이는지 확인한다.
2. 다른 이메일 계정으로 로그인했을 때 관리자 API가 403을 반환하는지 확인한다.
3. 상태와 메모를 저장한 뒤 `issue_reports`와 `issue_report_review_logs`가 함께 갱신되는지 확인한다.
4. 브라우저 개발자 도구에 `service_role`이 존재하지 않는지 확인한다.
5. `http://127.0.0.1:4173` 이외의 Origin에서 관리자 함수가 거부되는지 확인한다.
