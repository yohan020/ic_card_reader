import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/pass_transit_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/domain/pass_comparison.dart';

void main() {
  late PassTransitData data;

  setUp(() {
    data = PassTransitData.fromJsonString(_fixture);
  });

  test('finds a Korean station by initial consonant and syllable prefix', () {
    expect(data.searchStations('ㅅ').first.displayName, '시부야');
    expect(data.searchStations('시').first.displayName, '시부야');
    expect(data.searchStations('ㅅㅂㅇ').first.displayName, '시부야');
  });

  test('also searches Japanese and English station names', () {
    expect(data.searchStations('渋谷').single.displayName, '시부야');
    expect(data.searchStations('shib').single.displayName, '시부야');
  });

  test('resolves the minimum ODPT IC fare in either direction', () {
    final shibuya = data.searchStations('시부야').single;
    final ueno = data.searchStations('우에노').single;

    final fare = data.resolveFare(ueno, shibuya);

    expect(fare?.fare, 209);
    expect(fare?.coverage, TransitCoverage.tokyoMetro);
  });

  test('combines verified Metro and Toei fares through a transfer station', () {
    final shibuya = data.searchStations('시부야').single;
    final kasuga = data.searchStations('가스가').single;

    final outbound = data.resolveFare(shibuya, kasuga);
    final inbound = data.resolveFare(kasuga, shibuya);

    expect(outbound?.fare, 317);
    expect(outbound?.coverage, TransitCoverage.metroToToeiSubway);
    expect(inbound?.fare, 317);
    expect(inbound?.coverage, TransitCoverage.metroToToeiSubway);
  });

  test('returns no fare instead of guessing an unsupported pair', () {
    final shibuya = data.searchStations('시부야').single;

    expect(data.resolveFare(shibuya, shibuya), isNull);
  });

  test('finds a Tokunai station without inventing a fare', () {
    final tokunai = PassTransitData.fromJsonString(_tokunaiDirectoryFixture);
    final station = tokunai.searchStations(
      'ㅅㅂㅇ',
      product: PassProduct.tokunai1Day,
    );

    expect(station.single.displayName, '시부야');
    expect(tokunai.hasTokunaiStationDirectory, isTrue);
    expect(tokunai.hasTokunaiJrFareData, isFalse);
    expect(tokunai.resolveFare(station.single, station.single), isNull);
  });

  test('loads the complete derived Tokunai fare matrix', () async {
    final tokunai = PassTransitData.fromJsonString(
      await File(
        'assets/data/pass_comparison/tokunai_jr_data.json',
      ).readAsString(),
    );
    final koiwa = tokunai
        .searchStations('고이와', product: PassProduct.tokunai1Day)
        .single;
    final kasai = tokunai
        .searchStations('가사이린카이코엔', product: PassProduct.tokunai1Day)
        .single;

    expect(tokunai.stations, hasLength(77));
    expect(tokunai.fares, hasLength(2926));
    expect(tokunai.hasTokunaiJrFareData, isTrue);
    expect(tokunai.searchStations('히가시나카노').single.nameJa, '東中野');
    expect(tokunai.resolveFare(koiwa, kasai)?.fare, 440);
    expect(
      tokunai.resolveFare(koiwa, kasai)?.coverage,
      TransitCoverage.tokunaiJr,
    );
  });

  test(
    'uses the precomputed product station index for merged assets',
    () async {
      final odpt = PassTransitData.fromJsonString(
        await File(
          'assets/data/pass_comparison/odpt_pass_data.json',
        ).readAsString(),
      );
      final tokunai = PassTransitData.fromJsonString(
        await File(
          'assets/data/pass_comparison/tokunai_jr_data.json',
        ).readAsString(),
      );
      final merged = odpt.merge(tokunai);

      expect(
        merged
            .searchStations('한조몬', product: PassProduct.tokyoSubway24)
            .map((station) => station.nameJa),
        contains('半蔵門'),
      );
      expect(
        merged.searchStations('한조몬', product: PassProduct.tokunai1Day),
        isEmpty,
      );
      expect(
        merged
            .searchStations('고이와', product: PassProduct.tokunai1Day)
            .map((station) => station.nameJa),
        contains('小岩'),
      );
      expect(
        merged
            .searchStations('고이와', product: PassProduct.tokyoSubway24)
            .map((station) => station.nameJa),
        isNot(contains('小岩')),
      );

      final stopwatch = Stopwatch()..start();
      for (var index = 0; index < 50; index++) {
        merged.searchStations('ㅅㅂㅇ', product: PassProduct.tokyoSubway24);
        merged.searchStations('ㄱㅇㅇ', product: PassProduct.tokunai1Day);
      }
      stopwatch.stop();
      expect(
        stopwatch.elapsed,
        lessThan(const Duration(seconds: 2)),
        reason: '키 입력 검색에서 전체 운임표를 다시 순회하면 안 됩니다.',
      );
    },
  );
}

