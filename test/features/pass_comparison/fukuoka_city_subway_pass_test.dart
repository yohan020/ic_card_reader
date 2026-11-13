import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/fukuoka_city_subway_pass_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/domain/fukuoka_city_subway_pass.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/fukuoka_city_subway_pass_page.dart';

void main() {
  final data = FukuokaCitySubwayPassData.fromCsv(
    stationsCsv: '''station_id,name_ja,name_en,operator,station_codes
K08,天神,Tenjin,福岡市交通局,K08
K09,中洲川端,Nakasu-Kawabata,福岡市交通局,K09|H01
K11,博多,Hakata,福岡市交通局,K11|N18
N16,天神南,Tenjin-minami,福岡市交通局,N16
''',
    faresCsv:
        '''origin_id,origin_name_ja,destination_id,destination_name_ja,distance_km,fare_zone,adult_fare_yen,calculation_path,rule
K08,天神,K09,中洲川端,0.8,1,210,K08>K09,distance_band
K09,中洲川端,K08,天神,0.8,1,210,K09>K08,distance_band
K08,天神,K11,博多,2.2,1,210,K08>K09>K11,distance_band
K11,博多,K08,天神,2.2,1,210,K11>K09>K08,distance_band
''',
  );

  test('공통 환승역은 하나의 물리 역으로 검색하고, 성인 운임을 찾는다', () {
    expect(data.stations, hasLength(4));
    expect(data.search('나카스').single.nameJa, '中洲川端');
    expect(data.search('ㄴㅋㅅ').single.nameJa, '中洲川端');
    expect(data.search('후쿠오카시'), isEmpty);
    expect(
      data.fareBetween(data.search('텐진').first, data.search('하카타').single),
      210,
    );
  });

  test('성인 일반 운임 합계가 1일권 가격을 넘으면 이득으로 판정한다', () {
    final tenjin = data.search('텐진').first;
    final hakata = data.search('하카타').single;
    final result = FukuokaCitySubwayPassEvaluator.evaluate([
      for (var index = 0; index < 4; index++)
        FukuokaCitySubwayPlannedSegment(from: tenjin, to: hakata, fare: 210),
    ]);
    expect(result.regularFareTotal, 840);
    expect(result.savings, 200);
    expect(result.verdict, FukuokaCitySubwayPassVerdict.beneficial);
  });

  testWidgets('요약 카드에 개별 노선 라벨을 표시하지 않는다', (tester) async {
    // Complete real asset I/O outside the widget test's simulated clock.
    // The page then consumes the same shared repository Future as production.
    final loaded = await tester.runAsync(
      () => const FukuokaCitySubwayPassDataRepository().load(),
    );
    expect(loaded, isNotNull);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const FukuokaCitySubwayPassPage(),
        ),
      );
      // Allow the page's await on the real-zone cached Future to complete.
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();

    expect(find.text('후쿠오카 지하철 1일권'), findsOneWidget);
    expect(find.text('공항선'), findsNothing);
    expect(find.text('하코자키선'), findsNothing);
    expect(find.text('나나쿠마선'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
