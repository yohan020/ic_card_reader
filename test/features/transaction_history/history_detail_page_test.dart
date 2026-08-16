import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/widgets/app_ui.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/raw_history_block.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_resolution.dart';
import 'package:ic_card_reader/src/features/transaction_history/data/transit_history_parser.dart';
import 'package:ic_card_reader/src/features/transaction_history/domain/amount_calculation.dart';
import 'package:ic_card_reader/src/features/transaction_history/domain/parsed_transit_history.dart';
import 'package:ic_card_reader/src/features/transaction_history/domain/transit_transaction_type.dart';
import 'package:ic_card_reader/src/features/transaction_history/presentation/history_pages.dart';

void main() {
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

ParsedTransitHistory _history() => ParsedTransitHistory(
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
  amountCalculation: const AmountCalculation.calculated(980),
);
