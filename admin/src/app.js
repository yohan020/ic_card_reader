import { adminConfig } from '../config.js'
import {
  filterReports,
  formatCurrency,
  formatDate,
  formatDateTime,
  issueTypeLabels,
  reportFields,
  routeLabel,
  selectedBulkUpdateIds,
  statusMeta,
  summarizeReports,
  transactionTypeLabel,
} from './domain.mjs'

const sessionKey = 'ic-card-admin-session'
const state = {
  session: readSession(),
  reports: [],
  totalCount: 0,
  selectedId: null,
  selectedBulkIds: new Set(),
  pendingBulkUpdate: null,
}

const elements = Object.fromEntries(
  [
    'login-view', 'dashboard-view', 'login-form', 'login-error', 'email', 'password',
    'admin-email', 'refresh-button', 'logout-button', 'summary', 'report-count',
    'search-input', 'status-filter', 'type-filter', 'loading-state', 'report-list',
    'empty-detail', 'report-detail', 'detail-created', 'detail-title', 'detail-status',
    'route-card', 'payload-fields', 'payload-json', 'review-form', 'review-status',
    'applied-version', 'review-note', 'save-message', 'save-button',
    'reporter-block-description', 'reporter-block-message', 'reporter-block-button',
    'bulk-actions', 'bulk-target-count', 'bulk-status', 'bulk-open-button',
    'bulk-select-all',
    'bulk-message', 'bulk-confirm-dialog', 'bulk-confirm-description',
    'bulk-cancel-button', 'bulk-confirm-button',
  ].map((id) => [id, document.getElementById(id)]),
)

elements['login-form'].addEventListener('submit', signIn)
elements['logout-button'].addEventListener('click', signOut)
elements['refresh-button'].addEventListener('click', loadReports)
elements['review-form'].addEventListener('submit', saveReview)
elements['reporter-block-button'].addEventListener('click', toggleReporterBlock)
elements['bulk-open-button'].addEventListener('click', openBulkConfirmation)
elements['bulk-select-all'].addEventListener('change', toggleSelectAll)
elements['bulk-cancel-button'].addEventListener('click', closeBulkConfirmation)
elements['bulk-confirm-button'].addEventListener('click', saveBulkReview)
for (const id of ['search-input', 'status-filter', 'type-filter']) {
  elements[id].addEventListener(id === 'search-input' ? 'input' : 'change', () => {
    state.selectedBulkIds.clear()
    renderList()
  })
}

if (state.session?.accessToken) {
  showDashboard(state.session.email)
  loadReports()
} else {
  showLogin()
}

async function signIn(event) {
  event.preventDefault()
  setLoginError('')
  const submit = elements['login-form'].querySelector('button[type="submit"]')
  submit.disabled = true
  submit.textContent = '로그인 중…'
  try {
    const response = await fetch(
      `${adminConfig.supabaseUrl}/auth/v1/token?grant_type=password`,
      {
        method: 'POST',
        headers: {
          apikey: adminConfig.publishableKey,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          email: elements.email.value.trim(),
          password: elements.password.value,
        }),
      },
    )
    const body = await readJson(response)
    if (!response.ok || !body.access_token) {
      throw new Error(loginErrorMessage(body))
    }
    state.session = {
      accessToken: body.access_token,
      email: body.user?.email ?? elements.email.value.trim(),
    }
    sessionStorage.setItem(sessionKey, JSON.stringify(state.session))
    elements.password.value = ''
    showDashboard(state.session.email)
    await loadReports()
  } catch (error) {
    setLoginError(error.message || '로그인하지 못했습니다.')
  } finally {
    submit.disabled = false
    submit.textContent = '관리자 로그인'
  }
}

function signOut() {
  sessionStorage.removeItem(sessionKey)
  state.session = null
  state.reports = []
  state.totalCount = 0
  state.selectedId = null
  state.selectedBulkIds.clear()
  state.pendingBulkUpdate = null
  showLogin()
}

