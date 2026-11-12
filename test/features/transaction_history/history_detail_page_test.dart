import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/core/widgets/app_ui.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/raw_history_block.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_resolution.dart';
import 'package:ic_card_reader/src/features/transaction_history/data/transit_history_parser.dart';
import 'package:ic_card_reader/src/features/transaction_history/domain/amount_calculation.dart';
import 'package:ic_card_reader/src/features/transaction_history/domain/parsed_transit_history.dart';
import 'package:ic_card_reader/src/features/transaction_history/domain/transit_transaction_type.dart';
import 'package:ic_card_reader/src/features/transaction_history/presentation/history_pages.dart';
import 'package:ic_card_reader/src/features/transaction_history/presentation/widgets/history_station_map.dart';

void main() {
  testWidgets('station map follows details and precedes report, rail only', (
    tester,
  ) async {
    for (final sample in [
      _history(),
      const TransitHistoryParser().parse([
        _rawBlock('050F000F342E0A0100003000000412C0'),
      ]).single,
    ]) {
      await tester.pumpWidget(
        MaterialApp(home: HistoryDetailPage(history: sample)),
      );
      final children = tester.widget<AppPage>(find.byType(AppPage)).children;
      final mapIndex = children.indexWhere(
        (child) => child is HistoryStationMap,
      );
      if (sample.transactionType == TransitTransactionType.rail) {
        final detailIndex = children.indexWhere(
          (child) => child is SectionLabel && child.text == '상세 정보',
        );
        final reportIndex = children.lastIndexWhere(
          (child) => child is OutlinedButton,
        );
        expect(mapIndex, greaterThan(detailIndex));
        expect(mapIndex, lessThan(reportIndex));
      } else {
        expect(mapIndex, -1);
      }
    }
  });

  for (final dark in [false, true]) {
    testWidgets(
      'unavailable amount is lighter in list and detail (${dark ? 'dark' : 'light'})',
      (tester) async {
        final history = _history(
          amountCalculation: const AmountCalculation.unavailable(),
        );
        final theme = dark ? AppTheme.dark : AppTheme.light;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: HistoryListPage(
                histories: [history],
                currentBalance: history.balance,
                stationPairs: const {},
                onScan: () {},
              ),
            ),
          ),
        );
        await tester.scrollUntilVisible(
          find.text('계산 불가'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        final listAmount = tester.widget<Text>(find.text('계산 불가'));
        expect(listAmount.style?.fontSize, 14);
        expect(listAmount.style?.fontWeight, FontWeight.w500);
        final type = tester.widget<Text>(find.text('철도 이용'));
        expect(type.style?.fontSize, 15);
        expect(type.style?.fontWeight, FontWeight.w600);
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: HistoryDetailPage(history: history),
          ),
        );
        final detailAmount = tester.widget<Text>(find.text('계산 불가'));
        expect(detailAmount.style?.fontSize, 18);
        expect(detailAmount.style?.fontWeight, FontWeight.w500);
        expect(detailAmount.style?.color, theme.colorScheme.onSurfaceVariant);
      },
    );
  }

  testWidgets('compact history cards remain readable at large text', (
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
          ).copyWith(textScaler: TextScaler.linear(1.5)),
          child: child!,
        ),
        home: Scaffold(
          body: HistoryListPage(
            histories: [_history()],
            currentBalance: 994,
            stationPairs: const {},
            onScan: () {},
          ),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('철도 이용'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('잔액 ¥994'), findsOneWidget);
    _expectRightAlignedBalance(tester);
    final padding = find.ancestor(
      of: find.text('철도 이용'),
      matching: find.byType(Padding),
    );
    expect(
      tester
          .widgetList<Padding>(padding)
          .any(
            (widget) =>
                widget.padding ==
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'history balance and chevron stay at the lower right at normal text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: HistoryListPage(
              histories: [_history()],
              currentBalance: 994,
              stationPairs: const {},
              onScan: () {},
            ),
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('철도 이용'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      _expectRightAlignedBalance(tester);
    },
  );

  testWidgets('keeps the detail page above the system navigation area', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: HistoryDetailPage(history: _history())),
    );

    final detailSafeArea = find.ancestor(
      of: find.byType(AppPage),
      matching: find.byType(SafeArea),
    );
    final safeArea = tester.widget<SafeArea>(detailSafeArea);
    expect(safeArea.top, isFalse);
    expect(safeArea.bottom, isTrue);
    expect(safeArea.child, isA<AppPage>());
  });

  testWidgets('shows gate-window processing without a false rail route', (
    tester,
  ) async {
    final history = const TransitHistoryParser().parse([
      _rawBlock('1A06000E3502010701077C0100005200'),
    ]).single;
    final location = _location(
      region: 0,
      line: 0x01,
      station: 0x07,
      stationName: '品川',
      lineName: '東海道線',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HistoryDetailPage(
          history: history,
          transactionLocation: location,
        ),
      ),
    );

    expect(find.text('개찰 창구 처리'), findsWidgets);
    expect(find.text('品川 · 東海道線'), findsOneWidget);
    expect(find.text('승차'), findsNothing);
    expect(find.text('하차'), findsNothing);
  });

  testWidgets('shows mobile benefit and cash-combined purchase labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HistoryDetailPage(
          history: const TransitHistoryParser().parse([
            _rawBlock('1B481E00342E9B810000020100041100'),
          ]).single,
        ),
      ),
    );
    expect(find.text('모바일 특전'), findsOneWidget);
    expect(find.text('확인할 수 없음'), findsWidgets);

    await tester.pumpWidget(
      MaterialApp(
        home: HistoryDetailPage(
          history: const TransitHistoryParser().parse([
            _rawBlock('C8C60000342E5541A9F5480000040E00'),
          ]).single,
        ),
      ),
    );
    expect(find.text('현금 병용'), findsOneWidget);
    expect(find.text('10:42:02'), findsOneWidget);
  });

  testWidgets('shows verified bus operators only when parsed', (tester) async {
    for (final fixture in const [
      ('050F000F342E0A0100003000000412C0', '西日本鉄道'),
      ('050D000F34E20D2A00001A0400000440', '名古屋市交通局 市バス'),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: HistoryDetailPage(
            history: const TransitHistoryParser().parse([
              _rawBlock(fixture.$1),
            ]).single,
          ),
        ),
      );
      expect(find.text(fixture.$2), findsOneWidget);
    }
  });
}

