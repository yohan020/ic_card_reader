import 'dart:convert';

import 'package:flutter/services.dart';

import 'pass_transit_data.dart';

class KintetsuStation {
  const KintetsuStation({
    required this.id,
    required this.nameJa,
    required this.nameEn,
    required this.nameKo,
    required this.operator,
    required this.lines,
  });

  factory KintetsuStation.fromJson(Map<String, dynamic> json) =>
      KintetsuStation(
        id: json['id'] as String,
        nameJa: json['ja'] as String,
        nameEn: json['en'] as String,
        nameKo: json['ko'] as String,
        operator: json['operator'] as String,
        lines: json['lines'] as String,
      );

  final String id;
  final String nameJa;
  final String nameEn;
  final String nameKo;
  final String operator;
  final String lines;

  String get displayName => nameKo.isEmpty
      ? nameJa
      : nameKo.endsWith('역')
      ? nameKo.substring(0, nameKo.length - 1)
      : nameKo;
  String get operatorLabel => operator == 'Iga Railway' ? '이가철도' : '긴테쓰 전철';
  String get secondaryLabel => '$nameJa · $operatorLabel';
}

class KintetsuRailPass5DayData {
  KintetsuRailPass5DayData._({
    required this.stations,
    required this.passPrice,
    required Map<String, int> fares,
  }) : _fares = fares,
       _index = stations.map(_SearchEntry.new).toList(growable: false);

  final List<KintetsuStation> stations;
  final int passPrice;
  final Map<String, int> _fares;
  final List<_SearchEntry> _index;

  factory KintetsuRailPass5DayData.forTest({
    required List<KintetsuStation> stations,
    required int passPrice,
    required Map<String, int> fares,
  }) => KintetsuRailPass5DayData._(
    stations: stations,
    passPrice: passPrice,
    fares: fares,
  );

  int? fareBetween(KintetsuStation from, KintetsuStation to) =>
      from.id == to.id ? null : _fares[_fareKey(from.id, to.id)];

  List<KintetsuStation> search(String query, {int limit = 20}) {
    final normalized = normalizeStationSearchText(query);
    if (normalized.isEmpty) return const [];
    final initials = hangulInitials(normalized);
    final isInitialQuery = isHangulInitialSearch(normalized);
    final matches = <({KintetsuStation station, int score})>[];
    for (final entry in _index) {
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
    return matches
        .take(limit)
        .map((item) => item.station)
        .toList(growable: false);
  }

  static String _fareKey(String first, String second) =>
      first.compareTo(second) <= 0 ? '$first|$second' : '$second|$first';
}

class KintetsuRailPass5DayDataRepository {
  const KintetsuRailPass5DayDataRepository();

  static Future<KintetsuRailPass5DayData>? _cachedLoad;

  Future<KintetsuRailPass5DayData> load() => _cachedLoad ??= _load();

  Future<KintetsuRailPass5DayData> _load() async {
    final files = await Future.wait([
      rootBundle.loadString(
        'assets/data/pass_comparison/kintetsu_rail_pass_5day_stations_2026.json',
      ),
      rootBundle.loadString(
        'assets/data/pass_comparison/kintetsu_rail_pass_5day_fares_2026.csv',
      ),
    ]);
    final root = jsonDecode(files[0]) as Map<String, dynamic>;
    final fares = <String, int>{};
    for (final line in const LineSplitter().convert(files[1]).skip(1)) {
      final values = line.split(',');
      if (values.length == 3) {
        fares[KintetsuRailPass5DayData._fareKey(values[0], values[1])] =
            int.parse(values[2]);
      }
    }
    return KintetsuRailPass5DayData._(
      passPrice: root['pass_price_yen'] as int,
      stations: (root['stations'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(KintetsuStation.fromJson)
          .toList(growable: false),
      fares: fares,
    );
  }
}

class _SearchEntry {
  _SearchEntry(this.station)
    : candidates = {station.nameJa, station.nameEn, station.nameKo}
          .where((value) => value.isNotEmpty)
          .map(
            (value) => (
              normalized: normalizeStationSearchText(value),
              initials: hangulInitials(normalizeStationSearchText(value)),
            ),
          )
          .toList(growable: false);
  final KintetsuStation station;
  final List<({String normalized, String initials})> candidates;
}
