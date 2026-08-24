export function normalizeStationName(value) {
  return value
    .normalize('NFKC')
    .replaceAll(/[\s　]/g, '')
    .replace(/駅$/, '')
}

export function normalizeLineName(value) {
  return value
    .normalize('NFKC')
    .replaceAll(/[\s　・･]/g, '')
    .replaceAll(/[()（）]/g, '')
    .replaceAll('東京地下鉄', '東京メトロ')
    .replaceAll('大阪市高速電気軌道', '大阪メトロ')
    .replaceAll('OsakaMetro', '大阪メトロ')
    .replaceAll('東京都交通局', '都営地下鉄')
    .replace(/線$/, '')
}

export function selectStationCandidate(station, candidates) {
  const expectedStation = normalizeStationName(station.stationName)
  const expectedLine = normalizeLineName(station.lineName)
  const nameMatches = candidates.filter(
    (candidate) => normalizeStationName(candidate.stationName) === expectedStation,
  )
  if (nameMatches.length === 0) return null

  const scored = nameMatches.map((candidate) => {
    const matchingLine = (candidate.lineNames ?? []).find((lineName) =>
      linesMatch(expectedLine, normalizeLineName(lineName)),
    )
    return {
      candidate,
      score: matchingLine == null ? 0 : 2,
      evidence: matchingLine == null ? 'station_name_only' : `station_name+line:${matchingLine}`,
    }
  })
  const highestScore = Math.max(...scored.map((entry) => entry.score))
  if (highestScore === 0 && scored.length > 1) return null
  const best = scored.filter((entry) => entry.score === highestScore)
  const koreanNames = new Set(best.map((entry) => entry.candidate.koreanName))
  const itemIds = new Set(best.map((entry) => entry.candidate.item))
  if (best.length !== 1 && (koreanNames.size !== 1 || itemIds.size !== 1)) return null
  return best[0]
}

function linesMatch(expected, actual) {
  if (!expected || !actual) return false
  return expected === actual || expected.includes(actual) || actual.includes(expected)
}
