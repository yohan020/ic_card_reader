import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/pass_transit_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/pass_selection_page.dart';

void main() {
  testWidgets('opens the Kanto pass list and the Tokunai page', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PassSelectionPage(
          initialTransitData: PassTransitData.fromJsonString(_fixture),
        ),
      ),
    );

    expect(find.text('도쿄·간토'), findsOneWidget);
    expect(find.text('간사이'), findsOneWidget);
    expect(find.text('홋카이도'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('홋카이도')).dy <
          tester.getTopLeft(find.text('도쿄·간토')).dy,
      true,
    );
    expect(
      tester.getTopLeft(find.text('도쿄·간토')).dy <
          tester.getTopLeft(find.text('간사이')).dy,
      true,
    );
    expect(
      tester.getTopLeft(find.text('간사이')).dy <
          tester.getTopLeft(find.text('규슈')).dy,
      true,
    );

    await tester.tap(find.text('도쿄·간토'));
    await tester.pumpAndSettle();

    expect(find.text('Tokyo Subway Ticket'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('도쿠나이 패스'), 280);
    expect(find.text('도쿠나이 패스'), findsOneWidget);
    expect(find.text('오사카 주유패스'), findsNothing);
    expect(find.text('후쿠오카 지하철 1일권'), findsNothing);

    await tester.tap(find.text('도쿠나이 패스'));
    await tester.pumpAndSettle();

    expect(find.text('이동 계획을 입력해 주세요'), findsOneWidget);
  });

  testWidgets('opens the Osaka Amazing Pass page from the Android selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PassSelectionPage(
          initialTransitData: PassTransitData.fromJsonString(_fixture),
        ),
      ),
    );

    await tester.tap(find.text('간사이'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('오사카 주유패스'));
    await tester.tap(find.text('오사카 주유패스'));
    await tester.pumpAndSettle();

    expect(find.text('교통패스 비교'), findsOneWidget);
    expect(find.text('이동 계획을 입력해 주세요'), findsOneWidget);
    expect(find.text('이동 구간'), findsWidgets);
    expect(find.text('1일권'), findsOneWidget);
    expect(find.text('2일권'), findsOneWidget);
  });

  testWidgets('shows unimplemented regions as unavailable', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PassSelectionPage(
          initialTransitData: PassTransitData.fromJsonString(_fixture),
        ),
      ),
    );

    await tester.scrollUntilVisible(find.text('도호쿠'), 280);
    expect(find.text('준비 중'), findsWidgets);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('홋카이도'));
    await tester.pumpAndSettle();

    expect(find.text('홋카이도의\n교통패스를 선택해 주세요'), findsOneWidget);
    expect(find.text('홋카이도 레일패스'), findsOneWidget);
  });

  testWidgets('opens the Hiroden pass from the Chugoku list', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: PassSelectionPage(
          region: PassRegion.chugoku,
          initialTransitData: PassTransitData.fromJsonString(_fixture),
        ),
      ),
    );

    expect(find.text('히로덴 전차 패스'), findsOneWidget);
    await tester.tap(find.text('히로덴 전차 패스'));
    await tester.pumpAndSettle();

    expect(find.text('이동 계획을 입력해 주세요'), findsOneWidget);
    expect(find.text('히로덴 전차 1일권'), findsOneWidget);
    expect(find.text('1일권'), findsOneWidget);
    expect(find.text('8시간권'), findsOneWidget);
    expect(find.text('24시간권'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

const _fixture = '''
{
  "generatedAt": "2026-08-24T00:00:00.000Z",
  "source": "test fixture",
  "stations": [],
  "fares": []
}
''';
