create or replace function public.admin_list_issue_reports(
  p_limit integer default 100,
  p_review_status text default null,
  p_issue_type text default null
)
returns jsonb
language plpgsql
stable
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
    'WRONG_BOARDING_STATION',
    'WRONG_ALIGHTING_STATION',
    'STATION_NOT_RESOLVED',
    'WRONG_TRANSACTION_TYPE',
    'WRONG_AMOUNT_OR_BALANCE',
    'OTHER'
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
        reports.updated_at
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

comment on function public.admin_list_issue_reports(integer, text, text) is
  'Returns issue reports inside one JSON value so PostgREST row limits cannot truncate the admin list.';