async function loadReports() {
  elements['loading-state'].hidden = false
  elements['loading-state'].textContent = '문의 데이터를 불러오는 중입니다.'
  elements['report-list'].replaceChildren()
  elements['refresh-button'].disabled = true
  try {
    const body = await adminRequest('', { method: 'GET' })
    state.reports = Array.isArray(body.reports) ? body.reports : []
    state.totalCount = Number.isInteger(body.count)
      ? body.count
      : state.reports.length
    const availableIds = new Set(state.reports.map((report) => report.id))
    state.selectedBulkIds = new Set(
      [...state.selectedBulkIds].filter((id) => availableIds.has(id)),
    )
    if (state.selectedId && !state.reports.some((report) => report.id === state.selectedId)) {
      state.selectedId = null
    }
    renderSummary()
    renderList()
    renderDetail()
  } catch (error) {
    if (error.status === 401 || error.status === 403) {
      signOut()
      setLoginError(
        error.status === 403
          ? '이 계정에는 관리자 권한이 없습니다.'
          : '세션이 만료되었습니다. 다시 로그인해 주세요.',
      )
      return
    }
    elements['loading-state'].hidden = false
    elements['loading-state'].textContent = `문의 데이터를 불러오지 못했습니다. ${error.message}`
  } finally {
    elements['refresh-button'].disabled = false
  }
}

function renderSummary() {
  const summary = summarizeReports(state.reports)
  elements.summary.replaceChildren()
  for (const [status, meta] of Object.entries(statusMeta)) {
    const button = document.createElement('button')
    button.type = 'button'
    button.className = `summary-card tone-${meta.tone}`
    button.innerHTML = '<span class="summary-label"></span><strong></strong><span class="summary-hint">불러온 문의</span>'
    button.querySelector('.summary-label').textContent = meta.label
    button.querySelector('strong').textContent = summary[status]
    button.addEventListener('click', () => {
      elements['status-filter'].value = status
      state.selectedBulkIds.clear()
      renderList()
    })
    elements.summary.append(button)
  }
}

function renderList() {
  const reports = filteredReports()
  elements['report-list'].replaceChildren()
  elements['report-count'].textContent = state.totalCount === reports.length
    ? `${reports.length}건`
    : `표시 ${reports.length} / 전체 ${state.totalCount}건`
  renderBulkActions(reports)
  elements['loading-state'].hidden = reports.length > 0
  if (reports.length === 0) {
    elements['loading-state'].textContent = state.reports.length === 0
      ? '접수된 문의가 없습니다.'
      : '조건에 맞는 문의가 없습니다.'
    return
  }

  const selectionEnabled = elements['status-filter'].value !== ''
  reports.forEach((report, index) => {
    const checked = state.selectedBulkIds.has(report.id)
    const item = document.createElement('div')
    item.className = [
      'report-item',
      selectionEnabled ? 'selectable' : '',
      report.id === state.selectedId ? 'selected' : '',
      checked ? 'checked' : '',
    ].filter(Boolean).join(' ')

    if (selectionEnabled) {
      const selection = document.createElement('label')
      selection.className = 'report-selection'
      const checkbox = document.createElement('input')
      checkbox.type = 'checkbox'
      checkbox.checked = checked
      checkbox.setAttribute('aria-label', `목록 ${index + 1} 선택`)
      checkbox.addEventListener('change', () => {
        if (checkbox.checked) {
          state.selectedBulkIds.add(report.id)
          item.classList.add('checked')
        } else {
          state.selectedBulkIds.delete(report.id)
          item.classList.remove('checked')
        }
        renderBulkActions(reports)
      })
      selection.append(checkbox)
      item.append(selection)
    }

    const button = document.createElement('button')
    button.type = 'button'
    button.className = 'report-content'
    const header = document.createElement('div')
    header.className = 'report-list-heading'
    const number = document.createElement('span')
    number.className = 'report-number'
    number.textContent = `#${String(index + 1).padStart(2, '0')}`
    const type = document.createElement('span')
    type.className = 'report-type'
    type.textContent = issueTypeLabels[report.issue_type] ?? report.issue_type
    header.append(number, type)
    const date = document.createElement('time')
    date.className = 'report-date'
    date.dateTime = report.created_at ?? ''
    date.textContent = formatDate(report.created_at)
    button.append(header, date)
    button.addEventListener('click', () => {
      state.selectedId = report.id
      renderList()
      renderDetail()
    })
    item.append(button)
    elements['report-list'].append(item)
  })
}

