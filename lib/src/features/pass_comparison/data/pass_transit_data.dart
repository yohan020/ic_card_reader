import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
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
    this.tokunaiPassEligible = false,
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
    tokunaiPassEligible: json['tokunaiPassEligible'] as bool? ?? false,
  );

  final String id;
  final String nameKo;
  final String nameJa;
  final String nameEn;
  final List<String> odptIds;
  final List<String> operators;
  final List<String> railways;
  final List<String> aliases;
  final bool tokunaiPassEligible;

  String get displayName => nameKo.isNotEmpty ? nameKo : nameJa;

  String get secondaryLabel {
    final parts = <String>[
      if (nameJa.isNotEmpty && nameJa != displayName) nameJa,
      if (railways.isNotEmpty) railways.take(2).map(_shortId).join(' · '),
    ];
    return parts.join(' · ');
  }
}

class _StationSearchEntry {
  _StationSearchEntry(this.station) {
    final normalizedCandidates =
        <String>{
              station.nameKo,
              station.nameJa,
              station.nameEn,
              ...station.aliases,
            }
            .map(normalizeStationSearchText)
            .where((value) => value.isNotEmpty)
            .toSet();
    candidates = [
      for (final value in normalizedCandidates)
        (normalized: value, initials: hangulInitials(value)),
    ];
  }

  final PassStation station;
  late final List<({String normalized, String initials})> candidates;
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