void _expectRightAlignedBalance(WidgetTester tester) {
  final amount = tester.getRect(find.text('-¥980'));
  final balance = tester.getRect(find.text('잔액 ¥994'));
  final arrow = tester.getRect(find.byIcon(Icons.chevron_right_rounded));
  expect(arrow.right, closeTo(amount.right, .1));
  expect(balance.right, closeTo(arrow.left - 4, .1));
  expect(balance.top, greaterThan(amount.top));
  expect(tester.widget<Text>(find.text('잔액 ¥994')).textAlign, TextAlign.end);
}

RawHistoryBlock _rawBlock(String hexadecimal) => RawHistoryBlock(
  index: 0,
  bytes: Uint8List.fromList([
    for (var offset = 0; offset < hexadecimal.length; offset += 2)
      int.parse(hexadecimal.substring(offset, offset + 2), radix: 16),
  ]),
);

StationResolution _location({
  required int region,
  required int line,
  required int station,
  required String stationName,
  required String lineName,
}) {
  final code = StationCode(
    regionCode: region,
    lineCode: line,
    stationCode: station,
  );
  return StationResolution(
    requestedCode: code,
    strategy: StationMatchStrategy.exactRegion,
    station: StationRecord(
      code: code,
      operatorName: '',
      lineName: lineName,
      stationName: stationName,
      source: 'test',
    ),
  );
}

ParsedTransitHistory _history({
  AmountCalculation amountCalculation = const AmountCalculation.calculated(980),
}) => ParsedTransitHistory(
  rawBlock: RawHistoryBlock(index: 0, bytes: Uint8List(16)),
  usageDate: DateTime(2026, 7, 4),
  terminalCode: 0x16,
  processCode: 0x01,
  regionCode: 0x50,
  boardingLineCode: 0xA5,
  boardingStationCode: 0x78,
  alightingLineCode: 0xAC,
  alightingStationCode: 0x38,
  balance: 994,
  transactionType: TransitTransactionType.rail,
  amountCalculation: amountCalculation,
);
