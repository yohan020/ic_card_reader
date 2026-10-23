import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/raw_history_block.dart';
import 'package:ic_card_reader/src/features/transaction_history/domain/amount_calculation.dart';
import 'package:ic_card_reader/src/features/transaction_history/domain/history_total.dart';
import 'package:ic_card_reader/src/features/transaction_history/domain/parsed_transit_history.dart';
import 'package:ic_card_reader/src/features/transaction_history/domain/transit_transaction_type.dart';
import 'package:ic_card_reader/src/features/transaction_history/presentation/history_pages.dart';

void main() {
  test('spending includes only calculated rail, bus and purchases', () {
    final records = [
      for (final (index, type) in TransitTransactionType.values.indexed)
        _record(index, type, const AmountCalculation.calculated(100)),
    ];
    final total = HistoryTotal.calculate(
      records,
      kind: HistoryTotalKind.spending,
    );
    expect(total.amount, 300);
    expect(total.includedCount, 3);
    expect(total.excludedCount, 5);
  });

  test(
    'unavailable, suspicious, increases and nonpositive amounts are excluded',
    () {
      final records = [
        for (final (index, amount) in [
          const AmountCalculation.unavailable(),
          const AmountCalculation.suspicious(),
          const AmountCalculation.balanceIncrease(500),
          const AmountCalculation.calculated(0),
          const AmountCalculation.calculated(-10),
        ].indexed)
          _record(index, TransitTransactionType.rail, amount),
      ];
      final total = HistoryTotal.calculate(
        records,
        kind: HistoryTotalKind.spending,
      );
      expect(total.amount, isNull);
      expect(total.includedCount, 0);
      expect(total.excludedCount, 5);
    },
  );

  test('charges require a classified charge and verified balance increase', () {
    final total = HistoryTotal.calculate([
      _record(
        0,
        TransitTransactionType.charge,
        const AmountCalculation.balanceIncrease(1000),
      ),
      _record(
        1,
        TransitTransactionType.charge,
        const AmountCalculation.balanceIncrease(2000),
      ),
      _record(
        2,
        TransitTransactionType.charge,
        const AmountCalculation.calculated(500),
      ),
      _record(
        3,
        TransitTransactionType.purchase,
        const AmountCalculation.balanceIncrease(500),
      ),
      _record(
        4,
        TransitTransactionType.charge,
        const AmountCalculation.suspicious(),
      ),
      _record(
        5,
        TransitTransactionType.charge,
        const AmountCalculation.balanceIncrease(-10),
      ),
    ], kind: HistoryTotalKind.charge);
    expect(total.amount, 3000);
    expect(total.includedCount, 2);
    expect(total.excludedCount, 4);
  });

  test(
    'unknown records never become spending even with a calculated amount',
    () {
      final total = HistoryTotal.calculate([
        _record(
          0,
          TransitTransactionType.unknown,
          const AmountCalculation.calculated(250),
        ),
      ], kind: HistoryTotalKind.unidentified);
      expect(total.amount, isNull);
      expect(total.recordCount, 1);
      expect(total.includedCount, 0);
    },
  );

  test('empty input is absent rather than a fabricated zero', () {
    for (final kind in HistoryTotalKind.values) {
      final total = HistoryTotal.calculate(const [], kind: kind);
      expect(total.amount, isNull);
      expect(total.recordCount, 0);
      expect(total.excludedCount, 0);
    }
  });

  test(
    'filtering adds precomputed amounts, not remaining balance differences',
    () {
      final records = _records();
      final all = HistoryTotal.calculate(
        records,
        kind: HistoryTotalKind.spending,
      );
      final transport = HistoryTotal.calculate(
        records.where(
          (record) =>
              record.transactionType == TransitTransactionType.rail ||
              record.transactionType == TransitTransactionType.bus,
        ),
        kind: HistoryTotalKind.spending,
      );
      // All fixture balances are identical; valid precomputed amounts still count.
      expect(all.amount, 510);
      expect(transport.amount, 330);
      expect(records.first.amountCalculation.amount, 220);
    },
  );

  for (final dark in [false, true]) {
    testWidgets(
      'filters update totals without changing records (${dark ? 'dark' : 'light'})',
      (tester) async {
        final records = _records();
        await _pump(tester, records, dark: dark);
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('history-filter-total')),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('지출 합계'), findsOneWidget);
        _expectAmount(tester, '¥510');
        final titleRect = tester.getRect(find.text('지출 합계'));
        final amountRect = tester.getRect(
          find.byKey(const ValueKey('history-filter-total-amount')),
        );
        expect(titleRect.right, lessThan(amountRect.left));
        expect(titleRect.center.dy, closeTo(amountRect.center.dy, 0.1));
        expect(find.text('합산 3건 · 합계 제외 4건'), findsNothing);
        expect(
          find.byKey(const ValueKey('history-filter-total-details')),
          findsNothing,
        );
        final collapsedHeight = tester
            .getSize(find.byKey(const ValueKey('history-filter-total')))
            .height;
        await _toggleTotal(tester);
        expect(find.text('합산 3건 · 합계 제외 4건'), findsOneWidget);
        _expectAmount(tester, '¥510');
        expect(
          tester
              .getSize(find.byKey(const ValueKey('history-filter-total')))
              .height,
          greaterThan(collapsedHeight),
        );
        await _toggleTotal(tester);
        expect(find.text('합산 3건 · 합계 제외 4건'), findsNothing);
        expect(
          tester
              .getSize(find.byKey(const ValueKey('history-filter-total')))
              .height,
          collapsedHeight,
        );
        await _toggleTotal(tester);
        for (final (filter, title, amount, counts) in [
          ('교통', '지출 합계', '¥330', '합산 2건 · 합계 제외 2건'),
          ('결제', '지출 합계', '¥180', '합산 1건 · 합계 제외 0건'),
          ('충전', '충전 합계', '¥1000', '합산 1건 · 합계 제외 0건'),
        ]) {
          await _filter(tester, filter);
          expect(find.text(title), findsOneWidget);
          _expectAmount(tester, amount);
          expect(find.text(counts), findsNothing);
          await _toggleTotal(tester);
          expect(find.text(counts), findsOneWidget);
        }
        await _filter(tester, '미확인');
        expect(find.text('미확인 1건'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('history-filter-total-details')),
          findsNothing,
        );
        await _toggleTotal(tester);
        expect(
          find.byKey(const ValueKey('history-filter-total-details')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('history-filter-total-amount')),
          findsNothing,
        );
        await _filter(tester, '전체');
        _expectAmount(tester, '¥510');
        expect(
          find.byKey(const ValueKey('history-filter-total-details')),
          findsNothing,
        );
        expect(find.byType(Checkbox), findsNothing);
        expect(records.first.amountCalculation.amount, 220);
      },
    );

    testWidgets('summary wraps at large text (${dark ? 'dark' : 'light'})', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pump(tester, _records(), dark: dark, scale: 1.5);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('history-filter-total')),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      _expectAmount(tester, '¥510');
      await _toggleTotal(tester);
      expect(
        find.byKey(const ValueKey('history-filter-total-details')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'horizontal total keeps long amounts visible on a narrow large-text screen',
    (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pump(tester, [
        for (var index = 0; index < 20; index++)
          _record(
            index,
            TransitTransactionType.rail,
            const AmountCalculation.calculated(9999),
          ),
      ], scale: 2);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('history-filter-total')),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      _expectAmount(tester, '¥199980');
      final amount = tester.widget<Text>(
        find.byKey(const ValueKey('history-filter-total-amount')),
      );
      expect(amount.maxLines, isNull);
      expect(amount.overflow, isNot(TextOverflow.ellipsis));
      await _toggleTotal(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'no card, empty filters and all excluded records never show a zero total',
    (tester) async {
      await _pump(tester, const []);
      expect(find.byKey(const ValueKey('history-filter-total')), findsNothing);
      await _pump(tester, [
        _record(
          0,
          TransitTransactionType.rail,
          const AmountCalculation.unavailable(),
        ),
      ]);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('history-filter-total')),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('합산 가능한 지출 기록이 없어요'), findsOneWidget);
      expect(find.text('합산 0건 · 합계 제외 1건'), findsNothing);
      await _toggleTotal(tester);
      expect(find.text('합산 0건 · 합계 제외 1건'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('history-filter-total-amount')),
        findsNothing,
      );
      await _filter(tester, '충전');
      expect(find.byKey(const ValueKey('history-filter-total')), findsNothing);
      expect(find.text('해당 조건의 이용내역이 없습니다.'), findsOneWidget);
    },
  );

  testWidgets(
    'new scan records and session clear refresh the current filter total',
    (tester) async {
      await _pump(tester, _records());
      await _filter(tester, '교통');
      _expectAmount(tester, '¥330');
      await _pump(tester, [
        _record(
          0,
          TransitTransactionType.bus,
          const AmountCalculation.calculated(90),
        ),
      ]);
      _expectAmount(tester, '¥90');
      await _pump(tester, const []);
      expect(find.byKey(const ValueKey('history-filter-total')), findsNothing);
    },
  );
}

