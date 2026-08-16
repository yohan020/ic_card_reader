-- Abuse prevention uses the Supabase anonymous Auth UUID only on the server.
-- Card IDm and device identifiers are never stored or transmitted.
alter table public.issue_reports
  add column if not exists reporter_auth_user_id uuid;

create index if not exists issue_reports_reporter_auth_created_at_idx
  on public.issue_reports (reporter_auth_user_id, created_at desc)
  where reporter_auth_user_id is not null;

comment on column public.issue_reports.reporter_auth_user_id is
  'Supabase anonymous Auth UUID used only for report abuse prevention and moderator blocking. No card IDm or device ID.';

create table if not exists public.blocked_issue_reporters (
  reporter_auth_user_id uuid primary key,
  source_report_id uuid references public.issue_reports(id) on delete set null,
  blocked_by_admin_user_id uuid not null,
  blocked_reason text,
  blocked_at timestamptz not null default now(),
  is_active boolean not null default true,
  unblocked_at timestamptz,
  unblocked_by_admin_user_id uuid,
  check (blocked_reason is null or char_length(blocked_reason) <= 500)
);

alter table public.blocked_issue_reporters enable row level security;
revoke all on table public.blocked_issue_reporters from anon, authenticated;

comment on table public.blocked_issue_reporters is
  'Private moderation block list for abusive anonymous report submitters. Stores only Supabase anonymous Auth UUIDs.';

create or replace function public.is_issue_reporter_blocked(
  p_reporter_auth_user_id uuid
)
returns boolean
language sql
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
      from public.blocked_issue_reporters
     where reporter_auth_user_id = p_reporter_auth_user_id
       and is_active is true
  );
$$;

revoke all on function public.is_issue_reporter_blocked(uuid) from public;
grant execute on function public.is_issue_reporter_blocked(uuid) to service_role;

