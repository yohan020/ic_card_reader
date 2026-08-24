import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/osaka_pass_station_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/domain/osaka_amazing_pass.dart';

void main() {
  group('OsakaAmazingPassEvaluator', () {
    test('1일권은 입력한 교통비 합계와 3500엔을 비교한다', () {
      final result = OsakaAmazingPassEvaluator.evaluate(
        product: OsakaAmazingPassProduct.oneDay,
        segments: const [
          OsakaPlannedSegment(
            dayIndex: 0,
            operator: 'Osaka Metro',
            fromStation: '난바',
            toStation: '우메다',
            regularFare: 2100,
          ),
          OsakaPlannedSegment(
            dayIndex: 0,
            operator: 'Osaka Metro',
            fromStation: '우메다',
            toStation: '덴노지',
            regularFare: 1900,
          ),
        ],
      );

      expect(result.regularFareTotal, 4000);
      expect(result.savings, 500);
      expect(result.verdict, OsakaPassVerdict.beneficial);
    });

    test('2일권 범위 밖 일차와 0엔 구간은 합산하지 않는다', () {
      final result = OsakaAmazingPassEvaluator.evaluate(
        product: OsakaAmazingPassProduct.twoDay,
        segments: const [
          OsakaPlannedSegment(
            dayIndex: 0,
            operator: 'Osaka Metro',
            fromStation: 'A',
            toStation: 'B',
            regularFare: 240,
          ),
          OsakaPlannedSegment(
            dayIndex: 2,
            operator: 'Osaka Metro',
            fromStation: 'B',
            toStation: 'C',
            regularFare: 5000,
          ),
          OsakaPlannedSegment(
            dayIndex: 1,
            operator: 'Osaka Metro',
            fromStation: 'C',
            toStation: 'D',
            regularFare: 0,
          ),
        ],
      );

      expect(result.segments, hasLength(1));
      expect(result.regularFareTotal, 240);
      expect(result.verdict, OsakaPassVerdict.notBeneficial);
    });
  });

  test('검증 asset에서 전체 철도역을 검색하고 사업자별 운임을 조회한다', () {
    final data = OsakaPassStationData.fromJson(
      File(
        'assets/data/pass_comparison/osaka_amazing_pass_fares_2026.json',
      ).readAsStringSync(),
    );

    expect(data.stations, hasLength(183));
    expect(data.railEdges, hasLength(196));
    expect(data.transfers, hasLength(27));
    expect(data.busAdultFare, 210);
    final japanese = data.search('なんば', operator: 'Osaka Metro');
    expect(japanese, isNotEmpty);
    expect(japanese.first.nameJa, 'なんば');
    expect(japanese.first.lines.length, greaterThanOrEqualTo(3));
    final koreanInitials = data.search('ㄴㅂ');
    expect(koreanInitials.any((station) => station.nameJa == 'なんば'), isTrue);

    OsakaPassStation station(String operator, String nameJa) =>
        data.stations.singleWhere(
          (station) => station.operator == operator && station.nameJa == nameJa,
        );
    expect(
      data.fareBetween(
        station('Osaka Metro', '梅田'),
        station('Osaka Metro', 'なんば'),
      ),
      240,
    );
    expect(
      data.fareBetween(station('京阪電鉄', '大江橋'), station('京阪電鉄', '京橋')),
      180,
    );
    expect(
      data.fareBetween(station('京阪電鉄', '中之島'), station('京阪電鉄', '京橋')),
      300,
    );
    expect(
      data.fareBetween(station('南海電鉄', '難波'), station('南海電鉄', '中百舌鳥')),
      350,
    );
    expect(
      data.fareBetween(station('阪神電鉄', '大阪難波'), station('阪神電鉄', '尼崎')),
      340,
    );
    expect(
      data.fareBetween(station('Osaka Metro', '梅田'), station('阪神電鉄', '大阪梅田')),
      isNull,
    );

    final metroToNankai = data.routeBetween(
      station('Osaka Metro', '梅田'),
      station('南海電鉄', '堺'),
    );
    expect(metroToNankai, isNotNull);
    expect(metroToNankai!.transferCount, 1);
    expect(metroToNankai.legs.map((leg) => leg.operator), [
      'Osaka Metro',
      '南海電鉄',
    ]);
    expect(
      metroToNankai.fare,
      metroToNankai.legs.fold<int>(0, (sum, leg) => sum + leg.fare),
    );

    final hankyuToNankai = data.routeBetween(
      station('阪急電鉄', '神崎川'),
      station('南海電鉄', '堺'),
    );
    expect(hankyuToNankai, isNotNull);
    expect(hankyuToNankai!.transferCount, greaterThanOrEqualTo(2));
    expect(hankyuToNankai.legs.first.operator, '阪急電鉄');
    expect(hankyuToNankai.legs.last.operator, '南海電鉄');
  });

  test('버스 탑승 횟수도 패스 손익에 합산한다', () {
    final result = OsakaAmazingPassEvaluator.evaluate(
      product: OsakaAmazingPassProduct.oneDay,
      segments: const [],
      busRidesByDay: const [3, 99],
      busAdultFare: 210,
    );

    expect(result.busRidesByDay, [3]);
    expect(result.railFareTotal, 0);
    expect(result.busFareTotal, 630);
    expect(result.regularFareTotal, 630);
    expect(result.verdict, OsakaPassVerdict.notBeneficial);
  });
}
