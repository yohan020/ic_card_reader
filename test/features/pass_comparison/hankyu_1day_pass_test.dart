import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/hankyu_1day_pass_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/domain/hankyu_1day_pass.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/hankyu_1day_pass_page.dart';
import 'package:flutter/material.dart';

void main() {
  const fixture =
      '''{"pass_price_yen":1300,"stations":[{"id":"A","ja":"大阪梅田","ko":"오사카우메다"},{"id":"B","ja":"西院","ko":"사이인"},{"id":"C","ja":"京都河原町","ko":"가와라마치"}],"fares":[["A","B",330],["B","A",330],["A","C",410],["C","A",410],["B","C",170],["C","B",170]]}''';

  final data = Hankyu1DayPassData.fromJson(fixture);

  test('일본어·한글·초성으로 한큐 역을 찾는다', () {
    expect(data.search('西院').single.displayName, '사이인');
    expect(data.search('가와').single.nameJa, '京都河原町');
    expect(data.search('ㄱㅇ').single.nameJa, '京都河原町');
    expect(data.search('한큐전철'), isEmpty);
  });

  test('일반 운임 합계와 한큐패스 1일권 손익을 계산한다', () {
    final from = data.search('오사카').single;
    final to = data.search('가와').single;
    final result = Hankyu1DayPassEvaluator.evaluate(
      data: data,
      segments: [
        HankyuPlannedSegment(
          from: from,
          to: to,
          fare: data.fareBetween(from, to)!,
        ),
        HankyuPlannedSegment(
          from: to,
          to: from,
          fare: data.fareBetween(to, from)!,
        ),
        HankyuPlannedSegment(
          from: from,
          to: to,
          fare: data.fareBetween(from, to)!,
        ),
        HankyuPlannedSegment(
          from: to,
          to: from,
          fare: data.fareBetween(to, from)!,
        ),
      ],
    );

    expect(result.regularFareTotal, 1640);
    expect(result.savings, 340);
    expect(result.verdict, HankyuPassVerdict.beneficial);
  });

  testWidgets('한큐패스 1일권 계획 화면이 앱 asset으로 열린다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Hankyu1DayPassPage()));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    expect(find.text('한큐패스 1일권'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('hankyu-journey-plan-card')),
      findsOneWidget,
    );
  });
}
