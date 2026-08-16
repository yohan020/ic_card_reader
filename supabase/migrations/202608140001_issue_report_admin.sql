alter table public.issue_reports
  add column if not exists review_note text,
  add column if not exists reviewed_at timestamptz,
  add column if not exists resolved_at timestamptz,
  add column if not exists applied_app_version text,
  add column if not exists updated_at timestamptz not null default now();

alter table public.issue_reports
  drop constraint if exists issue_reports_review_note_length_check;
alter table public.issue_reports
  add constraint issue_reports_review_note_length_check
  check (review_note is null or char_length(review_note) <= 2000);

alter table public.issue_reports
  drop constraint if exists issue_reports_applied_app_version_length_check;
alter table public.issue_reports
  add constraint issue_reports_applied_app_version_length_check
  check (
    applied_app_version is null
    or char_length(applied_app_version) between 1 and 80
  );

create index if not exists issue_reports_review_status_updated_at_idx
  on public.issue_reports (review_status, updated_at desc);

create table if not exists public.issue_report_review_logs (
  id bigint generated always as identity primary key,
  report_id uuid not null references public.issue_reports(id) on delete cascade,
  reviewer_user_id uuid not null,
  previous_status text not null,
  next_status text not null,
  review_note text,
  applied_app_version text,
  created_at timestamptz not null default now(),
  check (previous_status in (
    'RECEIVED', 'REVIEWING', 'VERIFIED', 'APPLIED', 'REJECTED'
  )),
  check (next_status in (
    'RECEIVED', 'REVIEWING', 'VERIFIED', 'APPLIED', 'REJECTED'
  )),
  check (review_note is null or char_length(review_note) <= 2000),
  check (
    applied_app_version is null
    or char_length(applied_app_version) between 1 and 80
  )
);

create index if not exists issue_report_review_logs_report_created_at_idx
  on public.issue_report_review_logs (report_id, created_at desc);

alter table public.issue_report_review_logs enable row level security;
revoke all on table public.issue_report_review_logs from anon, authenticated;

comment on table public.issue_report_review_logs is
  'Private audit history for administrator review changes. Client roles have no access.';

create or replace function public.admin_update_issue_report_review(
  p_report_id uuid,
  p_review_status text,
  p_review_note text,
  p_applied_app_version text,
  p_reviewer_user_id uuid
)
returns public.issue_reports
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  previous_status text;
  updated_report public.issue_reports;
  normalized_note text := nullif(trim(p_review_note), '');
  normalized_version text := nullif(trim(p_applied_app_version), '');
begin
  if p_review_status not in (
    'RECEIVED', 'REVIEWING', 'VERIFIED', 'APPLIED', 'REJECTED'
  ) then
    raise exception 'INVALID_REVIEW_STATUS' using errcode = '22023';
  end if;
  if normalized_note is not null and char_length(normalized_note) > 2000 then
    raise exception 'REVIEW_NOTE_TOO_LONG' using errcode = '22023';
  end if;
  if normalized_version is not null and char_length(normalized_version) > 80 then
    raise exception 'APP_VERSION_TOO_LONG' using errcode = '22023';
  end if;

  select review_status
    into previous_status
    from public.issue_reports
   where id = p_report_id
   for update;

  if not found then
    raise exception 'REPORT_NOT_FOUND' using errcode = 'P0002';
  end if;

  update public.issue_reports
     set review_status = p_review_status,
         review_note = normalized_note,
         applied_app_version = normalized_version,
         reviewed_at = case
           when p_review_status = 'RECEIVED' then null
           else coalesce(reviewed_at, now())
         end,
         resolved_at = case
           when p_review_status in ('APPLIED', 'REJECTED') then now()
           else null
         end,
         updated_at = now()
   where id = p_report_id
   returning * into updated_report;

  insert into public.issue_report_review_logs (
    report_id,
    reviewer_user_id,
    previous_status,
    next_status,
    review_note,
    applied_app_version
  ) values (
    p_report_id,
    p_reviewer_user_id,
    previous_status,
    p_review_status,
    normalized_note,
    normalized_version
  );

  return updated_report;
end;
$$;

revoke all on function public.admin_update_issue_report_review(
  uuid, text, text, text, uuid
) from public;
grant execute on function public.admin_update_issue_report_review(
  uuid, text, text, text, uuid
) to service_role;

comment on function public.admin_update_issue_report_review(
  uuid, text, text, text, uuid
) is 'Atomically updates a report review and writes a private audit log. Service role only.';
