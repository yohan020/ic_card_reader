create table if not exists public.issue_reports (
  id uuid primary key default gen_random_uuid(),
  anonymous_report_id uuid not null unique,
  anonymous_raw_record text not null
    check (anonymous_raw_record ~ '^[0-9A-F]{32}$'),
  issue_type text not null
    check (issue_type in (
      'WRONG_BOARDING_STATION',
      'WRONG_ALIGHTING_STATION',
      'STATION_NOT_RESOLVED',
      'WRONG_TRANSACTION_TYPE',
      'WRONG_AMOUNT_OR_BALANCE',
      'OTHER'
    )),
  report_payload jsonb not null,
  deduplication_key text not null
    check (deduplication_key ~ '^[0-9a-f]{64}$'),
  review_status text not null default 'RECEIVED'
    check (review_status in (
      'RECEIVED', 'REVIEWING', 'VERIFIED', 'APPLIED', 'REJECTED'
    )),
  created_at timestamptz not null default now()
);

alter table public.issue_reports enable row level security;

revoke all on table public.issue_reports from anon, authenticated;

create index if not exists issue_reports_deduplication_key_idx
  on public.issue_reports (deduplication_key);

create index if not exists issue_reports_created_at_idx
  on public.issue_reports (created_at desc);

comment on table public.issue_reports is
  'Anonymous single-record IC card correction reports. Client roles have no access.';
