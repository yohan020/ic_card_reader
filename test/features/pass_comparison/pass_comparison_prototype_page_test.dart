import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/pass_transit_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/pass_comparison_prototype_page.dart';

void main() {
  testWidgets('shows ODPT station fields and supports adding a segment', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
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

    expect(find.text('교통패스 비교 실험실'), findsOneWidget);
    expect(find.text('ODPT 실제 역·운임 데이터'), findsOneWidget);
    expect(find.text('출발역'), findsOneWidget);
    expect(find.text('ODPT 성인 IC 운임'), findsOneWidget);

    await tester.ensureVisible(find.text('이동 구간 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이동 구간 추가'));
    await tester.pump();

    expect(find.text('2'), findsOneWidget);
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
