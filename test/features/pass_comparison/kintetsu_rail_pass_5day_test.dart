import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/kintetsu_rail_pass_5day_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/domain/kintetsu_rail_pass_5day.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/kintetsu_rail_pass_5day_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const repository = KintetsuRailPass5DayDataRepository();
  final stations = [
    const KintetsuStation(
      id: 'namba',
      nameJa: '大阪難波',
      nameEn: 'Osaka-Namba',
      nameKo: '오사카난바',
      operator: 'Kintetsu Railway',
      lines: 'kintetsu_namba',
    ),
    const KintetsuStation(
      id: 'nara',
      nameJa: '近鉄奈良',
      nameEn: 'Kintetsu-Nara',
      nameKo: '긴테쓰나라',
      operator: 'Kintetsu Railway',
      lines: 'nara',
    ),
  ];
  final data = KintetsuRailPass5DayData.forTest(
    stations: stations,
    passPrice: 4900,
    fares: const {'namba|nara': 680},
  );

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
    final result = KintetsuRailPass5DayEvaluator.evaluate(
      data: data,
      segments: [
        for (var index = 0; index < 5; index++)
          KintetsuPlannedSegment(from: stations[0], to: stations[1], fare: 680),
        KintetsuPlannedSegment(from: stations[1], to: stations[0], fare: 680),
        KintetsuPlannedSegment(from: stations[0], to: stations[1], fare: 680),
        KintetsuPlannedSegment(from: stations[1], to: stations[0], fare: 680),
      ],
    );
    expect(result.regularFareTotal, 5440);
    expect(result.savings, 540);
    expect(result.verdict, KintetsuPassVerdict.beneficial);
  });

  test('공식 권종의 성인 가격과 적용 역 경계를 실제 asset에서 확인한다', () async {
    final bundled = await repository.load();
    KintetsuStation station(String id) =>
        bundled.stations.singleWhere((s) => s.id == id);
    expect(KintetsuPassVariant.values.map((v) => v.price), [
      1900,
      3700,
      4900,
      6700,
    ]);
    expect(bundled.passPrice, KintetsuPassVariant.fiveDay.price);
    for (final id in [
      'osaka_namba',
      'kintetsu_nara',
      'kyoto',
      'kujo_nara',
      'tsutsui',
      'nagata',
      'ikoma',
      'toriimae',
      'ikoma_sanjo',
    ]) {
      expect(
        KintetsuPassVariant.oneDay.covers(station(id)),
        isTrue,
        reason: id,
      );
    }
    for (final id in ['hirahata', 'sambommatsu', 'yoshino']) {
      expect(
        KintetsuPassVariant.oneDay.covers(station(id)),
        isFalse,
        reason: id,
      );
      expect(
        KintetsuPassVariant.twoDay.covers(station(id)),
        isTrue,
        reason: id,
      );
    }
    for (final id in ['akameguchi', 'nabari', 'iga_ueno', 'kintetsu_nagoya']) {
      expect(
        KintetsuPassVariant.twoDay.covers(station(id)),
        isFalse,
        reason: id,
      );
      expect(
        KintetsuPassVariant.fiveDay.covers(station(id)),
        isTrue,
        reason: id,
      );
      expect(
        KintetsuPassVariant.fiveDayPlus.covers(station(id)),
        isTrue,
        reason: id,
      );
    }
    expect(
      bundled.stations.where(KintetsuPassVariant.oneDay.covers),
      hasLength(61),
    );
    expect(
      bundled.stations.where(KintetsuPassVariant.twoDay.covers),
      hasLength(185),
    );
  });

  test('범위 밖 철도 운임 제외, 지정 버스만 반영, 데이터 없으면 결론을 내리지 않는다', () {
    const outside = KintetsuStation(
      id: 'nabari',
      nameJa: '名張',
      nameEn: 'Nabari',
      nameKo: '나바리',
      operator: 'Kintetsu Railway',
      lines: 'osaka',
    );
    final local = KintetsuPlannedSegment(
      from: stations.first,
      to: stations.last,
      fare: 680,
    );
    final remote = KintetsuPlannedSegment(
      from: stations.first,
      to: outside,
      fare: 1420,
    );
    final short = KintetsuRailPass5DayEvaluator.evaluate(
      data: data,
      variant: KintetsuPassVariant.oneDay,
      segments: [local, remote],
      confirmedBusFare: 1220,
    );
    expect(short.outsideCoverage, [remote]);
    expect(short.railFareTotal, 680);
    expect(short.regularFareTotal, 1900);
    expect(short.verdict, KintetsuPassVerdict.breakEven);
    final excludedOnly = KintetsuRailPass5DayEvaluator.evaluate(
      data: data,
      variant: KintetsuPassVariant.twoDay,
      segments: [remote],
    );
    expect(excludedOnly.verdict, KintetsuPassVerdict.insufficientData);
    final standard = KintetsuRailPass5DayEvaluator.evaluate(
      data: data,
      segments: [local, remote],
      confirmedBusFare: 5000,
    );
    final plus = KintetsuRailPass5DayEvaluator.evaluate(
      data: data,
      variant: KintetsuPassVariant.fiveDayPlus,
      segments: [local, remote],
      confirmedBusFare: 5000,
    );
    expect(standard.regularFareTotal, 2100);
    expect(standard.busFareTotal, 0);
    expect(plus.verdict, KintetsuPassVerdict.beneficial);
    expect(plus.savings, 400);
  });

  testWidgets('좁은 다크 화면과 글자 확대에서 권종 전환 및 버스만 비교', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.5)),
          child: child!,
        ),
        home: KintetsuRailPass5DayPage(initialData: data),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1일권'), findsOneWidget);
    expect(find.text('2일권'), findsOneWidget);
    expect(find.text('5일권'), findsOneWidget);
    final plus = find.text('5일권 Plus');
    await tester.ensureVisible(plus);
    await tester.tap(plus);
    await tester.pumpAndSettle();
    final scroll = find.byType(Scrollable).first;
    final busFare = find.byType(TextField);
    await tester.scrollUntilVisible(busFare, 160, scrollable: scroll);
    await tester.enterText(busFare, '6800');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    final compare = find.text('비교 결과 보기');
    await tester.scrollUntilVisible(compare, 100, scrollable: scroll);
    await tester.ensureVisible(compare);
    await tester.tap(compare);
    await tester.pumpAndSettle();
    expect(find.text('패스가 더 이득이에요'), findsOneWidget);
    expect(find.text('5일권 Plus 가격'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
