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
      _block(1, '050D000F34E30D2A0000B60700012840'),
    ]);

    final current = records.first;
    expect(current.usageDate, DateTime(2026, 7, 4));
    expect(current.terminalCode, 0x16);
    expect(current.processCode, 0x01);
    expect(current.regionCode, 0x01);
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

  test('parses a verified transfer gate rail record', () {
    final record = parser.parse([
      _block(0, '1D01000232B9F109F104480A00002A00'),
    ]).single;

    expect(record.transactionType, TransitTransactionType.rail);
    expect(record.usageDate, DateTime(2025, 5, 25));
    expect(record.regionCode, 0x00);
    expect(record.boardingLineCode, 0xF1);
    expect(record.boardingStationCode, 0x09);
    expect(record.alightingLineCode, 0xF1);
    expect(record.alightingStationCode, 0x04);
    expect(record.balance, 2632);
  });

  test('parses the physical simple-gate rail record', () {
    final record = parser.parse([
      _block(0, '1701000234DE44244428EC0400000300'),
    ]).single;

    expect(record.transactionType, TransitTransactionType.rail);
    expect(record.usageDate, DateTime(2026, 6, 30));
    expect(record.regionCode, 0x00);
    expect(record.boardingLineCode, 0x44);
    expect(record.boardingStationCode, 0x24);
    expect(record.alightingLineCode, 0x44);
    expect(record.alightingStationCode, 0x28);
    expect(record.balance, 1260);
  });

  test('classifies the physical CA 46 record as a purchase', () {
    final record = parser.parse([
      _block(0, 'CA46000034E35DA49B0AE60000000900'),
    ]).single;

    expect(record.transactionType, TransitTransactionType.purchase);
    expect(record.usageDate, DateTime(2026, 7, 3));
    expect(record.balance, 230);
    expect(record.hasTransactionLocationCode, isFalse);
  });

  test('calculates the adjacent CA 46 purchase amount', () {
    final records = parser.parse([
      _block(0, 'CA46000034E35DA49B0AE60000000900'),
      _block(1, '1701000234DE44244428EC0400000800'),
    ]);

    expect(records.first.transactionType, TransitTransactionType.purchase);
    expect(
      records.first.amountCalculation.status,
      AmountCalculationStatus.calculated,
    );
    expect(records.first.amountCalculation.amount, 1030);
  });

  test('classifies process 46 independently of the terminal code', () {
    final record = parser.parse([
      _block(0, 'AB46000034E35DA49B0AE60000000900'),
    ]).single;

    expect(record.transactionType, TransitTransactionType.purchase);
  });

  test('does not include other purchase-related process codes in 46', () {
    for (final process in const [0x4A, 0x4B, 0xC6, 0xCB]) {
      final processHex = process.toRadixString(16).padLeft(2, '0');
      final record = parser.parse([
        _block(0, 'CA${processHex}000034E35DA49B0AE60000000900'),
      ]).single;
      expect(record.transactionType, TransitTransactionType.unknown);
    }
  });

  test('parses a ticket-machine charge and preserves its location code', () {
    final record = parser.parse([
      _block(0, '0802000030F6E91F0000A60400000FC0'),
    ]).single;

    expect(record.transactionType, TransitTransactionType.charge);
    expect(record.usageDate, DateTime(2024, 7, 22));
    expect(record.regionCode, 0x03);
    expect(record.balance, 1190);
    expect(record.transactionLocationRegionCode, 0x03);
    expect(record.transactionLocationLineCode, 0xE9);
    expect(record.transactionLocationStationCode, 0x1F);
    expect(
      record.amountCalculation.unavailableReason,
      AmountUnavailableReason.noOlderRecord,
    );
  });

  test('classifies a store-terminal charge without an older record', () {
    final record = parser.parse([
      _block(0, 'C849000034E378CAC0CE880800012600'),
    ]).single;

    expect(record.transactionType, TransitTransactionType.charge);
    expect(
      record.amountCalculation.unavailableReason,
      AmountUnavailableReason.noOlderRecord,
    );
    expect(record.hasTransactionLocationCode, isFalse);
  });

  test('does not turn a charge with a balance decrease into spending', () {
    final records = parser.parse([
      _block(0, 'C849000034E378CAC0CEB60700012600'),
      _block(1, '050D000F34E30D2A0000B80800012540'),
    ]);

    expect(records.first.transactionType, TransitTransactionType.charge);
    expect(
      records.first.amountCalculation.status,
      AmountCalculationStatus.suspicious,
    );
    expect(records.first.amountCalculation.amount, isNull);
  });

  test('supports documented conventional gate candidates with route codes', () {
    for (final terminal in const ['17', '1A']) {
      final record = parser.parse([
        _block(0, '${terminal}01000234E4A578AC38E20300012950'),
      ]).single;
      expect(record.transactionType, TransitTransactionType.rail);
    }
  });

  test('keeps incomplete conventional gate candidates unknown', () {
    for (final terminal in const ['17', '1A']) {
      final record = parser.parse([
        _block(0, '${terminal}01000234E40000AC38E20300012950'),
      ]).single;
      expect(record.transactionType, TransitTransactionType.unknown);
    }
  });

  test('keeps unverified Shinkansen gate records unknown', () {
    final record = parser.parse([
      _block(0, '2313000234E4A578AC38E20300012950'),
    ]).single;

    expect(record.transactionType, TransitTransactionType.unknown);
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

  group('third parser revision physical fixtures', () {
    test('classifies 1A 06 at Shinagawa as gate window processing', () {
      final record = parser.parse([
        _block(0, '1A06000E3502010701077C0100005200'),
      ]).single;

      expect(
        record.transactionType,
        TransitTransactionType.gateWindowProcessing,
      );
      expect(record.transactionType.wireName, 'GATE_WINDOW_PROCESSING');
      expect(record.usageDate, DateTime(2026, 8, 2));
      expect(record.regionCode, 0);
      expect(record.balance, 380);
      expect(record.transactionLocationLineCode, 0x01);
      expect(record.transactionLocationStationCode, 0x07);
    });

    test('classifies 1B 02 as a mobile charge without a station', () {
      for (final fixture in const [
        ('1B023F00350302FD00003F0200005700', 575, 8, 3),
        ('1B023F0034969B810000240200041300', 548, 4, 22),
      ]) {
        final record = parser.parse([_block(0, fixture.$1)]).single;
        expect(record.transactionType, TransitTransactionType.charge);
        expect(record.balance, fixture.$2);
        expect(record.usageDate, DateTime(2026, fixture.$3, fixture.$4));
        expect(record.hasTransactionLocationCode, isFalse);
      }
    });

    test('maps only the full Nishitetsu bus signature', () {
      final record = parser.parse([
        _block(0, '050F000F342E0A0100003000000412C0'),
      ]).single;

      expect(record.transactionType, TransitTransactionType.bus);
      expect(record.regionCode, 3);
      expect(record.balance, 48);
      expect(record.busOperatorName, '西日本鉄道');

      final differentRegion = parser.parse([
        _block(0, '050F000F342E0A010000300000041240'),
      ]).single;
      expect(differentRegion.busOperatorName, isNull);
    });

    test('classifies 1B 48 as a mobile benefit charge', () {
      final record = parser.parse([
        _block(0, '1B481E00342E9B810000020100041100'),
      ]).single;

      expect(record.transactionType, TransitTransactionType.charge);
      expect(record.usageDate, DateTime(2026, 1, 14));
      expect(record.balance, 258);
      expect(record.hasTransactionLocationCode, isFalse);
    });

    test('parses C8 C6 as a timed cash-combined purchase', () {
      final record = parser.parse([
        _block(0, 'C8C60000342E5541A9F5480000040E00'),
      ]).single;

      expect(record.transactionType, TransitTransactionType.purchase);
      expect(record.balance, 72);
      expect(record.transactionDateTime, DateTime(2026, 1, 14, 10, 42, 2));
      expect(record.hasTransactionLocationCode, isFalse);
    });

    test('classifies C6 only for the verified C8 terminal', () {
      final record = parser.parse([
        _block(0, 'CAC60000342E5541A9F5480000040E00'),
      ]).single;

      expect(record.transactionType, TransitTransactionType.unknown);
    });

    test('uses 1A 02 first code pair only as a charge location', () {
      final record = parser.parse([
        _block(0, '1A020000342CE91F00009F04000404C0'),
      ]).single;

      expect(record.transactionType, TransitTransactionType.charge);
      expect(record.regionCode, 3);
      expect(record.balance, 1183);
      expect(record.transactionLocationLineCode, 0xE9);
      expect(record.transactionLocationStationCode, 0x1F);
    });

    test('classifies Nishitetsu gate-window location without a route', () {
      final record = parser.parse([
        _block(0, '1A06000E342BD765D7658901000400F0'),
      ]).single;

      expect(
        record.transactionType,
        TransitTransactionType.gateWindowProcessing,
      );
      expect(record.regionCode, 3);
      expect(record.balance, 393);
      expect(record.transactionLocationLineCode, 0xD7);
      expect(record.transactionLocationStationCode, 0x65);
    });

    test('maps only the full Nagoya city bus signature', () {
      final record = parser.parse([
        _block(0, '050D000F34E20D2A00001A0400000440'),
      ]).single;

      expect(record.transactionType, TransitTransactionType.bus);
      expect(record.usageDate, DateTime(2026, 7, 2));
      expect(record.regionCode, 1);
      expect(record.balance, 1050);
      expect(record.busOperatorName, '名古屋市交通局 市バス');

      final differentIdentifier = parser.parse([
        _block(0, '050D000F34E20D2B00001A0400000440'),
      ]).single;
      expect(differentIdentifier.busOperatorName, isNull);
    });
  });

  group('fourth parser revision physical fixtures', () {
    test('classifies 21 02 as a conservative station-terminal charge', () {
      final record = parser.parse([
        _block(0, '21020000350DAC3800007B1700005E40'),
      ]).single;

      expect(TransitHistoryParser.version, 'phase2-parser-v6.1');
      expect(record.transactionType, TransitTransactionType.charge);
      expect(record.usageDate, DateTime(2026, 8, 13));
      expect(record.regionCode, 1);
      expect(record.balance, 6011);
      expect(record.rawBlock.bytes.sublist(12, 15), [0, 0, 94]);
      expect(record.hasTransactionLocationCode, isFalse);
      expect(
        record.amountCalculation.unavailableReason,
        AmountUnavailableReason.noOlderRecord,
      );
    });

    test('calculates 5000 yen only from an adjacent older balance', () {
      final records = parser.parse([
        _block(0, '21020000350DAC3800007B1700005E40'),
        _block(1, '16010002350CA578AC38F30300005D40'),
      ]);

      expect(records.first.transactionType, TransitTransactionType.charge);
      expect(
        records.first.amountCalculation.status,
        AmountCalculationStatus.balanceIncrease,
      );
      expect(records.first.amountCalculation.amount, 5000);
    });

    test('parses the two verified Iyotetsu Takahama line routes', () {
      final records = parser.parse([
        _block(0, '1601000234FEC51BC5275F0600005AF0'),
        _block(1, '1601000234FEC527C517A70400005CF0'),
      ]);

      expect(records, hasLength(2));
      expect(
        records.every(
          (record) => record.transactionType == TransitTransactionType.rail,
        ),
        isTrue,
      );
      expect(records.first.usageDate, DateTime(2026, 7, 30));
      expect(records.first.regionCode, 3);
      expect(records.first.boardingLineCode, 0xC5);
      expect(records.first.boardingStationCode, 0x1B);
      expect(records.first.alightingStationCode, 0x27);
      expect(records.first.balance, 1631);
      expect(records.last.boardingStationCode, 0x27);
      expect(records.last.alightingStationCode, 0x17);
      expect(records.last.balance, 1191);
    });
  });

  group('fourth parser revision follow-up fixture', () {
    test('maps only the full Iyotetsu bus-or-tram signature', () {
      final record = parser.parse([
        _block(0, '050D000F34FC0F3D00002F0700004FC0'),
      ]).single;

      expect(record.transactionType, TransitTransactionType.bus);
      expect(record.usageDate, DateTime(2026, 7, 28));
      expect(record.regionCode, 3);
      expect(record.balance, 1839);
      expect(record.rawBlock.bytes.sublist(12, 15), [0, 0, 79]);
      expect(record.busOperatorName, '伊予鉄道');
      expect(record.hasTransactionLocationCode, isFalse);
    });

    test('does not generalize the Iyotetsu signature', () {
      for (final raw in const [
        '050D000F34FC0F3D00002F0700004F40',
        '050F000F34FC0F3D00002F0700004FC0',
        '050D000F34FC0F3E00002F0700004FC0',
        '060D000F34FC0F3D00002F0700004FC0',
      ]) {
        final record = parser.parse([_block(0, raw)]).single;
        expect(record.busOperatorName, isNull, reason: raw);
      }
    });
  });

  group('fourth parser revision second follow-up fixture', () {
    test('parses the verified Iyotetsu Gunchu line route', () {
      final record = parser.parse([
        _block(0, '1601000234FCC501C517FF04000051F0'),
      ]).single;

      expect(TransitHistoryParser.version, 'phase2-parser-v6.1');
      expect(record.transactionType, TransitTransactionType.rail);
      expect(record.usageDate, DateTime(2026, 7, 28));
      expect(record.regionCode, 3);
      expect(record.boardingLineCode, 0xC5);
      expect(record.boardingStationCode, 0x01);
      expect(record.alightingLineCode, 0xC5);
      expect(record.alightingStationCode, 0x17);
      expect(record.balance, 1279);
      expect(record.sequenceNumber, 81);
    });

    test(
      'does not require transaction sequence numbers to increase by one',
      () {
        final records = parser.parse([
          _block(0, '1601000234FCC501C517FF04000051F0'),
          _block(1, '050D000F34FC0F3D00002F0700004FC0'),
        ]);

        expect(
          records.first.amountCalculation.status,
          AmountCalculationStatus.calculated,
        );
        expect(records.first.amountCalculation.amount, 560);
      },
    );
  });

  test('calculates adjacent balances for the 34-to-0F sequence fixture', () {
    const hexBlocks = <String>[
      '1601000232BAEF06AE076A0200003400',
      '1601000232B9F101F109C60700003200',
      '1601000232B9E35CE70CA20800003000',
      '1601000232B9250F2508540900002E00',
      '1601000532B9E376E370060A00002C00',
      '1D01000232B9F109F104480A00002A00',
      '1601000232B8EF03EF06240B00002800',
      '1601000532B8EF07EF03D60B00002600',
      '1601000232B8E430E42E420C00002400',
      '1601000232B83F083F02F40C00002200',
      '1601000232B82A163F08DA0D00002000',
      '1601000532B7F038F109C00E00001E00',
      '1601000232B7E33EE6290D0F00001C00',
      '1601000532B7E629E33DDE0F00001A00',
      '1601000232B7F109F0384A1000001800',
      '1601000232B7AE07EF06FC1000001600',
      'C849000032B772CAF746581600001400',
      '1601000230F6E715E719D002000013F0',
      '1601000230F6E91FE715D403000011F0',
      '0802000030F6E91F0000A60400000FC0',
    ];
    final records = parser.parse([
      for (var index = 0; index < hexBlocks.length; index++)
        _block(index, hexBlocks[index]),
    ]);

    expect(records, hasLength(20));
    expect(records.first.sequenceNumber, 0x34);
    expect(records[1].sequenceNumber, 0x32);
    expect(
      records.first.amountCalculation.status,
      AmountCalculationStatus.calculated,
    );
    expect(records.first.amountCalculation.amount, 1372);
    expect(
      records
          .take(19)
          .where(
            (record) =>
                record.amountCalculation.status ==
                AmountCalculationStatus.unavailable,
          ),
      isEmpty,
    );
    expect(
      records.last.amountCalculation.unavailableReason,
      AmountUnavailableReason.noOlderRecord,
    );
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
      expect(
        records.first.amountCalculation.status,
        AmountCalculationStatus.calculated,
      );
      expect(records.first.amountCalculation.amount, 980);
      expect(
        records[2].amountCalculation.status,
        AmountCalculationStatus.balanceIncrease,
      );
      expect(records[2].amountCalculation.amount, 2000);
      expect(
        records[16].amountCalculation.status,
        AmountCalculationStatus.calculated,
      );
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
