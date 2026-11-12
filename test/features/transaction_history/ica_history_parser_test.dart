import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/raw_history_block.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_scan_result.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_comparison_session.dart';
import 'package:ic_card_reader/src/features/transaction_history/data/ica_history_parser.dart';
import 'package:ic_card_reader/src/features/transaction_history/data/transit_history_parser.dart';
import 'package:ic_card_reader/src/features/transaction_history/domain/amount_calculation.dart';
import 'package:ic_card_reader/src/features/transaction_history/domain/history_total.dart';
import 'package:ic_card_reader/src/features/transaction_history/domain/transit_transaction_type.dart';

import '../../support/ica_fixture.dart';

void main() {
  const parser = TransitHistoryParser();
  test('ICa dispatch reads date 0/1 and big-endian balance 13/14', () {
    final block = icaFixture();
    block.bytes[4] = 0xFF;
    block.bytes[5] = 0xFF;
    block.bytes[10] = 0x99;
    final record = parser.parse([block]).single;
    expect(record.usageDate, DateTime(2026, 10, 24));
    expect(record.balance, 1234);
    expect(parser.currentBalance([block]), 1234);
    expect(record.amountCalculation.amount, 230);
    expect(record.amountCalculation.status, AmountCalculationStatus.calculated);
    expect(record.sequenceNumber, isNull);
  });
  test('ICa signed delta works without inventing a rail/bus/charge type', () {
    for (final delta in [-20480, -230, -10, 10, 2000, 20470]) {
      final record = parser.parse([icaFixture(delta: delta)]).single;
      expect(record.amountCalculation.amount, delta.abs());
      expect(
        record.amountCalculation.status,
        delta < 0
            ? AmountCalculationStatus.calculated
            : AmountCalculationStatus.balanceIncrease,
      );
      expect(record.transactionType, TransitTransactionType.unknown);
      expect(record.terminalCode, 0);
      expect(record.processCode, 0);
      expect(record.boardingLineCode, 0);
      expect(record.alightingLineCode, 0);
      expect(record.hasTransactionLocationCode, isFalse);
      expect(record.transactionDateTime, isNull);
    }
  });
  test('zero delta is not a made-up payment or charge', () {
    final record = parser.parse([icaFixture(delta: 0)]).single;
    expect(
      record.amountCalculation.status,
      AmountCalculationStatus.unavailable,
    );
    expect(record.transactionType, TransitTransactionType.unknown);
  });
  test('ICa kind byte and signed amount must agree for bus and charge', () {
    for (final kind in [0x53, 0x5D, 0x59, 0x79]) {
      for (final delta in [-240, -230, 0, 1500]) {
        final record = parser.parse([
          icaFixture(kind: kind, delta: delta),
        ]).single;
        final expected = (kind == 0x53 || kind == 0x5D) && delta < 0
            ? TransitTransactionType.bus
            : (kind == 0x59 || kind == 0x79) && delta > 0
            ? TransitTransactionType.charge
            : TransitTransactionType.unknown;
        expect(record.transactionType, expected);
        expect(
          record.amountCalculation.amount,
          delta == 0 ? null : delta.abs(),
        );
        expect(record.terminalCode, 0);
        expect(record.processCode, 0);
        expect(record.busOperatorName, isNull);
        expect(record.hasTransactionLocationCode, isFalse);
        expect(record.boardingLineCode, 0);
        expect(record.alightingLineCode, 0);
      }
    }
    // No partial nibble/fare/position-based classification or refund guesses.
    for (final kind in [0x00, 0x03, 0x09, 0x13, 0x19, 0x73, 0x7D, 0xFF]) {
      for (final delta in [-230, 1500]) {
        expect(
          parser
              .parse([icaFixture(kind: kind, delta: delta)])
              .single
              .transactionType,
          TransitTransactionType.unknown,
        );
      }
    }
  });
  test(
    'recognized ICa rides and charges use existing totals without discounts',
    () {
      final records = parser.parse([
        icaFixture(index: 0, delta: 1500, kind: 0x79),
        icaFixture(index: 1, delta: -240, kind: 0x53),
        icaFixture(index: 2, delta: -240, kind: 0x5D),
        icaFixture(index: 3, delta: -230, kind: 0x53),
        icaFixture(index: 4, delta: -230, kind: 0x5D),
        icaFixture(index: 5, delta: -230),
        icaFixture(index: 6, delta: 1500),
      ]);
      final spending = HistoryTotal.calculate(
        records,
        kind: HistoryTotalKind.spending,
      );
      final charges = HistoryTotal.calculate(
        records,
        kind: HistoryTotalKind.charge,
      );
      expect(spending.amount, 940);
      expect(spending.includedCount, 4);
      expect(charges.amount, 1500);
      expect(charges.includedCount, 1);
    },
  );
  test(
    'ICa does not recompute direct amounts from adjacent balance records',
    () {
      final records = parser.parse([
        icaFixture(balance: 1200, delta: -230),
        icaFixture(index: 1, balance: 9999, delta: 2000, day: 23),
      ]);
      expect(records.first.amountCalculation.amount, 230);
      expect(records.last.amountCalculation.amount, 2000);
      for (final kind in [HistoryTotalKind.spending, HistoryTotalKind.charge]) {
        expect(HistoryTotal.calculate(records, kind: kind).amount, isNull);
      }
    },
  );
  test(
    'invalid dates and all-zero/all-FF tails never yield a false balance',
    () {
      final invalid = icaFixture(month: 2, day: 30);
      for (final block in [
        invalid,
        RawHistoryBlock(
          index: 0,
          bytes: Uint8List(16),
          format: HistoryRecordFormat.ica,
        ),
        RawHistoryBlock(
          index: 0,
          bytes: Uint8List.fromList(List.filled(16, 255)),
          format: HistoryRecordFormat.ica,
        ),
      ]) {
        expect(parser.currentBalance([block]), isNull);
        expect(parser.parse([block]), isEmpty);
        expect(parser.parse([icaFixture(), block]).length, 1);
      }
      expect(IcaHistoryParser.recordDate([]), isNull);
      expect(
        IcaHistoryParser.recordDate(
          icaFixture(year: 2024, month: 2, day: 29).bytes,
        ),
        DateTime(2024, 2, 29),
      );
    },
  );
  test('mixed formats do not bleed into either parser', () {
    final ica = icaFixture();
    final common = RawHistoryBlock(
      index: 0,
      bytes: Uint8List.fromList([
        0x16,
        1,
        0,
        0,
        0x35,
        0x58,
        1,
        2,
        3,
        4,
        0xE8,
        3,
        0,
        0,
        0,
        0,
      ]),
    );
    expect(parser.currentBalance([common]), 1000);
    expect(parser.parse([common, ica]).length, 1);
    expect(parser.parse([ica, common]).length, 1);
  });
  test('comparison snapshots retain ICa format, not raw identity', () {
    final session = CardComparisonSession();
    addTearDown(session.dispose);
    final block = icaFixture();
    final card = session.accept(
      CardScanResult(
        scannedAt: DateTime(2026),
        blocks: [block],
        comparisonToken: 'synthetic-session-token',
      ),
    );
    expect(card.balance, 1234);
    expect(card.result.comparisonToken, isNull);
    expect(card.result.blocks.single.format, HistoryRecordFormat.ica);
    block.bytes[13] = 0;
    expect(parser.currentBalance(card.result.blocks), 1234);
    expect(
      parser.parse(card.result.blocks).single.amountCalculation.amount,
      230,
    );
  });
}
