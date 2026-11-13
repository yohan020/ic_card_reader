import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_diagnostics.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_reader.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/card_diagnostics_page.dart';

void main() {
  if (!cardDiagnosticsEnabled) {
    testWidgets('diagnostic route is inert without opt-in', (tester) async {
      final reader = _Reader();
      await tester.pumpWidget(
        MaterialApp(home: CardDiagnosticsPage(reader: reader)),
      );
      expect(find.text('개발용 진단이 활성화되지 않았어요.'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      expect(reader.scans, 0);
    });
    return;
  }
  for (final dark in [false, true]) {
    testWidgets('scan without any manual brand after consent ($dark)', (
      tester,
    ) async {
      final logs = <String>[];
      final saved = debugPrint;
      debugPrint = (String? value, {int? wrapWidth}) {
        if (value != null) logs.add(value);
      };
      addTearDown(() => debugPrint = saved);
      final reader = _Reader();
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: CardDiagnosticsPage(reader: reader),
        ),
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(reader.scans, 1);
      reader.pending.complete(_report());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('자동 판별 후보: TOICA'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('자동 판별 후보: TOICA'), findsOneWidget);
      expect(find.textContaining('실제 브랜드 (직접 선택):'), findsNothing);
      expect(logs.single, contains('"manual_brand":null'));
      expect(logs.single, contains('"brand":"toica"'));
      expect(tester.takeException(), isNull);
      debugPrint = saved;
    });

    testWidgets('manual brand and consent precede diagnostic logging ($dark)', (
      tester,
    ) async {
      final logs = <String>[];
      final saved = debugPrint;
      debugPrint = (String? value, {int? wrapWidth}) {
        if (value != null) logs.add(value);
      };
      addTearDown(() => debugPrint = saved);
      final reader = _Reader();
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: CardDiagnosticsPage(reader: reader),
        ),
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.tap(find.text('실제 브랜드 입력 (선택 사항)'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'toica');
      await tester.pump();
      await tester.tap(find.text('TOICA'));
      await tester.pumpAndSettle();
      expect(reader.scans, 0);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(reader.scans, 1);
      reader.pending.complete(_report());
      await tester.pumpAndSettle();
      expect(logs.single, contains('"manual_brand":"TOICA"'));
      expect(logs.single, contains('"schema":3'));
      await tester.ensureVisible(find.text('자동 판별 후보: TOICA'));
      expect(find.text('실제 브랜드 (직접 선택): TOICA'), findsOneWidget);
      expect(find.text('자동 판별 후보: TOICA'), findsOneWidget);
      expect(tester.takeException(), isNull);
      debugPrint = saved;
    });
  }

  testWidgets('leaving during scan cancels and never logs a late report', (
    tester,
  ) async {
    final logs = <String>[];
    final saved = debugPrint;
    debugPrint = (String? value, {int? wrapWidth}) {
      if (value != null) logs.add(value);
    };
    addTearDown(() => debugPrint = saved);
    final reader = _Reader();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => CardDiagnosticsPage(reader: reader),
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
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.pageBack();
    reader.pending.complete(_report());
    await tester.pumpAndSettle();
    expect(reader.cancels, greaterThan(0));
    expect(logs, isEmpty);
    expect(tester.takeException(), isNull);
    debugPrint = saved;
  });

  testWidgets(
    'unknown on failed probe and manual label never supplies result',
    (tester) async {
      final reader = _Reader();
      await tester.pumpWidget(
        MaterialApp(home: CardDiagnosticsPage(reader: reader)),
      );
      await tester.tap(find.text('실제 브랜드 입력 (선택 사항)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suica'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton));
      reader.pending.complete(
        CardDiagnosticReport(
          initialSystemCode: '0003',
          pmm: null,
          systemCodes: [],
          systemCodeStatus: 'unavailable',
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('자동 판별 후보: 확인 불가'));
      expect(find.text('실제 브랜드 (직접 선택): Suica'), findsOneWidget);
      expect(find.text('자동 판별 후보: 확인 불가'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'small dark screen and large text keep separate candidate visible',
    (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final reader = _Reader();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.5)),
            child: child!,
          ),
          home: CardDiagnosticsPage(reader: reader),
        ),
      );
      await tester.tap(find.text('실제 브랜드 입력 (선택 사항)'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'toica');
      await tester.pump();
      await tester.ensureVisible(find.text('TOICA'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('TOICA'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      // Deliberate mismatch with manual TOICA: no label-fed identification.
      reader.pending.complete(_report([0x1A48, 0x1A88, 0x9608]));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('자동 판별 후보: ICOCA'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('실제 브랜드 (직접 선택): TOICA'), findsOneWidget);
      expect(find.text('자동 판별 후보: ICOCA'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('TOICA'),
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('TOICA'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'pasmo');
      await tester.pump();
      await tester.tap(find.text('PASMO'));
      await tester.pumpAndSettle();
      expect(find.text('자동 판별 후보: ICOCA'), findsNothing);
      await tester.scrollUntilVisible(
        find.byType(CheckboxListTile),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

CardDiagnosticReport _report([
  List<int> services = const [0x1E08, 0x1E48, 0x1E8B],
]) => CardDiagnosticReport(
  initialSystemCode: '0003',
  pmm: '0101000000000000',
  systemCodes: ['0003'],
  systemCodeStatus: 'ok',
  serviceProbe: CardServiceProbeReport(
    status: 'ok',
    presence: {
      for (final code in diagnosticServiceCodes) code: services.contains(code),
    },
  ),
);

class _Reader implements CardReader, DiagnosticCardReader {
  int scans = 0;
  int cancels = 0;
  final pending = Completer<CardDiagnosticReport>();
  @override
  Future<CardDiagnosticReport> scanDiagnostics() {
    scans++;
    return pending.future;
  }

  @override
  Future<void> cancel() async {
    cancels++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
