export const statusMeta = Object.freeze({
  RECEIVED: { label: '신규 접수', tone: 'blue' },
  REVIEWING: { label: '확인 중', tone: 'amber' },
  VERIFIED: { label: '수정 확정', tone: 'violet' },
  APPLIED: { label: '반영 완료', tone: 'green' },
  REJECTED: { label: '제외', tone: 'gray' },
})

export const issueTypeLabels = Object.freeze({
  WRONG_STATION_NAME: '역 정보가 없거나 잘못됨',
  WRONG_BOARDING_STATION: '승차역이 잘못됨',
  WRONG_ALIGHTING_STATION: '하차역이 잘못됨',
  WRONG_BOTH_STATIONS: '승차역과 하차역이 모두 잘못됨',
  STATION_NOT_RESOLVED: '역명이 표시되지 않음',
  BUS_COMPANY_NOT_RESOLVED: '버스 회사 정보가 없거나 잘못됨',
  KOREAN_STATION_NAME_REQUEST: '역명 한글 표기 추가 요청',
  WRONG_TRANSACTION_TYPE: '이용 유형이 잘못됨',
  WRONG_AMOUNT_OR_BALANCE: '금액 또는 잔액이 잘못됨',
  OTHER: '기타 문제',
})

export function filterReports(reports, { search = '', status = '', issueType = '' }) {
  const needle = search.trim().toLocaleLowerCase('ko-KR')
  return reports.filter((report) => {
    if (status && report.review_status !== status) return false
    if (issueType && report.issue_type !== issueType) return false
    if (!needle) return true
    return searchableText(report).includes(needle)
  })
}

export function selectedBulkUpdateIds(reports, filters, selectedIds) {
  if (!filters.status) return []
  const selected = new Set(selectedIds)
  return filterReports(reports, filters)
    .map((report) => report.id)
    .filter((id) => selected.has(id))
}

export function summarizeReports(reports) {
  const summary = Object.fromEntries(
    Object.keys(statusMeta).map((status) => [status, 0]),
  )
  for (const report of reports) {
    if (report.review_status in summary) summary[report.review_status] += 1
  }
  return summary
}

export function formatDateTime(value) {
  if (!value) return '기록 없음'
  const date = new Date(value)
  if (Number.isNaN(date.valueOf())) return String(value)
  return new Intl.DateTimeFormat('ko-KR', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  }).format(date)
}

