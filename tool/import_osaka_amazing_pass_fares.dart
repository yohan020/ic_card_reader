import 'dart:convert';
import 'dart:io';

const _defaultInput = 'osaka_amazing_pass_fare_data_2026_keihan_open_sources';
const _defaultOutput =
    'assets/data/pass_comparison/osaka_amazing_pass_fares_2026.json';

const _operatorCodes = <String, String>{
  'Osaka Metro': 'metro',
  '阪急電鉄': 'hankyu',
  '阪神電鉄': 'hanshin',
  '京阪電鉄': 'keihan',
  '近鉄': 'kintetsu',
  '南海電鉄': 'nankai',
};

const _yoikoOperators = <String, String>{
  'Osaka Metro': '大阪市高速電気軌道',
  '阪急電鉄': '阪急電鉄',
  '阪神電鉄': '阪神電気鉄道',
  '京阪電鉄': '京阪電気鉄道',
  '近鉄': '近畿日本鉄道',
  '南海電鉄': '南海電気鉄道',
};

const _yoikoStationAliases = <String, String>{
  'あびこ': '我孫子',
  'なかもず': '中百舌鳥',
  'なんば': '難波',
  '四天王寺前夕陽ヶ丘': '四天王寺前夕陽ケ丘',
};

const _fallbackKoreanNames = <String, String>{
  'Osaka Metro::京橋': '교바시',
  'Osaka Metro::四天王寺前夕陽ヶ丘': '시텐노지마에유히가오카',
  'Osaka Metro::梅田': '우메다',
  '京阪電鉄::京橋': '교바시',
  '阪神電鉄::ドーム前': '돔마에',
  '阪神電鉄::大阪梅田': '오사카우메다',
  '阪神電鉄::尼崎': '아마가사키',
  '阪神電鉄::福島': '후쿠시마',
};

