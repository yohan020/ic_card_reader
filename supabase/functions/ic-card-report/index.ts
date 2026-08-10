import { withSupabase } from 'npm:@supabase/server@^1'

const issueTypes = new Set([
  'WRONG_BOARDING_STATION',
  'WRONG_ALIGHTING_STATION',
  'STATION_NOT_RESOLVED',
  'WRONG_TRANSACTION_TYPE',
  'WRONG_AMOUNT_OR_BALANCE',
  'OTHER',
])

const transactionTypes = new Set([
  'RAIL',
  'BUS',
  'PURCHASE',
  'CHARGE',
  'REFUND',
  'ADJUSTMENT',
  'UNKNOWN',
])

type ReportPayload = Record<string, unknown>

export default {
  fetch: withSupabase({ auth: 'user' }, async (request, context) => {
    if (request.method !== 'POST') {
      return Response.json({ error: 'METHOD_NOT_ALLOWED' }, { status: 405 })
    }

    const contentLength = Number(request.headers.get('content-length') ?? '0')
    if (contentLength > 12_000) {
      return Response.json({ error: 'PAYLOAD_TOO_LARGE' }, { status: 413 })
    }

    let payload: ReportPayload
    try {
      payload = await request.json()
    } catch {
      return Response.json({ error: 'INVALID_JSON' }, { status: 400 })
    }

    const validationError = validatePayload(payload)
    if (validationError !== null) {
      return Response.json(
        { error: 'INVALID_REPORT', field: validationError },
        { status: 400 },
      )
    }

    const anonymousUserId = context.userClaims?.id
    if (!isUuid(anonymousUserId)) {
      return Response.json({ error: 'INVALID_AUTH_USER' }, { status: 401 })
    }

    const { data: quotaAllowed, error: quotaError } =
      await context.supabaseAdmin.rpc('consume_issue_report_quota', {
        p_anonymous_user_id: anonymousUserId,
      })
    if (quotaError !== null) {
      console.error('issue report quota check failed', quotaError.code)
      return Response.json({ error: 'QUOTA_CHECK_FAILED' }, { status: 500 })
    }
    if (quotaAllowed !== true) {
      return Response.json(
        { error: 'REPORT_RATE_LIMITED', retryAfterSeconds: 600 },
        { status: 429, headers: { 'Retry-After': '600' } },
      )
    }

    const deduplicationKey = await createDeduplicationKey(payload)
    const { data, error } = await context.supabaseAdmin
      .from('issue_reports')
      .insert({
        anonymous_report_id: payload.anonymousReportId,
        anonymous_raw_record: payload.anonymousRawRecord,
        issue_type: payload.issueType,
        report_payload: payload,
        deduplication_key: deduplicationKey,
      })
      .select('id')
      .single()

    if (error?.code === '23505') {
      return Response.json({ error: 'REPORT_ALREADY_RECEIVED' }, { status: 409 })
    }
    if (error !== null) {
      console.error('issue report insert failed', error.code)
      return Response.json({ error: 'STORE_FAILED' }, { status: 500 })
    }

    return Response.json(
      { reportId: data.id, reviewStatus: 'RECEIVED' },
      { status: 202 },
    )
  }),
}

function validatePayload(payload: ReportPayload): string | null {
  if (!isUuid(payload.anonymousReportId)) return 'anonymousReportId'
  if (!isHexRecord(payload.anonymousRawRecord)) return 'anonymousRawRecord'
  if (!issueTypes.has(payload.issueType as string)) return 'issueType'
  if (!isByte(payload.regionCode)) return 'regionCode'
  if (!isByte(payload.boardingLineCode)) return 'boardingLineCode'
  if (!isByte(payload.boardingStationCode)) return 'boardingStationCode'
  if (!isByte(payload.alightingLineCode)) return 'alightingLineCode'
  if (!isByte(payload.alightingStationCode)) return 'alightingStationCode'
  if (!transactionTypes.has(payload.currentTransactionType as string)) {
    return 'currentTransactionType'
  }
  if (!isNullableDate(payload.usageDate)) return 'usageDate'
  if (!isIntegerInRange(payload.balance, 0, 65535)) return 'balance'
  if (!isNullableInteger(payload.calculatedAmount)) return 'calculatedAmount'
  if (!isNullableShortText(payload.additionalDescription, 300)) {
    return 'additionalDescription'
  }
  if (!isShortText(payload.parserVersion, 80)) return 'parserVersion'
  if (!isShortText(payload.stationDatabaseVersion, 100)) {
    return 'stationDatabaseVersion'
  }
  if (!isShortText(payload.appVersion, 40)) return 'appVersion'
  if (!isShortText(payload.platform, 20)) return 'platform'
  if (!isShortText(payload.osVersion, 160)) return 'osVersion'

  const forbiddenKeys = [
    'idm',
    'cardId',
    'cardIdentifier',
    'deviceId',
    'location',
    'latitude',
    'longitude',
    'allHistories',
  ]
  const lowerKeys = new Set(Object.keys(payload).map((key) => key.toLowerCase()))
  if (forbiddenKeys.some((key) => lowerKeys.has(key.toLowerCase()))) {
    return 'forbiddenField'
  }
  return null
}

async function createDeduplicationKey(payload: ReportPayload): Promise<string> {
  const canonical = JSON.stringify({
    anonymousRawRecord: payload.anonymousRawRecord,
    issueType: payload.issueType,
    regionCode: payload.regionCode,
    boardingLineCode: payload.boardingLineCode,
    boardingStationCode: payload.boardingStationCode,
    alightingLineCode: payload.alightingLineCode,
    alightingStationCode: payload.alightingStationCode,
    currentTransactionType: payload.currentTransactionType,
    parserVersion: payload.parserVersion,
    stationDatabaseVersion: payload.stationDatabaseVersion,
  })
  const digest = await crypto.subtle.digest(
    'SHA-256',
    new TextEncoder().encode(canonical),
  )
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('')
}

function isUuid(value: unknown): value is string {
  return typeof value === 'string' &&
    /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value)
}

function isHexRecord(value: unknown): value is string {
  return typeof value === 'string' && /^[0-9A-F]{32}$/.test(value)
}

function isByte(value: unknown): value is number {
  return isIntegerInRange(value, 0, 255)
}

function isIntegerInRange(value: unknown, minimum: number, maximum: number): value is number {
  return typeof value === 'number' &&
    Number.isInteger(value) &&
    value >= minimum &&
    value <= maximum
}

function isNullableInteger(value: unknown): boolean {
  return value === null || (typeof value === 'number' && Number.isInteger(value))
}

function isNullableDate(value: unknown): boolean {
  return value === null ||
    (typeof value === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(value))
}

function isShortText(value: unknown, maximum: number): value is string {
  return typeof value === 'string' && value.length > 0 && value.length <= maximum
}

function isNullableShortText(value: unknown, maximum: number): boolean {
  return value === null || (typeof value === 'string' && value.length <= maximum)
}
