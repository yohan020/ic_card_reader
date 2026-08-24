import { createReadStream, existsSync, statSync } from 'node:fs'
import { readFile, rename, writeFile } from 'node:fs/promises'
import { createServer } from 'node:http'
import { extname, join, normalize } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = fileURLToPath(new URL('.', import.meta.url))
const host = '127.0.0.1'
const port = Number(process.env.IC_CARD_ADMIN_PORT ?? 4173)
const origin = `http://${host}:${port}`
const manualStationCsvPath = join(root, '..', 'assets', 'data', 'stations', 'manual_station_names_ko_by_code.csv')
const mimeTypes = new Map([
  ['.css', 'text/css; charset=utf-8'],
  ['.html', 'text/html; charset=utf-8'],
  ['.js', 'text/javascript; charset=utf-8'],
  ['.mjs', 'text/javascript; charset=utf-8'],
  ['.svg', 'image/svg+xml'],
])

let manualStationWriteQueue = Promise.resolve()

createServer(async (request, response) => {
  const url = new URL(request.url ?? '/', origin)
  if (url.pathname === '/api/manual-station-names') {
    await handleManualStationName(request, response)
    return
  }
  serveStatic(url, response)
}).listen(port, host, () => {
  console.log(`IC 카드 문의 관리: ${origin}`)
  console.log('종료하려면 Ctrl+C를 누르세요.')
})

async function handleManualStationName(request, response) {
  if (request.method !== 'POST') {
    sendJson(response, 405, { error: '허용되지 않은 요청입니다.' })
    return
  }
  if (request.headers.origin !== origin || request.headers['x-requested-with'] !== 'ic-card-admin') {
    sendJson(response, 403, { error: 'localhost 관리자 화면에서만 저장할 수 있습니다.' })
    return
  }
  if (!String(request.headers['content-type'] ?? '').startsWith('application/json')) {
    sendJson(response, 415, { error: 'JSON 요청만 허용합니다.' })
    return
  }
  try {
    const candidate = validateManualStationCandidate(await readJsonBody(request))
    const result = await queueManualStationWrite(candidate)
    sendJson(response, 200, result)
  } catch (error) {
    sendJson(response, error.statusCode ?? 400, { error: error.message ?? '수동 CSV를 저장하지 못했습니다.' })
  }
}

function queueManualStationWrite(candidate) {
  const pending = manualStationWriteQueue.then(() => upsertManualStationName(candidate))
  manualStationWriteQueue = pending.catch(() => undefined)
  return pending
}

async function upsertManualStationName(candidate) {
  const text = await readFile(manualStationCsvPath, 'utf8')
  const rows = parseCsv(text)
  const header = rows.shift()
  const expectedHeader = ['region_code', 'line_code', 'station_code', 'station_name_ja', 'station_name_ko', 'source_note']
  if (JSON.stringify(header) !== JSON.stringify(expectedHeader)) {
    throw Object.assign(new Error('수동 역명 CSV 형식이 올바르지 않습니다.'), { statusCode: 500 })
  }
  const date = new Intl.DateTimeFormat('sv-SE', { timeZone: 'Asia/Seoul' }).format(new Date())
  const lineNote = candidate.parsedLineName ? ` · 파서 노선 ${candidate.parsedLineName}` : ''
  const row = [String(candidate.regionCode), String(candidate.lineCode), String(candidate.stationCode), candidate.stationNameJa, candidate.stationNameKo, `문의 관리 수동 ${date}${lineNote}`]
  const existingIndex = rows.findIndex((item) => item[0] === row[0] && item[1] === row[1] && item[2] === row[2])
  const action = existingIndex >= 0 ? 'updated' : 'created'
  if (existingIndex >= 0) rows[existingIndex] = row
  else rows.push(row)
  rows.sort(compareCodeRows)
  const output = [header, ...rows].map((item) => item.map(escapeCsv).join(',')).join('\n') + '\n'
  const temporaryPath = `${manualStationCsvPath}.tmp`
  await writeFile(temporaryPath, output, 'utf8')
  await rename(temporaryPath, manualStationCsvPath)
  return { action, row: { ...candidate, sourceNote: row[5] } }
}

