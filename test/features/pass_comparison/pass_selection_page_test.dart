import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/pass_transit_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/pass_selection_page.dart';

void main() {
  testWidgets('starts with a pass choice and opens the Tokunai page', (
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

    expect(find.text('Tokyo Subway Ticket'), findsOneWidget);
    expect(find.text('도쿠나이 패스'), findsOneWidget);
    expect(find.text('오사카 주유패스'), findsOneWidget);

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

    await tester.ensureVisible(find.text('오사카 주유패스'));
    await tester.tap(find.text('오사카 주유패스'));
    await tester.pumpAndSettle();

    expect(find.text('교통패스 비교'), findsOneWidget);
    expect(find.text('이동 계획을 입력해 주세요'), findsOneWidget);
    expect(find.text('이동 구간'), findsWidgets);
    expect(find.text('1일권'), findsOneWidget);
    expect(find.text('2일권'), findsOneWidget);
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