Future<void> _toggleTotal(WidgetTester tester) async {
  final toggle = find.byKey(const ValueKey('history-filter-total-toggle'));
  await tester.ensureVisible(toggle);
  await tester.pumpAndSettle();
  await tester.tap(toggle);
  await tester.pumpAndSettle();
}

void _expectAmount(WidgetTester tester, String text) {
  expect(
    tester
        .widget<Text>(find.byKey(const ValueKey('history-filter-total-amount')))
        .data,
    text,
  );
  final toggle = tester.getRect(
    find.byKey(const ValueKey('history-filter-total-toggle')),
  );
  final chevron = tester.getRect(
    find.byKey(const ValueKey('history-filter-total-chevron')),
  );
  final amount = tester.getRect(
    find.byKey(const ValueKey('history-filter-total-amount')),
  );
  expect(chevron.right, closeTo(toggle.right - 16, 0.1));
  expect(amount.right, closeTo(chevron.left - 8, 0.1));
}

Future<void> _filter(WidgetTester tester, String label) async {
  final chip = find.widgetWithText(FilterChip, label);
  await tester.scrollUntilVisible(
    chip,
    -150,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(chip);
  await tester.pump();
  await tester.tap(chip);
  await tester.pump();
}

Future<void> _pump(
  WidgetTester tester,
  List<ParsedTransitHistory> records, {
  bool dark = false,
  double scale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? AppTheme.dark : AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: HistoryListPage(
          histories: records,
          currentBalance: records.isEmpty ? null : 1000,
          stationPairs: const {},
          onScan: () {},
        ),
      ),
    ),
  );
  await tester.pump();
}

