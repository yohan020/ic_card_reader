import assert from 'node:assert/strict'
import test from 'node:test'

import { selectStationCandidate } from '../lib/wikidata_station_matcher.mjs'

test('selects Tokyo Nihombashi using its line instead of the Osaka homonym', () => {
  const selected = selectStationCandidate(
    { stationName: '日本橋', lineName: '東京地下鉄 銀座線' },
    [
      { item: 'Q1040630', stationName: '日本橋駅', koreanName: '닛폰바시역', lineNames: ['大阪メトロ千日前線'] },
      { item: 'Q1134127', stationName: '日本橋駅', koreanName: '니혼바시역', lineNames: ['東京メトロ銀座線'] },
    ],
  )
  assert.equal(selected?.candidate.item, 'Q1134127')
  assert.match(selected?.evidence ?? '', /東京メトロ銀座線/)
})

test('selects Osaka Nippombashi using its line', () => {
  const selected = selectStationCandidate(
    { stationName: '日本橋', lineName: 'Osaka Metro 堺筋線' },
    [
      { item: 'Q1040630', stationName: '日本橋駅', koreanName: '닛폰바시역', lineNames: ['大阪メトロ堺筋線'] },
      { item: 'Q1134127', stationName: '日本橋駅', koreanName: '니혼바시역', lineNames: ['東京メトロ銀座線'] },
    ],
  )
  assert.equal(selected?.candidate.item, 'Q1040630')
})

test('does not choose a same-name station without a unique line match', () => {
  const selected = selectStationCandidate(
    { stationName: '大手町', lineName: '-' },
    [
      { item: 'Q1', stationName: '大手町駅', koreanName: '오테마치역', lineNames: ['東京メトロ丸ノ内線'] },
      { item: 'Q2', stationName: '大手町駅', koreanName: '오테마치역', lineNames: ['伊予鉄道高浜線'] },
    ],
  )
  assert.equal(selected, null)
})
