import 'package:flutter/services.dart';

import 'pass_transit_data.dart';

const _koreanNames = <String, String>{
  '足守': '아시모리',
  '備中箕島': '빗추미시마',
  '備中高松': '빗추타카마쓰',
  '備前一宮': '비젠이치노미야',
  '備前片岡': '비젠카타오카',
  '備前三門': '비젠미카도',
  '備前西市': '비젠니시이치',
  '備前田井': '비젠타이',
  '茶屋町': '차야마치',
  '大安寺': '다이안지',
  '八浜': '하치하마',
  '服部': '핫토리',
  '早島': '하야시마',
  '迫川': '하자카와',
  '東総社': '히가시소자',
  '彦崎': '히코사키',
  '上の町': '가미노초',
  '吉備津': '기비쓰',
  '木見': '기미',
  '北長瀬': '기타나가세',
  '清音': '기요네',
  '児島': '고지마',
  '久々原': '구구하라',
  '倉敷': '구라시키',
  '中庄': '나카쇼',
  '西阿知': '니시아치',
  '庭瀬': '니와세',
  '岡山': '오카야마',
  '大元': '오모토',
  '妹尾': '세노오',
  '新倉敷': '신쿠라시키',
  '総社': '소자',
  '常山': '쓰네야마',
  '植松': '우에마쓰',
  '宇野': '우노',
};

class OkayamaKurashikiGururinStation {
  const OkayamaKurashikiGururinStation({
    required this.id,
    required this.nameJa,
    required this.nameEn,
  });

  final String id;
  final String nameJa;
  final String nameEn;

  String get nameKo => _koreanNames[nameJa] ?? nameJa;
  String get displayName => nameKo;
  String get secondaryLabel => '$nameJa · JR 서일본';
}

class OkayamaKurashikiGururinPassData {
  OkayamaKurashikiGururinPassData._({
    required this.stations,
    required Map<String, int> fares,
    required this.services,
  }) : _fares = fares,
       _searchIndex = stations.map(_SearchEntry.new).toList(growable: false);

  static const passPrice = 3800;
  static const validDays = 3;
  final List<OkayamaKurashikiGururinStation> stations;
  final List<OkayamaKurashikiGururinRideService> services;
  final Map<String, int> _fares;
  final List<_SearchEntry> _searchIndex;

  static OkayamaKurashikiGururinPassData fromCsv({
    required String stationsCsv,
    required String faresCsv,
  }) {
    final stationRows = _csvRows(stationsCsv);
    final stations = stationRows
        .map(
          (row) => OkayamaKurashikiGururinStation(
            id: row['station_id']!,
            nameJa: row['name_ja']!,
            nameEn: row['name_en']!,
          ),
        )
        .toList(growable: false);
    final fares = <String, int>{
      for (final row in _csvRows(faresCsv))
        '${row['origin']}|${row['destination']}': int.parse(
          row['adult_fare_yen']!,
        ),
    };
    return OkayamaKurashikiGururinPassData._(
      stations: stations,
      fares: fares,
      services: const [
        OkayamaKurashikiGururinRideService(
          id: 'okayama_tram',
          label: '오카야마 전기궤도',
          note: '전선 균일 · 1회 ¥160',
          fare: 160,
          isEstimate: false,
        ),
        OkayamaKurashikiGururinRideService(
          id: 'kojima_kurashiki_bus',
          label: '시모덴 버스 고지마–구라시키',
          note: '1회 ¥770 · 전 구간 대표 운임',
          fare: 770,
          isEstimate: true,
        ),
        OkayamaKurashikiGururinRideService(
          id: 'tokohai_bus',
          label: '도코하이호',
          note: '1회 ¥250 · 대표 운임',
          fare: 250,
          isEstimate: true,
        ),
        OkayamaKurashikiGururinRideService(
          id: 'jeans_bus',
          label: '진즈 버스',
          note: '1회 ¥200 · 금·토·일·공휴일 운행',
          fare: 200,
          isEstimate: false,
        ),
        OkayamaKurashikiGururinRideService(
          id: 'washuzan_bus',
          label: '와슈잔 석양 감상 버스',
          note: '1회 ¥540 · 금·토·공휴일 전날 운행',
          fare: 540,
          isEstimate: false,
        ),
      ],
    );
  }

  int? fareBetween(
    OkayamaKurashikiGururinStation from,
    OkayamaKurashikiGururinStation to,
  ) {
    if (from.id == to.id) return null;
    return _fares['${from.id}|${to.id}'];
  }

  List<OkayamaKurashikiGururinStation> search(String query, {int limit = 20}) {
    final normalized = normalizeStationSearchText(query);
    if (normalized.isEmpty) return const [];
    final initials = hangulInitials(normalized);
    final isInitialQuery = isHangulInitialSearch(normalized);
    final matches = <({OkayamaKurashikiGururinStation station, int score})>[];
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

class OkayamaKurashikiGururinPassDataRepository {
  const OkayamaKurashikiGururinPassDataRepository();

  static Future<OkayamaKurashikiGururinPassData>? _cachedLoad;

  Future<OkayamaKurashikiGururinPassData> load() => _cachedLoad ??= _load();

  Future<OkayamaKurashikiGururinPassData>
  _load() async => OkayamaKurashikiGururinPassData.fromCsv(
    stationsCsv: await rootBundle.loadString(
      'assets/data/pass_comparison/okayama_kurashiki_gururin_stations_2026.csv',
    ),
    faresCsv: await rootBundle.loadString(
      'assets/data/pass_comparison/okayama_kurashiki_gururin_fares_2026.csv',
    ),
  );
}

class OkayamaKurashikiGururinRideService {
  const OkayamaKurashikiGururinRideService({
    required this.id,
    required this.label,
    required this.note,
    required this.fare,
    required this.isEstimate,
  });

  final String id;
  final String label;
  final String note;
  final int fare;
  final bool isEstimate;
}

class _SearchEntry {
  _SearchEntry(this.station)
    : candidates = {station.nameJa, station.nameKo, station.nameEn}
          .map(normalizeStationSearchText)
          .where((value) => value.isNotEmpty)
          .map((value) => (normalized: value, initials: hangulInitials(value)))
          .toList(growable: false);

  final OkayamaKurashikiGururinStation station;
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
