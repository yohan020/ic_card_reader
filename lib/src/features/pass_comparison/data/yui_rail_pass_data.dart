import 'package:flutter/services.dart';

import 'pass_transit_data.dart';

const _koreanNames = <String, String>{
  '那覇空港': '나하공항',
  '赤嶺': '아카미네',
  '小禄': '오로쿠',
  '奥武山公園': '오노야마공원',
  '壺川': '쓰보가와',
  '旭橋': '아사히바시',
  '県庁前': '켄초마에',
  '美栄橋': '미에바시',
  '牧志': '마키시',
  '安里': '아사토',
  'おもろまち': '오모로마치',
  '古島': '후루지마',
  '市立病院前': '시리츠뵤인마에',
  '儀保': '기보',
  '首里': '슈리',
  '石嶺': '이시미네',
  '経塚': '쿄즈카',
  '浦添前田': '우라소에마에다',
  'てだこ浦西': '테다코우라니시',
};

class YuiRailStation {
  const YuiRailStation({
    required this.id,
    required this.nameJa,
    required this.nameEn,
    required this.stationCodes,
  });

  final String id;
  final String nameJa;
  final String nameEn;
  final List<String> stationCodes;

  String get nameKo => _koreanNames[nameJa] ?? nameJa;
  String get displayName => nameKo;
  String get secondaryLabel => '$nameJa · 유이레일';
}

class YuiRailPassData {
  YuiRailPassData._({required this.stations, required Map<String, int> fares})
    : _fares = fares,
      _searchIndex = stations.map(_SearchEntry.new).toList(growable: false);

  static const passPrices = <int, int>{24: 1000, 48: 1800};
  final List<YuiRailStation> stations;
  final Map<String, int> _fares;
  final List<_SearchEntry> _searchIndex;

  static YuiRailPassData fromCsv({
    required String stationsCsv,
    required String faresCsv,
  }) {
    final stationRows = _csvRows(stationsCsv);
    final stations = stationRows
        .map(
          (row) => YuiRailStation(
            id: row['station_id']!,
            nameJa: row['name_ja']!,
            nameEn: row['name_en']!,
            stationCodes: row['station_codes']!.split('|'),
          ),
        )
        .toList(growable: false);
    final fares = <String, int>{
      for (final row in _csvRows(faresCsv))
        '${row['origin']}|${row['destination']}': int.parse(
          row['adult_fare_yen']!,
        ),
    };
    return YuiRailPassData._(stations: stations, fares: fares);
  }

  int? fareBetween(YuiRailStation from, YuiRailStation to) {
    if (from.id == to.id) return null;
    return _fares['${from.id}|${to.id}'];
  }

  List<YuiRailStation> search(String query, {int limit = 20}) {
    final normalized = normalizeStationSearchText(query);
    if (normalized.isEmpty) return const [];
    final initials = hangulInitials(normalized);
    final isInitialQuery = isHangulInitialSearch(normalized);
    final matches = <({YuiRailStation station, int score})>[];
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

class YuiRailPassDataRepository {
  const YuiRailPassDataRepository();

  static Future<YuiRailPassData>? _cachedLoad;

  Future<YuiRailPassData> load() => _cachedLoad ??= _load();

  Future<YuiRailPassData> _load() async => YuiRailPassData.fromCsv(
    stationsCsv: await rootBundle.loadString(
      'assets/data/pass_comparison/yui_rail_stations_2026.csv',
    ),
    faresCsv: await rootBundle.loadString(
      'assets/data/pass_comparison/yui_rail_fares_2026.csv',
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

  final YuiRailStation station;
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
