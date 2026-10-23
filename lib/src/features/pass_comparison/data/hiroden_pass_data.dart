import 'package:flutter/services.dart';

import 'pass_transit_data.dart';

class HirodenStation {
  const HirodenStation({
    required this.id,
    required this.nameJa,
    required this.nameEn,
    required this.nameKo,
  });

  final String id;
  final String nameJa;
  final String nameEn;
  final String nameKo;

  String get displayName => nameKo;
  String get secondaryLabel => '$nameJa · 히로시마 전철';
}

class HirodenPassData {
  HirodenPassData._(this.stations)
    : _searchIndex = stations.map(_SearchEntry.new).toList(growable: false);

  static const adultFlatFare = 240;

  final List<HirodenStation> stations;
  final List<_SearchEntry> _searchIndex;

  static HirodenPassData fromCsv(String source) {
    final stations = _csvRows(source)
        .map(
          (row) => HirodenStation(
            id: row['station_id']!,
            nameJa: row['name_ja']!,
            nameEn: row['name_en']!,
            nameKo: row['name_ko']!,
          ),
        )
        .toList(growable: false);
    return HirodenPassData._(stations);
  }

  int? fareBetween(HirodenStation from, HirodenStation to) =>
      from.id == to.id ? null : adultFlatFare;

  List<HirodenStation> search(String query, {int limit = 20}) {
    final normalized = normalizeStationSearchText(query);
    if (normalized.isEmpty) return const [];
    final initials = hangulInitials(normalized);
    final isInitialQuery = isHangulInitialSearch(normalized);
    final matches = <({HirodenStation station, int score})>[];
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

class HirodenPassDataRepository {
  const HirodenPassDataRepository();

  static Future<HirodenPassData>? _cachedLoad;

  Future<HirodenPassData> load() => _cachedLoad ??= _load();

  Future<HirodenPassData> _load() async => HirodenPassData.fromCsv(
    await rootBundle.loadString(
      'assets/data/pass_comparison/hiroden_stations_2026.csv',
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

  final HirodenStation station;
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
