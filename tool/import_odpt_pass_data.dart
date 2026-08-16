import 'dart:convert';
import 'dart:io';

const _apiBase = 'https://api.odpt.org/api/v4';
const _outputPath = 'assets/data/pass_comparison/odpt_pass_data.json';
const _operators = <String>['odpt.Operator:TokyoMetro', 'odpt.Operator:Toei'];

Future<void> main() async {
  final token = Platform.environment['ODPT_ACCESS_TOKEN']?.trim();
  if (token == null || token.isEmpty) {
    stderr.writeln(
      'ODPT_ACCESS_TOKEN is required. The token is never written to output.',
    );
    exitCode = 64;
    return;
  }

  final stationRows = <Map<String, Object?>>[];
  final railwayRows = <Map<String, Object?>>[];
  final fareRows = <Map<String, Object?>>[];
  for (final operatorId in _operators) {
    stationRows.addAll(await _fetch('odpt:Station', operatorId, token));
    railwayRows.addAll(await _fetch('odpt:Railway', operatorId, token));
    fareRows.addAll(await _fetch('odpt:RailwayFare', operatorId, token));
  }

  final railwayStationTitles = <String, Map<String, Object?>>{};
  for (final railway in railwayRows) {
    final orders = railway['odpt:stationOrder'];
    if (orders is! List) continue;
    for (final value in orders) {
      final order = _map(value);
      final stationId = _string(order['odpt:station'] ?? order['owl:sameAs']);
      if (stationId.isEmpty) continue;
      railwayStationTitles[stationId] = _map(order['odpt:stationTitle']);
    }
  }

  final groups = <String, _StationGroup>{};
  for (final row in stationRows) {
    final odptId = _string(row['owl:sameAs']);
    final stationTitle = _map(row['odpt:stationTitle']);
    final railwayTitle = railwayStationTitles[odptId] ?? const {};
    final nameJa = _language(
      stationTitle,
      'ja',
      fallback: _language(
        railwayTitle,
        'ja',
        fallback: _string(row['dc:title']),
      ),
    );
    final nameEn = _language(
      stationTitle,
      'en',
      fallback: _language(railwayTitle, 'en'),
    );
    final nameKo = _language(
      stationTitle,
      'ko',
      fallback: _language(railwayTitle, 'ko'),
    );
    if (odptId.isEmpty || nameJa.isEmpty) continue;
    final key = _normalizeJapaneseName(nameJa);
    final group = groups.putIfAbsent(
      key,
      () => _StationGroup(
        id: 'station-${groups.length + 1}',
        nameJa: nameJa,
        nameEn: nameEn,
        nameKo: nameKo,
      ),
    );
    group
      ..odptIds.add(odptId)
      ..operators.add(_string(row['odpt:operator']))
      ..railways.add(_string(row['odpt:railway']));
    if (group.nameKo.isEmpty && nameKo.isNotEmpty) group.nameKo = nameKo;
    if (group.nameEn.isEmpty && nameEn.isNotEmpty) group.nameEn = nameEn;
  }

  final fares = <Map<String, Object?>>[];
  for (final row in fareRows) {
    final from = _string(row['odpt:fromStation']);
    final to = _string(row['odpt:toStation']);
    final fare = row['odpt:icCardFare'];
    if (from.isEmpty || to.isEmpty || fare is! int) continue;
    fares.add({
      'operatorId': _string(row['odpt:operator']),
      'fromStationId': from,
      'toStationId': to,
      'adultIcFare': fare,
    });
  }

  final stations = groups.values.map((group) => group.toJson()).toList()
    ..sort(
      (a, b) => (a['nameJa']! as String).compareTo(b['nameJa']! as String),
    );
  final output = <String, Object?>{
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'source': 'Public Transportation Open Data Center (ODPT)',
    'stations': stations,
    'fares': fares,
  };
  final file = File(_outputPath);
  await file.parent.create(recursive: true);
  await file.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(output)}\n',
  );
  stdout.writeln(
    'Imported ${stations.length} stations and ${fares.length} fares.',
  );
}

Future<List<Map<String, Object?>>> _fetch(
  String type,
  String operatorId,
  String token,
) async {
  final uri = Uri.parse('$_apiBase/$type').replace(
    queryParameters: {'odpt:operator': operatorId, 'acl:consumerKey': token},
  );
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'ODPT returned HTTP ${response.statusCode} for $type / $operatorId',
        uri: uri.replace(queryParameters: {'odpt:operator': operatorId}),
      );
    }
    return (jsonDecode(body) as List<Object?>)
        .map((item) => Map<String, Object?>.from(item! as Map))
        .toList(growable: false);
  } finally {
    client.close(force: true);
  }
}

class _StationGroup {
  _StationGroup({
    required this.id,
    required this.nameJa,
    required this.nameEn,
    required this.nameKo,
  });

  final String id;
  final String nameJa;
  String nameEn;
  String nameKo;
  final Set<String> odptIds = {};
  final Set<String> operators = {};
  final Set<String> railways = {};

  Map<String, Object?> toJson() => {
    'id': id,
    'nameKo': nameKo,
    'nameJa': nameJa,
    'nameEn': nameEn,
    'odptIds': odptIds.where((item) => item.isNotEmpty).toList()..sort(),
    'operators': operators.where((item) => item.isNotEmpty).toList()..sort(),
    'railways': railways.where((item) => item.isNotEmpty).toList()..sort(),
    'aliases': <String>[],
  };
}

String _string(Object? value) => value is String ? value : '';

Map<String, Object?> _map(Object? value) =>
    value is Map ? Map<String, Object?>.from(value) : const {};

String _language(
  Map<String, Object?> title,
  String language, {
  String fallback = '',
}) => _string(title[language]).isEmpty ? fallback : _string(title[language]);

String _normalizeJapaneseName(String value) =>
    value.replaceAll(RegExp(r'[\s・()（）\-_]'), '');