  TransitCoverage get coverage => _coverageForFare(this);
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
    this.tokunaiFareDataComplete = false,
  }) : _stationIds = {
         for (final station in stations)
           for (final odptId in station.odptIds) odptId: station,
       } {
    _searchIndex = stations
        .map(_StationSearchEntry.new)
        .toList(growable: false);
    final coveragesByFromStationId = <String, Set<TransitCoverage>>{};
    for (final fare in fares) {
      (coveragesByFromStationId[fare.fromStationId] ??= <TransitCoverage>{})
          .add(fare.coverage);
    }
    _tokyoSubwayStationIds = _stationIdsForCoverage(
      coveragesByFromStationId,
      (coverage) => coverage.tokyoSubwayTicket,
    );
    _tokunaiStationIds = _stationIdsForCoverage(
      coveragesByFromStationId,
      (coverage) => coverage.tokunaiPass,
      include: (station) => station.tokunaiPassEligible,
    );
  }

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
      tokunaiFareDataComplete:
          json['tokunaiFareDataComplete'] as bool? ?? false,
    );
  }

  final DateTime generatedAt;
  final String source;
  final List<PassStation> stations;
  final List<PassFare> fares;
  final bool tokunaiFareDataComplete;
  final Map<String, PassStation> _stationIds;
  late final List<_StationSearchEntry> _searchIndex;
  late final Set<String> _tokyoSubwayStationIds;
  late final Set<String> _tokunaiStationIds;

  bool get hasTokunaiStationDirectory =>
      stations.any((station) => station.tokunaiPassEligible);

  bool get hasTokunaiJrFareData =>
      tokunaiFareDataComplete &&
      fares.any((fare) => fare.coverage == TransitCoverage.tokunaiJr);

  PassTransitData merge(PassTransitData additional) => PassTransitData(
    generatedAt: generatedAt.isAfter(additional.generatedAt)
        ? generatedAt
        : additional.generatedAt,
    source: '$source + ${additional.source}',
    stations: [...stations, ...additional.stations],
    fares: [...fares, ...additional.fares],
    tokunaiFareDataComplete:
        tokunaiFareDataComplete || additional.tokunaiFareDataComplete,
  );

  List<PassStation> searchStations(
    String query, {
    PassProduct? product,
    int limit = 8,
  }) {
    final normalizedQuery = normalizeStationSearchText(query);
    if (normalizedQuery.isEmpty) return const [];
    final queryInitials = hangulInitials(normalizedQuery);
    final ranked = <({PassStation station, int score})>[];
    final availableStationIds = product == null
        ? null
        : product.isTokyoSubwayTicket
        ? _tokyoSubwayStationIds
        : _tokunaiStationIds;

    for (final entry in _searchIndex) {
      final station = entry.station;
      if (availableStationIds != null &&
          !availableStationIds.contains(station.id)) {
        continue;
      }
      var best = 1000;
      for (final candidate in entry.candidates) {
        if (candidate.normalized == normalizedQuery) {
          best = 0;
        } else if (candidate.normalized.startsWith(normalizedQuery)) {
          best = best > 10 ? 10 : best;
        } else if (candidate.initials.startsWith(queryInitials)) {
          best = best > 20 ? 20 : best;
        } else if (candidate.normalized.contains(normalizedQuery)) {
          best = best > 30 ? 30 : best;
        } else if (candidate.initials.contains(queryInitials)) {
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
    final cheapest = _lowestFareBetween(from.odptIds, to.odptIds);
    if (cheapest != null) {
      return ResolvedPassFare(
        fare: cheapest.adultIcFare,
        coverage: _coverageForFare(cheapest),
      );
    }
    return _resolveMetroToToeiFare(from, to);
  }

  PassStation? stationForOdptId(String id) => _stationIds[id];

  Set<String> _stationIdsForCoverage(
    Map<String, Set<TransitCoverage>> coveragesByFromStationId,
    bool Function(TransitCoverage coverage) accepts, {
    bool Function(PassStation station)? include,
  }) => {
    for (final station in stations)
      if ((include?.call(station) ?? false) ||
          station.odptIds.any(
            (id) => coveragesByFromStationId[id]?.any(accepts) ?? false,
          ))
        station.id,
  };

  PassFare? _lowestFareBetween(
    Iterable<String> firstStationIds,
    Iterable<String> secondStationIds, {
    String? operatorId,
  }) {
    final first = firstStationIds.toSet();
    final second = secondStationIds.toSet();
    PassFare? cheapest;
    for (final fare in fares) {
      if (operatorId != null && fare.operatorId != operatorId) continue;
      final direct =
          first.contains(fare.fromStationId) &&
          second.contains(fare.toStationId);
      final reverse =
          first.contains(fare.toStationId) &&
          second.contains(fare.fromStationId);
      if (!direct && !reverse) continue;
      if (cheapest == null || fare.adultIcFare < cheapest.adultIcFare) {
        cheapest = fare;
      }
    }
    return cheapest;
  }

  ResolvedPassFare? _resolveMetroToToeiFare(PassStation from, PassStation to) {
    final candidates = <int>[];
    for (final transfer in _metroToToeiTransfers) {
      final metroFrom = _lowestFareBetween(
        from.odptIds,
        transfer.metroStationIds,
        operatorId: _tokyoMetroOperatorId,
      );
      final toeiTo = _lowestFareBetween(
        transfer.toeiStationIds,
        to.odptIds,
        operatorId: _toeiOperatorId,
      );
      if (metroFrom != null && toeiTo != null) {
        candidates.add(
          metroFrom.adultIcFare + toeiTo.adultIcFare - _metroToToeiDiscount,
        );
      }

      final toeiFrom = _lowestFareBetween(
        from.odptIds,
        transfer.toeiStationIds,
        operatorId: _toeiOperatorId,
      );
      final metroTo = _lowestFareBetween(
        transfer.metroStationIds,
        to.odptIds,
        operatorId: _tokyoMetroOperatorId,
      );
      if (toeiFrom != null && metroTo != null) {
        candidates.add(
          toeiFrom.adultIcFare + metroTo.adultIcFare - _metroToToeiDiscount,
        );
      }
    }
    if (candidates.isEmpty) return null;
    return ResolvedPassFare(
      fare: candidates.reduce(
        (value, element) => value < element ? value : element,
      ),
      coverage: TransitCoverage.metroToToeiSubway,
    );
  }
}

const _tokyoMetroOperatorId = 'odpt.Operator:TokyoMetro';
const _toeiOperatorId = 'odpt.Operator:Toei';
const _metroToToeiDiscount = 70;

class _MetroToToeiTransfer {
  const _MetroToToeiTransfer({
    required this.metroStationIds,
    required this.toeiStationIds,
  });

  final List<String> metroStationIds;
  final List<String> toeiStationIds;
}

// Official Metro↔Toei transfer stations. The connection fare is the two
// operator fares minus ¥70 when the transfer is completed within 60 minutes.
// Source: https://www.tokyometro.jp/ticket/guide/transfertime/index.html
const _metroToToeiTransfers = <_MetroToToeiTransfer>[
  _MetroToToeiTransfer(
    metroStationIds: ['odpt.Station:TokyoMetro.Ginza.Asakusa'],
    toeiStationIds: ['odpt.Station:Toei.Asakusa.Asakusa'],
  ),
  _MetroToToeiTransfer(
    metroStationIds: [
      'odpt.Station:TokyoMetro.Ginza.Nihombashi',
      'odpt.Station:TokyoMetro.Tozai.Nihombashi',
    ],
    toeiStationIds: ['odpt.Station:Toei.Asakusa.Nihombashi'],
  ),
  _MetroToToeiTransfer(
    metroStationIds: ['odpt.Station:TokyoMetro.Ginza.Shimbashi'],
    toeiStationIds: ['odpt.Station:Toei.Asakusa.Shimbashi'],
  ),
  _MetroToToeiTransfer(
    metroStationIds: [
      'odpt.Station:TokyoMetro.Marunouchi.ShinjukuSanchome',
      'odpt.Station:TokyoMetro.Fukutoshin.ShinjukuSanchome',
    ],
    toeiStationIds: ['odpt.Station:Toei.Shinjuku.ShinjukuSanchome'],
  ),
  _MetroToToeiTransfer(
    metroStationIds: [
      'odpt.Station:TokyoMetro.Marunouchi.Otemachi',
      'odpt.Station:TokyoMetro.Tozai.Otemachi',
      'odpt.Station:TokyoMetro.Chiyoda.Otemachi',
      'odpt.Station:TokyoMetro.Hanzomon.Otemachi',
    ],
    toeiStationIds: ['odpt.Station:Toei.Mita.Otemachi'],
  ),
  _MetroToToeiTransfer(
    metroStationIds: ['odpt.Station:TokyoMetro.Marunouchi.Awajicho'],
    toeiStationIds: ['odpt.Station:Toei.Shinjuku.Ogawamachi'],
  ),
  _MetroToToeiTransfer(
    metroStationIds: ['odpt.Station:TokyoMetro.Chiyoda.ShinOchanomizu'],
    toeiStationIds: ['odpt.Station:Toei.Shinjuku.Ogawamachi'],
  ),
  _MetroToToeiTransfer(
    metroStationIds: ['odpt.Station:TokyoMetro.Hibiya.Ningyocho'],
    toeiStationIds: ['odpt.Station:Toei.Asakusa.Ningyocho'],
  ),
  _MetroToToeiTransfer(
    metroStationIds: ['odpt.Station:TokyoMetro.Hanzomon.Suitengumae'],
    toeiStationIds: ['odpt.Station:Toei.Asakusa.Ningyocho'],
  ),
  _MetroToToeiTransfer(
    metroStationIds: ['odpt.Station:TokyoMetro.Hibiya.HigashiGinza'],
    toeiStationIds: ['odpt.Station:Toei.Asakusa.HigashiGinza'],
  ),
  _MetroToToeiTransfer(
    metroStationIds: [
      'odpt.Station:TokyoMetro.Hibiya.Hibiya',
      'odpt.Station:TokyoMetro.Chiyoda.Hibiya',
    ],
    toeiStationIds: ['odpt.Station:Toei.Mita.Hibiya'],
  ),
  _MetroToToeiTransfer(
    metroStationIds: ['odpt.Station:TokyoMetro.Yurakucho.Yurakucho'],
    toeiStationIds: ['odpt.Station:Toei.Mita.Hibiya'],
  ),
  _MetroToToeiTransfer(
    metroStationIds: ['odpt.Station:TokyoMetro.Hanzomon.Jimbocho'],
    toeiStationIds: [
      'odpt.Station:Toei.Mita.Jimbocho',
      'odpt.Station:Toei.Shinjuku.Jimbocho',
    ],
  ),
  _MetroToToeiTransfer(
    metroStationIds: [
      'odpt.Station:TokyoMetro.Namboku.Ichigaya',
      'odpt.Station:TokyoMetro.Yurakucho.Ichigaya',
    ],
    toeiStationIds: ['odpt.Station:Toei.Shinjuku.Ichigaya'],
  ),
  _MetroToToeiTransfer(
    metroStationIds: [
      'odpt.Station:TokyoMetro.Marunouchi.NakanoSakaue',
      'odpt.Station:TokyoMetro.MarunouchiBranch.NakanoSakaue',
    ],
    toeiStationIds: ['odpt.Station:Toei.Oedo.NakanoSakaue'],
  ),
  _MetroToToeiTransfer(
    metroStationIds: [
      'odpt.Station:TokyoMetro.Ginza.AoyamaItchome',
      'odpt.Station:TokyoMetro.Hanzomon.AoyamaItchome',
    ],
    toeiStationIds: ['odpt.Station:Toei.Oedo.AoyamaItchome'],
  ),
  _MetroToToeiTransfer(
    metroStationIds: ['odpt.Station:TokyoMetro.Hibiya.Roppongi'],
    toeiStationIds: ['odpt.Station:Toei.Oedo.Roppongi'],
  ),
  _MetroToToeiTransfer(
    metroStationIds: ['odpt.Station:TokyoMetro.Namboku.AzabuJuban'],
    toeiStationIds: ['odpt.Station:Toei.Oedo.AzabuJuban'],
  ),
  _MetroToToeiTransfer(
    metroStationIds: ['odpt.Station:TokyoMetro.Yurakucho.Tsukishima'],
    toeiStationIds: ['odpt.Station:Toei.Oedo.Tsukishima'],
  ),
  _MetroToToeiTransfer(
    metroStationIds: ['odpt.Station:TokyoMetro.Tozai.MonzenNakacho'],
    toeiStationIds: ['odpt.Station:Toei.Oedo.MonzenNakacho'],
  ),
  _MetroToToeiTransfer(
    metroStationIds: ['odpt.Station:TokyoMetro.Ginza.UenoHirokoji'],
    toeiStationIds: ['odpt.Station:Toei.Oedo.UenoOkachimachi'],
  ),
  _MetroToToeiTransfer(
    metroStationIds: ['odpt.Station:TokyoMetro.Hibiya.NakaOkachimachi'],
    toeiStationIds: ['odpt.Station:Toei.Oedo.UenoOkachimachi'],
  ),
  _MetroToToeiTransfer(
    metroStationIds: ['odpt.Station:TokyoMetro.Marunouchi.HongoSanchome'],
    toeiStationIds: ['odpt.Station:Toei.Oedo.HongoSanchome'],
  ),
  _MetroToToeiTransfer(
    metroStationIds: [
      'odpt.Station:TokyoMetro.Marunouchi.Korakuen',
      'odpt.Station:TokyoMetro.Namboku.Korakuen',
    ],
    toeiStationIds: [
      'odpt.Station:Toei.Mita.Kasuga',
      'odpt.Station:Toei.Oedo.Kasuga',
    ],
  ),
  _MetroToToeiTransfer(
    metroStationIds: [
      'odpt.Station:TokyoMetro.Tozai.Iidabashi',
      'odpt.Station:TokyoMetro.Yurakucho.Iidabashi',
      'odpt.Station:TokyoMetro.Namboku.Iidabashi',
    ],
    toeiStationIds: ['odpt.Station:Toei.Oedo.Iidabashi'],
  ),
  _MetroToToeiTransfer(
    metroStationIds: ['odpt.Station:TokyoMetro.Marunouchi.Shinjuku'],
    toeiStationIds: ['odpt.Station:Toei.Oedo.ShinjukuNishiguchi'],
  ),
  _MetroToToeiTransfer(
    metroStationIds: ['odpt.Station:TokyoMetro.Hanzomon.KiyosumiShirakawa'],
    toeiStationIds: ['odpt.Station:Toei.Oedo.KiyosumiShirakawa'],
  ),
  _MetroToToeiTransfer(
    metroStationIds: ['odpt.Station:TokyoMetro.Hanzomon.Sumiyoshi'],
    toeiStationIds: ['odpt.Station:Toei.Shinjuku.Sumiyoshi'],
  ),
  _MetroToToeiTransfer(
    metroStationIds: ['odpt.Station:TokyoMetro.Hanzomon.Oshiage'],
    toeiStationIds: ['odpt.Station:Toei.Asakusa.Oshiage'],
  ),
  _MetroToToeiTransfer(
    metroStationIds: ['odpt.Station:TokyoMetro.Fukutoshin.HigashiShinjuku'],
    toeiStationIds: ['odpt.Station:Toei.Oedo.HigashiShinjuku'],
  ),
  _MetroToToeiTransfer(
    metroStationIds: ['odpt.Station:TokyoMetro.Hibiya.Akihabara'],
    toeiStationIds: ['odpt.Station:Toei.Shinjuku.Iwamotocho'],
  ),
];

class PassTransitDataRepository {
  const PassTransitDataRepository();

  static const assetPath = 'assets/data/pass_comparison/odpt_pass_data.json';
  static const tokunaiAssetPath =
      'assets/data/pass_comparison/tokunai_jr_data.json';
  static Future<PassTransitData>? _cachedLoad;

  /// Starts the shared load before the user selects a pass.
  void warmUp() => unawaited(load());

  Future<PassTransitData> load() => _cachedLoad ??= _load();

  Future<PassTransitData> _load() async {
    final odptSource = await rootBundle.loadString(assetPath);
    String? tokunaiSource;
    try {
      tokunaiSource = await rootBundle.loadString(tokunaiAssetPath);
    } on FlutterError {
      // The Tokyo Subway Ticket data remains usable without the optional JR
      // asset, matching the former fallback behavior.
    }
    final sources = <String, String>{'odpt': odptSource};
    if (tokunaiSource != null) sources['tokunai'] = tokunaiSource;
    return compute(_parsePassTransitData, sources);
  }
}

PassTransitData _parsePassTransitData(Map<String, String> sources) {
  final odpt = PassTransitData.fromJsonString(sources['odpt']!);
  final tokunaiSource = sources['tokunai'];
  return tokunaiSource == null
      ? odpt
      : odpt.merge(PassTransitData.fromJsonString(tokunaiSource));
}

final _stationSearchSeparators = RegExp(r'[\s·・()（）\-_]');
final _stationSuffix = RegExp(r'역$');

String normalizeStationSearchText(String value) => value
    .toLowerCase()
    .replaceAll(_stationSearchSeparators, '')
    .replaceFirst(_stationSuffix, '');

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
  if (fare.operatorId == 'jr-east:tokunai') {
    return TransitCoverage.tokunaiJr;
  }
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
