import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/kintetsu_rail_pass_5day_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/domain/kintetsu_rail_pass_5day.dart';

void main() {
  final stations = [
    const KintetsuStation(id: 'namba', nameJa: '大阪難波', nameEn: 'Osaka-Namba', nameKo: '오사카난바', operator: 'Kintetsu Railway', lines: 'kintetsu_namba'),
    const KintetsuStation(id: 'nara', nameJa: '近鉄奈良', nameEn: 'Kintetsu-Nara', nameKo: '긴테쓰나라', operator: 'Kintetsu Railway', lines: 'nara'),
  ];
  final data = KintetsuRailPass5DayData.forTest(stations: stations, passPrice: 4900, fares: const {'namba|nara': 680});

  test('한국어·일본어·초성 역 검색은 역명만 사용한다', () {
    expect(data.search('오사카').single.id, 'namba');
    expect(data.search('긴테쓰나라').single.id, 'nara');
    expect(data.search('ㄱㅌㅆㄴㄹ').single.id, 'nara');
    expect(data.search('긴테쓰전철'), isEmpty);
  });

  test('한국어 표시에서는 역 접미사를 중복 표기하지 않는다', () {
    const station = KintetsuStation(
      id: 'suffix',
      nameJa: '黄金',
      nameEn: 'Kogane',
      nameKo: '고가네역',
      operator: 'Kintetsu Railway',
      lines: 'nagoya',
    );
    expect(station.displayName, '고가네');
  });

  test('5일 동안 입력한 기본 운임 합계와 패스 가격을 비교한다', () {
    final result = KintetsuRailPass5DayEvaluator.evaluate(data: data, segments: [
      for (var index = 0; index < 5; index++) KintetsuPlannedSegment(from: stations[0], to: stations[1], fare: 680),
      KintetsuPlannedSegment(from: stations[1], to: stations[0], fare: 680),
      KintetsuPlannedSegment(from: stations[0], to: stations[1], fare: 680),
      KintetsuPlannedSegment(from: stations[1], to: stations[0], fare: 680),
    ]);
    expect(result.regularFareTotal, 5440);
    expect(result.savings, 540);
    expect(result.verdict, KintetsuPassVerdict.beneficial);
  });
}
