import { createClient } from 'npm:@supabase/supabase-js@^2'
import { clampInteger } from './query_parameters.mjs'

const reviewStatuses = new Set([
  'RECEIVED',
  'REVIEWING',
  'VERIFIED',
  'APPLIED',
  'REJECTED',
])

const issueTypes = new Set([
  'WRONG_STATION_NAME',
  'WRONG_BOARDING_STATION',
  'WRONG_ALIGHTING_STATION',
  'WRONG_BOTH_STATIONS',
  'STATION_NOT_RESOLVED',
  'BUS_COMPANY_NOT_RESOLVED',
  'KOREAN_STATION_NAME_REQUEST',
  'WRONG_TRANSACTION_TYPE',
  'WRONG_AMOUNT_OR_BALANCE',
  'OTHER',
])

type JsonRecord = Record<string, unknown>

Deno.serve(async (request) => {
  const origin = request.headers.get('origin')
  const corsHeaders = createCorsHeaders(origin)
  if (corsHeaders === null) {
    return Response.json({ error: 'ORIGIN_NOT_ALLOWED' }, { status: 403 })
  }
  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders })
  }

  const authorization = await authorizeAdministrator(request)
  if ('response' in authorization) {
    return withCors(authorization.response, corsHeaders)
  }

  if (request.method === 'GET') {
    return withCors(
      await listReports(request, authorization.adminClient),
      corsHeaders,
    )
  }
  if (request.method === 'PATCH') {
    return withCors(
      await updateReport(request, authorization.adminClient, authorization.userId),
      corsHeaders,
    )
  }
  return jsonResponse({ error: 'METHOD_NOT_ALLOWED' }, 405, {
    Allow: 'GET, PATCH, OPTIONS',
    ...corsHeaders,
  })
})

async function authorizeAdministrator(request: Request): Promise<
  | {
      userId: string
      adminClient: ReturnType<typeof createClient>
    }
  | { response: Response }
> {
  const token = readBearerToken(request.headers.get('authorization'))
  if (token === null) {
    return { response: jsonResponse({ error: 'AUTH_REQUIRED' }, 401) }
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const publishableKey =
    Deno.env.get('SUPABASE_ANON_KEY') ?? Deno.env.get('SB_PUBLISHABLE_KEY')
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  if (!supabaseUrl || !publishableKey || !serviceRoleKey) {
    console.error('issue report admin function is missing Supabase secrets')
    return { response: jsonResponse({ error: 'SERVER_NOT_CONFIGURED' }, 500) }
  }

  const userClient = createClient(supabaseUrl, publishableKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  })
  const { data, error } = await userClient.auth.getUser(token)
  if (error !== null || data.user === null) {
    return { response: jsonResponse({ error: 'INVALID_SESSION' }, 401) }
  }

  const email = data.user.email?.trim().toLowerCase()
  if (email === undefined || !allowedAdminEmails().has(email)) {
    console.warn('issue report admin access denied', data.user.id)
    return { response: jsonResponse({ error: 'ADMIN_ACCESS_REQUIRED' }, 403) }
  }

  return {
    userId: data.user.id,
    adminClient: createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    }),
  }
}

async function listReports(
  request: Request,
  adminClient: ReturnType<typeof createClient>,
): Promise<Response> {
  const url = new URL(request.url)
  const status = url.searchParams.get('status')
  const issueType = url.searchParams.get('issueType')
  const limit = clampInteger(url.searchParams.get('limit'), 1, 200, 100)
  if (status !== null && !reviewStatuses.has(status)) {
    return jsonResponse({ error: 'INVALID_REVIEW_STATUS' }, 400)
  }
  if (issueType !== null && !issueTypes.has(issueType)) {
    return jsonResponse({ error: 'INVALID_ISSUE_TYPE' }, 400)
  }

  // DB 안에서 여러 행을 JSON 배열 하나로 집계한다. PostgREST의 API
  // Max Rows가 1이어도 RPC 응답 자체는 한 행이므로 목록이 잘리지 않는다.
  const { data, error } = await adminClient.rpc('admin_list_issue_reports', {
    p_limit: limit,
    p_review_status: status,
    p_issue_type: issueType,
  })
  if (error !== null) {
    console.error('issue report admin list failed', error.code)
    return jsonResponse({ error: 'LIST_FAILED' }, 500)
  }
  if (!isJsonRecord(data) || !Array.isArray(data.reports)) {
    console.error('issue report admin list returned an invalid payload')
    return jsonResponse({ error: 'LIST_FAILED' }, 500)
  }

  const count = typeof data.count === 'number' && Number.isInteger(data.count)
    ? data.count
    : data.reports.length
  return jsonResponse({ reports: data.reports, count })
}

