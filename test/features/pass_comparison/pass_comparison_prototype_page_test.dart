import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/pass_transit_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/domain/pass_comparison.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/pass_comparison_prototype_page.dart';

void main() {
  testWidgets('shows compact journey inputs and supports adding a segment', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PassComparisonPrototypePage(
          initialData: PassTransitData.fromJsonString(_fixture),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('이동 계획을 입력해 주세요'), findsOneWidget);
    expect(find.text('24시간'), findsOneWidget);
    expect(find.text('48시간'), findsOneWidget);
    expect(find.text('72시간'), findsOneWidget);
    expect(find.text('변경'), findsNothing);
    expect(find.text('첫 이용 예정'), findsNothing);
    expect(find.text('출발'), findsOneWidget);
    expect(find.text('도착'), findsOneWidget);
    expect(find.text('역 선택'), findsNWidgets(2));
    expect(
      tester.getSize(find.byKey(const ValueKey('station-picker-출발역'))).height,
      closeTo(60, 2),
    );
    for (final widget in tester.widgetList<Text>(find.text('역 선택'))) {
      expect(widget.style?.color, AppColors.skyDark);
      expect(widget.style?.fontWeight, FontWeight.w700);
    }
    expect(find.byTooltip('출발역과 도착역 바꾸기'), findsOneWidget);
    expect(find.text('적용 구분'), findsNothing);
    expect(find.text('성인 IC 기준 운임'), findsNothing);
    expect(find.text('출발 예정'), findsNothing);
    expect(find.byKey(const ValueKey('journey-plan-card')), findsOneWidget);
    final planner = tester.widget<ListView>(
      find.byKey(const ValueKey('pass-comparison-planner-scroll')),
    );
    expect(
      planner.keyboardDismissBehavior,
      ScrollViewKeyboardDismissBehavior.onDrag,
    );
    expect(find.byType(RawAutocomplete<PassStation>), findsNothing);

    await tester.ensureVisible(find.text('이동 구간 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이동 구간 추가'));
    await tester.pump();

    expect(find.text('2'), findsOneWidget);
    expect(find.byKey(const ValueKey('journey-plan-card')), findsOneWidget);

    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.tap(find.text('비교 결과 보기'));
    await tester.pumpAndSettle();

    expect(find.text('비교 결과'), findsOneWidget);
    expect(find.text('아직 비교할 이동이 없어요'), findsOneWidget);
  });

  testWidgets('changes the Tokyo Subway Ticket duration in the planner', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PassComparisonPrototypePage(
          initialData: PassTransitData.fromJsonString(_fixture),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('48시간'));
    await tester.pumpAndSettle();

    expect(find.text('¥1500'), findsNWidgets(2));
    expect(find.text('1일차'), findsOneWidget);
    expect(find.text('2일차'), findsOneWidget);
    expect(find.text('3일차'), findsNothing);
  });

  testWidgets('searches and selects a Tokunai station on a dedicated page', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PassComparisonPrototypePage(
          initialProduct: PassProduct.tokunai1Day,
          initialData: PassTransitData.fromJsonString(_tokunaiFixture),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('사용일'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('station-picker-출발역')));
    await tester.pumpAndSettle();

    expect(find.text('출발역 선택'), findsOneWidget);
    expect(find.text('역 이름을 검색해 주세요'), findsOneWidget);
    expect(find.text('찾고 싶은 역을 입력해 주세요'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('station-search-field')),
      'ㅅㅂㅇ',
    );
    await tester.pump();

    expect(find.text('시부야'), findsOneWidget);
    await tester.tap(find.text('시부야'));
    await tester.pumpAndSettle();

    expect(find.text('시부야'), findsOneWidget);
    expect(find.text('이동 계획을 입력해 주세요'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('station-picker-도착역')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('station-search-field')),
      '도쿄',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(ListTile, '도쿄'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('station-picker-출발역')),
        matching: find.text('시부야'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('station-picker-도착역')),
        matching: find.text('도쿄'),
      ),
      findsOneWidget,
    );
    expect(find.text('JR 동일본'), findsNWidgets(2));

    await tester.tap(find.byTooltip('출발역과 도착역 바꾸기'));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('station-picker-출발역')),
        matching: find.text('도쿄'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('station-picker-도착역')),
        matching: find.text('시부야'),
      ),
      findsOneWidget,
    );
  });
}

const _fixture = '''
{
  "generatedAt": "2026-08-12T00:00:00.000Z",
  "source": "ODPT test fixture",
  "stations": [],
  "fares": []
}
''';

const _tokunaiFixture = '''
{
  "generatedAt": "2026-08-23T00:00:00.000Z",
  "source": "Tokunai test fixture",
  "stations": [
    {
      "id": "jr-tokunai:shibuya",
      "nameKo": "시부야",
      "nameJa": "渋谷",
      "nameEn": "Shibuya",
      "odptIds": ["jr-tokunai:Shibuya"],
      "operators": ["odpt.Operator:JR-East"],
      "railways": ["도쿠나이 패스 적용 JR"],
      "aliases": [],
      "tokunaiPassEligible": true
    },
    {
      "id": "jr-tokunai:tokyo",
      "nameKo": "도쿄",
      "nameJa": "東京",
      "nameEn": "Tokyo",
      "odptIds": ["jr-tokunai:Tokyo"],
      "operators": ["odpt.Operator:JR-East"],
      "railways": ["도쿠나이 패스 적용 JR"],
      "aliases": [],
      "tokunaiPassEligible": true
    }
  ],
  "fares": []
}
''';
