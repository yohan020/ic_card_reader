import 'dart:collection';

import 'pass_transit_data.dart';
import 'pass_named_place.dart';

class SapporoSubwayStation implements PassNamedPlace {
  const SapporoSubwayStation({
    required this.id,
    required this.nameJa,
    required this.nameEn,
    required this.nameKo,
  });

  final String id;
  @override
  final String nameJa;
  @override
  final String nameEn;
  @override
  final String nameKo;

  String get displayName => nameKo;
  @override
  String get secondaryLabel => '$nameJa · 삿포로시 지하철';
}

/// Data normalized from the supplied 2026 Sapporo Subway fare package.
///
/// The 46 physical stations are held once: さっぽろ and 大通 are not duplicated
/// for their interchange lines. Fares are derived from the official distance
/// bands after the small fixed graph is built, then shared through [_cached].
class SapporoSubwayPassData {
  SapporoSubwayPassData._(this.stations, this._fares)
    : _searchIndex = stations.map(_SearchEntry.new).toList(growable: false);

  static Future<SapporoSubwayPassData>? _cached;

  final List<SapporoSubwayStation> stations;
  final Map<String, int> _fares;
  final List<_SearchEntry> _searchIndex;

  static Future<SapporoSubwayPassData> load() =>
      _cached ??= Future.value(_fromNormalizedData());

  static SapporoSubwayPassData _fromNormalizedData() {
    final stations = <SapporoSubwayStation>[
      for (final value in _stationRows)
        SapporoSubwayStation(
          id: value.$1,
          nameJa: value.$2,
          nameEn: value.$3,
          nameKo: value.$4,
        ),
    ];
    final byId = {for (final station in stations) station.id: station};
    final graph = <String, List<({String id, double km})>>{
      for (final station in stations) station.id: [],
    };
    for (final edge in _edges) {
      graph[edge.$1]!.add((id: edge.$2, km: edge.$3));
      graph[edge.$2]!.add((id: edge.$1, km: edge.$3));
    }
    final fares = <String, int>{};
    for (final origin in stations) {
      final distances = _shortestDistances(origin.id, graph);
      for (final destination in stations) {
        if (origin.id == destination.id) continue;
        fares['${origin.id}|${destination.id}'] = _fareForKm(
          distances[destination.id]!,
        );
      }
    }
    assert(byId.length == 46 && fares.length == 2070);
    return SapporoSubwayPassData._(stations, fares);
  }

  int? fareBetween(SapporoSubwayStation from, SapporoSubwayStation to) =>
      from.id == to.id ? null : _fares['${from.id}|${to.id}'];

