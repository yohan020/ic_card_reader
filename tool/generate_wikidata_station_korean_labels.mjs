import { mkdir, readFile, writeFile } from 'node:fs/promises'
import { resolve } from 'node:path'

const root = resolve(import.meta.dirname, '..')
const sourcePath = resolve(root, 'assets/data/stations/yoiko_station_codes.csv')
const outputPath = resolve(root, 'assets/data/stations/wikidata_station_names_ko.csv')
const cachePath = resolve(root, 'tool/.cache/wikidata_railway_station_names_ko_v2.json')
const endpoint = 'https://query.wikidata.org/sparql'
const chunkSize = 40
const delayMs = 1100
const maxChunksArgument = process.argv.find((argument) => argument.startsWith('--max-chunks='))
const maxChunks = maxChunksArgument == null ? null : Number(maxChunksArgument.split('=')[1])
const stationsArgument = process.argv.find((argument) => argument.startsWith('--stations='))

const source = await readFile(sourcePath, 'utf8')
const stationNames = [...new Set(
  parseCsv(source)
    .slice(1)
    .map((fields) => fields[8]?.trim())
    .filter((name) => name && name !== '-'),
)].sort((left, right) => left.localeCompare(right, 'ja'))
const requestedStationNames = stationsArgument == null
  ? stationNames
  : stationsArgument
      .split('=')[1]
      .split(',')
      .map((name) => name.trim())
      .filter((name) => stationNames.includes(name))

await mkdir(resolve(root, 'tool/.cache'), { recursive: true })
const matched = new Map(Object.entries(await readJson(cachePath)))
const existingLabels = new Map(
  parseCsv(await readFile(outputPath, 'utf8'))
    .slice(1)
    .filter((fields) => fields.length >= 4 && fields[0] && fields[1])
    .map((fields) => [fields[0], [fields[1], fields[2], fields[3]]]),
)
const remainingNames = requestedStationNames.filter((name) => !matched.has(name))
const pendingChunks = chunks(remainingNames, chunkSize)
const selectedChunks = maxChunks == null ? pendingChunks : pendingChunks.slice(0, maxChunks)
for (const names of selectedChunks) {
  const query = `
    SELECT ?sourceName ?item ?koName WHERE {
      VALUES (?sourceName ?jaName) {
        ${names.map((name) => `("${escapeSparql(name)}" "${escapeSparql(name)}"@ja) ("${escapeSparql(name)}" "${escapeSparql(name)}駅"@ja)`).join(' ')}
      }
      ?item wdt:P31/wdt:P279* wd:Q55488;
            rdfs:label ?jaName;
            rdfs:label ?koName.
      FILTER(LANG(?koName) = "ko")
    }
  `
  const response = await fetchWithRetry(query)
  const json = await response.json()
  for (const row of json.results.bindings) {
    const japanese = row.sourceName?.value
    const korean = row.koName?.value
    const item = row.item?.value?.replace('http://www.wikidata.org/entity/', '')
    if (!japanese || !korean || !item) continue
    const candidates = new Map(matched.get(japanese) ?? [])
    candidates.set(`${item}\u0000${korean}`, { item, korean })
    matched.set(japanese, [...candidates])
  }
  for (const name of names) matched.set(name, matched.get(name) ?? [])
  await writeFile(cachePath, JSON.stringify(Object.fromEntries(matched)), 'utf8')
  await writeMergedLabels()
  process.stdout.write(`Wikidata: ${matched.size}/${stationNames.length}\n`)
  await wait(delayMs)
}

await writeMergedLabels()
if (selectedChunks.length < pendingChunks.length) {
  console.log(`Paused after ${selectedChunks.length} chunk(s). Run the same command again to resume.`)
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

function escapeSparql(value) {
  return value.replaceAll('\\', '\\\\').replaceAll('"', '\\"')
}

function escapeCsv(value) {
  return /[",\r\n]/.test(value) ? `"${value.replaceAll('"', '""')}"` : value
}

async function writeMergedLabels() {
  const labels = new Map(existingLabels)
  for (const japanese of stationNames) {
    const candidates = (matched.get(japanese) ?? []).map(([, candidate]) => candidate)
    const koreanLabels = [...new Set(candidates.map((candidate) => candidate.korean))]
    if (koreanLabels.length !== 1) continue
    const exact = candidates.find((candidate) => candidate.korean === koreanLabels[0])
    labels.set(japanese, [koreanLabels[0], exact.item, 'unique_korean_label'])
  }
  const rows = [
    ['station_name_ja', 'station_name_ko', 'wikidata_id', 'match_status', 'source'],
    ...[...labels.entries()]
      .sort(([left], [right]) => left.localeCompare(right, 'ja'))
      .map(([japanese, [korean, item, status]]) => [japanese, korean, item, status, 'Wikidata CC0']),
  ]
  await writeFile(outputPath, `${rows.map((row) => row.map(escapeCsv).join(',')).join('\n')}\n`, 'utf8')
  console.log(`Wrote ${rows.length - 1} conservative Korean station labels to ${outputPath}`)
}

function chunks(values, size) {
  return Array.from({ length: Math.ceil(values.length / size) }, (_, index) =>
    values.slice(index * size, (index + 1) * size),
  )
}

function wait(milliseconds) {
  return new Promise((resolveWait) => setTimeout(resolveWait, milliseconds))
}

async function readJson(path) {
  try {
    return JSON.parse(await readFile(path, 'utf8'))
  } catch (error) {
    if (error?.code === 'ENOENT') return {}
    throw error
  }
}

async function fetchWithRetry(query) {
  for (let attempt = 1; attempt <= 4; attempt += 1) {
    try {
      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          Accept: 'application/sparql-results+json',
          'Content-Type': 'application/sparql-query; charset=utf-8',
          'User-Agent': 'ic-card-reader-localization-generator/1.0 (mailto:iccardreader10@gmail.com)',
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
