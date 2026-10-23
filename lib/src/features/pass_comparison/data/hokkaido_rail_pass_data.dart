import 'dart:typed_data';

import 'package:flutter/services.dart';

import 'pass_transit_data.dart';

class HokkaidoRailPassStation {
  const HokkaidoRailPassStation({
    required this.id,
    required this.nameJa,
    required this.nameKo,
  });

  final String id;
  final String nameJa;
  final String nameKo;

  String get displayName => nameKo;
  String get secondaryLabel => '$nameJa · JR 홋카이도';
}

class HokkaidoLimitedExpressFare {
  const HokkaidoLimitedExpressFare({
    required this.normalTotalYen,
    required this.seatChargeYen,
  });

  final int normalTotalYen;
  final int seatChargeYen;
}

class HokkaidoRailPassData {
  HokkaidoRailPassData._({
    required this.stations,
    Map<String, int>? basicFares,
    Map<String, int>? stationIndexes,
    Uint16List? basicFareMatrix,
    required Map<String, HokkaidoLimitedExpressFare> limitedExpressFares,
  }) : _basicFares = basicFares,
       _stationIndexes = stationIndexes,
       _basicFareMatrix = basicFareMatrix,
       _limitedExpressFares = limitedExpressFares,
       _searchIndex = stations.map(_SearchEntry.new).toList(growable: false);

  static const _missingFare = 0xffff;
  static const _binaryHeaderLength = 8;

  static const stationPurchasePrices = <int, int>{
    5: 23000,
    7: 29000,
    10: 38000,
  };

  final List<HokkaidoRailPassStation> stations;
  final Map<String, int>? _basicFares;
  final Map<String, int>? _stationIndexes;
  final Uint16List? _basicFareMatrix;
  final Map<String, HokkaidoLimitedExpressFare> _limitedExpressFares;
  final List<_SearchEntry> _searchIndex;

  static HokkaidoRailPassData fromCsv({
    required String stationsCsv,
    required String minimumFaresCsv,
    required String limitedExpressSafePairsCsv,
  }) {
    final stations = _csvRows(stationsCsv)
        .map(
          (row) => HokkaidoRailPassStation(
            id: row['station_id']!,
            nameJa: row['name_ja']!,
            nameKo: row['name_ko']!,
          ),
        )
        .toList(growable: false);
    final basicFares = <String, int>{
      for (final row in _csvRows(minimumFaresCsv))
        '${row['origin_id']}|${row['destination_id']}': int.parse(
          row['adult_basic_fare_yen']!,
        ),
    };
    final limitedExpressFares = <String, HokkaidoLimitedExpressFare>{};
    for (final row in _csvRows(limitedExpressSafePairsCsv)) {
      final key = '${row['origin_id']}|${row['destination_id']}';
      limitedExpressFares.putIfAbsent(
        key,
        () => HokkaidoLimitedExpressFare(
          normalTotalYen: int.parse(row['normal_total_yen']!),
          seatChargeYen: int.parse(row['seat_charge_yen']!),
        ),
      );
    }
    return HokkaidoRailPassData._(
      stations: stations,
      basicFares: basicFares,
      limitedExpressFares: limitedExpressFares,
    );
  }