void main(List<String> arguments) {
  final input = Directory(_argument(arguments, '--input') ?? _defaultInput);
  final output = File(_argument(arguments, '--output') ?? _defaultOutput);
  if (!input.existsSync()) {
    stderr.writeln('Input directory not found: ${input.path}');
    exitCode = 2;
    return;
  }

  final stationRows = _readCsv(File('${input.path}/stations_covered_2026.csv'));
  final fareRows = _readCsv(
    File('${input.path}/fares_osaka_amazing_pass_2026.csv'),
  );
  final busRows = _readCsv(File('${input.path}/bus_fares_2026.csv'));
  final productRows = _readCsv(File('${input.path}/pass_products_2026.csv'));
  final edgeRows = [
    ..._readCsv(File('${input.path}/metro_edges_2026.csv')),
    ..._readCsv(File('${input.path}/private_rail_edges_2026.csv')),
  ];
  final transferRows = _readCsv(
    File('${input.path}/transfer_connections_2026.csv'),
  );

  _expect(stationRows.length == 183, 'expected 183 rail stations');
  _expect(fareRows.length == 6394, 'expected 6,394 rail fare pairs');
  _expect(busRows.length == 1, 'expected one Osaka City Bus fare row');
  _expect(
    productRows.length == 2 &&
        productRows[0]['adult_price_yen'] == '3500' &&
        productRows[1]['adult_price_yen'] == '5000',
    'unexpected standard pass products or prices',
  );
  _expect(edgeRows.length == 196, 'expected 196 adjacent rail edges');
  _expect(transferRows.isNotEmpty, 'expected transfer connections');

  final koreanByCode = _loadKoreanNames();
  final yoikoRows = _readCsv(
    File('assets/data/stations/yoiko_station_codes.csv'),
  );
  final stations = <Map<String, Object>>[];
  final stationIdByPair = <String, String>{};
  for (final row in stationRows) {
    final operator = row['operator']!;
    final nameJa = row['station_name']!;
    final operatorCode = _operatorCodes[operator];
    _expect(operatorCode != null, 'unknown operator: $operator');
    final id = '$operatorCode::$nameJa';
    final pairKey = '$operator\u0000$nameJa';
    _expect(
      !stationIdByPair.containsKey(pairKey),
      'duplicate station: $pairKey',
    );
    stationIdByPair[pairKey] = id;
    stations.add({
      'id': id,
      'operator': operator,
      'name_ja': nameJa,
      'name_ko': _findKoreanName(
        operator: operator,
        nameJa: nameJa,
        yoikoRows: yoikoRows,
        koreanByCode: koreanByCode,
      ),
      'lines': row['lines']!
          .split(';')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
    });
  }

  final fares = <List<Object>>[];
  final fareKeys = <String>{};
  for (final row in fareRows) {
    final operator = row['operator']!;
    final origin = stationIdByPair['$operator\u0000${row['origin']}'];
    final destination = stationIdByPair['$operator\u0000${row['destination']}'];
    final fare = int.tryParse(row['adult_fare_yen'] ?? '');
    _expect(origin != null, 'unknown origin: $operator ${row['origin']}');
    _expect(
      destination != null,
      'unknown destination: $operator ${row['destination']}',
    );
    _expect(fare != null && fare > 0, 'invalid fare row: $row');
    final key = _sortedPair(origin!, destination!);
    _expect(fareKeys.add(key), 'duplicate fare pair: $key');
    fares.add([origin, destination, fare!]);
    if (operator == '京阪電鉄') {
      _expect(
        !(row['source_url'] ?? '').contains('keihan.co.jp'),
        'Keihan official domain must not be a production source',
      );
    }
  }

  final railEdges = <List<Object>>[];
  final railEdgeKeys = <String>{};
  for (final row in edgeRows) {
    final operator = row['operator']!;
    final from = stationIdByPair['$operator\u0000${row['station_a']}'];
    final to = stationIdByPair['$operator\u0000${row['station_b']}'];
    final distance = double.tryParse(row['business_km'] ?? '');
    _expect(
      from != null,
      'unknown rail edge origin: $operator ${row['station_a']}',
    );
    _expect(
      to != null,
      'unknown rail edge destination: $operator ${row['station_b']}',
    );
    _expect(distance != null && distance > 0, 'invalid rail edge: $row');
    final key = '${_sortedPair(from!, to!)}\u0000${row['line']}';
    _expect(railEdgeKeys.add(key), 'duplicate rail edge: $key');
    railEdges.add([from, to, distance!, row['line'] ?? '']);
  }

  final transfers = <List<Object>>[];
  final transferKeys = <String>{};
  for (final row in transferRows) {
    final from =
        stationIdByPair['${row['from_operator']}\u0000${row['from_station']}'];
    final to =
        stationIdByPair['${row['to_operator']}\u0000${row['to_station']}'];
    final walkMinutes = int.tryParse(row['walk_minutes'] ?? '');
    _expect(from != null, 'unknown transfer origin: $row');
    _expect(to != null, 'unknown transfer destination: $row');
    _expect(walkMinutes != null && walkMinutes >= 0, 'invalid transfer: $row');
    final key = _sortedPair(from!, to!);
    _expect(transferKeys.add(key), 'duplicate transfer: $key');
    transfers.add([from, to, row['transfer_kind'] ?? 'walk', walkMinutes!]);
  }

  final busFare = int.tryParse(busRows.single['adult_fare_yen'] ?? '');
  _expect(busFare == 210, 'unexpected Osaka City Bus adult fare');
  final root = <String, Object>{
    'schema_version': 2,
    'dataset_version': 'osaka-amazing-pass-routing-2026.08.24',
    'valid_from': '2026-04-01',
    'valid_to': '2027-03-31',
    'rail_station_count': stations.length,
    'rail_fare_pair_count': fares.length,
    'bus_adult_fare_yen': busFare!,
    'products': productRows
        .map(
          (row) => {
            'days': int.parse(row['days']!),
            'adult_price_yen': int.parse(row['adult_price_yen']!),
          },
        )
        .toList(growable: false),
    'sources': const [
      {
        'label': 'Osaka Metro 운임 규칙',
        'url':
            'https://subway.osakametro.co.jp/guide/fare/conditions_carriage/unsoyakan.php',
        'note': '인접 영업거리와 공식 운임 규칙으로 독립 계산',
      },
      {
        'label': '오사카 시티버스 일반 운임',
        'url': 'https://citybus-osaka.co.jp/howto/',
        'note': '성인 일반 노선 정액 운임',
      },
      {
        'label': '게이한 본선·나카노시마선 영업거리',
        'url':
            'https://ja.wikipedia.org/wiki/%E4%BA%AC%E9%98%AA%E6%9C%AC%E7%B7%9A',
        'note': 'Wikipedia contributors, CC BY-SA 4.0',
      },
      {
        'label': '게이한 운임 규칙',
        'url': 'https://www.mlit.go.jp/common/001879895.pdf',
        'note': '일본 국토교통성 공개자료로 독립 계산',
      },
      {
        'label': '한큐 전철 공개 운임 자료',
        'url':
            'https://www.hankyu.co.jp/files/upload/topics/220803/2023040_fare.pdf',
        'note': '적용 구간 성인 일반 운임 계산 기준',
      },
      {
        'label': '한신 전철 공개 운임 자료',
        'url': 'https://www.hanshin.co.jp/ticket/',
        'note': '적용 구간 성인 일반 운임 계산 기준',
      },
      {
        'label': '긴테쓰 공개 운임 자료',
        'url':
            'https://www.kintetsu.co.jp/gyoumu/kippu/pdf/kirotei_20260314.pdf',
        'note': '적용 구간 성인 일반 운임 계산 기준',
      },
      {
        'label': '난카이 전철 공개 운임 자료',
        'url':
            'https://www.nankai.co.jp/lib/traffic/guide/pdf/kisoku/01_20250401.pdf',
        'note': '적용 구간 성인 일반 운임 계산 기준',
      },
      {
        'label': '오사카 주유패스 적용 구간',
        'url': 'https://osaka-amazing-pass.com/en/howto_about_1day.html',
        'note': '2026년도 일반판 상품 가격과 6개 철도 사업자·버스 적용 범위 확인',
      },
    ],
    'stations': stations,
    'fares': fares,
    'rail_edges': railEdges,
    'transfers': transfers,
  };
  output.parent.createSync(recursive: true);
  output.writeAsStringSync(jsonEncode(root));
  stdout.writeln(
    'Wrote ${stations.length} stations, ${fares.length} fare pairs, '
    '${railEdges.length} rail edges and ${transfers.length} transfers '
    'to ${output.path}',
  );
}

