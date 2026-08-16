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

  test('returns no fare instead of guessing an unsupported pair', () {
    final shibuya = data.searchStations('시부야').single;

    expect(data.resolveFare(shibuya, shibuya), isNull);
  });
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
    }
  ],
  "fares": [
    {
      "operatorId": "odpt.Operator:TokyoMetro",
      "fromStationId": "odpt.Station:TokyoMetro.Ginza.Shibuya",
      "toStationId": "odpt.Station:TokyoMetro.Ginza.Ueno",
      "adultIcFare": 209
    }
  ]
}
''';
