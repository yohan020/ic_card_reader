import 'dart:convert';

import 'package:flutter/services.dart';

import 'pass_named_place.dart';
import 'pass_station_english.g.dart';

import 'pass_transit_data.dart';

class EnodenStation implements PassNamedPlace {
  @override
  String get nameEn => passStationEnglish['enoden:$id'] ?? '';

  const EnodenStation({
    required this.id,
    required this.nameJa,
    required this.nameKo,
    required this.kilometer,
  });

  factory EnodenStation.fromJson(Map<String, dynamic> json) => EnodenStation(
    id: json['id'] as String,
    nameJa: json['ja'] as String,
    nameKo: json['ko'] as String,
    kilometer: (json['km'] as num).toDouble(),
  );

  final String id;
  @override
  final String nameJa;
  @override
  final String nameKo;
  final double kilometer;

  String get displayName => nameKo.isEmpty ? nameJa : nameKo;
  @override
  String get secondaryLabel => '$nameJa · 에노시마 전철';
}

class EnodenNoriorikunPassData {
  EnodenNoriorikunPassData._({
    required this.stations,
    required this.passPrice,
    required List<_FareBand> fareBands,
  }) : _fareBands = fareBands,
       _index = stations.map(_SearchEntry.new).toList(growable: false);

  factory EnodenNoriorikunPassData.fromJson(String source) {
    final root = jsonDecode(source) as Map<String, dynamic>;
    return EnodenNoriorikunPassData._(
      stations: (root['stations'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(EnodenStation.fromJson)
          .toList(growable: false),
      passPrice: root['pass_price_yen'] as int,
      fareBands: (root['fare_bands'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(_FareBand.fromJson)
          .toList(growable: false),
    );
  }

  final List<EnodenStation> stations;
  final int passPrice;
  final List<_FareBand> _fareBands;
  final List<_SearchEntry> _index;

  int? fareBetween(EnodenStation from, EnodenStation to) {
    if (from.id == to.id) return null;
    final distance = (from.kilometer - to.kilometer).abs();
    for (final band in _fareBands) {
      if (distance <= band.maxKilometer) return band.adultFare;
    }
    return null;
  }

  List<EnodenStation> search(String query, {int limit = 20}) {
    final normalized = normalizeStationSearchText(query);
    if (normalized.isEmpty) return const [];
    final initials = hangulInitials(normalized);
    final isInitialQuery = isHangulInitialSearch(normalized);
    final matches = <({EnodenStation station, int score})>[];
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
    return matches.take(limit).map((item) => item.station).toList();
  }
}

class EnodenNoriorikunPassDataRepository {
  const EnodenNoriorikunPassDataRepository();

  static Future<EnodenNoriorikunPassData>? _cachedLoad;

  Future<EnodenNoriorikunPassData> load() => _cachedLoad ??= _load();

  Future<EnodenNoriorikunPassData> _load() async =>
      EnodenNoriorikunPassData.fromJson(
        await rootBundle.loadString(
          'assets/data/pass_comparison/enoden_noriorikun_2026.json',
        ),
      );
}

class _FareBand {
  const _FareBand(this.maxKilometer, this.adultFare);
  factory _FareBand.fromJson(Map<String, dynamic> json) =>
      _FareBand((json['max_km'] as num).toDouble(), json['adult_yen'] as int);
  final double maxKilometer;
  final int adultFare;
}

class _SearchEntry {
  _SearchEntry(this.station)
    : candidates = {station.nameJa, station.nameKo, station.nameEn}
          .map(
            (value) => (
              normalized: normalizeStationSearchText(value),
              initials: hangulInitials(normalizeStationSearchText(value)),
            ),
          )
          .toList(growable: false);
  final EnodenStation station;
  final List<({String normalized, String initials})> candidates;
}
