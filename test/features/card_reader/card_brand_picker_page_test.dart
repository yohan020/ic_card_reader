import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/card_brand_picker_page.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('search and select ICa in ${dark ? "dark" : "light"} theme', (
      tester,
    ) async {
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => selected = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CardBrandPickerPage(),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '아이카');
      await tester.pump();
      expect(find.text('ICa (가나자와)'), findsOneWidget);
      expect(find.text('Suica'), findsNothing);
      await tester.tap(find.text('ICa (가나자와)'));
      await tester.pumpAndSettle();
      expect(selected, 'ICa (가나자와)');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'manual entry remains reachable with no search results, validates and returns label',
    (tester) async {
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => selected = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CardBrandPickerPage(),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '목록에없는카드');
      await tester.pump();
      await tester.tap(find.text('직접 입력'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('선택'));
      await tester.pump();
      expect(find.text('브랜드 이름을 입력해 주세요.'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, '새로운 지역 카드');
      await tester.tap(find.text('선택'));
      await tester.pumpAndSettle();
      expect(selected, '새로운 지역 카드');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('narrow screen and large text keep direct input visible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: const CardBrandPickerPage(),
      ),
    );
    expect(find.text('직접 입력'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
