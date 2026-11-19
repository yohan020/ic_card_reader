import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/station_resolution.dart';

part 'station_map_group_names_en.g.dart';

class StationCoordinate {
  const StationCoordinate(
    this.latitude,
    this.longitude, {
    this.name,
    this.englishName,
    this.description,
  });

  final double latitude;
  final double longitude;
  final String? name;
  final String? englishName;
  final String? description;
}

/// A group is not an inferred boarding station: every member remains a candidate.
class StationMapLocations {
  StationMapLocations(
    Iterable<StationCoordinate> points, {
    this.kind = 'station',
  }) : points = List.unmodifiable(points) {
    if (this.points.isEmpty ||
        this.points.length > 32 ||
        (isGroup && this.points.length < 2)) {
      throw ArgumentError('Invalid station location set');
    }
  }

  final List<StationCoordinate> points;
  final String kind;
  bool get isGroup => kind == 'station_complex' || kind == 'route_group';
  bool get isRouteGroup => kind == 'route_group';
}

/// Public station positions only. No card data or network requests are used.
class StationCoordinateRepository {
  StationCoordinateRepository._(this._records, this._groups);

  static const assetPath =
      'assets/data/stations/station_coordinates_by_code.json';
  static Future<StationCoordinateRepository>? _shared;

  static Future<StationCoordinateRepository> load() => _shared ??= _load();

  static Future<StationCoordinateRepository> _load() async {
    try {
      final source = await rootBundle.loadString(assetPath);
      return await compute(StationCoordinateRepository.fromJson, source);
    } catch (_) {
      _shared = null; // Allow a later, explicit retry after an asset failure.
      rethrow;
    }
  }

  final Map<StationCode, Map<String, dynamic>> _records;
  final Map<StationCode, Map<String, dynamic>> _groups;

  factory StationCoordinateRepository.fromJson(String source) {
    final decoded = jsonDecode(source) as Map<String, dynamic>;
    if (decoded['schema'] != 1 || decoded['records'] is! List) {
      throw const FormatException('Unsupported station coordinate asset');
    }
    final records = <StationCode, Map<String, dynamic>>{};
    final duplicates = <StationCode>{};
    for (final raw in decoded['records'] as List) {
      if (raw is! Map<String, dynamic>) continue;
      final code = raw['code'];
      final lat = raw['lat'];
      final lon = raw['lon'];
      if (code is! List ||
          code.length != 3 ||
          code.any((value) => value is! int || value < 0 || value > 255) ||
          lat is! num ||
          lon is! num ||
          !lat.isFinite ||
          !lon.isFinite ||
          lat < 24 ||
          lat > 46 ||
          lon < 122 ||
          lon > 154 ||
          ['operator', 'line', 'name'].any((key) => raw[key] is! String)) {
        continue;
      }
      final key = StationCode(
        regionCode: code[0] as int,
        lineCode: code[1] as int,
        stationCode: code[2] as int,
      );
      if (records.containsKey(key)) duplicates.add(key);
      records[key] = raw;
    }
    for (final duplicate in duplicates) {
      records.remove(duplicate);
    }
    final groups = <StationCode, Map<String, dynamic>>{};
    final invalidGroups = <StationCode>{};
    final rawGroups = decoded['groups'];
    if (rawGroups != null && rawGroups is! List) {
      throw const FormatException('Invalid station location groups');
    }
    for (final raw in (rawGroups as List? ?? const [])) {
      if (raw is! Map<String, dynamic>) continue;
      final code = raw['code'];
      if (code is! List ||
          code.length != 3 ||
          code.any((n) => n is! int || n < 0 || n > 255)) {
        continue;
      }
      final key = StationCode(
        regionCode: code[0] as int,
        lineCode: code[1] as int,
        stationCode: code[2] as int,
      );
      if (groups.containsKey(key) ||
          records.containsKey(key) ||
          duplicates.contains(key)) {
        invalidGroups.add(key);
      }
      final members = raw['members'];
      if (!['station_complex', 'route_group'].contains(raw['kind']) ||
          raw.containsKey('lat') ||
          raw.containsKey('lon') ||
          ['operator', 'line', 'name'].any((k) => raw[k] is! String) ||
          members is! List ||
          members.length < 2 ||
          members.length > 32) {
        invalidGroups.add(key);
        continue;
      }
      final seen = <StationCode>{};
      var valid = true;
      for (final member in members) {
        if (member is! Map<String, dynamic>) {
          valid = false;
          break;
        }
        final mc = member['code'];
        if (mc is! List ||
            mc.length != 3 ||
            mc.any((n) => n is! int || n < 0 || n > 255)) {
          valid = false;
          break;
        }
        final mk = StationCode(
          regionCode: mc[0] as int,
          lineCode: mc[1] as int,
          stationCode: mc[2] as int,
        );
        final source = records[mk];
        if (!seen.add(mk) ||
            source == null ||
            [
              'name',
              'operator',
              'line',
              'qid',
              'lat',
              'lon',
            ].any((f) => source[f] != member[f])) {
          valid = false;
          break;
        }
      }
      if (valid) {
        groups[key] = raw;
      } else {
        invalidGroups.add(key);
      }
    }
    for (final key in invalidGroups) {
      groups.remove(key);
      records.remove(key); // A point/group collision must not choose either.
    }
    groups.removeWhere(
      (key, group) => (group['members'] as List).any((dynamic m) {
        final code = m['code'] as List;
        return !records.containsKey(
          StationCode(
            regionCode: code[0] as int,
            lineCode: code[1] as int,
            stationCode: code[2] as int,
          ),
        );
      }),
    );
    return StationCoordinateRepository._(records, groups);
  }

