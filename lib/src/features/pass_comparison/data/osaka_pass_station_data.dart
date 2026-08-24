import 'dart:convert';

import 'package:flutter/services.dart';

import 'pass_transit_data.dart';

class OsakaPassStation {
  const OsakaPassStation({
    required this.nameJa,
    required this.nameKo,
    required this.lines,
    this.id = '',
    this.operator = 'Osaka Metro',
  });

  factory OsakaPassStation.fromJson(Map<String, dynamic> json) =>
      OsakaPassStation(
        id: json['id'] as String,
        operator: json['operator'] as String,
        nameJa: json['name_ja'] as String,
        nameKo: json['name_ko'] as String? ?? '',
        lines: (json['lines'] as List<dynamic>).cast<String>(),
      );

  final String id;
  final String operator;
  final String nameJa;
  final String nameKo;
  final List<String> lines;

  String get lookupId => id.isEmpty ? '$operator::$nameJa' : id;
  String get displayName => nameKo.isEmpty ? nameJa : nameKo;
  String get secondaryLabel => [
    if (nameKo.isNotEmpty) nameJa,
    operatorDisplayName(operator),
    ...lines,
  ].join(' · ');
}

class OsakaPassSource {
  const OsakaPassSource({
    required this.label,
    required this.url,
    required this.note,
  });

  factory OsakaPassSource.fromJson(Map<String, dynamic> json) =>
      OsakaPassSource(
        label: json['label'] as String,
        url: json['url'] as String,
        note: json['note'] as String? ?? '',
      );

  final String label;
  final String url;
  final String note;
}

class OsakaRailEdge {
  const OsakaRailEdge({
    required this.fromId,
    required this.toId,
    required this.distanceKm,
    required this.line,
  });

  factory OsakaRailEdge.fromJson(List<dynamic> row) => OsakaRailEdge(
    fromId: row[0] as String,
    toId: row[1] as String,
    distanceKm: (row[2] as num).toDouble(),
    line: row[3] as String,
  );

  final String fromId;
  final String toId;
  final double distanceKm;
  final String line;
}

class OsakaTransferConnection {
  const OsakaTransferConnection({
    required this.fromId,
    required this.toId,
    required this.kind,
    required this.walkMinutes,
  });

  factory OsakaTransferConnection.fromJson(List<dynamic> row) =>
      OsakaTransferConnection(
        fromId: row[0] as String,
        toId: row[1] as String,
        kind: row[2] as String,
        walkMinutes: row[3] as int,
      );

  final String fromId;
  final String toId;
  final String kind;
  final int walkMinutes;
}

class OsakaPassRouteLeg {
  const OsakaPassRouteLeg({
    required this.operator,
    required this.from,
    required this.to,
    required this.fare,
  });

  final String operator;
  final OsakaPassStation from;
  final OsakaPassStation to;
  final int fare;
}

class OsakaPassRouteTransfer {
  const OsakaPassRouteTransfer({
    required this.from,
    required this.to,
    required this.walkMinutes,
  });

  final OsakaPassStation from;
  final OsakaPassStation to;
  final int walkMinutes;
}

class OsakaPassRoute {
  const OsakaPassRoute({required this.legs, required this.transfers});

  final List<OsakaPassRouteLeg> legs;
  final List<OsakaPassRouteTransfer> transfers;

  int get fare => legs.fold(0, (sum, leg) => sum + leg.fare);
  int get transferCount => transfers.length;
}

class OsakaPassStationData {
  OsakaPassStationData(
    this.stations, {
    Map<String, int> fares = const {},
    this.railEdges = const [],
    this.transfers = const [],
    this.busAdultFare = 210,
    this.datasetVersion = 'test',
    this.validFrom = '',
    this.validTo = '',
    this.sources = const [],
  }) : _fares = Map.unmodifiable(fares),
       _stationById = {
         for (final station in stations) station.lookupId: station,
       },
       _index = stations.map(_OsakaSearchEntry.new).toList(growable: false);

