import 'dart:convert';

import 'package:flutter/services.dart';

import 'pass_transit_data.dart';

class HankyuStation {
  const HankyuStation({
    required this.id,
    required this.nameJa,
    required this.nameKo,
  });

  factory HankyuStation.fromJson(Map<String, dynamic> json) => HankyuStation(
    id: json['id'] as String,
    nameJa: json['ja'] as String,
    nameKo: json['ko'] as String,
  );

  final String id;
  final String nameJa;
  final String nameKo;

  String get displayName => nameKo.isEmpty ? nameJa : nameKo;
  String get secondaryLabel => '$nameJa · 한큐 전철';
}

class Hankyu1DayPassData {
  Hankyu1DayPassData._({
    required this.stations,
    required this.passPrice,
    required Map<String, int> fares,
  }) : _fares = fares,
       _index = stations.map(_HankyuSearchEntry.new).toList(growable: false);

  factory Hankyu1DayPassData.fromJson(String source) {
    final root = jsonDecode(source) as Map<String, dynamic>;
    final fares = <String, int>{};
    for (final row in root['fares'] as List<dynamic>) {
      final values = row as List<dynamic>;
      fares['${values[0]}:${values[1]}'] = values[2] as int;
    }
    return Hankyu1DayPassData._(
      stations: (root['stations'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(HankyuStation.fromJson)
          .toList(growable: false),
      passPrice: root['pass_price_yen'] as int,
      fares: fares,
    );
  }

  final List<HankyuStation> stations;
  final int passPrice;
  final Map<String, int> _fares;
  final List<_HankyuSearchEntry> _index;

  int? fareBetween(HankyuStation from, HankyuStation to) {
    if (from.id == to.id) return null;
    return _fares['${from.id}:${to.id}'];
  }

  List<HankyuStation> search(String query, {int limit = 20}) {
    final normalized = normalizeStationSearchText(query);
    if (normalized.isEmpty) return const [];
    final initials = hangulInitials(normalized);
    final isInitialQuery = isHangulInitialSearch(normalized);
    final matches = <({HankyuStation station, int score})>[];
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
    return matches.take(limit).map((match) => match.station).toList();
  }
}

class Hankyu1DayPassDataRepository {
  const Hankyu1DayPassDataRepository();

  static Future<Hankyu1DayPassData>? _cachedLoad;

  Future<Hankyu1DayPassData> load() => _cachedLoad ??= _load();

  Future<Hankyu1DayPassData> _load() async => Hankyu1DayPassData.fromJson(
    await rootBundle.loadString(
      'assets/data/pass_comparison/hankyu_1day_2026.json',
    ),
  );
}

class _HankyuSearchEntry {
  _HankyuSearchEntry(this.station)
    : candidates = {station.nameJa, station.nameKo}
          .map(
            (value) => (
              normalized: normalizeStationSearchText(value),
              initials: hangulInitials(normalizeStationSearchText(value)),
            ),
          )
          .toList(growable: false);

  final HankyuStation station;
  final List<({String normalized, String initials})> candidates;
}
