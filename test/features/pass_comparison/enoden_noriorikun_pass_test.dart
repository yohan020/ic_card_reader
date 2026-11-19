import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/enoden_noriorikun_pass_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/domain/enoden_noriorikun_pass.dart';

void main() {
  final data = EnodenNoriorikunPassData.fromJson('''
  {"pass_price_yen":800,"stations":[
    {"id":"a","ja":"藤沢","ko":"후지사와","km":0.0},
    {"id":"b","ja":"江ノ島","ko":"에노시마","km":3.3},
    {"id":"c","ja":"鎌倉","ko":"가마쿠라","km":10.0},
    {"id":"d","ja":"長谷","ko":"하세","km":7.8}
  ],"fare_bands":[
    {"max_km":2.0,"adult_yen":200},
    {"max_km":4.0,"adult_yen":220},
    {"max_km":7.0,"adult_yen":260},
    {"max_km":10.0,"adult_yen":310}
  ]}''');

  test('거리대별 에노덴 성인 운임을 계산한다', () {
    expect(data.fareBetween(data.stations[0], data.stations[1]), 220);
    expect(data.fareBetween(data.stations[0], data.stations[2]), 310);
    expect(data.fareBetween(data.stations[0], data.stations[0]), isNull);
  });

  test('한국어와 초성으로 역을 찾는다', () {
    expect(data.search('에노').single.nameJa, '江ノ島');
    expect(data.search('에').single.nameJa, '江ノ島');
    expect(data.search('ㅎㅅ').single.nameJa, '長谷');
    expect(data.search('에노덴'), isEmpty);
  });

  test('일반 운임 합계가 패스 가격을 넘으면 이득으로 판정한다', () {
    final result = EnodenNoriorikunPassEvaluator.evaluate(
      data: data,
      segments: [
        EnodenPlannedSegment(
          from: data.stations[0],
          to: data.stations[2],
          fare: 310,
        ),
        EnodenPlannedSegment(
          from: data.stations[2],
          to: data.stations[0],
          fare: 310,
        ),
        EnodenPlannedSegment(
          from: data.stations[0],
          to: data.stations[2],
          fare: 310,
        ),
      ],
    );
    expect(result.regularFareTotal, 930);
    expect(result.savings, 130);
    expect(result.verdict, EnodenPassVerdict.beneficial);
  });
}
