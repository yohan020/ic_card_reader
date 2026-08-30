import 'dart:convert';

import 'package:flutter/services.dart';

import 'pass_transit_data.dart';

class KyotoSubwayStation {
  const KyotoSubwayStation({
    required this.id,
    required this.nameJa,
    required this.nameKo,
    required this.lineJa,
    required this.lineKo,
  });

  factory KyotoSubwayStation.fromJson(List<dynamic> row) => KyotoSubwayStation(
    id: row[0] as String,
    nameJa: row[1] as String,
    nameKo: row[2] as String,
    lineJa: row[3] as String,
    lineKo: row[4] as String,
  );

  final String id;
  final String nameJa;
  final String nameKo;
  final String lineJa;
  final String lineKo;

  String get displayName => nameKo.isEmpty ? nameJa : nameKo;
  String get secondaryLabel => '$nameJa · 교토시영 지하철 · $lineKo';
}

class KyotoSubwayBusPassData {
  KyotoSubwayBusPassData._({
    required this.stations,
    required List<_KyotoEdge> edges,
    required List<_KyotoFareBand> fareBands,
    required this.passPrice,
    required this.cityBusFare,
    required this.sightseeingExpressFare,
  }) : _edges = edges,
       _fareBands = fareBands,
       _byId = {for (final station in stations) station.id: station},
       _index = stations.map(_KyotoSearchEntry.new).toList(growable: false);

  factory KyotoSubwayBusPassData.fromJson(String source) {
    final root = jsonDecode(source) as Map<String, dynamic>;
    final bus = root['bus_fares'] as Map<String, dynamic>;
    return KyotoSubwayBusPassData._(
      stations: (root['stations'] as List<dynamic>)
          .cast<List<dynamic>>()
          .map(KyotoSubwayStation.fromJson)
          .toList(growable: false),
      edges: (root['edges'] as List<dynamic>)
          .cast<List<dynamic>>()
          .map(
            (row) => _KyotoEdge(
              row[0] as String,
              row[1] as String,
              (row[2] as num).toDouble(),
            ),
          )
          .toList(growable: false),
      fareBands: (root['fare_bands'] as List<dynamic>)
          .cast<List<dynamic>>()
          .map(
            (row) => _KyotoFareBand((row[0] as num).toDouble(), row[1] as int),
          )
          .toList(growable: false),
      passPrice: root['pass_price_yen'] as int,
      cityBusFare: bus['city_bus'] as int,
      sightseeingExpressFare: bus['sightseeing_express'] as int,
    );
  }

  final List<KyotoSubwayStation> stations;
  final List<_KyotoEdge> _edges;
  final List<_KyotoFareBand> _fareBands;
  final int passPrice;
  final int cityBusFare;
  final int sightseeingExpressFare;
  final Map<String, KyotoSubwayStation> _byId;
  final List<_KyotoSearchEntry> _index;

  int? fareBetween(KyotoSubwayStation from, KyotoSubwayStation to) {
    if (from.id == to.id) return null;
    final distance = _shortestDistance(from.id, to.id);
    if (distance == null) return null;
    return _fareBands.firstWhere((band) => distance <= band.maximumKm).fare;
  }

  List<KyotoSubwayStation> search(String query, {int limit = 20}) {
    final normalized = normalizeStationSearchText(query);
    if (normalized.isEmpty) return const [];
    final initials = hangulInitials(normalized);
    final matches = <({KyotoSubwayStation station, int score})>[];
    for (final entry in _index) {
      var score = 1000;
      for (final candidate in entry.candidates) {
        if (candidate.normalized == normalized) {
          score = 0;
        }
        if (candidate.normalized.startsWith(normalized)) {
          score = score < 10 ? score : 10;
        }
        if (candidate.initials.startsWith(initials)) {
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
        .map((match) => match.station)
        .toList(growable: false);
  }

  double? _shortestDistance(String from, String to) {
    final graph = <String, List<_KyotoEdge>>{};
    for (final edge in _edges) {
      graph.putIfAbsent(edge.from, () => []).add(edge);
      graph
          .putIfAbsent(edge.to, () => [])
          .add(_KyotoEdge(edge.to, edge.from, edge.km));
    }
    final distances = <String, double>{from: 0};
    final unsettled = _byId.keys.toSet();
    while (unsettled.isNotEmpty) {
      String? current;
      var best = double.infinity;
      for (final id in unsettled) {
        final value = distances[id] ?? double.infinity;
        if (value < best) {
          current = id;
          best = value;
        }
      }
      if (current == null || best == double.infinity) {
        return null;
      }
      if (current == to) {
        return best;
      }
      unsettled.remove(current);
      for (final edge in graph[current] ?? const []) {
        if (!unsettled.contains(edge.to)) {
          continue;
        }
        final candidate = best + edge.km;
        if (candidate < (distances[edge.to] ?? double.infinity)) {
          distances[edge.to] = candidate;
        }
      }
    }
    return null;
  }
}

class KyotoSubwayBusPassDataRepository {
  const KyotoSubwayBusPassDataRepository();
  Future<KyotoSubwayBusPassData> load() async =>
      KyotoSubwayBusPassData.fromJson(
        await rootBundle.loadString(
          'assets/data/pass_comparison/kyoto_subway_bus_1day_2026.json',
        ),
      );
}

class _KyotoSearchEntry {
  _KyotoSearchEntry(this.station)
    : candidates =
          {
                station.nameJa,
                station.nameKo,
                station.lineJa,
                station.lineKo,
                '교토시영 지하철',
              }
              .map(
                (value) => (
                  normalized: normalizeStationSearchText(value),
                  initials: hangulInitials(normalizeStationSearchText(value)),
                ),
              )
              .toList(growable: false);
  final KyotoSubwayStation station;
  final List<({String normalized, String initials})> candidates;
}

class _KyotoEdge {
  const _KyotoEdge(this.from, this.to, this.km);
  final String from;
  final String to;
  final double km;
}

class _KyotoFareBand {
  const _KyotoFareBand(this.maximumKm, this.fare);
  final double maximumKm;
  final int fare;
}
