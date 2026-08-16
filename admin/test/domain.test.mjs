import test from 'node:test'
import assert from 'node:assert/strict'
import {
  filterReports,
  formatDate,
  formatCurrency,
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
