# Supabase 오류 제보 배포

## 원칙

- Flutter 앱에는 Project URL과 Publishable key만 넣는다.
- Secret key, service role key, 데이터베이스 비밀번호는 앱·Git·채팅에 넣지 않는다.
- 앱은 `issue_reports` 테이블에 직접 접근하지 않는다.
- 익명 사용자 JWT를 검증한 `ic-card-report` Edge Function만 RLS를 우회해 한 건을 저장한다.

## 최초 배포

프로젝트 루트에서 Supabase CLI 로그인을 완료한 뒤 실행한다.

```powershell
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
supabase functions deploy ic-card-report
```

`YOUR_PROJECT_REF`는 Project URL의 `https://` 뒤에서 `.supabase.co` 앞까지의 값이다.

localhost 문의 관리 기능까지 배포할 때는 추가 migration과 관리자 함수를 반영한다.

```powershell
npx supabase db push
npx supabase functions deploy ic-card-report
npx supabase functions deploy issue-report-admin
```

`202608140003_issue_report_admin_bulk_update.sql`은 특정 상태로 필터링된
문의의 원자적 일괄 상태 변경과 문의별 감사 로그 기록을 추가한다.
`202608140004_issue_report_station_corrections.sql`과
`202608140005_issue_report_station_name.sql`은 역 교정 입력과 통합된 `역 이름이
잘못됨` 유형을 허용하고 관리 목록의 유형 필터를 갱신한다. 이 migration과 함께
`ic-card-report`를 재배포해야 역명·도시·노선 교정과 거래 유형 직접 입력을
검증할 수 있다.
`202608140006_issue_report_bus_company.sql`은 버스 기록에 한정한 `버스 회사 정보를
찾지 못함` 유형과 실제 회사명·운행 도시/지역 필수 입력을 허용한다. 노선 번호는
수집하지 않는다.

`202608150001_issue_report_abuse_and_retention.sql`은 새 제보의 익명 Auth UUID를
서버 내부의 악성 제보 차단용으로 연결하고, `blocked_issue_reporters`와 관리자 차단·해제 RPC를
추가한다. 또한 `APPLIED`·`REJECTED` 문의와 연결된 검토 이력을 해결 시점부터 1년 뒤 삭제하는
월간 Cron 작업(`issue-report-monthly-retention`)을 등록한다. migration은 `pg_cron`을 활성화하려
시도한다. 권한 오류가 나면 Supabase Dashboard의 **Integrations → Cron**에서 `pg_cron`을 먼저
활성화한 뒤 migration을 다시 실행한다.

관리자 계정 생성과 로컬 실행 방법은 [`ISSUE_REPORT_ADMIN.md`](ISSUE_REPORT_ADMIN.md)를 따른다.

## Android 실행 및 release 빌드

기본 production Project URL과 Publishable key는 앱에 포함되어 있으므로 일반
`flutter run`과 `flutter build appbundle --release`에서도 오류 제보가 동작한다.
Publishable key는 모바일 앱에 공개하도록 설계된 키이며, Secret key와 service role
key는 앱에 포함하지 않는다.

다른 Supabase 프로젝트를 사용하는 개발 환경에서는 다음처럼 기본값을 덮어쓸 수
있다.

```powershell
flutter run `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

두 값 중 하나를 빈 값으로 명시하면 앱의 NFC·이용내역 기능은 정상 동작하지만 오류
제보 전송은 설정 안내와 함께 실패한다.

## 검증

1. 이용내역 상세에서 오류 제보 3단계를 완료한다.
2. `역 정보가 없거나 잘못됨`에서 하단 팝업으로 승차역·하차역·둘 다 범위를 선택하고, 역 이름·도시·지역 필수, 노선명 선택 입력과 함께 한 건이 저장되는지 확인한다.
3. 거래 유형 오류에서 목록 선택과 `목록에 없음` 직접 입력이 모두 저장되는지 확인한다.
4. 버스 이용 기록에서만 `버스 회사 정보가 없거나 잘못됨`이 보이고, 실제 회사명·운행 도시/지역을 입력한 제보가 저장되는지 확인한다.
5. Supabase Table Editor의 `issue_reports`에서 한 건이 저장됐는지 확인한다.
6. `anonymous_raw_record`가 32자리인지 확인한다.
7. `report_payload`에 IDm, 다른 이용내역, 기기 ID, 위치가 없는지 확인한다.
8. 앱의 Publishable key로 테이블 조회·직접 삽입이 거부되는지 확인한다.
9. 네트워크를 끈 상태에서 실패 안내와 다시 시도가 동작하는지 확인한다.

## 무료 플랜 운영

### 월 1회 백업

무료 프로젝트는 정기 백업이 없으므로 매월 1회 연결된 프로젝트의 데이터를 외부에 백업한다.

```powershell
New-Item -ItemType Directory -Force -Path .private-backups
supabase db dump --linked --data-only --file ".private-backups/issue-reports-YYYY-MM.sql"
```

`.private-backups/`는 Git에 추가하지 않고 암호화된 개인 저장소로 옮긴다. 백업 성공과 파일 열기 여부를 확인한 뒤 정리 작업을 실행한다.

### 월 1회 보존 기간 정리

새 migration을 배포한 뒤 Supabase Dashboard의 SQL Editor에서 다음을 실행한다.

```sql
select * from public.run_issue_report_maintenance();
```

이 작업은 `APPLIED` 또는 `REJECTED` 상태이며 해결 시점부터 1년이 지난 제보와 연결된 검토 이력만 삭제한다. 진행 중인 `RECEIVED`·`REVIEWING`·`VERIFIED` 제보, 반복 제한 기록, Supabase 익명 Auth 사용자는 이 작업으로 삭제하지 않는다. migration이 등록한 Cron은 매월 1일 03:20 UTC에 같은 정리를 실행하므로 Dashboard에서 실행 이력을 확인한다.

### 반복 제보 제한

Edge Function은 익명 Auth ID별로 10분당 최대 5건을 허용한다. 제한 정보는 제보 테이블과 연결하지 않으며, 초과 시 앱에 10분 뒤 다시 시도하라는 안내를 표시한다. Supabase Auth 자체의 익명 로그인 IP 제한도 Dashboard의 Authentication → Rate Limits에서 유지한다.