  List<SapporoSubwayStation> search(String query, {int limit = 20}) {
    final normalized = normalizeStationSearchText(query);
    if (normalized.isEmpty) return const [];
    final initials = hangulInitials(normalized);
    final isInitialQuery = isHangulInitialSearch(normalized);
    final matches = <({SapporoSubwayStation station, int score})>[];
    for (final entry in _searchIndex) {
      var score = 1000;
      for (final candidate in entry.candidates) {
        if (candidate.normalized == normalized) {
          score = 0;
        }
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

class SapporoSubwayPassDataRepository {
  const SapporoSubwayPassDataRepository();
  Future<SapporoSubwayPassData> load() => SapporoSubwayPassData.load();
}

Map<String, double> _shortestDistances(
  String origin,
  Map<String, List<({String id, double km})>> graph,
) {
  final distances = <String, double>{origin: 0};
  final queue = SplayTreeSet<({String id, double km})>(
    (a, b) => a.km != b.km ? a.km.compareTo(b.km) : a.id.compareTo(b.id),
  )..add((id: origin, km: 0));
  while (queue.isNotEmpty) {
    final current = queue.first;
    queue.remove(current);
    if (current.km != distances[current.id]) continue;
    for (final edge in graph[current.id]!) {
      final next = current.km + edge.km;
      if (next < (distances[edge.id] ?? double.infinity)) {
        distances[edge.id] = next;
        queue.add((id: edge.id, km: next));
      }
    }
  }
  return distances;
}

int _fareForKm(double km) {
  // Source distances are specified to one decimal place. Normalize a binary
  // floating point sum before it is compared against an official boundary.
  final normalizedKm = (km * 10).round() / 10;
  if (normalizedKm <= 3) return 210;
  if (normalizedKm <= 7) return 250;
  if (normalizedKm <= 11) return 290;
  if (normalizedKm <= 15) return 330;
  if (normalizedKm <= 19) return 360;
  return 380;
}

class _SearchEntry {
  _SearchEntry(this.station)
    : candidates = {station.nameKo, station.nameJa, station.nameEn}
          .map(normalizeStationSearchText)
          .where((value) => value.isNotEmpty)
          .map((value) => (normalized: value, initials: hangulInitials(value)))
          .toList(growable: false);

  final SapporoSubwayStation station;
  final List<({String normalized, String initials})> candidates;
}

const _stationRows = <(String, String, String, String)>[
  ('S001', '麻生', 'Asabu', '아사부'),
  ('S002', '北34条', 'Kita-sanjuyo-jo', '기타34조'),
  ('S003', '北24条', 'Kita-nijuyo-jo', '기타24조'),
  ('S004', '北18条', 'Kita-juhachi-jo', '기타18조'),
  ('S005', '北12条', 'Kita-juni-jo', '기타12조'),
  ('S006', 'さっぽろ', 'Sapporo', '삿포로'),
  ('S007', '大通', 'Odori', '오도리'),
  ('S008', 'すすきの', 'Susukino', '스스키노'),
  ('S009', '中島公園', 'Nakajima-koen', '나카지마공원'),
  ('S010', '幌平橋', 'Horohira-bashi', '호로히라바시'),
  ('S011', '中の島', 'Nakanoshima', '나카노시마'),
  ('S012', '平岸', 'Hiragishi', '히라기시'),
  ('S013', '南平岸', 'Minami-hiragishi', '미나미히라기시'),
  ('S014', '澄川', 'Sumikawa', '스미카와'),
  ('S015', '自衛隊前', 'Jieitai-mae', '지에이타이마에'),
  ('S016', '真駒内', 'Makomanai', '마코마나이'),
  ('S017', '宮の沢', 'Miyanosawa', '미야노사와'),
  ('S018', '発寒南', 'Hassamu-minami', '핫사무미나미'),
  ('S019', '琴似', 'Kotoni', '고토니'),
  ('S020', '二十四軒', 'Nijuyon-ken', '니주욘켄'),
  ('S021', '西28丁目', 'Nishi-nijuhatchome', '니시28초메'),
  ('S022', '円山公園', 'Maruyama-koen', '마루야마공원'),
  ('S023', '西18丁目', 'Nishi-juhatchome', '니시18초메'),
  ('S024', '西11丁目', 'Nishi-juichome', '니시11초메'),
  ('S025', 'バスセンター前', 'Bus Center-mae', '버스센터마에'),
  ('S026', '菊水', 'Kikusui', '기쿠스이'),
  ('S027', '東札幌', 'Higashi-Sapporo', '히가시삿포로'),
  ('S028', '白石', 'Shiroishi', '시로이시'),
  ('S029', '南郷7丁目', 'Nango-nanachome', '난고7초메'),
  ('S030', '南郷13丁目', 'Nango-jusanchome', '난고13초메'),
  ('S031', '南郷18丁目', 'Nango-juhatchome', '난고18초메'),
  ('S032', '大谷地', 'Oyachi', '오야치'),
  ('S033', 'ひばりが丘', 'Hibarigaoka', '히바리가오카'),
  ('S034', '新さっぽろ', 'Shin-Sapporo', '신삿포로'),
  ('S035', '栄町', 'Sakaemachi', '사카에마치'),
  ('S036', '新道東', 'Shindo-higashi', '신도히가시'),
  ('S037', '元町', 'Motomachi', '모토마치'),
  ('S038', '環状通東', 'Kanjo-dori-higashi', '간조도리히가시'),
  ('S039', '東区役所前', 'Higashi-kuyakusho-mae', '히가시쿠야쿠쇼마에'),
  ('S040', '北13条東', 'Kita-jusanjo-higashi', '기타13조히가시'),
  ('S041', '豊水すすきの', 'Hosui-Susukino', '호스이스스키노'),
  ('S042', '学園前', 'Gakuen-mae', '가쿠엔마에'),
  ('S043', '豊平公園', 'Toyohira-koen', '도요히라공원'),
  ('S044', '美園', 'Misono', '미소노'),
  ('S045', '月寒中央', 'Tsukisamu-chuo', '쓰키사무추오'),
  ('S046', '福住', 'Fukuzumi', '후쿠즈미'),
];

const _edges = <(String, String, double)>[
  ('S001', 'S002', 1),
  ('S002', 'S003', 1.2),
  ('S003', 'S004', .9),
  ('S004', 'S005', .8),
  ('S005', 'S006', 1),
  ('S006', 'S007', .6),
  ('S007', 'S008', .6),
  ('S008', 'S009', .7),
  ('S009', 'S010', 1),
  ('S010', 'S011', .5),
  ('S011', 'S012', .7),
  ('S012', 'S013', 1.1),
  ('S013', 'S014', 1.2),
  ('S014', 'S015', 1.3),
  ('S015', 'S016', 1.7),
  ('S017', 'S018', 1.5),
  ('S018', 'S019', 1.3),
  ('S019', 'S020', .9),
  ('S020', 'S021', 1.2),
  ('S021', 'S022', .8),
  ('S022', 'S023', .9),
  ('S023', 'S024', .9),
  ('S024', 'S007', 1),
  ('S007', 'S025', .8),
  ('S025', 'S026', 1.1),
  ('S026', 'S027', 1.2),
  ('S027', 'S028', 1.1),
  ('S028', 'S029', 1.4),
  ('S029', 'S030', 1.1),
  ('S030', 'S031', 1.2),
  ('S031', 'S032', 1.5),
  ('S032', 'S033', 1),
  ('S033', 'S034', 1.2),
  ('S035', 'S036', .9),
  ('S036', 'S037', 1.2),
  ('S037', 'S038', 1.4),
  ('S038', 'S039', 1),
  ('S039', 'S040', .9),
  ('S040', 'S006', 1.3),
  ('S007', 'S041', .8),
  ('S041', 'S042', 1.4),
  ('S042', 'S043', .9),
  ('S043', 'S044', 1),
  ('S044', 'S045', 1.2),
  ('S045', 'S046', 1),
];