function renderBulkActions(reports) {
  const currentStatus = elements['status-filter'].value
  const enabled = currentStatus !== '' && reports.length > 0
  elements['bulk-actions'].hidden = !enabled
  if (!enabled) return

  const ids = selectedBulkUpdateIds(state.reports, currentFilters(), state.selectedBulkIds)
  const allSelected = ids.length === reports.length
  elements['bulk-select-all'].checked = allSelected
  elements['bulk-select-all'].indeterminate = ids.length > 0 && !allSelected
  elements['bulk-target-count'].textContent = `${ids.length}건 선택됨`
  elements['bulk-open-button'].disabled = ids.length === 0
  const options = [...elements['bulk-status'].options]
  for (const option of options) option.disabled = option.value === currentStatus
  if (elements['bulk-status'].value === currentStatus) {
    elements['bulk-status'].value = options.find((option) => !option.disabled)?.value ?? ''
  }
}

function toggleSelectAll() {
  const reports = filteredReports()
  if (elements['bulk-select-all'].checked) {
    for (const report of reports) state.selectedBulkIds.add(report.id)
  } else {
    for (const report of reports) state.selectedBulkIds.delete(report.id)
  }
  renderList()
}

function openBulkConfirmation() {
  const filters = currentFilters()
  const ids = selectedBulkUpdateIds(state.reports, filters, state.selectedBulkIds)
  const targetStatus = elements['bulk-status'].value
  if (ids.length === 0 || !filters.status || targetStatus === filters.status) return

  state.pendingBulkUpdate = { ids, targetStatus }
  const sourceLabel = statusMeta[filters.status]?.label ?? filters.status
  const targetLabel = statusMeta[targetStatus]?.label ?? targetStatus
  elements['bulk-confirm-description'].textContent =
    `체크한 ${sourceLabel} 문의 ${ids.length}건을 ${targetLabel} 상태로 변경합니다.`
  elements['bulk-confirm-dialog'].showModal()
}

function closeBulkConfirmation() {
  state.pendingBulkUpdate = null
  elements['bulk-confirm-dialog'].close()
}

async function saveBulkReview() {
  const pending = state.pendingBulkUpdate
  if (pending === null) return
  const button = elements['bulk-confirm-button']
  button.disabled = true
  elements['bulk-cancel-button'].disabled = true
  button.textContent = '변경 중…'
  try {
    const body = await adminRequest('', {
      method: 'PATCH',
      body: JSON.stringify({
        ids: pending.ids,
        reviewStatus: pending.targetStatus,
      }),
    })
    if (pending.ids.includes(state.selectedId)) state.selectedId = null
    state.selectedBulkIds.clear()
    state.pendingBulkUpdate = null
    elements['bulk-confirm-dialog'].close()
    await loadReports()
    elements['bulk-message'].textContent = `${body.updatedCount ?? pending.ids.length}건의 상태를 변경했습니다.`
  } catch (error) {
    state.pendingBulkUpdate = null
    elements['bulk-confirm-dialog'].close()
    elements['bulk-message'].textContent = `일괄 변경하지 못했습니다. ${error.message}`
  } finally {
    button.disabled = false
    elements['bulk-cancel-button'].disabled = false
    button.textContent = '변경하기'
  }
}

