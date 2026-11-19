import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/hiroden_pass_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/domain/hiroden_pass.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/hiroden_pass_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('77개 정류장을 로드하고 역명 표기만으로 검색한다', () async {
    final data = HirodenPassData.fromCsv(
      File(
        'assets/data/pass_comparison/hiroden_stations_2026.csv',
      ).readAsStringSync(),
    );

    expect(data.stations, hasLength(77));
    expect(data.search('히로시마').first.nameJa, '広島駅');
    expect(data.search('ㅇㅍㄷㅇ').single.nameJa, '原爆ドーム前');
    expect(data.search('宮島口').single.nameKo, '히로덴미야지마구치');
    expect(data.search('Hiroden-miyajima').single.nameJa, '広電宮島口');
    expect(data.search('히로시마 전철'), isEmpty);

    final hiroshima = data.search('히로시마').first;
    final miyajima = data.search('미야지마구치').single;
    expect(data.fareBetween(hiroshima, miyajima), 240);
    expect(data.fareBetween(hiroshima, hiroshima), isNull);
  });

  test('선택한 1일·8시간·24시간권 가격으로 손익을 계산한다', () async {
    final data = await const HirodenPassDataRepository().load();
    final hiroshima = data.search('히로시마').first;
    final miyajima = data.search('미야지마구치').single;
    final fare = data.fareBetween(hiroshima, miyajima)!;
    final segments = [
      for (var index = 0; index < 3; index++)
        HirodenPlannedSegment(from: hiroshima, to: miyajima, fare: fare),
    ];

    final paper = HirodenPassEvaluator.evaluate(segments);
    expect(paper.passType, HirodenPassType.paperOneDay);
    expect(paper.regularFareTotal, 720);
    expect(paper.savings, 20);
    expect(paper.verdict, HirodenPassVerdict.beneficial);

    final eightHours = HirodenPassEvaluator.evaluate(
      segments,
      passType: HirodenPassType.digitalEightHours,
    );
    expect(eightHours.savings, 120);

    final twentyFourHours = HirodenPassEvaluator.evaluate(
      segments,
      passType: HirodenPassType.digitalTwentyFourHours,
    );
    expect(twentyFourHours.savings, 20);
  });

  testWidgets('다크 모드 좁은 화면에서 공용 패스 UI를 표시한다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final data = HirodenPassData.fromCsv(
      File(
        'assets/data/pass_comparison/hiroden_stations_2026.csv',
      ).readAsStringSync(),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: HirodenPassPage(initialData: data),
      ),
    );
    await tester.pump();
    expect(find.text('역 선택'), findsNWidgets(2));
    expect(find.text('1일권'), findsOneWidget);
    expect(find.text('8시간권'), findsOneWidget);
    expect(find.text('24시간권'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