create or replace function public.admin_block_issue_reporter(
  p_report_id uuid,
  p_admin_user_id uuid,
  p_reason text default null
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  reporter_id uuid;
  normalized_reason text := nullif(trim(p_reason), '');
  was_already_active boolean;
begin
  if normalized_reason is not null and char_length(normalized_reason) > 500 then
    raise exception 'BLOCK_REASON_TOO_LONG' using errcode = '22023';
  end if;

  select reporter_auth_user_id
    into reporter_id
    from public.issue_reports
   where id = p_report_id
   for update;

  if not found then
    raise exception 'REPORT_NOT_FOUND' using errcode = 'P0002';
  end if;
  if reporter_id is null then
    raise exception 'REPORTER_ID_NOT_AVAILABLE' using errcode = 'P0003';
  end if;

  select is_active
    into was_already_active
    from public.blocked_issue_reporters
   where reporter_auth_user_id = reporter_id
   for update;

  insert into public.blocked_issue_reporters (
    reporter_auth_user_id,
    source_report_id,
    blocked_by_admin_user_id,
    blocked_reason,
    blocked_at,
    is_active,
    unblocked_at,
    unblocked_by_admin_user_id
  ) values (
    reporter_id,
    p_report_id,
    p_admin_user_id,
    normalized_reason,
    now(),
    true,
    null,
    null
  )
  on conflict (reporter_auth_user_id) do update
     set source_report_id = excluded.source_report_id,
         blocked_by_admin_user_id = excluded.blocked_by_admin_user_id,
         blocked_reason = excluded.blocked_reason,
         blocked_at = now(),
         is_active = true,
         unblocked_at = null,
         unblocked_by_admin_user_id = null;

  return coalesce(was_already_active, false) is false;
end;
$$;

create or replace function public.admin_unblock_issue_reporter(
  p_report_id uuid,
  p_admin_user_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  reporter_id uuid;
begin
  select reporter_auth_user_id
    into reporter_id
    from public.issue_reports
   where id = p_report_id
   for update;

  if not found then
    raise exception 'REPORT_NOT_FOUND' using errcode = 'P0002';
  end if;
  if reporter_id is null then
    raise exception 'REPORTER_ID_NOT_AVAILABLE' using errcode = 'P0003';
  end if;

  update public.blocked_issue_reporters
     set is_active = false,
         unblocked_at = now(),
         unblocked_by_admin_user_id = p_admin_user_id
   where reporter_auth_user_id = reporter_id
     and is_active is true;

  return found;
end;
$$;

revoke all on function public.admin_block_issue_reporter(uuid, uuid, text) from public;
revoke all on function public.admin_unblock_issue_reporter(uuid, uuid) from public;
grant execute on function public.admin_block_issue_reporter(uuid, uuid, text) to service_role;
grant execute on function public.admin_unblock_issue_reporter(uuid, uuid) to service_role;

-- PostgreSQL does not let CREATE OR REPLACE change a function's return type.
-- The previous maintenance helper returned three counters; this version returns
-- one, so remove only the old overload before defining the replacement.
drop function if exists public.run_issue_report_maintenance();

create function public.run_issue_report_maintenance()
returns table (deleted_reports bigint)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  report_count bigint;
begin
  -- Keep unresolved reports so that no pending correction is silently lost.
  -- Review logs are removed through their report_id ON DELETE CASCADE relation.
  delete from public.issue_reports
   where review_status in ('APPLIED', 'REJECTED')
     and resolved_at < now() - interval '1 year';
  get diagnostics report_count = row_count;

  return query select report_count;
end;
$$;

revoke all on function public.run_issue_report_maintenance() from public;

comment on function public.run_issue_report_maintenance() is
  'Monthly retention task: removes only APPLIED or REJECTED reports resolved more than one year ago, with cascading review logs.';

create or replace function public.schedule_issue_report_monthly_retention()
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  -- Dynamic SQL keeps this helper creatable before pg_cron is enabled.
  execute 'select cron.unschedule(jobid) from cron.job where jobname = $1'
    using 'issue-report-monthly-retention';
  execute 'select cron.schedule($1, $2, $3)'
    using
      'issue-report-monthly-retention',
      '20 3 1 * *',
      'select public.run_issue_report_maintenance();';
end;
$$;

do $$
begin
  -- Hosted Supabase supports pg_cron. If an existing project does not allow
  -- extension installation, enable it once in Dashboard > Integrations > Cron
  -- and run this migration again.
  execute 'create extension if not exists pg_cron';
  perform public.schedule_issue_report_monthly_retention();
exception
  when insufficient_privilege then
    raise notice 'Enable pg_cron in the Supabase Dashboard, then run select public.schedule_issue_report_monthly_retention();';
end;
$$;

create or replace function public.admin_list_issue_reports(
  p_limit integer default 100,
  p_review_status text default null,
  p_issue_type text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  bounded_limit integer := greatest(1, least(coalesce(p_limit, 100), 200));
begin
  if p_review_status is not null and p_review_status not in (
    'RECEIVED', 'REVIEWING', 'VERIFIED', 'APPLIED', 'REJECTED'
  ) then
    raise exception 'invalid review status' using errcode = '22023';
  end if;

  if p_issue_type is not null and p_issue_type not in (
    'WRONG_STATION_NAME', 'WRONG_BOARDING_STATION',
    'WRONG_ALIGHTING_STATION', 'WRONG_BOTH_STATIONS',
    'STATION_NOT_RESOLVED', 'BUS_COMPANY_NOT_RESOLVED',
    'WRONG_TRANSACTION_TYPE', 'WRONG_AMOUNT_OR_BALANCE', 'OTHER'
  ) then
    raise exception 'invalid issue type' using errcode = '22023';
  end if;

  return (
    with filtered as (
      select
        reports.id,
        reports.anonymous_report_id,
        reports.anonymous_raw_record,
        reports.issue_type,
        reports.report_payload,
        reports.deduplication_key,
        reports.review_status,
        reports.review_note,
        reports.reviewed_at,
        reports.resolved_at,
        reports.applied_app_version,
        reports.created_at,
        reports.updated_at,
        reports.reporter_auth_user_id is not null as reporter_identity_available,
        exists (
          select 1
            from public.blocked_issue_reporters as blocked
           where blocked.reporter_auth_user_id = reports.reporter_auth_user_id
             and blocked.is_active is true
        ) as reporter_is_blocked
      from public.issue_reports as reports
      where (p_review_status is null or reports.review_status = p_review_status)
        and (p_issue_type is null or reports.issue_type = p_issue_type)
    ),
    limited as (
      select *
      from filtered
      order by created_at desc, id desc
      limit bounded_limit
    )
    select jsonb_build_object(
      'reports', coalesce(
        (
          select jsonb_agg(to_jsonb(limited) order by created_at desc, id desc)
          from limited
        ),
        '[]'::jsonb
      ),
      'count', (select count(*) from filtered)
    )
  );
end;
$$;

revoke all on function public.admin_list_issue_reports(integer, text, text)
  from public;
grant execute on function public.admin_list_issue_reports(integer, text, text)
  to service_role;
