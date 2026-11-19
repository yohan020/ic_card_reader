import 'package:flutter/services.dart';

import 'pass_named_place.dart';

import 'pass_transit_data.dart';

const _koreanNames = <String, String>{
  '姪浜': '메이노하마',
  '室見': '무로미',
  '藤崎': '후지사키',
  '西新': '니시진',
  '唐人町': '도진마치',
  '大濠公園': '오호리코엔',
  '赤坂': '아카사카',
  '天神': '텐진',
  '中洲川端': '나카스카와바타',
  '祇園': '기온',
  '博多': '하카타',
  '東比恵': '히가시히에',
  '福岡空港': '후쿠오카공항',
  '呉服町': '고후쿠마치',
  '千代県庁口': '치요켄초구치',
  '馬出九大病院前': '마이다시큐다이뵤인마에',
  '箱崎宮前': '하코자키미야마에',
  '箱崎九大前': '하코자키큐다이마에',
  '貝塚': '가이즈카',
  '橋本': '하시모토',
  '次郎丸': '지로마루',
  '賀茂': '가모',
  '野芥': '노케',
  '梅林': '우메바야시',
  '福大前': '후쿠다이마에',
  '七隈': '나나쿠마',
  '金山': '가나야마',
  '茶山': '차야마',
  '別府': '베후',
  '六本松': '롯폰마쓰',
  '桜坂': '사쿠라자카',
  '薬院大通': '야쿠인오도리',
  '薬院': '야쿠인',
  '渡辺通': '와타나베도리',
  '天神南': '텐진미나미',
  '櫛田神社前': '쿠시다진자마에',
};

class FukuokaSubwayStation implements PassNamedPlace {
  const FukuokaSubwayStation({
    required this.id,
    required this.nameJa,
    required this.nameEn,
    required this.stationCodes,
  });

  final String id;
  @override
  final String nameJa;
  @override
  final String nameEn;
  final List<String> stationCodes;

  @override
  String get nameKo => _koreanNames[nameJa] ?? nameJa;
  String get displayName => nameKo;
  @override
  String get secondaryLabel => '$nameJa · 후쿠오카시 지하철';
}

class FukuokaCitySubwayPassData {
  FukuokaCitySubwayPassData._({
    required this.stations,
    required Map<String, int> fares,
  }) : _fares = fares,
       _searchIndex = stations.map(_SearchEntry.new).toList(growable: false);

  static const passPrice = 640;
  final List<FukuokaSubwayStation> stations;
  final Map<String, int> _fares;
  final List<_SearchEntry> _searchIndex;

  static FukuokaCitySubwayPassData fromCsv({
    required String stationsCsv,
    required String faresCsv,
  }) {
    final stationRows = _csvRows(stationsCsv);
    final stations = stationRows
        .map(
          (row) => FukuokaSubwayStation(
            id: row['station_id']!,
            nameJa: row['name_ja']!,
            nameEn: row['name_en']!,
            stationCodes: row['station_codes']!.split('|'),
          ),
        )
        .toList(growable: false);
    final fares = <String, int>{
      for (final row in _csvRows(faresCsv))
        '${row['origin_id']}|${row['destination_id']}': int.parse(
          row['adult_fare_yen']!,
        ),
    };
    return FukuokaCitySubwayPassData._(stations: stations, fares: fares);
  }

  int? fareBetween(FukuokaSubwayStation from, FukuokaSubwayStation to) {
    if (from.id == to.id) return null;
    return _fares['${from.id}|${to.id}'];
  }

  List<FukuokaSubwayStation> search(String query, {int limit = 20}) {
    final normalized = normalizeStationSearchText(query);
    if (normalized.isEmpty) return const [];
    final initials = hangulInitials(normalized);
    final isInitialQuery = isHangulInitialSearch(normalized);
    final matches = <({FukuokaSubwayStation station, int score})>[];
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

class FukuokaCitySubwayPassDataRepository {
  const FukuokaCitySubwayPassDataRepository();

  static Future<FukuokaCitySubwayPassData>? _cachedLoad;

  Future<FukuokaCitySubwayPassData> load() => _cachedLoad ??= _load();

  Future<FukuokaCitySubwayPassData>
  _load() async => FukuokaCitySubwayPassData.fromCsv(
    stationsCsv: await rootBundle.loadString(
      'assets/data/pass_comparison/fukuoka_city_subway_1day_stations_2026.csv',
    ),
    faresCsv: await rootBundle.loadString(
      'assets/data/pass_comparison/fukuoka_city_subway_1day_fares_2026.csv',
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

  final FukuokaSubwayStation station;
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
