import test from 'node:test'
import assert from 'node:assert/strict'
import { clampInteger } from '../../supabase/functions/issue-report-admin/query_parameters.mjs'

test('uses the requested fallback when the limit parameter is absent or empty', () => {
  assert.equal(clampInteger(null, 1, 200, 100), 100)
  assert.equal(clampInteger('', 1, 200, 100), 100)
  assert.equal(clampInteger('  ', 1, 200, 100), 100)
})

test('clamps valid integers and rejects invalid values', () => {
  assert.equal(clampInteger('20', 1, 200, 100), 20)
  assert.equal(clampInteger('0', 1, 200, 100), 1)
  assert.equal(clampInteger('201', 1, 200, 100), 200)
  assert.equal(clampInteger('invalid', 1, 200, 100), 100)
})
