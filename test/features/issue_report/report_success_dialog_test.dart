import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/issue_report/presentation/report_success_dialog.dart';

void main() {
  for (final dark in [false, true]) {
    for (final scale in [1.0, 1.7]) {
      testWidgets(
        'shared receipt dialog keeps design and can close; dark=$dark scale=$scale',
        (tester) async {
          tester.view.physicalSize = const Size(360, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Builder(
                builder: (context) => Scaffold(
                  body: FilledButton(
                    onPressed: () => showReportSuccessDialog(
                      context,
                      reportId: '12345678-1234-4234-8234-123456789012',
                    ),
                    child: const Text('완료 모달 열기'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('완료 모달 열기'));
          await tester.pumpAndSettle();
          expect(find.text('제보가 접수되었습니다'), findsOneWidget);
          expect(find.text('카드 IDm과 다른 이용내역은 전송되지 않았습니다.'), findsOneWidget);
          expect(find.byIcon(Icons.check_rounded), findsOneWidget);
          final dialog = tester.widget<Dialog>(
            find.byKey(const ValueKey('report-success-dialog')),
          );
          expect(
            dialog.insetPadding,
            const EdgeInsets.symmetric(horizontal: 24),
          );
          expect(
            (dialog.shape as RoundedRectangleBorder).borderRadius,
            BorderRadius.circular(28),
          );
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(find.text('확인'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('확인'));
          await tester.pumpAndSettle();
          expect(find.byType(ReportSuccessDialog), findsNothing);
          expect(find.text('완료 모달 열기'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