List<ParsedTransitHistory> _records() => [
  _record(
    0,
    TransitTransactionType.rail,
    const AmountCalculation.calculated(220),
  ),
  _record(
    1,
    TransitTransactionType.bus,
    const AmountCalculation.calculated(110),
  ),
  _record(
    2,
    TransitTransactionType.purchase,
    const AmountCalculation.calculated(180),
  ),
  _record(
    3,
    TransitTransactionType.charge,
    const AmountCalculation.balanceIncrease(1000),
  ),
  _record(
    4,
    TransitTransactionType.rail,
    const AmountCalculation.unavailable(),
  ),
  _record(
    5,
    TransitTransactionType.gateWindowProcessing,
    const AmountCalculation.calculated(40),
  ),
  _record(
    6,
    TransitTransactionType.unknown,
    const AmountCalculation.calculated(50),
  ),
];

ParsedTransitHistory _record(
  int index,
  TransitTransactionType type,
  AmountCalculation amount,
) => ParsedTransitHistory(
  rawBlock: RawHistoryBlock(index: index, bytes: Uint8List(16)),
  usageDate: DateTime(2026, 10, 21),
  terminalCode: 0x16,
  processCode: 0x01,
  regionCode: 0,
  boardingLineCode: 1,
  boardingStationCode: 1,
  alightingLineCode: 1,
  alightingStationCode: 2,
  balance: 1000,
  transactionType: type,
  amountCalculation: amount,
);
