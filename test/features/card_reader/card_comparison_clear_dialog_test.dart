import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/card_comparison_clear_dialog.dart';

void main() {
  for (final dark in [false, true]) {
    for (final compact in [false, true]) {
      testWidgets('compact icon clear dialog dark=$dark compact=$compact', (
        tester,
      ) async {
        tester.view.physicalSize = compact
            ? const Size(320, 400)
            : const Size(430, 950);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final results = <bool?>[];
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(compact ? 1.7 : 1)),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    results.add(
                      await showDialog<bool>(
                        context: context,
                        builder: (_) => const CardComparisonClearDialog(),
                      ),
                    );
                  },
                  child: const Text('열기'),
                ),
              ),
            ),
          ),
        );
        Future<void> open() async {
          await tester.tap(find.text('열기'));
          await tester.pumpAndSettle();
        }

        await open();
        expect(find.text('비교 목록을 비울까요?'), findsOneWidget);
        expect(find.text('추가한 카드와 이용내역을\n비교 목록에서 삭제합니다.'), findsOneWidget);
        expect(find.text('실제 카드 잔액은 바뀌지 않아요.'), findsOneWidget);
        expect(find.byIcon(Icons.filter_none_rounded), findsOneWidget);
        expect(find.byType(FilledButton), findsOneWidget);
        expect(find.byType(Divider), findsNothing);
        expect(find.byType(VerticalDivider), findsNothing);
        expect(
          tester.getSize(find.byKey(const ValueKey('comparison-clear-icon'))),
          const Size(52, 52),
        );
        final contentSize = tester.getSize(
          find.byKey(const ValueKey('comparison-clear-content')),
        );
        expect(contentSize.width, lessThanOrEqualTo(300));
        if (!compact) {
          expect(contentSize.width, 300);
          expect(contentSize.height, lessThan(300));
          final titleRect = tester.getRect(find.text('비교 목록을 비울까요?'));
          final iconRect = tester.getRect(
            find.byKey(const ValueKey('comparison-clear-icon')),
          );
          final bodyRect = tester.getRect(
            find.text('추가한 카드와 이용내역을\n비교 목록에서 삭제합니다.'),
          );
          expect(titleRect.top - iconRect.bottom, closeTo(12, .1));
          expect(bodyRect.top - titleRect.bottom, closeTo(10, .1));
        }
        for (final text in [
          '비교 목록을 비울까요?',
          '추가한 카드와 이용내역을\n비교 목록에서 삭제합니다.',
          '실제 카드 잔액은 바뀌지 않아요.',
        ]) {
          expect(
            tester.widget<Text>(find.text(text)).textAlign,
            TextAlign.center,
          );
        }
        final dialog = tester.widget<Dialog>(find.byType(Dialog));
        expect(
          dialog.backgroundColor,
          (dark ? AppTheme.dark : AppTheme.light).cardTheme.color,
        );
        expect(
          tester.widget<Text>(find.text('비교 목록을 비울까요?')).style!.fontWeight,
          FontWeight.w700,
        );
        final cancel = find.byKey(const ValueKey('comparison-clear-cancel'));
        final confirm = find.byKey(const ValueKey('comparison-clear-confirm'));
        await tester.ensureVisible(confirm);
        await tester.pumpAndSettle();
        expect(
          tester.getSize(cancel).width,
          closeTo(tester.getSize(confirm).width, .1),
        );
        expect(tester.getSize(confirm).height, greaterThanOrEqualTo(48));
        final deleteStyle = tester.widget<FilledButton>(confirm).style!;
        expect(
          deleteStyle.backgroundColor!.resolve({}),
          const Color(0xFFB94C58),
        );
        expect(deleteStyle.foregroundColor!.resolve({}), Colors.white);
        expect(tester.getTopLeft(cancel).dy, tester.getTopLeft(confirm).dy);
        expect(tester.takeException(), isNull);
        await tester.tap(cancel);
        await tester.pumpAndSettle();
        expect(results, [false]);

        await open();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(results, [false, null]);

        await open();
        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();
        expect(results, [false, null, null]);

        await open();
        await tester.ensureVisible(confirm);
        await tester.pumpAndSettle();
        await tester.tap(confirm);
        await tester.pumpAndSettle();
        expect(results, [false, null, null, true]);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