async function updateReport(
  request: Request,
  adminClient: ReturnType<typeof createClient>,
  reviewerUserId: string,
): Promise<Response> {
  let payload: JsonRecord
  try {
    payload = await request.json()
  } catch {
    return jsonResponse({ error: 'INVALID_JSON' }, 400)
  }

  if (Array.isArray(payload.ids)) {
    return bulkUpdateReports(payload, adminClient, reviewerUserId)
  }
  if (payload.action === 'blockReporter' || payload.action === 'unblockReporter') {
    return updateReporterBlock(payload, adminClient, reviewerUserId)
  }

  const id = payload.id
  const reviewStatus = payload.reviewStatus
  const reviewNote = normalizeNullableText(payload.reviewNote, 2000)
  const appliedAppVersion = normalizeNullableText(payload.appliedAppVersion, 80)
  if (!isUuid(id)) return jsonResponse({ error: 'INVALID_REPORT_ID' }, 400)
  if (typeof reviewStatus !== 'string' || !reviewStatuses.has(reviewStatus)) {
    return jsonResponse({ error: 'INVALID_REVIEW_STATUS' }, 400)
  }
  if (reviewNote === undefined) {
    return jsonResponse({ error: 'INVALID_REVIEW_NOTE' }, 400)
  }
  if (appliedAppVersion === undefined) {
    return jsonResponse({ error: 'INVALID_APP_VERSION' }, 400)
  }

  const { data, error } = await adminClient.rpc(
    'admin_update_issue_report_review',
    {
      p_report_id: id,
      p_review_status: reviewStatus,
      p_review_note: reviewNote,
      p_applied_app_version: appliedAppVersion,
      p_reviewer_user_id: reviewerUserId,
    },
  )
  if (error !== null) {
    console.error('issue report admin update failed', error.code)
    const statusCode = error.code === 'P0002' ? 404 : 500
    return jsonResponse(
      { error: statusCode === 404 ? 'REPORT_NOT_FOUND' : 'UPDATE_FAILED' },
      statusCode,
    )
  }
  return jsonResponse({ report: data })
}

async function updateReporterBlock(
  payload: JsonRecord,
  adminClient: ReturnType<typeof createClient>,
  reviewerUserId: string,
): Promise<Response> {
  const id = payload.id
  if (!isUuid(id)) return jsonResponse({ error: 'INVALID_REPORT_ID' }, 400)

  const isBlocking = payload.action === 'blockReporter'
  const blockReason = normalizeNullableText(payload.blockReason, 500)
  if (blockReason === undefined || (!isBlocking && blockReason !== null)) {
    return jsonResponse({ error: 'INVALID_BLOCK_REASON' }, 400)
  }

  const { data, error } = await adminClient.rpc(
    isBlocking ? 'admin_block_issue_reporter' : 'admin_unblock_issue_reporter',
    isBlocking
      ? {
          p_report_id: id,
          p_admin_user_id: reviewerUserId,
          p_reason: blockReason,
        }
      : {
          p_report_id: id,
          p_admin_user_id: reviewerUserId,
        },
  )
  if (error !== null) {
    console.error('issue report reporter block update failed', error.code)
    if (error.code === 'P0002') {
      return jsonResponse({ error: 'REPORT_NOT_FOUND' }, 404)
    }
    if (error.code === 'P0003') {
      return jsonResponse({ error: 'REPORTER_ID_NOT_AVAILABLE' }, 409)
    }
    return jsonResponse({ error: 'REPORTER_BLOCK_UPDATE_FAILED' }, 500)
  }
  if (typeof data !== 'boolean') {
    return jsonResponse({ error: 'REPORTER_BLOCK_UPDATE_FAILED' }, 500)
  }
  return jsonResponse({ blocked: isBlocking, changed: data })
}