  factory OsakaPassStationData.fromJson(String source) {
    final root = jsonDecode(source) as Map<String, dynamic>;
    final stations = (root['stations'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(OsakaPassStation.fromJson)
        .toList(growable: false);
    final fares = <String, int>{};
    for (final raw in (root['fares'] as List<dynamic>)) {
      final row = raw as List<dynamic>;
      fares[_fareKey(row[0] as String, row[1] as String)] = row[2] as int;
    }
    return OsakaPassStationData(
      stations,
      fares: fares,
      railEdges: (root['rail_edges'] as List<dynamic>? ?? const [])
          .cast<List<dynamic>>()
          .map(OsakaRailEdge.fromJson)
          .toList(growable: false),
      transfers: (root['transfers'] as List<dynamic>? ?? const [])
          .cast<List<dynamic>>()
          .map(OsakaTransferConnection.fromJson)
          .toList(growable: false),
      busAdultFare: root['bus_adult_fare_yen'] as int,
      datasetVersion: root['dataset_version'] as String,
      validFrom: root['valid_from'] as String,
      validTo: root['valid_to'] as String,
      sources: (root['sources'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(OsakaPassSource.fromJson)
          .toList(growable: false),
    );
  }

  final List<OsakaPassStation> stations;
  final List<OsakaRailEdge> railEdges;
  final List<OsakaTransferConnection> transfers;
  final int busAdultFare;
  final String datasetVersion;
  final String validFrom;
  final String validTo;
  final List<OsakaPassSource> sources;
  final Map<String, int> _fares;
  final Map<String, OsakaPassStation> _stationById;
  final List<_OsakaSearchEntry> _index;

  int? fareBetween(OsakaPassStation from, OsakaPassStation to) {
    if (from.operator != to.operator || from.lookupId == to.lookupId) {
      return null;
    }
    return _fares[_fareKey(from.lookupId, to.lookupId)];
  }

  OsakaPassRoute? routeBetween(OsakaPassStation from, OsakaPassStation to) {
    if (from.lookupId == to.lookupId) return null;
    final directFare = fareBetween(from, to);
    if (directFare != null) {
      return OsakaPassRoute(
        legs: [
          OsakaPassRouteLeg(
            operator: from.operator,
            from: from,
            to: to,
            fare: directFare,
          ),
        ],
        transfers: const [],
      );
    }
    if (railEdges.isEmpty || transfers.isEmpty) return null;

    final graph = <String, List<_OsakaGraphEdge>>{};
    void connect(String first, String second, _OsakaGraphEdge edge) {
      graph.putIfAbsent(first, () => []).add(edge);
    }

    for (final edge in railEdges) {
      connect(
        edge.fromId,
        edge.toId,
        _OsakaGraphEdge(
          fromId: edge.fromId,
          toId: edge.toId,
          cost: edge.distanceKm,
        ),
      );
      connect(
        edge.toId,
        edge.fromId,
        _OsakaGraphEdge(
          fromId: edge.toId,
          toId: edge.fromId,
          cost: edge.distanceKm,
        ),
      );
    }
    for (final transfer in transfers) {
      final cost = 1.5 + transfer.walkMinutes / 6;
      connect(
        transfer.fromId,
        transfer.toId,
        _OsakaGraphEdge(
          fromId: transfer.fromId,
          toId: transfer.toId,
          cost: cost,
          transfer: transfer,
        ),
      );
      connect(
        transfer.toId,
        transfer.fromId,
        _OsakaGraphEdge(
          fromId: transfer.toId,
          toId: transfer.fromId,
          cost: cost,
          transfer: transfer,
        ),
      );
    }

    final distances = <String, double>{from.lookupId: 0};
    final previous = <String, _OsakaGraphEdge>{};
    final unsettled = _stationById.keys.toSet();
    while (unsettled.isNotEmpty) {
      String? current;
      var currentDistance = double.infinity;
      for (final id in unsettled) {
        final distance = distances[id] ?? double.infinity;
        if (distance < currentDistance) {
          current = id;
          currentDistance = distance;
        }
      }
      if (current == null || currentDistance == double.infinity) break;
      if (current == to.lookupId) break;
      unsettled.remove(current);
      for (final edge in graph[current] ?? const <_OsakaGraphEdge>[]) {
        if (!unsettled.contains(edge.toId)) continue;
        final candidate = currentDistance + edge.cost;
        if (candidate < (distances[edge.toId] ?? double.infinity)) {
          distances[edge.toId] = candidate;
          previous[edge.toId] = edge;
        }
      }
    }
    if (!previous.containsKey(to.lookupId)) return null;

    final path = <_OsakaGraphEdge>[];
    var cursor = to.lookupId;
    while (cursor != from.lookupId) {
      final edge = previous[cursor];
      if (edge == null) return null;
      path.add(edge);
      cursor = edge.fromId;
    }
    final orderedPath = path.reversed.toList(growable: false);
    final legs = <OsakaPassRouteLeg>[];
    final routeTransfers = <OsakaPassRouteTransfer>[];
    OsakaPassStation? legStart;
    OsakaPassStation? legEnd;
    String? legOperator;

    bool finishLeg() {
      if (legStart == null || legEnd == null || legOperator == null) {
        return true;
      }
      if (legStart!.lookupId == legEnd!.lookupId) return true;
      final fare = fareBetween(legStart!, legEnd!);
      if (fare == null) return false;
      legs.add(
        OsakaPassRouteLeg(
          operator: legOperator!,
          from: legStart!,
          to: legEnd!,
          fare: fare,
        ),
      );
      legStart = null;
      legEnd = null;
      legOperator = null;
      return true;
    }

    for (final edge in orderedPath) {
      final edgeFrom = _stationById[edge.fromId]!;
      final edgeTo = _stationById[edge.toId]!;
      if (edge.transfer != null) {
        if (!finishLeg()) return null;
        routeTransfers.add(
          OsakaPassRouteTransfer(
            from: edgeFrom,
            to: edgeTo,
            walkMinutes: edge.transfer!.walkMinutes,
          ),
        );
        continue;
      }
      if (legOperator != null && legOperator != edgeFrom.operator) {
        if (!finishLeg()) return null;
      }
      legStart ??= edgeFrom;
      legEnd = edgeTo;
      legOperator = edgeFrom.operator;
    }
    if (!finishLeg() || legs.isEmpty) return null;
    return OsakaPassRoute(legs: legs, transfers: routeTransfers);
  }

  List<OsakaPassStation> search(
    String query, {
    String? operator,
    int limit = 20,
  }) {
    final normalized = normalizeStationSearchText(query);
    if (normalized.isEmpty) return const [];
    final initials = hangulInitials(normalized);
    final ranked = <({OsakaPassStation station, int score})>[];
    for (final entry in _index) {
      if (operator != null && entry.station.operator != operator) continue;
      var score = 1000;
      for (final candidate in entry.candidates) {
        if (candidate.normalized == normalized) {
          score = 0;
        } else if (candidate.normalized.startsWith(normalized)) {
          score = score > 10 ? 10 : score;
        } else if (candidate.initials.startsWith(initials)) {
          score = score > 20 ? 20 : score;
        } else if (candidate.normalized.contains(normalized)) {
          score = score > 30 ? 30 : score;
        }
      }
      if (score < 1000) ranked.add((station: entry.station, score: score));
    }
    ranked.sort((a, b) {
      final score = a.score.compareTo(b.score);
      if (score != 0) return score;
      final operatorScore = a.station.operator.compareTo(b.station.operator);
      return operatorScore != 0
          ? operatorScore
          : a.station.displayName.compareTo(b.station.displayName);
    });
    return ranked.take(limit).map((entry) => entry.station).toList();
  }
}

class OsakaPassStationDataRepository {
  const OsakaPassStationDataRepository();

  Future<OsakaPassStationData> load() async => OsakaPassStationData.fromJson(
    await rootBundle.loadString(
      'assets/data/pass_comparison/osaka_amazing_pass_fares_2026.json',
    ),
  );
}

class _OsakaSearchEntry {
  _OsakaSearchEntry(this.station)
    : candidates =
          {
                station.nameJa,
                station.nameKo,
                operatorDisplayName(station.operator),
                ...station.lines,
              }
              .where((value) => value.isNotEmpty)
              .map((value) {
                final normalized = normalizeStationSearchText(value);
                return (
                  normalized: normalized,
                  initials: hangulInitials(normalized),
                );
              })
              .toList(growable: false);

  final OsakaPassStation station;
  final List<({String normalized, String initials})> candidates;
}

String operatorDisplayName(String operator) => switch (operator) {
  'Osaka Metro' => '오사카 메트로',
  '大阪シティバス' => '오사카 시티버스',
  '阪急電鉄' => '한큐 전철',
  '阪神電鉄' => '한신 전철',
  '京阪電鉄' => '게이한 전철',
  '近鉄' => '긴테쓰',
  '南海電鉄' => '난카이 전철',
  _ => operator,
};

String _fareKey(String first, String second) => first.compareTo(second) <= 0
    ? '$first\u0000$second'
    : '$second\u0000$first';

class _OsakaGraphEdge {
  const _OsakaGraphEdge({
    required this.fromId,
    required this.toId,
    required this.cost,
    this.transfer,
  });

  final String fromId;
  final String toId;
  final double cost;
  final OsakaTransferConnection? transfer;
}