function renderDetail() {
  const report = selectedReport()
  elements['empty-detail'].hidden = report !== null
  elements['report-detail'].hidden = report === null
  if (report === null) return

  const payload = report.report_payload ?? {}
  elements['detail-created'].textContent = `접수 ${formatDateTime(report.created_at)}`
  elements['detail-title'].textContent = issueTypeLabels[report.issue_type] ?? report.issue_type
  elements['detail-status'].replaceWith(createStatusBadge(report.review_status, 'detail-status'))
  elements['detail-status'] = document.getElementById('detail-status')

  const routeCard = elements['route-card']
  routeCard.replaceChildren()
  const route = document.createElement('div')
  route.className = 'route-main'
  route.textContent = routeLabel(payload)
  const routeMeta = document.createElement('div')
  routeMeta.className = 'route-meta'
  routeMeta.textContent = [
    transactionTypeLabel(payload.currentTransactionType),
    payload.usageDate ?? '날짜 미확인',
    formatCurrency(payload.calculatedAmount, payload.currentTransactionType),
  ].join(' · ')
  const raw = document.createElement('code')
  raw.textContent = report.anonymous_raw_record
  routeCard.append(route, routeMeta, raw)

  elements['payload-fields'].replaceChildren()
  for (const [label, value] of reportFields(report)) {
    const row = document.createElement('div')
    const term = document.createElement('dt')
    const description = document.createElement('dd')
    term.textContent = label
    description.textContent = String(value)
    row.append(term, description)
    elements['payload-fields'].append(row)
  }
  elements['payload-json'].textContent = JSON.stringify(payload, null, 2)
  elements['review-status'].value = report.review_status
  elements['applied-version'].value = report.applied_app_version ?? ''
  elements['review-note'].value = report.review_note ?? ''
  elements['save-message'].textContent = ''
  const hasReporterIdentity = report.reporter_identity_available === true ||
    report.reporter_is_blocked === true
  const isBlocked = report.reporter_is_blocked === true
  elements['reporter-block-button'].disabled = !hasReporterIdentity
  elements['reporter-block-button'].textContent = isBlocked
    ? '제보자 차단 해제'
    : '제보자 차단'
  elements['reporter-block-description'].textContent = !hasReporterIdentity
    ? '이전 버전에서 접수된 문의라 제보자 식별 정보가 없습니다.'
    : isBlocked
    ? '이 제보자는 현재 추가 오류 제보를 보낼 수 없습니다. 차단 해제 후 다시 제보할 수 있습니다.'
    : '차단하면 이 익명 제보자의 이후 오류 제보를 서버에서 거절합니다. 현재 문의의 처리 상태는 변경되지 않습니다.'
  elements['reporter-block-message'].textContent = ''
}

async function toggleReporterBlock() {
  const report = selectedReport()
  if (report === null) return
  const isBlocked = report.reporter_is_blocked === true
  const actionLabel = isBlocked ? '차단을 해제' : '제보자를 차단'
  if (!window.confirm(`${actionLabel}할까요?`)) return

  const button = elements['reporter-block-button']
  button.disabled = true
  elements['reporter-block-message'].textContent = ''
  try {
    await adminRequest('', {
      method: 'PATCH',
      body: JSON.stringify({
        action: isBlocked ? 'unblockReporter' : 'blockReporter',
        id: report.id,
      }),
    })
    await loadReports()
    elements['reporter-block-message'].textContent = isBlocked
      ? '제보자 차단을 해제했습니다.'
      : '제보자를 차단했습니다. 이후 오류 제보는 서버에서 거절됩니다.'
  } catch (error) {
    elements['reporter-block-message'].textContent =
      `변경하지 못했습니다. ${error.message}`
  } finally {
    button.disabled = false
  }
}