async function bulkUpdateReports(
  payload: JsonRecord,
  adminClient: ReturnType<typeof createClient>,
  reviewerUserId: string,
): Promise<Response> {
  const ids = payload.ids
  const reviewStatus = payload.reviewStatus
  if (
    !Array.isArray(ids) ||
    ids.length < 1 ||
    ids.length > 100 ||
    !ids.every(isUuid) ||
    new Set(ids).size !== ids.length
  ) {
    return jsonResponse({ error: 'INVALID_REPORT_IDS' }, 400)
  }
  if (typeof reviewStatus !== 'string' || !reviewStatuses.has(reviewStatus)) {
    return jsonResponse({ error: 'INVALID_REVIEW_STATUS' }, 400)
  }

  const { data, error } = await adminClient.rpc(
    'admin_bulk_update_issue_report_reviews',
    {
      p_report_ids: ids,
      p_review_status: reviewStatus,
      p_reviewer_user_id: reviewerUserId,
    },
  )
  if (error !== null) {
    console.error('issue report admin bulk update failed', error.code)
    const statusCode = error.code === 'P0002' ? 404 : 500
    return jsonResponse(
      { error: statusCode === 404 ? 'REPORT_NOT_FOUND' : 'BULK_UPDATE_FAILED' },
      statusCode,
    )
  }
  if (typeof data !== 'number' || !Number.isInteger(data)) {
    console.error('issue report admin bulk update returned an invalid count')
    return jsonResponse({ error: 'BULK_UPDATE_FAILED' }, 500)
  }
  return jsonResponse({ updatedCount: data })
}

function allowedAdminEmails(): Set<string> {
  const configured = Deno.env.get('ISSUE_REPORT_ADMIN_EMAILS') ??
    'iccardreader10@gmail.com'
  return new Set(
    configured
      .split(',')
      .map((email) => email.trim().toLowerCase())
      .filter((email) => email.length > 0),
  )
}

function readBearerToken(header: string | null): string | null {
  if (header === null) return null
  const match = /^Bearer\s+(.+)$/i.exec(header)
  return match?.[1]?.trim() || null
}

function createCorsHeaders(origin: string | null): HeadersInit | null {
  if (origin !== null && !/^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/i.test(origin)) {
    return null
  }
  return {
    'Access-Control-Allow-Origin': origin ?? 'http://127.0.0.1:4173',
    'Access-Control-Allow-Headers':
      'authorization, apikey, content-type, x-client-info',
    'Access-Control-Allow-Methods': 'GET, PATCH, OPTIONS',
    'Access-Control-Max-Age': '86400',
    Vary: 'Origin',
  }
}

function withCors(response: Response, corsHeaders: HeadersInit): Response {
  const headers = new Headers(response.headers)
  for (const [key, value] of Object.entries(corsHeaders)) {
    headers.set(key, value)
  }
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  })
}

function jsonResponse(
  body: JsonRecord,
  status = 200,
  headers: HeadersInit = {},
): Response {
  const responseHeaders = new Headers(headers)
  responseHeaders.set('Cache-Control', 'no-store, max-age=0')
  responseHeaders.set('Pragma', 'no-cache')
  responseHeaders.set('Expires', '0')
  return Response.json(body, { status, headers: responseHeaders })
}

function normalizeNullableText(
  value: unknown,
  maximumLength: number,
): string | null | undefined {
  if (value === null || value === undefined || value === '') return null
  if (typeof value !== 'string') return undefined
  const normalized = value.trim()
  if (normalized.length > maximumLength) return undefined
  return normalized.length === 0 ? null : normalized
}

function isUuid(value: unknown): value is string {
  return typeof value === 'string' &&
    /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value)
}

function isJsonRecord(value: unknown): value is JsonRecord {
  return value !== null && typeof value === 'object' && !Array.isArray(value)
}
