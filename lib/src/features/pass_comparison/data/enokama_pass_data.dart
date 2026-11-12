import 'dart:convert';

import 'package:flutter/services.dart';

import 'pass_named_place.dart';
import 'pass_station_english.g.dart';

import 'pass_transit_data.dart';

class EnokamaStation implements PassNamedPlace {
  @override
  String get nameEn => passStationEnglish['enokama:$id'] ?? '';

  const EnokamaStation({
    required this.id,
    required this.nameJa,
    required this.nameKo,
    required this.operator,
    required this.line,
  });

  factory EnokamaStation.fromJson(Map<String, dynamic> json) => EnokamaStation(
    id: json['id'] as String,
    nameJa: json['ja'] as String,
    nameKo: json['ko'] as String,
    operator: json['operator'] as String,
    line: json['line'] as String,
  );

  final String id;
  @override
  final String nameJa;
  @override
  final String nameKo;
  final String operator;
  final String line;
  String get displayName => nameKo.isEmpty ? nameJa : nameKo;
  @override
  String get secondaryLabel =>
      '$nameJa · ${operator == 'Enoshima Electric Railway' ? '에노덴' : '오다큐 전철'}';
}

class EnokamaOrigin implements PassNamedPlace {
  @override
  String get nameEn => passStationEnglish['enokama-origin:$id'] ?? '';

  const EnokamaOrigin({
    required this.id,
    required this.nameJa,
    required this.nameKo,
    required this.line,
    required this.passPrice,
    required this.roundTripFare,
    required this.roundTripApplicable,
  });

  factory EnokamaOrigin.fromJson(Map<String, dynamic> json) => EnokamaOrigin(
    id: json['id'] as String,
    nameJa: json['ja'] as String,
    nameKo: json['ko'] as String,
    line: json['line'] as String,
    passPrice: json['pass_price'] as int,
    roundTripFare: json['roundtrip_ic'] as int,
    roundTripApplicable: json['applicable'] as bool,
  );

  final String id;
  @override
  final String nameJa;
  @override
  final String nameKo;
  final String line;
  final int passPrice;
  final int roundTripFare;
  final bool roundTripApplicable;
  String get displayName => nameKo.isEmpty ? nameJa : nameKo;
  @override
  String get secondaryLabel =>
      '$nameJa · 오다큐 ${line == 'Tama Line'
          ? '다마선'
          : line == 'Enoshima Line'
          ? '에노시마선'
          : '오다와라선'}';
}

class EnokamaPassData {
  EnokamaPassData._({
    required this.origins,
    required this.stations,
    required Map<String, int> fares,
  }) : _fares = fares;

  factory EnokamaPassData.fromJson(String source) {
    final root = jsonDecode(source) as Map<String, dynamic>;
    final fares = <String, int>{};
    for (final row in root['fares'] as List<dynamic>) {
      final value = row as Map<String, dynamic>;
      fares['${value['from']}:${value['to']}'] = value['adult_ic_yen'] as int;
    }
    return EnokamaPassData._(
      origins: (root['origins'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(EnokamaOrigin.fromJson)
          .toList(growable: false),
      stations: (root['stations'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(EnokamaStation.fromJson)
          .toList(growable: false),
      fares: fares,
    );
  }

  final List<EnokamaOrigin> origins;
  final List<EnokamaStation> stations;
  final Map<String, int> _fares;

  int? fareBetween(EnokamaStation from, EnokamaStation to) =>
      from.id == to.id ? null : _fares['${from.id}:${to.id}'];

  List<EnokamaStation> searchStations(String query) => _search(
    query,
    stations,
    (value) => [value.nameJa, value.nameKo, value.nameEn],
  );
  List<EnokamaOrigin> searchOrigins(String query) => _search(
    query,
    origins,
    (value) => [value.nameJa, value.nameKo, value.nameEn],
  );

  List<T> _search<T>(
    String query,
    List<T> values,
    List<String> Function(T) names,
  ) {
    final normalized = normalizeStationSearchText(query);
    if (normalized.isEmpty) return const [];
    final initials = hangulInitials(normalized);
    final isInitialQuery = isHangulInitialSearch(normalized);
    final matches = <({T value, int score})>[];
    for (final value in values) {
      var score = 100;
      for (final name in names(value)) {
        final candidate = normalizeStationSearchText(name);
        if (candidate == normalized) score = 0;
        if (candidate.startsWith(normalized)) score = score < 10 ? score : 10;
        if (isInitialQuery && hangulInitials(candidate).startsWith(initials)) {
          score = score < 20 ? score : 20;
        }
        if (candidate.contains(normalized)) score = score < 30 ? score : 30;
      }
      if (score < 100) matches.add((value: value, score: score));
    }
    matches.sort((a, b) => a.score.compareTo(b.score));
    return matches.take(20).map((match) => match.value).toList();
  }
}

class EnokamaPassDataRepository {
  const EnokamaPassDataRepository();

  static Future<EnokamaPassData>? _cachedLoad;

  Future<EnokamaPassData> load() => _cachedLoad ??= _load();

  Future<EnokamaPassData> _load() async => EnokamaPassData.fromJson(
    await rootBundle.loadString(
      'assets/data/pass_comparison/enokama_2026.json',
    ),
  );
}