  Map<String, dynamic>? _matchingRecord(
    StationResolution? resolution,
    Map<StationCode, Map<String, dynamic>> source,
  ) {
    if (resolution == null ||
        resolution.strategy == StationMatchStrategy.multipleCandidates ||
        resolution.strategy == StationMatchStrategy.notFound ||
        resolution.strategy == StationMatchStrategy.notApplicable) {
      return null;
    }
    final station = resolution.station;
    if (station == null) return null;
    final record = source[station.code];
    // A corrected/overridden code must not silently retain an old coordinate.
    if (record == null ||
        record['name'] != station.stationName ||
        record['operator'] != station.operatorName ||
        record['line'] != station.lineName) {
      return null;
    }
    return record;
  }

  StationCoordinate? find(StationResolution? resolution) {
    final record = _matchingRecord(resolution, _records);
    if (record == null) return null;
    return StationCoordinate(
      (record['lat'] as num).toDouble(),
      (record['lon'] as num).toDouble(),
    );
  }

  StationMapLocations? findLocations(StationResolution? resolution) {
    final single = _matchingRecord(resolution, _records);
    if (single != null) {
      return StationMapLocations([
        _point(single),
      ], kind: single['kind'] == 'facility' ? 'facility' : 'station');
    }
    final group = _matchingRecord(resolution, _groups);
    if (group == null) return null;
    return StationMapLocations(
      (group['members'] as List).cast<Map<String, dynamic>>().map(_point),
      kind: group['kind'] as String,
    );
  }

  static StationCoordinate _point(Map<String, dynamic> record) {
    final code = record['code'];
    final label = code is List ? _englishGroupPointNames[code.join('/')] : null;
    return StationCoordinate(
      (record['lat'] as num).toDouble(),
      (record['lon'] as num).toDouble(),
      name: record['name'] as String,
      englishName:
          label != null &&
              label[0] == record['name'] &&
              label[1] == record['operator'] &&
              label[2] == record['line']
          ? label[3]
          : null,
      description: '${record['operator']} · ${record['line']}',
    );
  }
}
