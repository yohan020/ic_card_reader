import { mkdir, readFile, writeFile } from 'node:fs/promises'
import { resolve } from 'node:path'

import { selectStationCandidate } from './lib/wikidata_station_matcher.mjs'

const root = resolve(import.meta.dirname, '..')
const sourcePath = resolve(root, 'assets/data/stations/yoiko_station_codes.csv')
const overridePath = resolve(root, 'assets/data/stations/verified_station_overrides.csv')
const outputPath = resolve(root, 'assets/data/stations/station_names_ko_by_code.csv')
const cachePath = resolve(root, 'tool/.cache/wikidata_station_candidates_by_name_v1.json')
const endpoint = 'https://query.wikidata.org/sparql'
const chunkSize = 50
const delayMs = 1100
const maxChunksArgument = process.argv.find((argument) => argument.startsWith('--max-chunks='))
const maxChunks = maxChunksArgument == null ? null : Number(maxChunksArgument.split('=')[1])
const refresh = process.argv.includes('--refresh')

const stations = mergeStations(
  parsePrimaryCsv(await readFile(sourcePath, 'utf8')),
  parseOverrideCsv(await readFile(overridePath, 'utf8')),
)
const stationNames = [...new Set(stations.map((station) => station.stationName))]
  .sort((left, right) => left.localeCompare(right, 'ja'))

await mkdir(resolve(root, 'tool/.cache'), { recursive: true })
const cached = refresh ? {} : await readJson(cachePath)
const remainingNames = stationNames.filter((name) => cached[name] == null)
const pendingChunks = chunks(remainingNames, chunkSize)
const selectedChunks = maxChunks == null ? pendingChunks : pendingChunks.slice(0, maxChunks)

for (const names of selectedChunks) {
  const response = await fetchWithRetry(buildQuery(names))
  const json = await response.json()
  const candidatesByName = new Map(names.map((name) => [name, new Map()]))
  for (const row of json.results.bindings) {
    const sourceName = row.sourceName?.value
    const item = row.item?.value?.replace('http://www.wikidata.org/entity/', '')
    const stationName = row.stationName?.value
    const koreanName = row.koreanName?.value
    if (!sourceName || !item || !stationName || !koreanName) continue
    const byItem = candidatesByName.get(sourceName)
    if (byItem == null) continue
    const candidate = byItem.get(item) ?? {
      item,
      stationName,
      koreanName,
      lineNames: [],
    }
    const lineName = row.lineName?.value
    if (lineName && !candidate.lineNames.includes(lineName)) candidate.lineNames.push(lineName)
    byItem.set(item, candidate)
  }
  for (const name of names) cached[name] = [...(candidatesByName.get(name)?.values() ?? [])]
  await writeFile(cachePath, JSON.stringify(cached), 'utf8')
  process.stdout.write(`Wikidata candidates: ${Object.keys(cached).length}/${stationNames.length}\n`)
  await wait(delayMs)
}

const generated = []
for (const station of stations) {
  const selected = selectStationCandidate(station, cached[station.stationName] ?? [])
  if (selected == null) continue
  generated.push([
    station.regionCode,
    station.lineCode,
    station.stationCode,
    station.stationName,
    selected.candidate.koreanName,
    selected.candidate.item,
    'matched_station_line',
    selected.evidence,
    'Wikidata CC0',
  ])
}
generated.sort((left, right) => Number(left[0]) - Number(right[0]) || Number(left[1]) - Number(right[1]) || Number(left[2]) - Number(right[2]))
const rows = [
  ['region_code', 'line_code', 'station_code', 'station_name_ja', 'station_name_ko', 'wikidata_id', 'match_status', 'match_evidence', 'source'],
  ...generated,
]
await writeFile(outputPath, `${rows.map((row) => row.map(escapeCsv).join(',')).join('\n')}\n`, 'utf8')
console.log(`Wrote ${generated.length} code-scoped Korean station labels to ${outputPath}`)
if (selectedChunks.length < pendingChunks.length) {
  console.log(`Paused after ${selectedChunks.length} chunk(s). Run the same command again to resume.`)
}

