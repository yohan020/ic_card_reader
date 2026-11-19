import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/kyoto_subway_1day_pass_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/kyoto_subway_bus_pass_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/domain/kyoto_subway_1day_pass.dart';

void main() {
  late KyotoSubway1DayPassData data;

  setUpAll(() async {
    final source = await File(
      'assets/data/pass_comparison/kyoto_subway_bus_1day_2026.json',
    ).readAsString();
    data = KyotoSubway1DayPassData(KyotoSubwayBusPassData.fromJson(source));
  });

  test('교토 지하철 전 구간의 검색과 성인 운임을 재사용한다', () {
    final kyoto = data
        .search('교토')
        .firstWhere((station) => station.id == 'K11');
    final shijo = data.search('시조').first;

    expect(KyotoSubway1DayPassData.passPrice, 800);
    expect(data.search('교토시영지하철'), isEmpty);
    expect(data.fareBetween(kyoto, shijo), 220);
  });

  test('지하철 성인 일반 운임만 패스 가격과 비교한다', () {
    final kyoto = data
        .search('교토')
        .firstWhere((station) => station.id == 'K11');
    final shijo = data.search('시조').first;
    final result = KyotoSubway1DayPassEvaluator.evaluate([
      KyotoSubway1DayPlannedSegment(
        from: kyoto,
        to: shijo,
        fare: data.fareBetween(kyoto, shijo)!,
      ),
      KyotoSubway1DayPlannedSegment(
        from: shijo,
        to: kyoto,
        fare: data.fareBetween(shijo, kyoto)!,
      ),
      KyotoSubway1DayPlannedSegment(
        from: kyoto,
        to: shijo,
        fare: data.fareBetween(kyoto, shijo)!,
      ),
      KyotoSubway1DayPlannedSegment(
        from: shijo,
        to: kyoto,
        fare: data.fareBetween(shijo, kyoto)!,
      ),
    ]);

    expect(result.regularFareTotal, 880);
    expect(result.savings, 80);
    expect(result.verdict, KyotoSubway1DayPassVerdict.beneficial);
  });
}