String _findKoreanName({
  required String operator,
  required String nameJa,
  required List<Map<String, String>> yoikoRows,
  required Map<String, String> koreanByCode,
}) {
  final yoikoName = _yoikoStationAliases[nameJa] ?? nameJa;
  final yoikoOperator = _yoikoOperators[operator];
  final names = <String>{};
  for (final row in yoikoRows) {
    if (row['operator_name'] != yoikoOperator ||
        row['station_name'] != yoikoName) {
      continue;
    }
    final code =
        '${row['region_code']}:${row['line_code']}:${row['station_code']}';
    final korean = koreanByCode[code];
    if (korean != null && korean.isNotEmpty) names.add(_stripStation(korean));
  }
  return names.length == 1
      ? names.single
      : _fallbackKoreanNames['$operator::$nameJa'] ?? '';
}

Map<String, String> _loadKoreanNames() {
  final result = <String, String>{};
  for (final path in [
    'assets/data/stations/station_names_ko_by_code.csv',
    'assets/data/stations/manual_station_names_ko_by_code.csv',
  ]) {
    for (final row in _readCsv(File(path))) {
      final value = row['station_name_ko']?.trim() ?? '';
      if (value.isEmpty) continue;
      result['${row['region_code']}:${row['line_code']}:${row['station_code']}'] =
          value;
    }
  }
  return result;
}

List<Map<String, String>> _readCsv(File file) {
  _expect(file.existsSync(), 'missing CSV: ${file.path}');
  final rows = _parseCsv(file.readAsStringSync());
  _expect(rows.isNotEmpty, 'empty CSV: ${file.path}');
  final headers = rows.first;
  return rows
      .skip(1)
      .map((values) {
        _expect(
          values.length == headers.length,
          'invalid CSV row in ${file.path}',
        );
        return <String, String>{
          for (var index = 0; index < headers.length; index++)
            headers[index]: values[index],
        };
      })
      .toList(growable: false);
}

List<List<String>> _parseCsv(String source) {
  final rows = <List<String>>[];
  var row = <String>[];
  var field = StringBuffer();
  var quoted = false;
  for (var index = 0; index < source.length; index++) {
    final char = source[index];
    if (char == '"') {
      if (quoted && index + 1 < source.length && source[index + 1] == '"') {
        field.write('"');
        index++;
      } else {
        quoted = !quoted;
      }
    } else if (char == ',' && !quoted) {
      row.add(field.toString());
      field = StringBuffer();
    } else if ((char == '\n' || char == '\r') && !quoted) {
      if (char == '\r' &&
          index + 1 < source.length &&
          source[index + 1] == '\n') {
        index++;
      }
      row.add(field.toString());
      field = StringBuffer();
      if (row.any((value) => value.isNotEmpty)) rows.add(row);
      row = <String>[];
    } else {
      field.write(char);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows;
}

String? _argument(List<String> arguments, String name) {
  final index = arguments.indexOf(name);
  return index >= 0 && index + 1 < arguments.length
      ? arguments[index + 1]
      : null;
}

String _stripStation(String value) =>
    value.endsWith('역') ? value.substring(0, value.length - 1) : value;

String _sortedPair(String first, String second) => first.compareTo(second) <= 0
    ? '$first\u0000$second'
    : '$second\u0000$first';

void _expect(bool condition, String message) {
  if (!condition) throw StateError(message);
}