function validateManualStationCandidate(value) {
  if (!value || typeof value !== 'object') throw new Error('저장할 역 정보가 없습니다.')
  for (const field of ['regionCode', 'lineCode', 'stationCode']) {
    if (!Number.isInteger(value[field]) || value[field] < 0 || value[field] > 255) {
      throw new Error('역 코드가 올바르지 않습니다.')
    }
  }
  return {
    regionCode: value.regionCode,
    lineCode: value.lineCode,
    stationCode: value.stationCode,
    stationNameJa: validateText(value.stationNameJa, '일본어 역명'),
    stationNameKo: validateText(value.stationNameKo, '한글 표기'),
    parsedLineName: optionalText(value.parsedLineName),
  }
}

function validateText(value, label) {
  const text = optionalText(value)
  if (text === null) throw new Error(`${label}이 필요합니다.`)
  return text
}

function optionalText(value) {
  if (typeof value !== 'string') return null
  const text = value.trim()
  if (!text || text.length > 100 || /[\r\n]/.test(text)) return null
  return text
}

function compareCodeRows(left, right) {
  for (let index = 0; index < 3; index += 1) {
    const difference = Number(left[index]) - Number(right[index])
    if (difference !== 0) return difference
  }
  return 0
}

function parseCsv(text) {
  const rows = []
  let row = []
  let field = ''
  let quoted = false
  for (let index = 0; index < text.length; index += 1) {
    const character = text[index]
    if (quoted) {
      if (character === '"' && text[index + 1] === '"') { field += '"'; index += 1 } else if (character === '"') quoted = false
      else field += character
      continue
    }
    if (character === '"') quoted = true
    else if (character === ',') { row.push(field); field = '' }
    else if (character === '\n') { row.push(field.replace(/\r$/, '')); rows.push(row); row = []; field = '' }
    else field += character
  }
  if (quoted) throw Object.assign(new Error('수동 역명 CSV의 따옴표가 닫히지 않았습니다.'), { statusCode: 500 })
  if (field || row.length > 0) { row.push(field.replace(/\r$/, '')); rows.push(row) }
  return rows.filter((item) => item.length > 1 || item[0] !== '')
}

function escapeCsv(value) {
  const text = String(value)
  return /[",\r\n]/.test(text) ? `"${text.replaceAll('"', '""')}"` : text
}

function readJsonBody(request) {
  return new Promise((resolve, reject) => {
    let body = ''
    request.setEncoding('utf8')
    request.on('data', (chunk) => {
      body += chunk
      if (body.length > 4096) { reject(Object.assign(new Error('요청 크기가 너무 큽니다.'), { statusCode: 413 })); request.destroy() }
    })
    request.on('end', () => { try { resolve(JSON.parse(body)) } catch { reject(new Error('올바른 JSON 요청이 아닙니다.')) } })
    request.on('error', () => reject(new Error('요청을 읽지 못했습니다.')))
  })
}

function sendJson(response, statusCode, body) {
  response.writeHead(statusCode, { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff' })
  response.end(JSON.stringify(body))
}

function serveStatic(url, response) {
  const requestedPath = url.pathname === '/' ? '/index.html' : url.pathname
  const relativePath = normalize(decodeURIComponent(requestedPath)).replace(/^(\.\.(\\|\/|$))+/, '')
  const filePath = join(root, relativePath)
  if (!filePath.startsWith(root) || !existsSync(filePath) || !statSync(filePath).isFile()) {
    response.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' })
    response.end('Not found')
    return
  }
  response.writeHead(200, {
    'Content-Type': mimeTypes.get(extname(filePath)) ?? 'application/octet-stream',
    'Cache-Control': 'no-store',
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'Referrer-Policy': 'no-referrer',
    'Content-Security-Policy': "default-src 'self'; connect-src 'self' https://uenyouholkxxyyaukrbz.supabase.co; style-src 'self'; script-src 'self'; img-src 'self' data:; frame-ancestors 'none'",
  })
  createReadStream(filePath).pipe(response)
}
