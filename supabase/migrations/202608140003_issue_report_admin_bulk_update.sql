create or replace function public.admin_bulk_update_issue_report_reviews(
  p_report_ids uuid[],
  p_review_status text,
  p_reviewer_user_id uuid
)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  requested_count integer;
  matched_count integer;
  updated_count integer;
begin
  if p_review_status not in (
    'RECEIVED', 'REVIEWING', 'VERIFIED', 'APPLIED', 'REJECTED'
  ) then
    raise exception 'INVALID_REVIEW_STATUS' using errcode = '22023';
  end if;

  requested_count := cardinality(p_report_ids);
  if requested_count is null or requested_count < 1 or requested_count > 100 then
    raise exception 'INVALID_REPORT_COUNT' using errcode = '22023';
  end if;

  if (
    select count(distinct report_id)
    from unnest(p_report_ids) as requested(report_id)
  ) <> requested_count then
    raise exception 'DUPLICATE_REPORT_ID' using errcode = '22023';
  end if;

  perform id
  from public.issue_reports
  where id = any(p_report_ids)
  for update;
  get diagnostics matched_count = row_count;

  if matched_count <> requested_count then
    raise exception 'REPORT_NOT_FOUND' using errcode = 'P0002';
  end if;

  insert into public.issue_report_review_logs (
    report_id,
    reviewer_user_id,
    previous_status,
    next_status,
    review_note,
    applied_app_version
  )
  select
    reports.id,
    p_reviewer_user_id,
    reports.review_status,
    p_review_status,
    reports.review_note,
    reports.applied_app_version
  from public.issue_reports as reports
  where reports.id = any(p_report_ids);

  update public.issue_reports
  set review_status = p_review_status,
      reviewed_at = case
        when p_review_status = 'RECEIVED' then null
        else coalesce(reviewed_at, now())
      end,
      resolved_at = case
        when p_review_status in ('APPLIED', 'REJECTED') then now()
        else null
      end,
      updated_at = now()
  where id = any(p_report_ids);
  get diagnostics updated_count = row_count;

  return updated_count;
end;
$$;

revoke all on function public.admin_bulk_update_issue_report_reviews(
  uuid[], text, uuid
) from public;
grant execute on function public.admin_bulk_update_issue_report_reviews(
  uuid[], text, uuid
) to service_role;

comment on function public.admin_bulk_update_issue_report_reviews(
  uuid[], text, uuid
) is 'Atomically changes up to 100 issue report statuses and writes one private audit log per report. Service role only.';
