import 'package:flutter/services.dart';

import '../domain/station_resolution.dart';

class AssetStationDatabase {
  AssetStationDatabase._({
    required Map<StationCode, List<StationRecord>> byFullCode,
    required Map<LineStationCode, List<StationRecord>> byLineStation,
  }) : _byFullCode = byFullCode,
       _byLineStation = byLineStation;

  static const assetPath = 'assets/data/stations/yoiko_station_codes.csv';
  static const overrideAssetPath =
      'assets/data/stations/verified_station_overrides.csv';
  static const koreanNameAssetPath =
      'assets/data/stations/wikidata_station_names_ko.csv';
  static const version = 'yoiko-c38cdaa4-2026-07-15+iyotetsu-v2';
  static const source = 'Yoiko 自動改札機の研究';
  static const overrideSource = 'App station override';

  final Map<StationCode, List<StationRecord>> _byFullCode;
  final Map<LineStationCode, List<StationRecord>> _byLineStation;

  static Future<AssetStationDatabase> load({AssetBundle? bundle}) async {
    final assets = bundle ?? rootBundle;
    final csv = await assets.loadString(assetPath);
    final overrideCsv = await assets.loadString(overrideAssetPath);
    final koreanNamesCsv = await assets.loadString(koreanNameAssetPath);
    return AssetStationDatabase.fromCsv(
      csv,
      overrideCsv: overrideCsv,
      koreanNamesCsv: koreanNamesCsv,
    );
  }

  factory AssetStationDatabase.fromCsv(
    String csv, {
    String? overrideCsv,
    String? koreanNamesCsv,
  }) {
    final byFullCode = <StationCode, List<StationRecord>>{};
    final byLineStation = <LineStationCode, List<StationRecord>>{};
    final koreanNames = _parseKoreanNames(koreanNamesCsv);
    _addPrimaryCsv(csv, byFullCode, byLineStation, koreanNames);
    if (overrideCsv != null) {
      _addOverrideCsv(overrideCsv, byFullCode, byLineStation, koreanNames);
    }

    return AssetStationDatabase._(
      byFullCode: byFullCode,
      byLineStation: byLineStation,
    );
  }

  static void _addPrimaryCsv(
    String csv,
    Map<StationCode, List<StationRecord>> byFullCode,
    Map<LineStationCode, List<StationRecord>> byLineStation,
    Map<String, String> koreanNames,
  ) {
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
        stationNameKorean: koreanNames[fields[8].trim()],
      );
      byFullCode.putIfAbsent(code, () => []).add(station);
      byLineStation
          .putIfAbsent(
            LineStationCode(lineCode: lineCode, stationCode: stationCode),
            () => [],
          )
          .add(station);
    }
  }

  static void _addOverrideCsv(
    String csv,
    Map<StationCode, List<StationRecord>> byFullCode,
    Map<LineStationCode, List<StationRecord>> byLineStation,
    Map<String, String> koreanNames,
  ) {
    final lines = csv.split(RegExp(r'\r?\n'));
    for (final line in lines.skip(1)) {
      if (line.trim().isEmpty) continue;
      final fields = _parseCsvLine(line);
      if (fields.length < 8) continue;
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
        operatorName: fields[3].trim(),
        lineName: fields[4].trim(),
        stationName: fields[5].trim(),
        source: overrideSource,
        stationNameKorean: koreanNames[fields[5].trim()],
        evidence: fields[6].trim(),
        sourceNote: fields[7].trim(),
      );
      byFullCode[code] = [station];
      final lineStation = LineStationCode(
        lineCode: lineCode,
        stationCode: stationCode,
      );
      final candidates = byLineStation.putIfAbsent(lineStation, () => []);
      candidates.removeWhere((candidate) => candidate.code == code);
      candidates.add(station);
    }
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

    final hasNormalizedRegion =
        requestedCode.regionCode >= 0 && requestedCode.regionCode <= 3;
    if (hasNormalizedRegion) {
      return StationResolution(
        requestedCode: requestedCode,
        strategy: StationMatchStrategy.notFound,
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

    final route = _resolveIyotetsuRoute(
      boardingCode: boardingCode,
      alightingCode: alightingCode,
    );
    return ResolvedStationPair(
      boarding: boarding,
      alighting: alighting,
      routeOperatorName: route?.operatorName,
      routeLineName: route?.lineName,
    );
  }

  static ({String operatorName, String lineName})? _resolveIyotetsuRoute({
    required StationCode boardingCode,
    required StationCode alightingCode,
  }) {
    if (boardingCode.regionCode != 0x03 ||
        alightingCode.regionCode != 0x03 ||
        boardingCode.lineCode != 0xC5 ||
        alightingCode.lineCode != 0xC5) {
      return null;
    }
    final stations = {boardingCode.stationCode, alightingCode.stationCode};
    final isGunchuRange = stations.every(
      (code) => code >= 0x01 && code <= 0x17,
    );
    if (isGunchuRange && stations.any((code) => code <= 0x15)) {
      return (operatorName: '伊予鉄道', lineName: '郡中線');
    }
    final isTakahamaRange = stations.every(
      (code) => code >= 0x17 && code <= 0x29,
    );
    if (isTakahamaRange && stations.any((code) => code >= 0x19)) {
      return (operatorName: '伊予鉄道', lineName: '高浜線');
    }
    return null;
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

  static Map<String, String> _parseKoreanNames(String? csv) {
    if (csv == null || csv.trim().isEmpty) return const {};
    final localized = <String, String>{};
    for (final line in csv.split(RegExp(r'\r?\n')).skip(1)) {
      if (line.trim().isEmpty) continue;
      final fields = _parseCsvLine(line);
      if (fields.length < 2) continue;
      final japanese = fields[0].trim();
      final korean = fields[1].trim();
      if (japanese.isNotEmpty && korean.isNotEmpty) {
        localized[japanese] = korean;
      }
    }
    return localized;
  }
}