  static HokkaidoRailPassData fromBinary({
    required String stationsCsv,
    required ByteData minimumFaresBinary,
    required String limitedExpressSafePairsCsv,
  }) {
    final stations = _csvRows(stationsCsv)
        .map(
          (row) => HokkaidoRailPassStation(
            id: row['station_id']!,
            nameJa: row['name_ja']!,
            nameKo: row['name_ko']!,
          ),
        )
        .toList(growable: false);
    final bytes = minimumFaresBinary.buffer.asUint8List(
      minimumFaresBinary.offsetInBytes,
      minimumFaresBinary.lengthInBytes,
    );
    if (bytes.length < _binaryHeaderLength ||
        bytes[0] != 0x48 ||
        bytes[1] != 0x52 ||
        bytes[2] != 0x50 ||
        bytes[3] != 0x46) {
      throw const FormatException('Invalid Hokkaido fare index header.');
    }
    final header = ByteData.sublistView(bytes);
    final version = header.getUint16(4, Endian.little);
    final stationCount = header.getUint16(6, Endian.little);
    final expectedLength =
        _binaryHeaderLength + stationCount * stationCount * 2;
    if (version != 1 ||
        stationCount != stations.length ||
        bytes.length != expectedLength) {
      throw const FormatException('Invalid Hokkaido fare index data.');
    }
    final stationIndexes = <String, int>{
      for (var index = 0; index < stations.length; index++)
        stations[index].id: index,
    };
    final limitedExpressFares = <String, HokkaidoLimitedExpressFare>{};
    for (final row in _csvRows(limitedExpressSafePairsCsv)) {
      final key = '${row['origin_id']}|${row['destination_id']}';
      limitedExpressFares.putIfAbsent(
        key,
        () => HokkaidoLimitedExpressFare(
          normalTotalYen: int.parse(row['normal_total_yen']!),
          seatChargeYen: int.parse(row['seat_charge_yen']!),
        ),
      );
    }
    return HokkaidoRailPassData._(
      stations: stations,
      stationIndexes: stationIndexes,
      basicFareMatrix: Uint16List.view(
        bytes.buffer,
        bytes.offsetInBytes + _binaryHeaderLength,
        stationCount * stationCount,
      ),
      limitedExpressFares: limitedExpressFares,
    );
  }

  int? basicFareBetween(
    HokkaidoRailPassStation from,
    HokkaidoRailPassStation to,
  ) {
    if (from.id == to.id) return null;
    final matrix = _basicFareMatrix;
    final indexes = _stationIndexes;
    if (matrix != null && indexes != null) {
      final fromIndex = indexes[from.id];
      final toIndex = indexes[to.id];
      if (fromIndex == null || toIndex == null) return null;
      final fare = matrix[fromIndex * stations.length + toIndex];
      return fare == _missingFare ? null : fare;
    }
    return _basicFares?['${from.id}|${to.id}'];
  }

  HokkaidoLimitedExpressFare? limitedExpressFareBetween(
    HokkaidoRailPassStation from,
    HokkaidoRailPassStation to,
  ) {
    if (from.id == to.id) return null;
    return _limitedExpressFares['${from.id}|${to.id}'];
  }

  List<HokkaidoRailPassStation> search(String query, {int limit = 20}) {
    final normalized = normalizeStationSearchText(query);
    if (normalized.isEmpty) return const [];
    final initials = hangulInitials(normalized);
    final isInitialQuery = isHangulInitialSearch(normalized);
    final matches = <({HokkaidoRailPassStation station, int score})>[];
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
      (left, right) => left.score != right.score
          ? left.score.compareTo(right.score)
          : left.station.displayName.compareTo(right.station.displayName),
    );
    return matches.take(limit).map((match) => match.station).toList();
  }
}

class HokkaidoRailPassDataRepository {
  const HokkaidoRailPassDataRepository();

  static Future<HokkaidoRailPassData>? _cachedLoad;

  Future<HokkaidoRailPassData> load() => _cachedLoad ??= _load();

  Future<HokkaidoRailPassData> _load() async {
    final assets = await Future.wait<Object>([
      rootBundle.loadString(
        'assets/data/pass_comparison/hokkaido_rail_pass_stations_2026.csv',
      ),
      rootBundle.load(
        'assets/data/pass_comparison/hokkaido_rail_pass_minimum_fares_2026.bin',
      ),
      rootBundle.loadString(
        'assets/data/pass_comparison/hokkaido_rail_pass_limited_express_safe_pairs_2026.csv',
      ),
    ]);
    return HokkaidoRailPassData.fromBinary(
      stationsCsv: assets[0] as String,
      minimumFaresBinary: assets[1] as ByteData,
      limitedExpressSafePairsCsv: assets[2] as String,
    );
  }
}

class _SearchEntry {
  _SearchEntry(this.station)
    : candidates = {station.nameJa, station.nameKo}
          .map(normalizeStationSearchText)
          .where((value) => value.isNotEmpty)
          .map((value) => (normalized: value, initials: hangulInitials(value)))
          .toList(growable: false);

  final HokkaidoRailPassStation station;
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
