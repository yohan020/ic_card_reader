import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/okayama_kurashiki_gururin_pass_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/domain/okayama_kurashiki_gururin_pass.dart';

void main() {
  final data = OkayamaKurashikiGururinPassData.fromCsv(
    stationsCsv: '''station_id,name_ja,name_en,operator,mode
OKAYAMA,岡山,Okayama,JR West,rail
KURASHIKI,倉敷,Kurashiki,JR West,rail
SOJA,総社,Sōja,JR West,rail
''',
    faresCsv: '''origin,destination,adult_fare_yen
OKAYAMA,KURASHIKI,330
KURASHIKI,OKAYAMA,330
OKAYAMA,SOJA,420
SOJA,OKAYAMA,420
''',
  );

  test('한국어·초성·일본어 역 검색과 JR 일반 운임을 제공한다', () {
    expect(data.search('오카야마').single.nameJa, '岡山');
    expect(data.search('ㅇㅋㅇ').single.nameJa, '岡山');
    expect(data.search('倉').single.nameJa, '倉敷');
    expect(data.search('jr'), isEmpty);
    expect(
      data.fareBetween(data.search('오카야마').single, data.search('구라시키').single),
      330,
    );
  });

  test('철도·정확 운임·대표 운임을 분리해 손익을 계산한다', () {
    final okayama = data.search('오카야마').single;
    final kurashiki = data.search('구라시키').single;
    final result = OkayamaKurashikiGururinPassEvaluator.evaluate(
      [
        OkayamaKurashikiGururinPlannedSegment(
          from: okayama,
          to: kurashiki,
          fare: 330,
        ),
      ],
      serviceRides: {data.services.first: 2, data.services[1]: 1},
    );

    expect(result.railFareTotal, 330);
    expect(result.exactServiceFareTotal, 320);
    expect(result.estimatedServiceFareTotal, 770);
    expect(result.regularFareTotal, 1420);
    expect(result.verdict, OkayamaKurashikiGururinPassVerdict.notBeneficial);
  });

  testWidgets('배포용 CSV 헤더로 하야시마와 비젠니시이치 운임을 조회한다', (tester) async {
    final loadedData = await tester.runAsync(
      () => const OkayamaKurashikiGururinPassDataRepository().load(),
    );
    expect(loadedData, isNotNull);
    final productionData = loadedData!;
    final hayashima = productionData.search('하야시마').single;
    final bizenNishiichi = productionData.search('비젠니시이치').single;

    expect(productionData.stations, hasLength(35));
    expect(productionData.fareBetween(hayashima, bizenNishiichi), 200);
    expect(productionData.fareBetween(bizenNishiichi, hayashima), 200);
  });
}