const _fixture = '''
{
  "generatedAt": "2026-08-12T00:00:00.000Z",
  "source": "ODPT test fixture",
  "stations": [
    {
      "id": "station-1",
      "nameKo": "시부야",
      "nameJa": "渋谷",
      "nameEn": "Shibuya",
      "odptIds": ["odpt.Station:TokyoMetro.Ginza.Shibuya"],
      "operators": ["odpt.Operator:TokyoMetro"],
      "railways": ["odpt.Railway:TokyoMetro.Ginza"],
      "aliases": []
    },
    {
      "id": "station-2",
      "nameKo": "우에노",
      "nameJa": "上野",
      "nameEn": "Ueno",
      "odptIds": ["odpt.Station:TokyoMetro.Ginza.Ueno"],
      "operators": ["odpt.Operator:TokyoMetro"],
      "railways": ["odpt.Railway:TokyoMetro.Ginza"],
      "aliases": []
    },
    {
      "id": "station-3",
      "nameKo": "가스가",
      "nameJa": "春日",
      "nameEn": "Kasuga",
      "odptIds": ["odpt.Station:Toei.Mita.Kasuga"],
      "operators": ["odpt.Operator:Toei"],
      "railways": ["odpt.Railway:Toei.Mita"],
      "aliases": []
    },
    {
      "id": "station-4",
      "nameKo": "오테마치",
      "nameJa": "大手町",
      "nameEn": "Otemachi",
      "odptIds": [
        "odpt.Station:TokyoMetro.Marunouchi.Otemachi",
        "odpt.Station:Toei.Mita.Otemachi"
      ],
      "operators": ["odpt.Operator:TokyoMetro", "odpt.Operator:Toei"],
      "railways": [
        "odpt.Railway:TokyoMetro.Marunouchi",
        "odpt.Railway:Toei.Mita"
      ],
      "aliases": []
    }
  ],
  "fares": [
    {
      "operatorId": "odpt.Operator:TokyoMetro",
      "fromStationId": "odpt.Station:TokyoMetro.Ginza.Shibuya",
      "toStationId": "odpt.Station:TokyoMetro.Ginza.Ueno",
      "adultIcFare": 209
    },
    {
      "operatorId": "odpt.Operator:TokyoMetro",
      "fromStationId": "odpt.Station:TokyoMetro.Ginza.Shibuya",
      "toStationId": "odpt.Station:TokyoMetro.Marunouchi.Otemachi",
      "adultIcFare": 209
    },
    {
      "operatorId": "odpt.Operator:Toei",
      "fromStationId": "odpt.Station:Toei.Mita.Otemachi",
      "toStationId": "odpt.Station:Toei.Mita.Kasuga",
      "adultIcFare": 178
    }
  ]
}
''';

const _tokunaiDirectoryFixture = '''
{
  "generatedAt": "2026-08-23T00:00:00.000Z",
  "source": "Tokunai directory test fixture",
  "stations": [
    {
      "id": "jr-tokunai:shibuya",
      "nameKo": "시부야",
      "nameJa": "渋谷",
      "nameEn": "Shibuya",
      "odptIds": ["jr-tokunai:Shibuya"],
      "operators": ["JR 동일본"],
      "railways": ["도쿠나이 패스 적용 JR"],
      "aliases": [],
      "tokunaiPassEligible": true
    }
  ],
  "fares": []
}
''';
