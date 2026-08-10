import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/app.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_reader.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_scan_result.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/raw_history_block.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/card_reader_page.dart';
import 'package:ic_card_reader/src/features/station_resolver/data/asset_station_database.dart';
import 'package:ic_card_reader/src/features/transaction_history/data/transit_history_parser.dart';
import 'package:ic_card_reader/src/features/transaction_history/presentation/history_pages.dart';

void main() {
  testWidgets('shows the privacy notice and scan action', (tester) async {
    await tester.pumpWidget(const IcCardReaderApp());

    expect(find.text('IC 카드 스캔'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('카드 데이터는 이 기기에서만 처리합니다'), 200);
    expect(find.text('카드 데이터는 이 기기에서만 처리합니다'), findsOneWidget);
  });

  testWidgets('shows the scan result and opens parsed history', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CardReaderPage(
          reader: _FakeCardReader(),
          stationDatabase: AssetStationDatabase.fromCsv(
            '지역,노선,역,사업자,노선명,역명,비고\n',
          ),
          themeMode: ThemeMode.system,
          onThemeModeChanged: (_) {},
        ),
      ),
    );

    await Scrollable.ensureVisible(
      tester.element(find.text('IC 카드 스캔')),
      alignment: 0.5,
    );
    await tester.pump();
    await tester.tap(find.text('IC 카드 스캔'));
    await tester.pumpAndSettle();

    expect(find.text('카드를 읽었습니다'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('이용내역 보기'), 200);
    expect(find.text('이용내역 보기'), findsOneWidget);

    await tester.tap(find.text('이용내역 보기'));
    await tester.pumpAndSettle();

    expect(find.text('최근 스캔 · 1개 기록'), findsOneWidget);
    expect(find.text('현재 카드 잔액'), findsOneWidget);
    expect(find.text('가장 최근 기록 기준'), findsOneWidget);
    expect(find.text('¥994'), findsOneWidget);
    expect(find.text('계산 불가'), findsOneWidget);

    await tester.tap(find.text('계산 불가'));
    await tester.pumpAndSettle();

    expect(find.text('금액을 계산할 수 없습니다'), findsOneWidget);
    expect(find.textContaining('그보다 오래된 잔액 기록이 없어'), findsOneWidget);
    final routeNames = tester.widgetList<Text>(find.text('역 정보 미등록'));
    expect(routeNames, hasLength(2));
    expect(routeNames.every((text) => text.style?.fontSize == 18), isTrue);
    expect(
      routeNames.every((text) => text.style?.fontWeight == FontWeight.w900),
      isTrue,
    );

    await tester.dragUntilVisible(
      find.text('이 내역의 오류 제보하기'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.tap(find.text('이 내역의 오류 제보하기'));
    await tester.pumpAndSettle();

    expect(find.text('선택한 이용내역'), findsOneWidget);
    expect(find.text('50-A5-78 → 50-AC-38'), findsOneWidget);
    expect(find.text('1/3 단계'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('report-progress-segment-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('report-progress-segment-2')),
      findsOneWidget,
    );
    expect(
      tester.widget<Text>(find.text('어떤 정보가 잘못되었나요?')).style?.fontWeight,
      FontWeight.w700,
    );
    expect(
      tester.widget<Text>(find.text('승차역이 잘못됨')).style?.fontWeight,
      FontWeight.w500,
    );
  });

  testWidgets('shows that the bus company code is not yet identified', (
    tester,
  ) async {
    const parser = TransitHistoryParser();
    final histories = parser.parse([
      _rawBlock(0, '050D000F34E30D2A0000B60700012740'),
      _rawBlock(1, 'C849000034E378CAC0CE880800012600'),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HistoryListPage(
            histories: histories,
            currentBalance: histories.first.balance,
            stationPairs: const {},
            onScan: () {},
          ),
        ),
      ),
    );

    expect(find.text('버스 회사 미확인'), findsOneWidget);
    await tester.tap(find.text('버스 회사 미확인'));
    await tester.pumpAndSettle();

    expect(find.text('버스 회사'), findsOneWidget);
    expect(find.text('미확인 · 회사 고유 코드 미해석'), findsOneWidget);
  });

  testWidgets('uses green for a charge amount', (tester) async {
    const parser = TransitHistoryParser();
    final histories = parser.parse([
      _rawBlock(0, 'C849000034E378CAC0CE880800012600'),
      _rawBlock(1, '050D000F34E30D2A0000B80000012540'),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HistoryListPage(
            histories: histories,
            currentBalance: histories.first.balance,
            stationPairs: const {},
            onScan: () {},
          ),
        ),
      ),
    );

    final amount = tester.widget<Text>(find.text('+¥2000'));
    expect(amount.style?.color, AppColors.success);

    await tester.tap(find.text('+¥2000'));
    await tester.pumpAndSettle();

    final detailAmount = tester.widget<Text>(find.text('+¥2000'));
    expect(detailAmount.style?.color, AppColors.success);
  });

  testWidgets('shows a balance from an initialization-only card', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HistoryListPage(
            histories: const [],
            currentBalance: 500,
            stationPairs: const {},
            onScan: () {},
          ),
        ),
      ),
    );

    expect(find.text('초기 잔액 기록 기준'), findsOneWidget);
    expect(find.text('¥500'), findsOneWidget);
    expect(find.text('이 카드에는 표시할 이용내역이 없습니다'), findsOneWidget);
    expect(find.text('초기 잔액 기록만 확인되었습니다.'), findsOneWidget);
  });
}

RawHistoryBlock _rawBlock(int index, String hexadecimal) => RawHistoryBlock(
  index: index,
  bytes: Uint8List.fromList([
    for (var offset = 0; offset < hexadecimal.length; offset += 2)
      int.parse(hexadecimal.substring(offset, offset + 2), radix: 16),
  ]),
);

class _FakeCardReader implements CardReader {
  @override
  Future<void> cancel() async {}

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<CardScanResult> scan({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    return CardScanResult(
      scannedAt: DateTime(2026, 8, 9, 12, 30),
      blocks: [
        RawHistoryBlock(
          index: 0,
          bytes: Uint8List.fromList(const [
            0x16,
            0x01,
            0x00,
            0x02,
            0x34,
            0xE4,
            0xA5,
            0x78,
            0xAC,
            0x38,
            0xE2,
            0x03,
            0x00,
            0x01,
            0x29,
            0x50,
          ]),
        ),
      ],
    );
  }
}
