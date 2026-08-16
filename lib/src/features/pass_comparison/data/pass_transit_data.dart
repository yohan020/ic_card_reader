import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/pass_comparison.dart';

const _hangulInitials = <String>[
  'ㄱ',
  'ㄲ',
  'ㄴ',
  'ㄷ',
  'ㄸ',
  'ㄹ',
  'ㅁ',
  'ㅂ',
  'ㅃ',
  'ㅅ',
  'ㅆ',
  'ㅇ',
  'ㅈ',
  'ㅉ',
  'ㅊ',
  'ㅋ',
  'ㅌ',
  'ㅍ',
  'ㅎ',
];

class PassStation {
  const PassStation({
    required this.id,
    required this.nameKo,
    required this.nameJa,
    required this.nameEn,
    required this.odptIds,
    required this.operators,
    required this.railways,
    required this.aliases,
  });

  factory PassStation.fromJson(Map<String, Object?> json) => PassStation(
    id: json['id']! as String,
    nameKo: json['nameKo']! as String,
    nameJa: json['nameJa']! as String,
    nameEn: json['nameEn']! as String,
    odptIds: _stringList(json['odptIds']),
    operators: _stringList(json['operators']),
    railways: _stringList(json['railways']),
    aliases: _stringList(json['aliases']),
  );

  final String id;
  final String nameKo;
  final String nameJa;
  final String nameEn;
  final List<String> odptIds;
  final List<String> operators;
  final List<String> railways;
  final List<String> aliases;

  String get displayName => nameKo.isNotEmpty ? nameKo : nameJa;

  String get secondaryLabel {
    final parts = <String>[
      if (nameJa.isNotEmpty && nameJa != displayName) nameJa,
      if (railways.isNotEmpty) railways.take(2).map(_shortId).join(' · '),
    ];
    return parts.join(' · ');
  }
}

class PassFare {
  const PassFare({
    required this.operatorId,
    required this.fromStationId,
    required this.toStationId,
    required this.adultIcFare,
  });

  factory PassFare.fromJson(Map<String, Object?> json) => PassFare(
    operatorId: json['operatorId']! as String,
    fromStationId: json['fromStationId']! as String,
    toStationId: json['toStationId']! as String,
    adultIcFare: json['adultIcFare']! as int,
  );

  final String operatorId;
  final String fromStationId;
  final String toStationId;
  final int adultIcFare;
}

class ResolvedPassFare {
  const ResolvedPassFare({required this.fare, required this.coverage});

  final int fare;
  final TransitCoverage coverage;
}

class PassTransitData {
  PassTransitData({
    required this.generatedAt,
    required this.source,
    required this.stations,
    required this.fares,
  }) : _stationIds = {
         for (final station in stations)
           for (final odptId in station.odptIds) odptId: station,
       };

  factory PassTransitData.fromJsonString(String source) {
    final json = jsonDecode(source) as Map<String, Object?>;
    return PassTransitData(
      generatedAt: DateTime.parse(json['generatedAt']! as String),
      source: json['source']! as String,
      stations: (json['stations']! as List<Object?>)
          .map((item) => PassStation.fromJson(_objectMap(item)))
          .toList(growable: false),
      fares: (json['fares']! as List<Object?>)
          .map((item) => PassFare.fromJson(_objectMap(item)))
          .toList(growable: false),
    );
  }

  final DateTime generatedAt;
  final String source;
  final List<PassStation> stations;
  final List<PassFare> fares;
  final Map<String, PassStation> _stationIds;

  List<PassStation> searchStations(String query, {int limit = 8}) {
    final normalizedQuery = normalizeStationSearchText(query);
    if (normalizedQuery.isEmpty) return const [];
    final queryInitials = hangulInitials(normalizedQuery);
    final ranked = <({PassStation station, int score})>[];

    for (final station in stations) {
      var best = 1000;
      final candidates = <String>{
        station.nameKo,
        station.nameJa,
        station.nameEn,
        ...station.aliases,
      };
      for (final candidate in candidates) {
        final normalized = normalizeStationSearchText(candidate);
        if (normalized.isEmpty) continue;
        if (normalized == normalizedQuery) {
          best = 0;
        } else if (normalized.startsWith(normalizedQuery)) {
          best = best > 10 ? 10 : best;
        } else if (hangulInitials(normalized).startsWith(queryInitials)) {
          best = best > 20 ? 20 : best;
        } else if (normalized.contains(normalizedQuery)) {
          best = best > 30 ? 30 : best;
        } else if (hangulInitials(normalized).contains(queryInitials)) {
          best = best > 40 ? 40 : best;
        }
      }
      if (best < 1000) ranked.add((station: station, score: best));
    }

    ranked.sort((a, b) {
      final byScore = a.score.compareTo(b.score);
      if (byScore != 0) return byScore;
      return a.station.displayName.compareTo(b.station.displayName);
    });
    return ranked.take(limit).map((item) => item.station).toList();
  }

  ResolvedPassFare? resolveFare(PassStation from, PassStation to) {
    PassFare? cheapest;
    for (final fare in fares) {
      final direct =
          from.odptIds.contains(fare.fromStationId) &&
          to.odptIds.contains(fare.toStationId);
      final reverse =
          from.odptIds.contains(fare.toStationId) &&
          to.odptIds.contains(fare.fromStationId);
      if (!direct && !reverse) continue;
      if (cheapest == null || fare.adultIcFare < cheapest.adultIcFare) {
        cheapest = fare;
      }
    }
    if (cheapest == null) return null;
    return ResolvedPassFare(
      fare: cheapest.adultIcFare,
      coverage: _coverageForFare(cheapest),
    );
  }

  PassStation? stationForOdptId(String id) => _stationIds[id];
}

class PassTransitDataRepository {
  const PassTransitDataRepository();

  static const assetPath = 'assets/data/pass_comparison/odpt_pass_data.json';

  Future<PassTransitData> load() async =>
      PassTransitData.fromJsonString(await rootBundle.loadString(assetPath));
}

String normalizeStationSearchText(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[\s·・()（）\-_]'), '')
    .replaceFirst(RegExp(r'역$'), '');

String hangulInitials(String value) {
  final buffer = StringBuffer();
  for (final rune in value.runes) {
    if (rune >= 0xac00 && rune <= 0xd7a3) {
      buffer.write(_hangulInitials[(rune - 0xac00) ~/ 588]);
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}

TransitCoverage _coverageForFare(PassFare fare) {
  if (fare.operatorId.endsWith(':TokyoMetro')) {
    return TransitCoverage.tokyoMetro;
  }
  if (fare.operatorId.endsWith(':Toei') &&
      _isToeiSubwayStation(fare.fromStationId) &&
      _isToeiSubwayStation(fare.toStationId)) {
    return TransitCoverage.toeiSubway;
  }
  return TransitCoverage.outside;
}

bool _isToeiSubwayStation(String stationId) => const [
  '.Asakusa.',
  '.Mita.',
  '.Shinjuku.',
  '.Oedo.',
].any(stationId.contains);

List<String> _stringList(Object? value) => (value as List<Object?>? ?? const [])
    .map((item) => item! as String)
    .toList(growable: false);

String _shortId(String value) => value.split(':').last;

Map<String, Object?> _objectMap(Object? value) =>
    Map<String, Object?>.from(value! as Map);
