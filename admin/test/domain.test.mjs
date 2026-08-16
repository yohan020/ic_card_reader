import test from 'node:test'
import assert from 'node:assert/strict'
import {
  filterReports,
  formatDate,
  formatCurrency,
  reportFields,
  routeLabel,
  selectedBulkUpdateIds,
  summarizeReports,
} from '../src/domain.mjs'

const reports = [
  {
    id: 'one',
    issue_type: 'WRONG_BOARDING_STATION',
    review_status: 'RECEIVED',
    anonymous_raw_record: '1601000234FCC501C517FF04000051F0',
    report_payload: {
      boarding: { currentName: '郡中港', suggestedName: '郡中' },
      alighting: { currentName: '松山市' },
      currentTransactionType: 'RAIL',
    },
  },
  {
    id: 'two',
    issue_type: 'OTHER',
    review_status: 'APPLIED',
    anonymous_raw_record: 'C849000032B772CAF746581600001400',
    report_payload: { currentTransactionType: 'CHARGE' },
    review_note: '충전 분류 반영',
  },
]

test('filters reports by status and Korean station text', () => {
  assert.deepEqual(
    filterReports(reports, { search: '군중'.replace('군중', '郡中'), status: 'RECEIVED' }).map((item) => item.id),
    ['one'],
  )
  assert.deepEqual(
    filterReports(reports, { search: '', status: 'APPLIED' }).map((item) => item.id),
    ['two'],
  )
})

test('summarizes all supported review statuses', () => {
  assert.deepEqual(summarizeReports(reports), {
    RECEIVED: 1,
    REVIEWING: 0,
    VERIFIED: 0,
    APPLIED: 1,
    REJECTED: 0,
  })
})

test('formats route and charge amounts conservatively', () => {
  assert.equal(routeLabel(reports[0].report_payload), '郡中港 → 松山市')
  assert.equal(formatCurrency(5000, 'CHARGE'), '+¥5,000')
  assert.equal(formatCurrency(null, 'RAIL'), '계산 불가')
})

test('shows parser-confirmed station names and explicit nulls in the detail fields', () => {
  const confirmed = {
    currentTransactionType: 'RAIL',
    currentBoardingStation: '名鉄名古屋',
    currentAlightingStation: '中部国際空港',
  }
  const missing = { currentTransactionType: 'RAIL' }

  assert.equal(routeLabel(confirmed), '名鉄名古屋 → 中部国際空港')
  assert.deepEqual(
    reportFields({
      issue_type: 'WRONG_STATION_NAME',
      anonymous_raw_record: 'A'.repeat(32),
      report_payload: { ...confirmed, stationIssueScope: 'BOTH' },
    })
      .filter(([label]) => label.startsWith('파서 확인')),
    [
      ['파서 확인 승차역', '名鉄名古屋'],
      ['파서 확인 하차역', '中部国際空港'],
    ],
  )
  assert.deepEqual(
    reportFields({
      issue_type: 'STATION_NOT_RESOLVED',
      anonymous_raw_record: 'A'.repeat(32),
      report_payload: { ...missing, stationIssueScope: 'BOTH' },
    })
      .filter(([label]) => label.startsWith('파서 확인')),
    [
      ['파서 확인 승차역', 'null'],
      ['파서 확인 하차역', 'null'],
    ],
  )
})

test('shows only station fields for a station report and only bus fields for a bus report', () => {
  const stationFields = reportFields({
    issue_type: 'WRONG_BOARDING_STATION',
    anonymous_raw_record: 'A'.repeat(32),
    report_payload: {
      stationIssueScope: 'BOARDING',
      currentBoardingStation: '渋谷',
      correctedBoardingStation: { name: '新宿', city: '東京都新宿区', line: '山手線' },
    },
  })
  const busFields = reportFields({
    issue_type: 'BUS_COMPANY_NOT_RESOLVED',
    anonymous_raw_record: 'B'.repeat(32),
    report_payload: {
      suggestedBusCompanyName: '都営バス',
      suggestedBusCompanyCity: '東京都',
    },
  })

  assert.deepEqual(
    stationFields.filter(([label]) => label.startsWith('제안 ')),
    [['제안 승차역', '新宿 · 東京都新宿区 · 山手線']],
  )
  assert.equal(stationFields.some(([label]) => label === '제안 버스 회사'), false)
  assert.deepEqual(
    busFields.filter(([label]) => label.startsWith('제안 ') || label === '운행 도시·지역'),
    [['제안 버스 회사', '都営バス'], ['운행 도시·지역', '東京都']],
  )
  assert.equal(busFields.some(([label]) => label === '제안 승차역'), false)
})

test('shows the proposed Korean station name in the report detail', () => {
  const fields = reportFields({
    issue_type: 'KOREAN_STATION_NAME_REQUEST',
    anonymous_raw_record: 'A'.repeat(32),
    report_payload: {
      suggestedKoreanBoardingStationName: '시부야',
      suggestedKoreanAlightingStationName: '아사쿠사',
    },
  })

  assert.deepEqual(
    fields.filter(([label]) => label.includes('한글 표기')),
    [
      ['제안 승차역 한글 표기', '시부야'],
      ['제안 하차역 한글 표기', '아사쿠사'],
    ],
  )
})

test('keeps a proposed Korean station name from the previous app format visible', () => {
  const fields = reportFields({
    issue_type: 'KOREAN_STATION_NAME_REQUEST',
    anonymous_raw_record: 'A'.repeat(32),
    report_payload: {
      stationIssueScope: 'BOTH',
      suggestedKoreanStationName: '시부야·아사쿠사',
    },
  })

  assert.deepEqual(
    fields.find(([label]) => label === '제안 한글 역명 (기존 앱)'),
    ['제안 한글 역명 (기존 앱)', '시부야·아사쿠사'],
  )
})

test('formats list dates without transaction details or time', () => {
  const formatted = formatDate('2026-08-13T19:59:00+09:00')
  assert.match(formatted, /2026/)
  assert.match(formatted, /08/)
  assert.match(formatted, /13/)
  assert.doesNotMatch(formatted, /19|59/)
})

test('bulk updates include only checked reports in the current non-all status list', () => {
  assert.deepEqual(
    selectedBulkUpdateIds(
      reports,
      {
        search: '郡中',
        status: 'RECEIVED',
        issueType: 'WRONG_BOARDING_STATION',
      },
      ['one', 'two'],
    ),
    ['one'],
  )
  assert.deepEqual(
    selectedBulkUpdateIds(
      reports,
      { search: '', status: 'RECEIVED', issueType: '' },
      ['two'],
    ),
    [],
  )
  assert.deepEqual(
    selectedBulkUpdateIds(
      reports,
      { search: '', status: '', issueType: '' },
      ['one'],
    ),
    [],
  )
})
