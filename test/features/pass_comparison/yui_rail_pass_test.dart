import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/yui_rail_pass_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/domain/yui_rail_pass.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/yui_rail_pass_page.dart';

void main() {
  final data = YuiRailPassData.fromCsv(
    stationsCsv: '''station_id,name_ja,name_en,operator,station_codes
YR01,那覇空港,Naha Airport,沖縄都市モノレール,1
YR02,赤嶺,Akamine,沖縄都市モノレール,2
YR03,小禄,Oroku,沖縄都市モノレール,3
''',
    faresCsv: '''origin,destination,adult_fare_yen
YR01,YR02,250
YR02,YR01,250
YR01,YR03,250
YR03,YR01,250
''',
  );

  test('한국어·초성·일본어·영어 역명으로 성인 일반 운임을 찾는다', () {
    expect(data.stations, hasLength(3));
    expect(data.search('아카미네').single.nameJa, '赤嶺');
    expect(data.search('ㅇㅋㅁㄴ').single.nameJa, '赤嶺');
    expect(data.search('Naha').single.nameJa, '那覇空港');
    expect(data.search('유이레일'), isEmpty);
    expect(
      data.fareBetween(data.search('나하').first, data.search('아카').single),
      250,
    );
  });

  test('선택한 시간권 가격을 기준으로 손익을 판정한다', () {
    final naha = data.search('나하').first;
    final akamine = data.search('아카').single;
    final result = YuiRailPassEvaluator.evaluate([
      for (var index = 0; index < 5; index++)
        YuiRailPlannedSegment(from: naha, to: akamine, fare: 250),
    ], passHours: 24);
    expect(result.regularFareTotal, 1250);
    expect(result.savings, 250);
    expect(result.verdict, YuiRailPassVerdict.beneficial);
  });

  testWidgets('요약 카드에서 24·48시간권을 선택할 수 있다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const YuiRailPassPage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('유이레일 1일권'), findsOneWidget);
    expect(find.text('24시간'), findsOneWidget);
    expect(find.text('48시간'), findsOneWidget);
  });
}
