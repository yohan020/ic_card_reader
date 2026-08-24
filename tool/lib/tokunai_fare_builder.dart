import 'dart:convert';

class TokunaiFareBuildException implements Exception {
  const TokunaiFareBuildException(this.message);

  final String message;

  @override
  String toString() => 'TokunaiFareBuildException: $message';
}

/// Produces the app asset only after every unordered station pair has a
/// separately verified IC fare. The app must not mix a partial fare table with
/// an apparently complete automatic calculation.
Map<String, Object?> buildTokunaiFareAsset({
  required Map<String, Object?> stationDirectory,
  required Map<String, Object?> verifiedInput,
}) {
  final stations = _listOfMaps(stationDirectory['stations']);
  if (stations.length < 2) {
    throw const TokunaiFareBuildException(
      'At least two stations are required.',
    );
  }
  final stationIds = <String, String>{};
  for (final station in stations) {
    final id = _string(station['id']);
    final runtimeIds = _stringList(station['odptIds']);
    if (id.isEmpty || runtimeIds.isEmpty) {
      throw TokunaiFareBuildException('Invalid station entry: $id');
    }
    if (station['tokunaiPassEligible'] != true) {
      throw TokunaiFareBuildException('$id is not marked as Tokunai eligible.');
    }
    if (stationIds.containsKey(id)) {
      throw TokunaiFareBuildException('Duplicated station id: $id');
    }
    stationIds[id] = runtimeIds.first;
  }

  final source = _string(verifiedInput['source']);
  final verifiedAt = _string(verifiedInput['verifiedAt']);
  if (source.isEmpty || verifiedAt.isEmpty) {
    throw const TokunaiFareBuildException(
      'verified input requires source and verifiedAt.',
    );
  }
  DateTime.tryParse(verifiedAt) ??
      (throw const TokunaiFareBuildException('verifiedAt must be ISO-8601.'));

  final seenPairs = <String>{};
  final fares = <Map<String, Object?>>[];
  for (final row in _listOfMaps(verifiedInput['fares'])) {
    final from = _string(row['from']);
    final to = _string(row['to']);
    final fare = row['adultIcFare'];
    final sourceUrl = _string(row['sourceUrl']);
    if (!stationIds.containsKey(from) || !stationIds.containsKey(to)) {
      throw TokunaiFareBuildException(
        'Unknown Tokunai station in $from → $to.',
      );
    }
    if (from == to) {
      throw TokunaiFareBuildException('Same-station fare is invalid: $from');
    }
    if (fare is! int || fare <= 0) {
      throw TokunaiFareBuildException('Invalid adult IC fare: $from → $to');
    }
    if (!_isOfficialJrEastUrl(sourceUrl)) {
      throw TokunaiFareBuildException(
        'Each fare needs an HTTPS jreast.co.jp sourceUrl: $from → $to',
      );
    }
    final pairKey = _pairKey(from, to);
    if (!seenPairs.add(pairKey)) {
      throw TokunaiFareBuildException('Duplicated pair: $from ↔ $to');
    }
    fares.add({
      'operatorId': 'jr-east:tokunai',
      'fromStationId': stationIds[from],
      'toStationId': stationIds[to],
      'adultIcFare': fare,
    });
  }

  final requiredPairCount = stationIds.length * (stationIds.length - 1) ~/ 2;
  if (fares.length != requiredPairCount) {
    throw TokunaiFareBuildException(
      'Incomplete verified fare table: ${fares.length}/$requiredPairCount pairs.',
    );
  }

  return {
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'source': source,
    'tokunaiFareDataComplete': true,
    'verifiedAt': verifiedAt,
    'stations': stations,
    'fares': fares,
  };
}

String encodeTokunaiFareAsset(Map<String, Object?> asset) =>
    '${const JsonEncoder.withIndent('  ').convert(asset)}\n';

List<Map<String, Object?>> _listOfMaps(Object? value) =>
    (value as List<Object?>? ?? const [])
        .map((item) => Map<String, Object?>.from(item! as Map))
        .toList(growable: false);

List<String> _stringList(Object? value) => (value as List<Object?>? ?? const [])
    .whereType<String>()
    .toList(growable: false);

String _string(Object? value) => value is String ? value.trim() : '';

String _pairKey(String first, String second) => first.compareTo(second) <= 0
    ? '$first\u0000$second'
    : '$second\u0000$first';

bool _isOfficialJrEastUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null && uri.scheme == 'https' && uri.host == 'www.jreast.co.jp';
}