async function saveReview(event) {
  event.preventDefault()
  const report = selectedReport()
  if (report === null) return
  const button = elements['save-button']
  button.disabled = true
  button.textContent = '저장 중…'
  elements['save-message'].textContent = ''
  try {
    await adminRequest('', {
      method: 'PATCH',
      body: JSON.stringify({
        id: report.id,
        reviewStatus: elements['review-status'].value,
        reviewNote: elements['review-note'].value,
        appliedAppVersion: elements['applied-version'].value,
      }),
    })
    elements['save-message'].textContent = '저장했습니다.'
    await loadReports()
  } catch (error) {
    elements['save-message'].textContent = `저장하지 못했습니다. ${error.message}`
  } finally {
    button.disabled = false
    button.textContent = '변경사항 저장'
  }
}

async function adminRequest(path, options) {
  if (!state.session?.accessToken) throw Object.assign(new Error('로그인이 필요합니다.'), { status: 401 })
  const endpoint = new URL(
    `${adminConfig.supabaseUrl}/functions/v1/${adminConfig.functionName}${path}`,
  )
  if ((options.method ?? 'GET') === 'GET') {
    endpoint.searchParams.set('_requestTime', Date.now().toString())
  }
  const response = await fetch(
    endpoint,
    {
      ...options,
      cache: 'no-store',
      headers: {
        apikey: adminConfig.publishableKey,
        Authorization: `Bearer ${state.session.accessToken}`,
        'Content-Type': 'application/json',
        ...(options.headers ?? {}),
      },
    },
  )
  const body = await readJson(response)
  if (!response.ok) {
    const error = new Error(apiErrorMessage(body.error))
    error.status = response.status
    throw error
  }
  return body
}

function filteredReports() {
  return filterReports(state.reports, currentFilters())
}

function currentFilters() {
  return {
    search: elements['search-input'].value,
    status: elements['status-filter'].value,
    issueType: elements['type-filter'].value,
  }
}

function selectedReport() {
  return state.reports.find((report) => report.id === state.selectedId) ?? null
}

function createStatusBadge(status, id = '') {
  const meta = statusMeta[status] ?? { label: status, tone: 'gray' }
  const badge = document.createElement('span')
  if (id) badge.id = id
  badge.className = `status-badge tone-${meta.tone}`
  badge.textContent = meta.label
  return badge
}

function showLogin() {
  elements['login-view'].hidden = false
  elements['dashboard-view'].hidden = true
}

function showDashboard(email) {
  elements['login-view'].hidden = true
  elements['dashboard-view'].hidden = false
  elements['admin-email'].textContent = email
}

function setLoginError(message) {
  elements['login-error'].textContent = message
  elements['login-error'].hidden = !message
}

function readSession() {
  try {
    return JSON.parse(sessionStorage.getItem(sessionKey))
  } catch {
    return null
  }
}

async function readJson(response) {
  try {
    return await response.json()
  } catch {
    return {}
  }
}

function loginErrorMessage(body) {
  if (body?.error_code === 'invalid_credentials') return '이메일 또는 비밀번호가 올바르지 않습니다.'
  return body?.msg ?? body?.error_description ?? '로그인하지 못했습니다.'
}

function apiErrorMessage(code) {
  return {
    AUTH_REQUIRED: '로그인이 필요합니다.',
    INVALID_SESSION: '세션이 만료되었습니다.',
    ADMIN_ACCESS_REQUIRED: '관리자 권한이 없습니다.',
    LIST_FAILED: '문의 목록을 읽지 못했습니다.',
    UPDATE_FAILED: '문의 상태를 저장하지 못했습니다.',
    BULK_UPDATE_FAILED: '문의 상태를 한꺼번에 저장하지 못했습니다.',
    REPORT_NOT_FOUND: '문의가 이미 삭제되었거나 존재하지 않습니다.',
    REPORTER_ID_NOT_AVAILABLE: '이전 버전에서 접수된 문의라 제보자를 차단할 수 없습니다.',
    REPORTER_BLOCK_UPDATE_FAILED: '제보자 차단 상태를 변경하지 못했습니다.',
  }[code] ?? code ?? '알 수 없는 오류가 발생했습니다.'
}