function buildQuery(names) {
  return `
    SELECT ?sourceName ?item ?stationName ?koreanName ?lineName WHERE {
      VALUES (?sourceName ?jaName) {
        ${names.map((name) => `("${escapeSparql(name)}" "${escapeSparql(name)}"@ja) ("${escapeSparql(name)}" "${escapeSparql(name)}駅"@ja)`).join(' ')}
      }
      ?item wdt:P31/wdt:P279* wd:Q55488;
            rdfs:label ?jaName;
            rdfs:label ?stationName;
            rdfs:label ?koreanName.
      FILTER(LANG(?stationName) = 'ja')
      FILTER(LANG(?koreanName) = 'ko')
      OPTIONAL {
        ?item wdt:P81 ?line.
        ?line rdfs:label ?lineName.
        FILTER(LANG(?lineName) = 'ja')
      }
    }
  `
}

function mergeStations(primary, overrides) {
  const records = new Map(primary.map((station) => [station.key, station]))
  for (const station of overrides) records.set(station.key, station)
  return [...records.values()].filter((station) => station.stationName && station.stationName !== '-')
}

function parsePrimaryCsv(input) {
  return parseCsv(input).slice(1).flatMap((fields) => makeStation(fields[0], fields[1], fields[2], fields[6], fields[7], fields[8]))
}

function parseOverrideCsv(input) {
  return parseCsv(input).slice(1).flatMap((fields) => makeStation(fields[0], fields[1], fields[2], fields[3], fields[4], fields[5]))
}

function makeStation(regionCode, lineCode, stationCode, operatorName, lineName, stationName) {
  const region = Number(regionCode)
  const line = Number(lineCode)
  const station = Number(stationCode)
  if (![region, line, station].every(Number.isInteger)) return []
  return [{
    key: `${region}-${line}-${station}`,
    regionCode: region,
    lineCode: line,
    stationCode: station,
    operatorName: operatorName?.trim() ?? '',
    lineName: lineName?.trim() ?? '',
    stationName: stationName?.trim() ?? '',
  }]
}

function parseCsv(input) {
  return input.split(/\r?\n/).filter(Boolean).map(parseLine)
}

function parseLine(line) {
  const fields = []
  let value = ''
  let quoted = false
  for (let index = 0; index < line.length; index += 1) {
    const character = line[index]
    if (character === '"') {
      if (quoted && line[index + 1] === '"') { value += '"'; index += 1 } else quoted = !quoted
    } else if (character === ',' && !quoted) { fields.push(value); value = '' } else value += character
  }
  fields.push(value)
  return fields
}

function chunks(values, size) {
  return Array.from({ length: Math.ceil(values.length / size) }, (_, index) => values.slice(index * size, (index + 1) * size))
}

function escapeSparql(value) {
  return value.replaceAll('\\', '\\\\').replaceAll('"', '\\"')
}

function escapeCsv(value) {
  const text = String(value)
  return /[",\r\n]/.test(text) ? `"${text.replaceAll('"', '""')}"` : text
}

async function readJson(path) {
  try { return JSON.parse(await readFile(path, 'utf8')) } catch (error) { if (error?.code === 'ENOENT') return {}; throw error }
}

function wait(milliseconds) { return new Promise((resolveWait) => setTimeout(resolveWait, milliseconds)) }

async function fetchWithRetry(query) {
  for (let attempt = 1; attempt <= 4; attempt += 1) {
    try {
      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          Accept: 'application/sparql-results+json',
          'Content-Type': 'application/sparql-query; charset=utf-8',
          'User-Agent': 'ic-card-reader-station-localization-generator/2.0 (mailto:iccardreader10@gmail.com)',
        },
        body: query,
      })
      if (response.ok) return response
      if (response.status < 500 && response.status !== 429) throw new Error(`Wikidata request failed: ${response.status} ${response.statusText}`)
    } catch (error) { if (attempt === 4) throw error }
    await wait(2_000 * attempt)
  }
  throw new Error('Wikidata request retry loop ended unexpectedly')
}
