import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/hokkaido_rail_pass_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/domain/hokkaido_rail_pass.dart';

void main() {
  final data = HokkaidoRailPassData.fromCsv(
    stationsCsv: '''station_id,name_ja,name_ko,station_type
SAPPORO,札幌,삿포로,regular
HAKODATE,函館,하코다테,regular
ASAHIKAWA,旭川,아사히카와,regular
''',
    minimumFaresCsv:
        '''origin_id,origin,destination_id,destination,adult_basic_fare_yen
SAPPORO,札幌,HAKODATE,函館,6270
HAKODATE,函館,SAPPORO,札幌,6270
SAPPORO,札幌,ASAHIKAWA,旭川,2860
''',
    limitedExpressSafePairsCsv:
        '''route_id,service_name_ja,direction_id,origin_sequence,destination_sequence,origin_id,origin_ja,origin_ko,destination_id,destination_ja,destination_ko,adult_basic_fare_yen,seat_charge_yen,normal_total_yen,pass_covered_value_yen,route_fares_match,route_fare_key,checked_date
LE_HOKUTO,北斗,HOKUTO_HAKODATE_TO_SAPPORO,1,2,HAKODATE,函館,하코다테,SAPPORO,札幌,삿포로,6600,3170,9770,9770,1,key,2026-09-04
''',
  );

  test('특급은 검증된 방향별 역쌍에서만 조회한다', () {
    final sapporo = data.search('삿포로').single;
    final hakodate = data.search('하코다테').single;
    final asahikawa = data.search('아사히').single;

    expect(data.basicFareBetween(sapporo, hakodate), 6270);
    expect(
      data.limitedExpressFareBetween(hakodate, sapporo)?.normalTotalYen,
      9770,
    );
    expect(data.limitedExpressFareBetween(sapporo, hakodate), isNull);
    expect(data.limitedExpressFareBetween(sapporo, asahikawa), isNull);
  });

  test('검색은 역명만 대상으로 하며 한글과 초성으로 동작한다', () {
    expect(data.search('삿포').single.nameJa, '札幌');
    expect(data.search('ㅎㅋㄷ').single.nameJa, '函館');
    expect(data.search('JR'), isEmpty);
  });

  test('binary 운임 인덱스는 방향별 기본 운임과 없는 역쌍을 구분한다', () {
    final bytes = Uint8List(8 + 3 * 3 * 2);
    bytes.setRange(0, 4, [0x48, 0x52, 0x50, 0x46]);
    ByteData.sublistView(bytes)
      ..setUint16(4, 1, Endian.little)
      ..setUint16(6, 3, Endian.little);
    final fares = Uint16List.view(bytes.buffer, 8, 9)..fillRange(0, 9, 0xffff);
    fares[1] = 6270;
    final binaryData = HokkaidoRailPassData.fromBinary(
      stationsCsv: '''station_id,name_ja,name_ko,station_type
SAPPORO,札幌,삿포로,regular
HAKODATE,函館,하코다테,regular
ASAHIKAWA,旭川,아사히카와,regular
''',
      minimumFaresBinary: ByteData.sublistView(bytes),
      limitedExpressSafePairsCsv:
          'route_id,service_name_ja,direction_id,origin_sequence,destination_sequence,origin_id,origin_ja,origin_ko,destination_id,destination_ja,destination_ko,adult_basic_fare_yen,seat_charge_yen,normal_total_yen,pass_covered_value_yen,route_fares_match,route_fare_key,checked_date\n',
    );
    final sapporo = binaryData.search('삿포로').single;
    final hakodate = binaryData.search('하코다테').single;
    final asahikawa = binaryData.search('아사히카와').single;

    expect(binaryData.basicFareBetween(sapporo, hakodate), 6270);
    expect(binaryData.basicFareBetween(hakodate, sapporo), isNull);
    expect(binaryData.basicFareBetween(sapporo, asahikawa), isNull);
  });

  test('특급 지정석과 버스 예상값을 합산해 역 구매 가격과 비교한다', () {
    final hakodate = data.search('하코다테').single;
    final sapporo = data.search('삿포로').single;
    final result = HokkaidoRailPassEvaluator.evaluate(
      segments: [
        HokkaidoRailPassPlannedSegment(
          from: hakodate,
          to: sapporo,
          fare: 9770,
          mode: HokkaidoRailTravelMode.limitedExpress,
        ),
      ],
      estimatedBusRides: 2,
      passPrice: HokkaidoRailPassData.stationPurchasePrices[5]!,
    );

    expect(result.railFareTotal, 9770);
    expect(result.estimatedBusValue, 600);
    expect(result.savings, -12630);
    expect(result.verdict, HokkaidoRailPassVerdict.notBeneficial);
  });
}
