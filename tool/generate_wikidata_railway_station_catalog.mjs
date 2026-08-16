import { mkdir, readFile, writeFile } from 'node:fs/promises'
import { resolve } from 'node:path'

const root = resolve(import.meta.dirname, '..')
const sourcePath = resolve(root, 'assets/data/stations/yoiko_station_codes.csv')
const outputPath = resolve(root, 'assets/data/stations/wikidata_station_names_ko.csv')
const cachePath = resolve(root, 'tool/.cache/wikidata_japan_railway_catalog_v2.json')
const endpoint = 'https://query.wikidata.org/sparql'
const pageSize = 250
const delayMs = 1200
const maxPagesArgument = process.argv.find((argument) => argument.startsWith('--max-pages='))
const maxPages = maxPagesArgument == null ? null : Number(maxPagesArgument.split('=')[1])

const yoikoCsv = await readFile(sourcePath, 'utf8')
const yoikoStationNames = new Set(
  parseCsv(yoikoCsv)
    .slice(1)
    .map((fields) => fields[8]?.trim())
    .filter((name) => name && name !== '-'),
)

await mkdir(resolve(root, 'tool/.cache'), { recursive: true })
const state = await readState(cachePath)
let pagesFetched = 0

while (!state.complete && (maxPages == null || pagesFetched < maxPages)) {
  const query = `
    SELECT ?item ?jaName ?koName WHERE {
      {
        SELECT DISTINCT ?item WHERE {
          ?item wdt:P31/wdt:P279* wd:Q55488;
                wdt:P17 wd:Q17.
        }
        ORDER BY STR(?item)
        LIMIT ${pageSize}
        OFFSET ${state.offset}
      }
      ?item rdfs:label ?jaName;
            rdfs:label ?koName.
      FILTER(LANG(?jaName) = 'ja')
      FILTER(LANG(?koName) = 'ko')
    }
    ORDER BY STR(?item)
  `
  const response = await fetchWithRetry(query)
  const json = await response.json()
  const rows = json.results.bindings
  if (rows.length === 0) {
    state.complete = true
    await writeState(cachePath, state)
    break
  }

  for (const row of rows) {
    const item = row.item?.value?.replace('http://www.wikidata.org/entity/', '')
    const japanese = row.jaName?.value
    const korean = row.koName?.value
    if (!item || !japanese || !korean) continue
    state.records[item] = { item, japanese, korean }
  }
  state.offset += pageSize
  pagesFetched += 1
  await writeState(cachePath, state)
  console.log(`Wikidata catalog: ${Object.keys(state.records).length} records, offset ${state.offset}`)
  await wait(delayMs)
}

const existing = await readExistingLabels(outputPath)
const generated = buildLabels({
  stationNames: yoikoStationNames,
  catalog: Object.values(state.records),
})
for (const [japanese, row] of generated) existing.set(japanese, row)
await writeLabels(outputPath, existing)

console.log(
  `Wrote ${existing.size} Korean station labels (${generated.size} from catalog).`,
)
if (!state.complete) {
  console.log('Catalog is partial. Run the same command again to resume.')
}

function buildLabels({ stationNames, catalog }) {
  const output = new Map()
  for (const stationName of stationNames) {
    const candidates = catalog.filter(
      (record) =>
        record.japanese === stationName || record.japanese === `${stationName}駅`,
    )
    const koreanLabels = [...new Set(candidates.map((record) => record.korean))]
    if (koreanLabels.length !== 1) continue
    const exactStationName = candidates.find(
      (record) => record.japanese === `${stationName}駅`,
    )
    const selected = exactStationName ?? candidates[0]
    output.set(stationName, {
      japanese: stationName,
      korean: koreanLabels[0],
      item: selected.item,
      matchStatus: 'unique_korean_label_catalog',
    })
  }
  return output
}

async function readExistingLabels(path) {
  try {
    const csv = await readFile(path, 'utf8')
    const rows = parseCsv(csv).slice(1)
    return new Map(
      rows
        .filter((fields) => fields.length >= 4 && fields[0] && fields[1])
        .map((fields) => [
          fields[0],
          {
            japanese: fields[0],
            korean: fields[1],
            item: fields[2],
            matchStatus: fields[3],
          },
        ]),
    )
  } catch (error) {
    if (error?.code === 'ENOENT') return new Map()
    throw error
  }
}

async function writeLabels(path, rows) {
  const header = ['station_name_ja', 'station_name_ko', 'wikidata_id', 'match_status', 'source']
  const values = [...rows.values()]
    .sort((left, right) => left.japanese.localeCompare(right.japanese, 'ja'))
    .map((row) => [row.japanese, row.korean, row.item, row.matchStatus, 'Wikidata CC0'])
  await writeFile(
    path,
    `${[header, ...values].map((row) => row.map(escapeCsv).join(',')).join('\n')}\n`,
    'utf8',
  )
}

async function readState(path) {
  try {
    const state = JSON.parse(await readFile(path, 'utf8'))
    return {
      offset: Number.isInteger(state.offset) ? state.offset : 0,
      complete: state.complete === true,
      records: state.records && typeof state.records === 'object' ? state.records : {},
    }
  } catch (error) {
    if (error?.code === 'ENOENT') return { offset: 0, complete: false, records: {} }
    throw error
  }
}

async function writeState(path, state) {
  await writeFile(path, JSON.stringify(state), 'utf8')
}

async function fetchWithRetry(query) {
  for (let attempt = 1; attempt <= 4; attempt += 1) {
    try {
      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          Accept: 'application/sparql-results+json',
          'Content-Type': 'application/sparql-query; charset=utf-8',
          'User-Agent': 'ic-card-reader-station-catalog/1.0 (mailto:iccardreader10@gmail.com)',
        },
        body: query,
      })
      if (response.ok) return response
      if (response.status < 500 && response.status !== 429) {
        throw new Error(`Wikidata request failed: ${response.status} ${response.statusText}`)
      }
      if (attempt === 4) {
        throw new Error(`Wikidata request failed: ${response.status} ${response.statusText}`)
      }
    } catch (error) {
      if (attempt === 4) throw error
    }
    await wait(2_000 * attempt)
  }
  throw new Error('Wikidata request retry loop ended unexpectedly')
}

function parseCsv(input) {
  return input
    .split(/\r?\n/)
    .filter((line) => line.length > 0)
    .map(parseLine)
}

function parseLine(line) {
  const fields = []
  let value = ''
  let quoted = false
  for (let index = 0; index < line.length; index += 1) {
    const character = line[index]
    if (character === '"') {
      if (quoted && line[index + 1] === '"') {
        value += '"'
        index += 1
      } else {
        quoted = !quoted
      }
    } else if (character === ',' && !quoted) {
      fields.push(value)
      value = ''
    } else {
      value += character
    }
  }
  fields.push(value)
  return fields
}

function escapeCsv(value) {
  return /[",\r\n]/.test(value) ? `"${value.replaceAll('"', '""')}"` : value
}

function wait(milliseconds) {
  return new Promise((resolveWait) => setTimeout(resolveWait, milliseconds))
}
