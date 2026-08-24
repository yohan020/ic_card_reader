import 'package:flutter_test/flutter_test.dart';
// ignore: avoid_relative_lib_imports
import '../../tool/lib/tokunai_derived_fare_csv.dart';
// ignore: avoid_relative_lib_imports
import '../../tool/lib/tokunai_fare_builder.dart';

void main() {
  test('builds a complete verified fare asset with runtime station ids', () {
    final result = buildTokunaiFareAsset(
      stationDirectory: _twoStationDirectory,
      verifiedInput: _oneVerifiedFare,
    );

    expect(result['tokunaiFareDataComplete'], isTrue);
    expect(result['fares'], [
      {
        'operatorId': 'jr-east:tokunai',
        'fromStationId': 'jr-tokunai:Tokyo',
        'toStationId': 'jr-tokunai:Kanda',
        'adultIcFare': 155,
      },
    ]);
  });

  test(
    'rejects an incomplete fare matrix instead of enabling a partial one',
    () {
      expect(
        () => buildTokunaiFareAsset(
          stationDirectory: _threeStationDirectory,
          verifiedInput: _oneVerifiedFare,
        ),
        throwsA(
          isA<TokunaiFareBuildException>().having(
            (error) => error.message,
            'message',
            contains('Incomplete verified fare table'),
          ),
        ),
      );
    },
  );

  test('rejects a non-official per-pair evidence URL', () {
    final invalid = {
      ..._oneVerifiedFare,
      'fares': [
        {
          ...(_oneVerifiedFare['fares']! as List<Object?>).single
              as Map<String, Object?>,
          'sourceUrl': 'https://example.com/fare',
        },
      ],
    };

    expect(
      () => buildTokunaiFareAsset(
        stationDirectory: _twoStationDirectory,
        verifiedInput: invalid,
      ),
      throwsA(isA<TokunaiFareBuildException>()),
    );
  });

  test('maps reviewed CSV station names to runtime fare ids', () {
    final input = tokunaiDerivedCsvToBuilderInput(
      csv: '''origin,destination,ic_fare
東京,神田,155
''',
      stationDirectory: _twoStationDirectoryWithNames,
      verifiedAt: DateTime.utc(2026, 8, 23),
    );
    final result = buildTokunaiFareAsset(
      stationDirectory: _twoStationDirectoryWithNames,
      verifiedInput: input,
    );

    expect(input['source'], contains('Derived 2026'));
    expect(result['tokunaiFareDataComplete'], isTrue);
    expect((result['fares']! as List<Object?>), hasLength(1));
  });
}

final _twoStationDirectory = <String, Object?>{
  'stations': [
    _station('jr-tokunai:tokyo', 'jr-tokunai:Tokyo'),
    _station('jr-tokunai:kanda', 'jr-tokunai:Kanda'),
  ],
};

final _threeStationDirectory = <String, Object?>{
  'stations': [
    _station('jr-tokunai:tokyo', 'jr-tokunai:Tokyo'),
    _station('jr-tokunai:kanda', 'jr-tokunai:Kanda'),
    _station('jr-tokunai:akihabara', 'jr-tokunai:Akihabara'),
  ],
};

final _twoStationDirectoryWithNames = <String, Object?>{
  'stations': [
    _stationWithName('jr-tokunai:tokyo', 'jr-tokunai:Tokyo', '東京'),
    _stationWithName('jr-tokunai:kanda', 'jr-tokunai:Kanda', '神田'),
  ],
};

final _oneVerifiedFare = <String, Object?>{
  'source': 'JR East official fare search',
  'verifiedAt': '2026-08-23T00:00:00.000Z',
  'fares': [
    {
      'from': 'jr-tokunai:tokyo',
      'to': 'jr-tokunai:kanda',
      'adultIcFare': 155,
      'sourceUrl': 'https://www.jreast.co.jp/2026unchin-kaitei/',
    },
  ],
};

Map<String, Object?> _station(String id, String runtimeId) => {
  'id': id,
  'odptIds': [runtimeId],
  'tokunaiPassEligible': true,
};

Map<String, Object?> _stationWithName(
  String id,
  String runtimeId,
  String nameJa,
) => {..._station(id, runtimeId), 'nameJa': nameJa};
