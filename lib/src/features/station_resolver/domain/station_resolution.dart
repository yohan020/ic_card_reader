class StationCode {
  const StationCode({
    required this.regionCode,
    required this.lineCode,
    required this.stationCode,
  });

  final int regionCode;
  final int lineCode;
  final int stationCode;

  @override
  bool operator ==(Object other) =>
      other is StationCode &&
      regionCode == other.regionCode &&
      lineCode == other.lineCode &&
      stationCode == other.stationCode;

  @override
  int get hashCode => Object.hash(regionCode, lineCode, stationCode);
}

class LineStationCode {
  const LineStationCode({required this.lineCode, required this.stationCode});

  final int lineCode;
  final int stationCode;

  @override
  bool operator ==(Object other) =>
      other is LineStationCode &&
      lineCode == other.lineCode &&
      stationCode == other.stationCode;

  @override
  int get hashCode => Object.hash(lineCode, stationCode);
}

class StationRecord {
  const StationRecord({
    required this.code,
    required this.operatorName,
    required this.lineName,
    required this.stationName,
    required this.source,
    this.stationNameKorean,
    this.evidence,
    this.sourceNote,
  });

  final StationCode code;
  final String operatorName;
  final String lineName;
  final String stationName;
  final String? stationNameKorean;
  final String source;
  final String? evidence;
  final String? sourceNote;
}

enum StationMatchStrategy {
  exactRegion,
  regionHint,
  uniqueLineStation,
  tripContext,
  multipleCandidates,
  notFound,
  notApplicable,
}

class StationResolution {
  const StationResolution({
    required this.requestedCode,
    required this.strategy,
    this.station,
    this.candidates = const [],
  });

  final StationCode requestedCode;
  final StationMatchStrategy strategy;
  final StationRecord? station;
  final List<StationRecord> candidates;

  bool get isResolved => station != null;

  StationResolution resolvedByContext(StationRecord selected) =>
      StationResolution(
        requestedCode: requestedCode,
        strategy: StationMatchStrategy.tripContext,
        station: selected,
      );
}

class ResolvedStationPair {
  const ResolvedStationPair({
    required this.boarding,
    required this.alighting,
    this.routeOperatorName,
    this.routeLineName,
  });

  final StationResolution boarding;
  final StationResolution alighting;
  final String? routeOperatorName;
  final String? routeLineName;
}
