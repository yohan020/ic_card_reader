import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/raw_history_block.dart';
import 'package:ic_card_reader/src/features/transaction_history/data/transit_history_parser.dart';
import 'package:ic_card_reader/src/features/transaction_history/domain/amount_calculation.dart';
import 'package:ic_card_reader/src/features/transaction_history/domain/transit_transaction_type.dart';

void main() {
  const parser = TransitHistoryParser();

  test('extracts confirmed fields and classifies verified rail codes', () {
    final records = parser.parse([
      _block(0, '1601000234E4A578AC38E20300012950'),
      _block(1, '050D000F34E30D2A0000B60700012740'),
    ]);

    final current = records.first;
    expect(current.usageDate, DateTime(2026, 7, 4));
    expect(current.terminalCode, 0x16);
    expect(current.processCode, 0x01);
    expect(current.regionCode, 0x50);
    expect(current.boardingLineCode, 0xA5);
    expect(current.boardingStationCode, 0x78);
    expect(current.alightingLineCode, 0xAC);
    expect(current.alightingStationCode, 0x38);
    expect(current.balance, 994);
    expect(current.transactionType, TransitTransactionType.rail);
    expect(records.last.transactionType, TransitTransactionType.bus);
    expect(
      current.amountCalculation.status,
      AmountCalculationStatus.calculated,
    );
    expect(current.amountCalculation.amount, 980);

    expect(
      records.last.amountCalculation.status,
      AmountCalculationStatus.unavailable,
    );
    expect(
      records.last.amountCalculation.unavailableReason,
      AmountUnavailableReason.noOlderRecord,
    );
  });

  test('classifies the verified charge and reports its balance increase', () {
    final records = parser.parse([
      _block(0, 'C849000034E378CAC0CE880800012600'),
      _block(1, '050D000F34E30D2A0000B80000012540'),
    ]);

    expect(records.first.balance, 2184);
    expect(records[1].balance, 184);
    expect(records.first.transactionType, TransitTransactionType.charge);
    expect(
      records.first.amountCalculation.status,
      AmountCalculationStatus.balanceIncrease,
    );
    expect(records.first.amountCalculation.amount, 2000);
  });

  test('keeps unverified refund or adjustment-like records unknown', () {
    final records = parser.parse([
      _block(0, 'AA55000034E378CAC0CE880800012600'),
      _block(1, '050D000F34E30D2A0000B60700012740'),
    ]);

    expect(records.first.transactionType, TransitTransactionType.unknown);
    expect(
      records.first.amountCalculation.status,
      AmountCalculationStatus.unavailable,
    );
  });

  test('uses an initialization balance for calculation and then hides it', () {
    final records = parser.parse([
      _block(0, '1601000234E4A578AC38E20300012950'),
      _block(1, '0807000034E300000000DC0400010000'),
      _block(2, '0000FFFF34E300000000000000010000'),
    ]);

    expect(records, hasLength(1));
    expect(records.single.rawBlock.index, 0);
    expect(records.single.transactionType, TransitTransactionType.rail);
    expect(
      records.single.amountCalculation.status,
      AmountCalculationStatus.calculated,
    );
    expect(records.single.amountCalculation.amount, 250);
  });

  test('keeps an initialization-only card balance available for display', () {
    final blocks = [
      _block(0, '0807000034E300000000F40100010000'),
      _block(1, '0000FFFF34E300000000000000010000'),
    ];

    expect(parser.parse(blocks), isEmpty);
    expect(parser.currentBalance(blocks), 500);
  });

  test('classifies C7 46 as a verified purchase', () {
    final records = parser.parse([
      _block(0, 'C746000034DD7C0F60DEC40300012100'),
      _block(1, '050D000F34DD0D2A0000F20200012240'),
    ]);

    expect(records.first.transactionType, TransitTransactionType.purchase);
  });

  final fixtureFile = File('test/fixtures/felica/android_history_20_v1.json');
  test(
    'parses all locally captured physical-card blocks',
    () {
      final fixture =
          jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
      final hexBlocks = (fixture['blocks'] as List<dynamic>).cast<String>();
      final records = parser.parse([
        for (var index = 0; index < hexBlocks.length; index++)
          _block(index, hexBlocks[index]),
      ]);

      expect(records, hasLength(20));
      expect(records.every((record) => record.usageDate != null), isTrue);
      expect(
        records
            .where(
              (record) => record.transactionType == TransitTransactionType.rail,
            )
            .length,
        7,
      );
      expect(
        records
            .where(
              (record) => record.transactionType == TransitTransactionType.bus,
            )
            .length,
        4,
      );
      expect(
        records
            .where(
              (record) =>
                  record.transactionType == TransitTransactionType.purchase,
            )
            .length,
        8,
      );
      expect(
        records
            .where(
              (record) =>
                  record.transactionType == TransitTransactionType.charge,
            )
            .length,
        1,
      );
      expect(records.first.amountCalculation.amount, 980);
      expect(
        records[2].amountCalculation.status,
        AmountCalculationStatus.balanceIncrease,
      );
      expect(records[2].amountCalculation.amount, 2000);
      expect(records[16].amountCalculation.amount, 250);
      expect(records[16].boardingStationCode, 0xA4);
      expect(records[16].alightingStationCode, 0xAC);
      expect(
        records.last.amountCalculation.status,
        AmountCalculationStatus.unavailable,
      );
      expect(
        records.last.amountCalculation.unavailableReason,
        AmountUnavailableReason.noOlderRecord,
      );
    },
    skip: fixtureFile.existsSync() ? false : 'Local private fixture not found',
  );
}

RawHistoryBlock _block(int index, String hexadecimal) {
  return RawHistoryBlock(
    index: index,
    bytes: Uint8List.fromList([
      for (var offset = 0; offset < hexadecimal.length; offset += 2)
        int.parse(hexadecimal.substring(offset, offset + 2), radix: 16),
    ]),
  );
}
