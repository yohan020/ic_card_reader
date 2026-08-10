create table if not exists public.issue_report_rate_limits (
  anonymous_user_id uuid primary key,
  window_started_at timestamptz not null default now(),
  submission_count integer not null default 0
    check (submission_count >= 0),
  updated_at timestamptz not null default now()
);

alter table public.issue_report_rate_limits enable row level security;

revoke all on table public.issue_report_rate_limits from anon, authenticated;

comment on table public.issue_report_rate_limits is
  'Anonymous Auth IDs used only for report rate limiting; never linked to issue_reports.';

create or replace function public.consume_issue_report_quota(
  p_anonymous_user_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  current_limit public.issue_report_rate_limits%rowtype;
begin
  insert into public.issue_report_rate_limits (
    anonymous_user_id,
    submission_count
  )
  values (p_anonymous_user_id, 0)
  on conflict (anonymous_user_id) do nothing;

  select *
    into current_limit
    from public.issue_report_rate_limits
   where anonymous_user_id = p_anonymous_user_id
   for update;

  if current_limit.window_started_at <= now() - interval '10 minutes' then
    update public.issue_report_rate_limits
       set window_started_at = now(),
           submission_count = 1,
           updated_at = now()
     where anonymous_user_id = p_anonymous_user_id;
    return true;
  end if;

  if current_limit.submission_count >= 5 then
    update public.issue_report_rate_limits
       set updated_at = now()
     where anonymous_user_id = p_anonymous_user_id;
    return false;
  end if;

  update public.issue_report_rate_limits
     set submission_count = submission_count + 1,
         updated_at = now()
   where anonymous_user_id = p_anonymous_user_id;
  return true;
end;
$$;

revoke all on function public.consume_issue_report_quota(uuid) from public;
grant execute on function public.consume_issue_report_quota(uuid) to service_role;

create or replace function public.run_issue_report_maintenance()
returns table (
  deleted_reports bigint,
  deleted_rate_limits bigint,
  deleted_anonymous_users bigint
)
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  report_count bigint;
  rate_limit_count bigint;
  user_count bigint;
begin
  delete from public.issue_reports
   where created_at < now() - interval '1 year';
  get diagnostics report_count = row_count;

  delete from auth.users as users
   where users.is_anonymous is true
     and coalesce(users.last_sign_in_at, users.created_at)
       < now() - interval '1 year'
     and not exists (
       select 1
         from public.issue_report_rate_limits as limits
        where limits.anonymous_user_id = users.id
          and limits.updated_at >= now() - interval '1 year'
     );
  get diagnostics user_count = row_count;

  delete from public.issue_report_rate_limits
   where updated_at < now() - interval '1 year';
  get diagnostics rate_limit_count = row_count;

  return query select report_count, rate_limit_count, user_count;
end;
$$;

revoke all on function public.run_issue_report_maintenance() from public;

comment on function public.run_issue_report_maintenance() is
  'Monthly retention task: delete reports and inactive anonymous users older than one year.';
