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

## Android 실행

```powershell
flutter run `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

두 값 중 하나라도 없으면 앱의 NFC·이용내역 기능은 정상 동작하지만 오류 제보 전송은 설정 안내와 함께 실패한다.

## 검증

1. 이용내역 상세에서 오류 제보 3단계를 완료한다.
2. Supabase Table Editor의 `issue_reports`에서 한 건이 저장됐는지 확인한다.
3. `anonymous_raw_record`가 32자리인지 확인한다.
4. `report_payload`에 IDm, 다른 이용내역, 기기 ID, 위치가 없는지 확인한다.
5. 앱의 Publishable key로 테이블 조회·직접 삽입이 거부되는지 확인한다.
6. 네트워크를 끈 상태에서 실패 안내와 다시 시도가 동작하는지 확인한다.

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

이 작업은 1년이 지난 제보, 마지막 제보 활동 후 1년이 지난 제한 기록과 비활성 익명 Auth 사용자를 삭제한다. Supabase Cron을 사용할 경우 매월 1일에 같은 SQL을 예약하고 실행 이력을 확인한다.

### 반복 제보 제한

Edge Function은 익명 Auth ID별로 10분당 최대 5건을 허용한다. 제한 정보는 제보 테이블과 연결하지 않으며, 초과 시 앱에 10분 뒤 다시 시도하라는 안내를 표시한다. Supabase Auth 자체의 익명 로그인 IP 제한도 Dashboard의 Authentication → Rate Limits에서 유지한다.
