import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/osaka_pass_station_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/pass_transit_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/osaka_amazing_pass_prototype_page.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/prototype_pass_selection_page.dart';

void main() {
  testWidgets('Web 프로토타입 선택 화면에 오사카 주유패스를 표시한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PrototypePassSelectionPage(
          initialTransitData: PassTransitData.fromJsonString(_selectionFixture),
        ),
      ),
    );

    expect(find.text('Tokyo Subway Ticket'), findsOneWidget);
    expect(find.text('도쿠나이 패스'), findsOneWidget);
    expect(find.text('오사카 주유패스'), findsOneWidget);
    expect(find.text('1일권 ¥3,500 · 2일권 ¥5,000 · 환승 자동 계산'), findsOneWidget);
  });

  testWidgets('오사카 계획 화면은 좁은 모바일 폭에서 1·2일권을 전환한다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = OsakaPassStationData.fromJson(
      File(
        'assets/data/pass_comparison/osaka_amazing_pass_fares_2026.json',
      ).readAsStringSync(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: OsakaAmazingPassPrototypePage(initialData: data),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('osaka-journey-plan-card')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('osaka-duration-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('osaka-duration-2')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('osaka-duration-2')));
    await tester.pumpAndSettle();
    expect(find.text('1일차'), findsWidgets);
    expect(find.text('2일차'), findsWidgets);
    expect(find.text('두 역을 선택하면 운임을 자동으로 확인합니다.'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('두 역을 선택하면 운임을 자동으로 확인합니다.')).dy <
          tester.getTopLeft(find.text('1일차').first).dy,
      isTrue,
    );
    expect(find.text('편도 성인 일반 운임'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('오사카 철도역을 선택하면 일반 운임을 자동 표시한다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = OsakaPassStationData.fromJson(
      File(
        'assets/data/pass_comparison/osaka_amazing_pass_fares_2026.json',
      ).readAsStringSync(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: OsakaAmazingPassPrototypePage(initialData: data),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('역 선택').first);
    await tester.pumpAndSettle();
    expect(find.text('출발역 선택'), findsOneWidget);
    expect(find.text('역 이름을 검색해 주세요'), findsOneWidget);
    expect(find.text('찾고 싶은 역을 입력해 주세요'), findsOneWidget);
    expect(find.text('지원 철도 6개 사업자 전체'), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('osaka-station-search-field')),
      '우메다',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, '우메다').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('역 선택').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('osaka-station-search-field')),
      '난바',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, '난바').first);
    await tester.pumpAndSettle();

    expect(find.text('오사카 메트로'), findsNWidgets(2));
    expect(find.text('성인 일반 운임 · ¥240'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('서로 다른 사업자의 역을 선택하면 환승 운임을 자동 표시한다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = OsakaPassStationData.fromJson(
      File(
        'assets/data/pass_comparison/osaka_amazing_pass_fares_2026.json',
      ).readAsStringSync(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: OsakaAmazingPassPrototypePage(initialData: data),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('역 선택').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('osaka-station-search-field')),
      '우메다',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, '우메다').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('역 선택').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('osaka-station-search-field')),
      '사카이',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, '사카이').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('환승 1회'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('비교 결과 보기'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('비교 결과 보기'));
    await tester.pumpAndSettle();
    expect(find.text('비교 결과'), findsWidgets);
    expect(find.textContaining('오사카 메트로'), findsWidgets);
    expect(find.textContaining('난카이 전철'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

const _selectionFixture = '''
{
  "generatedAt": "2026-08-24T00:00:00.000Z",
  "source": "test fixture",
  "stations": [],
  "fares": []
}
''';
