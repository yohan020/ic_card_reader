import 'package:flutter/services.dart';

import 'pass_transit_data.dart';

const _koreanNames = <String, String>{
  '赤迫': '아카사코',
  '住吉': '스미요시',
  '昭和町通': '쇼와마치도리',
  '千歳町': '치토세마치',
  '若葉町': '와카바마치',
  '長崎大学': '나가사키대학',
  '岩屋橋': '이와야바시',
  '浦上車庫': '우라카미샤코',
  '大橋': '오하시',
  '平和公園': '평화공원',
  '原爆資料館': '원폭자료관',
  '大学病院': '대학병원',
  '浦上駅前': '우라카미역 앞',
  '茂里町': '모리마치',
  'スタジアムシティノース': '스타디움시티노스',
  'スタジアムシティサウス': '스타디움시티사우스',
  '八千代町': '야치요마치',
  '長崎駅前': '나가사키역 앞',
  '五島町': '고토마치',
  '大波止': '오하토',
  '出島': '데지마',
  '新地中華街': '신치추카가이',
  '西浜町': '니시하마노마치',
  '観光通': '간코도리',
  '思案橋': '시안바시',
  '崇福寺': '소후쿠지',
  '桜町': '사쿠라마치',
  '市役所': '시청',
  'メディカルセンター': '메디컬센터',
  '大浦海岸通': '오우라카이간도리',
  '大浦天主堂': '오우라텐슈도',
  '石橋': '이시바시',
  '浜町アーケード': '하마노마치아케이드',
  'めがね橋': '메가네바시',
  '諏訪神社': '스와신사',
  '新大工町': '신다이쿠마치',
  '新中川町': '신나카가와마치',
  '蛍茶屋': '호타루자야',
};

class NagasakiElectricTramwayStation {
  const NagasakiElectricTramwayStation({
    required this.id,
    required this.nameJa,
    required this.nameEn,
  });

  final String id;
  final String nameJa;
  final String nameEn;

  String get nameKo => _koreanNames[nameJa] ?? nameJa;
  String get displayName => nameKo;
  String get secondaryLabel => '$nameJa · 나가사키 전기궤도';
}

/// Directional IC/touch fare table normalized from the supplied 2026 package.
///
/// [昭和町通] is served only in the Akasako-bound direction, so fares are kept
/// by ordered origin/destination pair instead of as an undirected table.
class NagasakiElectricTramwayPassData {
  NagasakiElectricTramwayPassData._({
    required this.stations,
    required Map<String, int> fares,
  }) : _fares = fares,
       _searchIndex = stations.map(_SearchEntry.new).toList(growable: false);

  final List<NagasakiElectricTramwayStation> stations;
  final Map<String, int> _fares;
  final List<_SearchEntry> _searchIndex;

  static NagasakiElectricTramwayPassData fromCsv({
    required String stationsCsv,
    required String faresCsv,
  }) {
    final stations = _csvRows(stationsCsv)
        .map(
          (row) => NagasakiElectricTramwayStation(
            id: row['station_id']!,
            nameJa: row['name_ja']!,
            nameEn: row['name_en']!,
          ),
        )
        .toList(growable: false);
    final fares = <String, int>{
      for (final row in _csvRows(faresCsv))
        '${row['origin']}|${row['destination']}': int.parse(
          row['adult_ic_yen']!,
        ),
    };
    return NagasakiElectricTramwayPassData._(stations: stations, fares: fares);
  }

  int? fareBetween(
    NagasakiElectricTramwayStation from,
    NagasakiElectricTramwayStation to,
  ) => from.id == to.id ? null : _fares['${from.nameJa}|${to.nameJa}'];

  List<NagasakiElectricTramwayStation> search(String query, {int limit = 20}) {
    final normalized = normalizeStationSearchText(query);
    if (normalized.isEmpty) return const [];
    final initials = hangulInitials(normalized);
    final isInitialQuery = isHangulInitialSearch(normalized);
    final matches = <({NagasakiElectricTramwayStation station, int score})>[];
    for (final entry in _searchIndex) {
      var score = 1000;
      for (final candidate in entry.candidates) {
        if (candidate.normalized == normalized) score = 0;
        if (candidate.normalized.startsWith(normalized)) {
          score = score < 10 ? score : 10;
        }
        if (isInitialQuery && candidate.initials.startsWith(initials)) {
          score = score < 20 ? score : 20;
        }
        if (candidate.normalized.contains(normalized)) {
          score = score < 30 ? score : 30;
        }
      }
      if (score < 1000) matches.add((station: entry.station, score: score));
    }
    matches.sort(
      (a, b) => a.score != b.score
          ? a.score.compareTo(b.score)
          : a.station.displayName.compareTo(b.station.displayName),
    );
    return matches.take(limit).map((item) => item.station).toList();
  }
}

class NagasakiElectricTramwayPassDataRepository {
  const NagasakiElectricTramwayPassDataRepository();

  static Future<NagasakiElectricTramwayPassData>? _cachedLoad;

  Future<NagasakiElectricTramwayPassData> load() => _cachedLoad ??= _load();

  Future<NagasakiElectricTramwayPassData>
  _load() async => NagasakiElectricTramwayPassData.fromCsv(
    stationsCsv: await rootBundle.loadString(
      'assets/data/pass_comparison/nagasaki_electric_tramway_stations_2026.csv',
    ),
    faresCsv: await rootBundle.loadString(
      'assets/data/pass_comparison/nagasaki_electric_tramway_fares_2026.csv',
    ),
  );
}

class _SearchEntry {
  _SearchEntry(this.station)
    : candidates = {station.nameJa, station.nameKo, station.nameEn}
          .map(normalizeStationSearchText)
          .where((value) => value.isNotEmpty)
          .map((value) => (normalized: value, initials: hangulInitials(value)))
          .toList(growable: false);

  final NagasakiElectricTramwayStation station;
  final List<({String normalized, String initials})> candidates;
}

List<Map<String, String>> _csvRows(String source) {
  final lines = source
      .replaceFirst('\uFEFF', '')
      .split(RegExp(r'\r?\n'))
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
  if (lines.isEmpty) return const [];
  final headers = lines.first.split(',');
  return [
    for (final line in lines.skip(1))
      {
        for (var index = 0; index < headers.length; index++)
          headers[index]: line.split(',')[index],
      },
  ];
}
