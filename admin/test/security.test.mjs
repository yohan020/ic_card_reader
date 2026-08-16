import test from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'

const browserSources = [
  readFileSync(new URL('../config.js', import.meta.url), 'utf8'),
  readFileSync(new URL('../src/app.js', import.meta.url), 'utf8'),
]

test('browser code contains no service role credential', () => {
  for (const source of browserSources) {
    assert.doesNotMatch(source, /service[_-]?role/i)
    assert.doesNotMatch(source, /SUPABASE_SERVICE_ROLE_KEY/)
  }
})

test('admin list bypasses browser caches and exposes loaded versus total counts', () => {
  const app = browserSources[1]
  assert.match(app, /cache: 'no-store'/)
  assert.match(app, /_requestTime/)
  assert.match(app, /표시 \$\{reports\.length\} \/ 전체 \$\{state\.totalCount\}건/)
})

test('local server only listens on loopback and disables caching', () => {
  const server = readFileSync(new URL('../server.mjs', import.meta.url), 'utf8')
  assert.match(server, /const host = '127\.0\.0\.1'/)
  assert.match(server, /'Cache-Control': 'no-store'/)
  assert.match(server, /frame-ancestors 'none'/)
})

test('admin function limits browser origins to localhost', () => {
  const edgeFunction = readFileSync(
    new URL('../../supabase/functions/issue-report-admin/index.ts', import.meta.url),
    'utf8',
  )
  assert.match(edgeFunction, /localhost\|127\\\.0\\\.0\\\.1/)
  assert.match(edgeFunction, /ADMIN_ACCESS_REQUIRED/)
  assert.match(edgeFunction, /ISSUE_REPORT_ADMIN_EMAILS/)
  assert.match(edgeFunction, /Cache-Control', 'no-store, max-age=0'/)
})

test('admin function uses a single aggregated RPC to bypass API row limits', () => {
  const edgeFunction = readFileSync(
    new URL('../../supabase/functions/issue-report-admin/index.ts', import.meta.url),
    'utf8',
  )
  assert.match(edgeFunction, /\.rpc\('admin_list_issue_reports'/)
  assert.doesNotMatch(edgeFunction, /\.from\('issue_reports'\)/)

  const migration = readFileSync(
    new URL('../../supabase/migrations/202608140002_issue_report_admin_list.sql', import.meta.url),
    'utf8',
  )
  assert.match(migration, /returns jsonb/i)
  assert.match(migration, /jsonb_agg/i)
  assert.match(migration, /grant execute[\s\S]+to service_role/i)
})

test('bulk status changes use an atomic service-role RPC with per-report audit logs', () => {
  const app = browserSources[1]
  assert.match(app, /currentStatus !== '' && reports\.length > 0/)
  assert.match(app, /selectedBulkUpdateIds/)
  assert.match(app, /checkbox\.type = 'checkbox'/)
  assert.match(app, /function toggleSelectAll\(\)/)
  assert.match(app, /indeterminate = ids\.length > 0 && !allSelected/)

  const edgeFunction = readFileSync(
    new URL('../../supabase/functions/issue-report-admin/index.ts', import.meta.url),
    'utf8',
  )
  assert.match(edgeFunction, /admin_bulk_update_issue_report_reviews/)
  assert.match(edgeFunction, /ids\.length > 100/)

  const migration = readFileSync(
    new URL('../../supabase/migrations/202608140003_issue_report_admin_bulk_update.sql', import.meta.url),
    'utf8',
  )
  assert.match(migration, /for update/i)
  assert.match(migration, /insert into public\.issue_report_review_logs/i)
  assert.match(migration, /grant execute[\s\S]+to service_role/i)
})

test('station correction reports support both-station errors end to end', () => {
  const reportFunction = readFileSync(
    new URL('../../supabase/functions/ic-card-report/index.ts', import.meta.url),
    'utf8',
  )
  const adminFunction = readFileSync(
    new URL('../../supabase/functions/issue-report-admin/index.ts', import.meta.url),
    'utf8',
  )
  const migration = readFileSync(
    new URL('../../supabase/migrations/202608140005_issue_report_station_name.sql', import.meta.url),
    'utf8',
  )
  assert.match(reportFunction, /WRONG_STATION_NAME/)
  assert.match(reportFunction, /correctedBoardingStation/)
  assert.match(reportFunction, /correctedAlightingStation/)
  assert.match(reportFunction, /customSuggestedTransactionType/)
  assert.match(adminFunction, /WRONG_STATION_NAME/)
  assert.match(migration, /WRONG_STATION_NAME/)
})

test('reporter blocking and completed-report retention stay server-side', () => {
  const reportFunction = readFileSync(
    new URL('../../supabase/functions/ic-card-report/index.ts', import.meta.url),
    'utf8',
  )
  const adminFunction = readFileSync(
    new URL('../../supabase/functions/issue-report-admin/index.ts', import.meta.url),
    'utf8',
  )
  const migration = readFileSync(
    new URL('../../supabase/migrations/202608150001_issue_report_abuse_and_retention.sql', import.meta.url),
    'utf8',
  )

  assert.match(reportFunction, /is_issue_reporter_blocked/)
  assert.match(reportFunction, /REPORTER_BLOCKED/)
  assert.match(reportFunction, /reporter_auth_user_id: anonymousUserId/)
  assert.match(adminFunction, /admin_block_issue_reporter/)
  assert.match(adminFunction, /admin_unblock_issue_reporter/)
  assert.match(migration, /create table if not exists public\.blocked_issue_reporters/i)
  assert.match(migration, /review_status in \('APPLIED', 'REJECTED'\)/)
  assert.match(migration, /cron\.schedule/)
  assert.match(migration, /reporter_identity_available/)
})

test('bus company reports are restricted to bus records and reach the admin flow', () => {
  const reportFunction = readFileSync(
    new URL('../../supabase/functions/ic-card-report/index.ts', import.meta.url),
    'utf8',
  )
  const adminFunction = readFileSync(
    new URL('../../supabase/functions/issue-report-admin/index.ts', import.meta.url),
    'utf8',
  )
  const migration = readFileSync(
    new URL('../../supabase/migrations/202608140006_issue_report_bus_company.sql', import.meta.url),
    'utf8',
  )
  assert.match(reportFunction, /BUS_COMPANY_NOT_RESOLVED/)
  assert.match(reportFunction, /suggestedBusCompanyName/)
  assert.match(reportFunction, /suggestedBusCompanyCity/)
  assert.match(reportFunction, /currentTransactionType !== 'BUS'/)
  assert.match(adminFunction, /BUS_COMPANY_NOT_RESOLVED/)
  assert.match(migration, /BUS_COMPANY_NOT_RESOLVED/)
})
