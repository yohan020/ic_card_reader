import 'package:flutter/services.dart';

import '../domain/station_resolution.dart';

class AssetStationDatabase {
  AssetStationDatabase._({
    required Map<StationCode, List<StationRecord>> byFullCode,
    required Map<LineStationCode, List<StationRecord>> byLineStation,
  }) : _byFullCode = byFullCode,
       _byLineStation = byLineStation;

  static const assetPath = 'assets/data/stations/yoiko_station_codes.csv';
  static const version = 'yoiko-c38cdaa4-2026-07-15';
  static const source = 'Yoiko 自動改札機の研究';

  final Map<StationCode, List<StationRecord>> _byFullCode;
  final Map<LineStationCode, List<StationRecord>> _byLineStation;

  static Future<AssetStationDatabase> load({AssetBundle? bundle}) async {
    final csv = await (bundle ?? rootBundle).loadString(assetPath);
    return AssetStationDatabase.fromCsv(csv);
  }

  factory AssetStationDatabase.fromCsv(String csv) {
    final byFullCode = <StationCode, List<StationRecord>>{};
    final byLineStation = <LineStationCode, List<StationRecord>>{};
    final lines = csv.split(RegExp(r'\r?\n'));

    for (final line in lines.skip(1)) {
      if (line.trim().isEmpty) continue;
      final fields = _parseCsvLine(line);
      if (fields.length < 9) continue;

      final regionCode = int.tryParse(fields[0].trim());
      final lineCode = int.tryParse(fields[1].trim());
      final stationCode = int.tryParse(fields[2].trim());
      if (regionCode == null || lineCode == null || stationCode == null) {
        continue;
      }

      final code = StationCode(
        regionCode: regionCode,
        lineCode: lineCode,
        stationCode: stationCode,
      );
      final station = StationRecord(
        code: code,
        operatorName: fields[6].trim(),
        lineName: fields[7].trim(),
        stationName: fields[8].trim(),
        source: source,
      );
      byFullCode.putIfAbsent(code, () => []).add(station);
      byLineStation
          .putIfAbsent(
            LineStationCode(lineCode: lineCode, stationCode: stationCode),
            () => [],
          )
          .add(station);
    }

    return AssetStationDatabase._(
      byFullCode: byFullCode,
      byLineStation: byLineStation,
    );
  }

  StationResolution resolve(StationCode requestedCode) {
    final exact = _uniqueRecords(_byFullCode[requestedCode] ?? const []);
    if (exact.length == 1) {
      return StationResolution(
        requestedCode: requestedCode,
        strategy: StationMatchStrategy.exactRegion,
        station: exact.single,
      );
    }
    if (exact.length > 1) {
      return StationResolution(
        requestedCode: requestedCode,
        strategy: StationMatchStrategy.multipleCandidates,
        candidates: exact,
      );
    }

    final hintedRegion = _regionHints[requestedCode.regionCode];
    if (hintedRegion != null) {
      final hinted = _uniqueRecords(
        _byFullCode[StationCode(
              regionCode: hintedRegion,
              lineCode: requestedCode.lineCode,
              stationCode: requestedCode.stationCode,
            )] ??
            const [],
      );
      if (hinted.length == 1) {
        return StationResolution(
          requestedCode: requestedCode,
          strategy: StationMatchStrategy.regionHint,
          station: hinted.single,
        );
      }
    }

    final candidates = _uniqueRecords(
      _byLineStation[LineStationCode(
            lineCode: requestedCode.lineCode,
            stationCode: requestedCode.stationCode,
          )] ??
          const [],
    );
    if (candidates.length == 1) {
      return StationResolution(
        requestedCode: requestedCode,
        strategy: StationMatchStrategy.uniqueLineStation,
        station: candidates.single,
      );
    }
    if (candidates.isNotEmpty) {
      return StationResolution(
        requestedCode: requestedCode,
        strategy: StationMatchStrategy.multipleCandidates,
        candidates: candidates,
      );
    }
    return StationResolution(
      requestedCode: requestedCode,
      strategy: StationMatchStrategy.notFound,
    );
  }

  ResolvedStationPair resolvePair({
    required StationCode boardingCode,
    required StationCode alightingCode,
  }) {
    var boarding = resolve(boardingCode);
    var alighting = resolve(alightingCode);

    final boardingRegions = _candidateRegions(boarding);
    final alightingRegions = _candidateRegions(alighting);
    final sharedRegions = boardingRegions.intersection(alightingRegions);
    if (sharedRegions.length == 1) {
      final region = sharedRegions.single;
      boarding = _selectRegion(boarding, region);
      alighting = _selectRegion(alighting, region);
    }

    return ResolvedStationPair(boarding: boarding, alighting: alighting);
  }

  static const _regionHints = <int, int>{0x50: 0x01, 0xF0: 0x03};

  static Set<int> _candidateRegions(StationResolution resolution) {
    final station = resolution.station;
    if (station != null) return {station.code.regionCode};
    return resolution.candidates
        .map((candidate) => candidate.code.regionCode)
        .toSet();
  }

  static StationResolution _selectRegion(
    StationResolution resolution,
    int region,
  ) {
    if (resolution.isResolved) return resolution;
    final matches = resolution.candidates
        .where((candidate) => candidate.code.regionCode == region)
        .toList(growable: false);
    return matches.length == 1
        ? resolution.resolvedByContext(matches.single)
        : resolution;
  }

  static List<StationRecord> _uniqueRecords(List<StationRecord> records) {
    final unique = <String, StationRecord>{};
    for (final record in records) {
      final key =
          '${record.code.regionCode}-${record.code.lineCode}-${record.code.stationCode}-'
          '${record.operatorName}-${record.lineName}-${record.stationName}';
      unique.putIfAbsent(key, () => record);
    }
    return unique.values.toList(growable: false);
  }

  static List<String> _parseCsvLine(String line) {
    final fields = <String>[];
    final current = StringBuffer();
    var inQuotes = false;
    for (var index = 0; index < line.length; index++) {
      final character = line[index];
      if (character == '"') {
        if (inQuotes && index + 1 < line.length && line[index + 1] == '"') {
          current.write('"');
          index++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (character == ',' && !inQuotes) {
        fields.add(current.toString());
        current.clear();
      } else {
        current.write(character);
      }
    }
    fields.add(current.toString());
    return fields;
  }
}
