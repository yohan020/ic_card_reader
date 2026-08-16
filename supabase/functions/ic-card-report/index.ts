import { withSupabase } from 'npm:@supabase/server@^1'

const issueTypes = new Set([
  'WRONG_STATION_NAME',
  'WRONG_BOARDING_STATION',
  'WRONG_ALIGHTING_STATION',
  'WRONG_BOTH_STATIONS',
  'STATION_NOT_RESOLVED',
  'BUS_COMPANY_NOT_RESOLVED',
  'WRONG_TRANSACTION_TYPE',
  'WRONG_AMOUNT_OR_BALANCE',
  'OTHER',
])

const stationIssueScopes = new Set(['BOARDING', 'ALIGHTING', 'BOTH'])

const suggestedTransactionTypes = new Set([
  'RAIL',
  'BUS',
  'PURCHASE',
  'CHARGE',
  'GATE_WINDOW_PROCESSING',
  'REFUND',
  'ADJUSTMENT',
  'OTHER',
])

const transactionTypes = new Set([
  'RAIL',
  'BUS',
  'PURCHASE',
  'CHARGE',
  'GATE_WINDOW_PROCESSING',
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

    const { data: reporterBlocked, error: blockCheckError } =
      await context.supabaseAdmin.rpc('is_issue_reporter_blocked', {
        p_reporter_auth_user_id: anonymousUserId,
      })
    if (blockCheckError !== null) {
      console.error('issue report block check failed', blockCheckError.code)
      return Response.json({ error: 'BLOCK_CHECK_FAILED' }, { status: 500 })
    }
    if (reporterBlocked === true) {
      return Response.json({ error: 'REPORTER_BLOCKED' }, { status: 403 })
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
        reporter_auth_user_id: anonymousUserId,
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
  if (!isNullableStationIssueScope(payload.stationIssueScope)) {
    return 'stationIssueScope'
  }
  if (!isNullableStationCorrection(payload.correctedBoardingStation)) {
    return 'correctedBoardingStation'
  }
  if (!isNullableStationCorrection(payload.correctedAlightingStation)) {
    return 'correctedAlightingStation'
  }
  if (!isNullableShortText(payload.suggestedBusCompanyName, 80)) {
    return 'suggestedBusCompanyName'
  }
  if (!isNullableShortText(payload.suggestedBusCompanyCity, 80)) {
    return 'suggestedBusCompanyCity'
  }
  if (!isNullableShortText(payload.suggestedTransactionType, 40)) {
    return 'suggestedTransactionType'
  }
  if (!isNullableShortText(payload.customSuggestedTransactionType, 80)) {
    return 'customSuggestedTransactionType'
  }
  const correctionError = validateCorrectionForIssue(payload)
  if (correctionError !== null) return correctionError
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

function validateCorrectionForIssue(payload: ReportPayload): string | null {
  const issueType = payload.issueType
  const scope = payload.stationIssueScope ?? null
  const boarding = payload.correctedBoardingStation ?? null
  const alighting = payload.correctedAlightingStation ?? null
  const suggestion = payload.suggestedTransactionType ?? null
  const customSuggestion = payload.customSuggestedTransactionType ?? null
  const busCompanyName = payload.suggestedBusCompanyName ?? null
  const busCompanyCity = payload.suggestedBusCompanyCity ?? null

  if (
    issueType !== 'BUS_COMPANY_NOT_RESOLVED' &&
    (busCompanyName !== null || busCompanyCity !== null)
  ) {
    return 'unexpectedCorrectionField'
  }

  if (issueType === 'WRONG_STATION_NAME') {
    return validateScopedStationCorrection(scope, boarding, alighting)
  }
  if (issueType === 'WRONG_BOARDING_STATION') {
    if (hasNoStationCorrection(scope, boarding, alighting)) return null
    return scope === 'BOARDING' && boarding !== null && alighting === null
      ? null
      : 'stationCorrection'
  }
  if (issueType === 'WRONG_ALIGHTING_STATION') {
    if (hasNoStationCorrection(scope, boarding, alighting)) return null
    return scope === 'ALIGHTING' && boarding === null && alighting !== null
      ? null
      : 'stationCorrection'
  }
  if (issueType === 'WRONG_BOTH_STATIONS') {
    if (hasNoStationCorrection(scope, boarding, alighting)) return null
    return scope === 'BOTH' && boarding !== null && alighting !== null
      ? null
      : 'stationCorrection'
  }
  if (issueType === 'STATION_NOT_RESOLVED') {
    if (hasNoStationCorrection(scope, boarding, alighting)) return null
    return validateScopedStationCorrection(scope, boarding, alighting)
  }
  if (issueType === 'BUS_COMPANY_NOT_RESOLVED') {
    if (payload.currentTransactionType !== 'BUS') return 'currentTransactionType'
    if (!isShortText(busCompanyName, 80)) return 'suggestedBusCompanyName'
    if (!isShortText(busCompanyCity, 80)) return 'suggestedBusCompanyCity'
    return scope === null && boarding === null && alighting === null &&
        suggestion === null && customSuggestion === null
      ? null
      : 'unexpectedCorrectionField'
  }
  if (issueType === 'WRONG_TRANSACTION_TYPE') {
    if (!suggestedTransactionTypes.has(suggestion as string)) {
      return 'suggestedTransactionType'
    }
    if (suggestion === 'OTHER') {
      return typeof customSuggestion === 'string' && customSuggestion.length > 0
        ? null
        : 'customSuggestedTransactionType'
    }
    return customSuggestion === null ? null : 'customSuggestedTransactionType'
  }
  return scope === null && boarding === null && alighting === null &&
      busCompanyName === null && busCompanyCity === null && suggestion === null &&
      customSuggestion === null
    ? null
    : 'unexpectedCorrectionField'
}

function hasNoStationCorrection(
  scope: unknown,
  boarding: unknown,
  alighting: unknown,
): boolean {
  return scope === null && boarding === null && alighting === null
}

function validateScopedStationCorrection(
  scope: unknown,
  boarding: unknown,
  alighting: unknown,
): string | null {
  if (!stationIssueScopes.has(scope as string)) return 'stationIssueScope'
  const hasExpectedBoarding = scope !== 'ALIGHTING' ? boarding !== null : boarding === null
  const hasExpectedAlighting = scope !== 'BOARDING' ? alighting !== null : alighting === null
  return hasExpectedBoarding && hasExpectedAlighting ? null : 'stationCorrection'
}

async function createDeduplicationKey(payload: ReportPayload): Promise<string> {
  const canonical: Record<string, unknown> = {
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
  }
  for (const field of [
    'stationIssueScope',
    'correctedBoardingStation',
    'correctedAlightingStation',
    'suggestedBusCompanyName',
    'suggestedBusCompanyCity',
    'suggestedTransactionType',
    'customSuggestedTransactionType',
  ]) {
    const value = payload[field]
    if (value != null) canonical[field] = value
  }
  const digest = await crypto.subtle.digest(
    'SHA-256',
    new TextEncoder().encode(JSON.stringify(canonical)),
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
  return value == null || (typeof value === 'string' && value.length <= maximum)
}

function isNullableStationIssueScope(value: unknown): boolean {
  return value == null || stationIssueScopes.has(value as string)
}

function isNullableStationCorrection(value: unknown): boolean {
  if (value == null) return true
  if (typeof value !== 'object' || Array.isArray(value)) return false
  const correction = value as Record<string, unknown>
  const allowedKeys = new Set(['name', 'city', 'line'])
  if (Object.keys(correction).some((key) => !allowedKeys.has(key))) return false
  return isShortText(correction.name, 80) &&
    isShortText(correction.city, 80) &&
    isNullableShortText(correction.line, 100)
}