export function formatDate(value) {
  if (!value) return '날짜 미확인'
  const date = new Date(value)
  if (Number.isNaN(date.valueOf())) return String(value)
  return new Intl.DateTimeFormat('ko-KR', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(date)
}

export function formatCurrency(value, transactionType = '') {
  if (!Number.isInteger(value)) return '계산 불가'
  const prefix = transactionType === 'CHARGE' ? '+' : '-'
  return `${prefix}¥${Math.abs(value).toLocaleString('ko-KR')}`
}

export function routeLabel(payload) {
  const boarding = currentStationName(payload, 'boarding') ??
    readName(payload, 'boarding', 'currentName') ??
    codeLabel(payload, 'boarding')
  const alighting = currentStationName(payload, 'alighting') ??
    readName(payload, 'alighting', 'currentName') ??
    codeLabel(payload, 'alighting')
  if (boarding && alighting) return `${boarding} → ${alighting}`
  return transactionTypeLabel(payload?.currentTransactionType)
}

export function transactionTypeLabel(value) {
  return {
    RAIL: '철도 이용',
    BUS: '버스 이용',
    PURCHASE: '물품 구매',
    CHARGE: '충전',
    GATE_WINDOW_PROCESSING: '개찰 창구 처리',
    REFUND: '환불',
    ADJUSTMENT: '정산',
    UNKNOWN: '유형 미확인',
  }[value] ?? '유형 미확인'
}

export function reportFields(report) {
  const payload = report.report_payload ?? {}
  const fields = [
    ['제보 유형', issueTypeLabels[report.issue_type] ?? report.issue_type],
    ['원본 16바이트', report.anonymous_raw_record],
    ['현재 거래 유형', transactionTypeLabel(payload.currentTransactionType)],
    ['이용 날짜', payload.usageDate ?? '확인 불가'],
    ['잔액', Number.isInteger(payload.balance) ? `¥${payload.balance.toLocaleString('ko-KR')}` : '확인 불가'],
    ['계산 금액', formatCurrency(payload.calculatedAmount, payload.currentTransactionType)],
  ]

  if (stationIssueTypes.has(report.issue_type)) {
    return [
      ...fields,
      ...stationReportFields(report.issue_type, payload),
      ...optionalDescriptionField(payload),
      ...environmentFields(payload),
    ]
  }

  if (report.issue_type === 'KOREAN_STATION_NAME_REQUEST') {
    return [
      ...fields,
      ...koreanStationNameFields(payload),
      ...environmentFields(payload),
    ]
  }

  if (report.issue_type === 'BUS_COMPANY_NOT_RESOLVED') {
    return [
      ...fields,
      ['제안 버스 회사', busCompanyLabel(payload)],
      ['운행 도시·지역', payload.suggestedBusCompanyCity ?? '입력 없음'],
      ...environmentFields(payload),
    ]
  }

  if (report.issue_type === 'WRONG_TRANSACTION_TYPE') {
    return [
      ...fields,
      ['제안 거래 유형', suggestedTransactionLabel(payload)],
      ...optionalDescriptionField(payload),
      ...environmentFields(payload),
    ]
  }

  return [
    ...fields,
    ...optionalDescriptionField(payload),
    ...environmentFields(payload),
  ]
}

const stationIssueTypes = new Set([
  'WRONG_STATION_NAME',
  'WRONG_BOARDING_STATION',
  'WRONG_ALIGHTING_STATION',
  'WRONG_BOTH_STATIONS',
  'STATION_NOT_RESOLVED',
])

function stationReportFields(issueType, payload) {
  const directions = stationDirections(issueType, payload.stationIssueScope)
  const fields = [
    ['역명 지정 범위', stationIssueScopeLabel(payload.stationIssueScope)],
  ]
  for (const direction of directions) {
    const label = direction === 'boarding' ? '승차역' : '하차역'
    const correction = direction === 'boarding'
      ? payload.correctedBoardingStation
      : payload.correctedAlightingStation
    fields.push(
      [`파서 확인 ${label}`, currentStationName(payload, direction) ?? 'null'],
      [`제안 ${label}`, stationCorrectionLabel(correction) ??
        readName(payload, direction, 'suggestedName') ?? '입력 없음'],
    )
  }
  return fields
}

function stationDirections(issueType, scope) {
  if (scope === 'BOARDING') return ['boarding']
  if (scope === 'ALIGHTING') return ['alighting']
  if (scope === 'BOTH') return ['boarding', 'alighting']
  if (issueType === 'WRONG_BOARDING_STATION') return ['boarding']
  if (issueType === 'WRONG_ALIGHTING_STATION') return ['alighting']
  return ['boarding', 'alighting']
}

function optionalDescriptionField(payload) {
  const description = nonEmptyText(payload.additionalDescription)
  return description === null ? [] : [['추가 설명', description]]
}

function environmentFields(payload) {
  return [
    ['앱 버전', payload.appVersion ?? '확인 불가'],
    ['파서 / 역 DB', `${payload.parserVersion ?? '-'} / ${payload.stationDatabaseVersion ?? '-'}`],
    ['플랫폼', `${payload.platform ?? '-'} ${payload.osVersion ?? ''}`.trim()],
  ]
}

function koreanStationNameFields(payload) {
  const legacyName = nonEmptyText(payload.suggestedKoreanStationName)
  const scope = payload.stationIssueScope
  const fields = [['역명 지정 범위', stationIssueScopeLabel(scope)]]
  for (const direction of stationDirections('KOREAN_STATION_NAME_REQUEST', scope)) {
    const isBoarding = direction === 'boarding'
    const label = isBoarding ? '승차역' : '하차역'
    const name = nonEmptyText(isBoarding
      ? payload.suggestedKoreanBoardingStationName
      : payload.suggestedKoreanAlightingStationName) ??
      ((isBoarding && scope === 'BOARDING') || (!isBoarding && scope === 'ALIGHTING')
        ? legacyName
        : null)
    fields.push(
      [`파서 확인 ${label}`, currentStationName(payload, direction) ?? 'null'],
      [`제안 ${label} 한글 표기`, name ?? '입력 없음'],
    )
  }

  // Older app versions sent one unscoped field. Keep it visible rather than
  // guessing which station it belonged to when both stations were selected.
  if (legacyName !== null && scope === 'BOTH') {
    fields.push(['제안 한글 역명 (기존 앱)', legacyName])
  }
  return fields
}

function stationIssueScopeLabel(value) {
  return { BOARDING: '승차역', ALIGHTING: '하차역', BOTH: '승차역과 하차역 모두' }[value] ?? '해당 없음'
}

function stationCorrectionLabel(value) {
  if (!value || typeof value !== 'object') return null
  const parts = [value.name, value.city, value.line]
    .filter((part) => typeof part === 'string' && part.length > 0)
  return parts.length > 0 ? parts.join(' · ') : null
}

function suggestedTransactionLabel(payload) {
  if (payload.suggestedTransactionType === 'OTHER') {
    return payload.customSuggestedTransactionType || '직접 입력 없음'
  }
  return payload.suggestedTransactionType
    ? transactionTypeLabel(payload.suggestedTransactionType)
    : '입력 없음'
}

function busCompanyLabel(payload) {
  return typeof payload.suggestedBusCompanyName === 'string' &&
      payload.suggestedBusCompanyName.length > 0
    ? payload.suggestedBusCompanyName
    : '입력 없음'
}

function searchableText(report) {
  return [
    report.anonymous_raw_record,
    report.issue_type,
    report.review_status,
    JSON.stringify(report.report_payload ?? {}),
    report.review_note,
    report.applied_app_version,
  ]
    .filter(Boolean)
    .join(' ')
    .toLocaleLowerCase('ko-KR')
}

function readName(payload, group, field) {
  const value = payload?.[group]
  return value && typeof value === 'object' && typeof value[field] === 'string'
    ? value[field]
    : null
}

function currentStationName(payload, direction) {
  const field = direction === 'boarding'
    ? 'currentBoardingStation'
    : 'currentAlightingStation'
  const value = payload?.[field]
  return typeof value === 'string' && value.trim().length > 0 ? value : null
}

function nonEmptyText(value) {
  return typeof value === 'string' && value.trim().length > 0 ? value : null
}

function codeLabel(payload, prefix) {
  const nested = payload?.[prefix]
  const line = nested?.lineCode ?? payload?.[`${prefix}LineCode`]
  const station = nested?.stationCode ?? payload?.[`${prefix}StationCode`]
  if (!Number.isInteger(line) || !Number.isInteger(station)) return null
  return `${toHex(line)}-${toHex(station)}`
}

function toHex(value) {
  return value.toString(16).toUpperCase().padStart(2, '0')
}
