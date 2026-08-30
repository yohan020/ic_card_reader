import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ic_card_reader/src/features/pass_comparison/data/kyoto_subway_bus_pass_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/domain/kyoto_subway_bus_pass.dart';

void main() {
  late KyotoSubwayBusPassData data;

  setUpAll(() async {
    data = KyotoSubwayBusPassData.fromJson(
      await File(
        'assets/data/pass_comparison/kyoto_subway_bus_1day_2026.json',
      ).readAsString(),
    );
  });

  test('교토 지하철 역 검색과 성인 운임표를 읽는다', () {
    final kyoto = data
        .search('교토')
        .firstWhere((station) => station.id == 'K11');
    final shijo = data.search('시조').first;
    final uzumasa = data.search('우즈마사').first;
    final rokkujizo = data.search('ㄹㅋㅈ').first;

    expect(data.search('ㄱㄹㅅㅁ').any((station) => station.id == 'K08'), true);
    expect(kyoto.nameJa, '京都');
    expect(rokkujizo.id, 'T01');
    expect(data.fareBetween(kyoto, shijo), 220);
    expect(data.fareBetween(uzumasa, rokkujizo), 360);
  });

  test('지하철 정확 운임과 사용자 입력 버스 예상 운임을 합산한다', () {
    final kyoto = data
        .search('교토')
        .firstWhere((station) => station.id == 'K11');
    final shijo = data.search('시조').first;
    final result = KyotoSubwayBusPassEvaluator.evaluate(
      data: data,
      segments: [
        KyotoPlannedSegment(
          from: kyoto,
          to: shijo,
          fare: data.fareBetween(kyoto, shijo)!,
        ),
      ],
      cityBusRides: 3,
      sightseeingExpressRides: 1,
    );

    expect(result.railFareTotal, 220);
    expect(result.busFareTotal, 1190);
    expect(result.regularFareTotal, 1410);
    expect(result.savings, 310);
    expect(result.verdict, KyotoPassVerdict.beneficial);
  });
}
