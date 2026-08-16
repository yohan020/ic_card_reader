import 'dart:async';
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
import 'package:ic_card_reader/src/features/station_resolver/domain/station_resolution.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_name_display.dart';
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
        theme: AppTheme.light,
        home: CardReaderPage(
          reader: _FakeCardReader(),
          stationDatabase: AssetStationDatabase.fromCsv(
            '지역,노선,역,사업자,노선명,역명,비고\n',
          ),
          themeMode: ThemeMode.system,
          onThemeModeChanged: (_) {},
          stationNameDisplayMode: StationNameDisplayMode.japanese,
          onStationNameDisplayModeChanged: (_) {},
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
    expect(find.text('01-A5-78 → 01-AC-38'), findsOneWidget);
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
      tester.widget<Text>(find.text('역 정보가 없거나 잘못됨')).style?.fontWeight,
      FontWeight.w500,
    );
  });

  testWidgets('keeps the scan countdown independent from disabled animations', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final reader = _PendingCardReader();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CardReaderPage(
          reader: reader,
          themeMode: ThemeMode.system,
          onThemeModeChanged: (_) {},
          stationNameDisplayMode: StationNameDisplayMode.japanese,
          onStationNameDisplayModeChanged: (_) {},
        ),
      ),
    );

    await Scrollable.ensureVisible(
      tester.element(find.text('IC 카드 스캔')),
      alignment: 0.5,
    );
    await tester.pump();
    await tester.tap(find.text('IC 카드 스캔'));
    await tester.pump();

    expect(find.text('남은 시간 30초'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('남은 시간 0초'), findsNothing);
    expect(find.text('남은 시간 28초'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pump();
    expect(reader.cancelled, isTrue);
  });

  testWidgets('keeps an unverified bus signature unidentified', (tester) async {
    const parser = TransitHistoryParser();
    final histories = parser.parse([
      _rawBlock(0, '050D000F34E30D2B0000B60700012740'),
      _rawBlock(1, 'C849000034E378CAC0CE880800012600'),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
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

  testWidgets('shows the physical simple-gate rail route', (tester) async {
    const parser = TransitHistoryParser();
    final histories = parser.parse([
      _rawBlock(0, '1701000234DE44244428EC0400000300'),
    ]);
    final database = AssetStationDatabase.fromCsv(
      'region,line,station,region_hex,line_hex,station_hex,operator,line_name,station_name\n'
      '0,68,36,00,44,24,東海旅客鉄道,高山線,高山\n'
      '0,68,40,00,44,28,東海旅客鉄道,高山線,飛騨古川\n',
    );
    final stations = database.resolvePair(
      boardingCode: const StationCode(
        regionCode: 0x00,
        lineCode: 0x44,
        stationCode: 0x24,
      ),
      alightingCode: const StationCode(
        regionCode: 0x00,
        lineCode: 0x44,
        stationCode: 0x28,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: HistoryListPage(
            histories: histories,
            currentBalance: histories.first.balance,
            stationPairs: {0: stations},
            onScan: () {},
          ),
        ),
      ),
    );

    expect(find.text('철도 이용'), findsOneWidget);
    expect(find.text('高山  →  飛騨古川'), findsOneWidget);
  });

  testWidgets('shows CA 46 only as a purchase without a guessed place', (
    tester,
  ) async {
    const parser = TransitHistoryParser();
    final histories = parser.parse([
      _rawBlock(0, 'CA46000034E35DA49B0AE60000000900'),
      _rawBlock(1, '1701000234DE44244428EC0400000800'),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
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

    expect(find.text('물품 구매'), findsNWidgets(2));
    expect(find.text('-¥1030'), findsOneWidget);
    expect(find.textContaining('9B-0A'), findsNothing);
    expect(find.textContaining('편의점'), findsNothing);
    expect(find.textContaining('자판기'), findsNothing);
  });

  testWidgets('uses green for a charge amount', (tester) async {
    const parser = TransitHistoryParser();
    final histories = parser.parse([
      _rawBlock(0, 'C849000034E378CAC0CE880800012600'),
      _rawBlock(1, '050D000F34E30D2A0000B80000012540'),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
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
    expect(find.text('매장에서 충전'), findsOneWidget);
    expect(find.textContaining('편의점'), findsNothing);

    await tester.tap(find.text('+¥2000'));
    await tester.pumpAndSettle();

    final detailAmount = tester.widget<Text>(find.text('+¥2000'));
    expect(detailAmount.style?.color, AppColors.success);
    expect(find.text('매장 단말'), findsOneWidget);
    expect(find.text('확인할 수 없음'), findsOneWidget);
  });

  testWidgets('shows the station for a ticket-machine charge', (tester) async {
    const parser = TransitHistoryParser();
    final histories = parser.parse([
      _rawBlock(0, '0802000030F6E91F0000A60400000FC0'),
    ]);
    final database = AssetStationDatabase.fromCsv(
      'region,line,station,region_hex,line_hex,station_hex,operator,line_name,station_name\n'
      '3,233,31,03,E9,1F,福岡市交通局,3号線(七隈線),天神南\n',
    );
    final location = database.resolve(
      const StationCode(regionCode: 0x03, lineCode: 0xE9, stationCode: 0x1F),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: HistoryListPage(
            histories: histories,
            currentBalance: histories.first.balance,
            stationPairs: const {},
            transactionLocations: {0: location},
            onScan: () {},
          ),
        ),
      ),
    );

    expect(find.text('자동발권기에서 충전 · 天神南'), findsOneWidget);
    await tester.tap(find.text('자동발권기에서 충전 · 天神南'));
    await tester.pumpAndSettle();

    expect(find.text('충전 방식'), findsOneWidget);
    expect(find.text('자동발권기'), findsOneWidget);
    expect(find.text('충전 장소'), findsOneWidget);
    expect(find.text('天神南 · 3号線(七隈線)'), findsOneWidget);
  });

  testWidgets('shows a balance from an initialization-only card', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
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

  testWidgets('shows 21 02 as a station-terminal charge without a place', (
    tester,
  ) async {
    final history = const TransitHistoryParser().parse([
      _rawBlock(0, '21020000350DAC3800007B1700005E40'),
    ]).single;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: HistoryDetailPage(history: history),
      ),
    );

    expect(find.text('충전'), findsWidgets);
    expect(find.text('역 단말'), findsOneWidget);
    expect(find.text('확인할 수 없음'), findsWidgets);
    expect(find.textContaining('中部国際空港'), findsNothing);
    expect(find.textContaining('자동발권기'), findsNothing);
  });

  testWidgets('shows the two verified Iyotetsu Takahama line routes', (
    tester,
  ) async {
    const overrideCsv =
        'region_code,line_code,station_code,operator_name,line_name,station_name,evidence,source_note\n'
        '3,197,23,伊予鉄道,高浜線,松山市,verified_fixture,test\n'
        '3,197,27,伊予鉄道,高浜線,古町,verified_fixture,test\n'
        '3,197,39,伊予鉄道,高浜線,梅津寺,verified_fixture,test\n';
    final database = AssetStationDatabase.fromCsv(
      'region,line,station,region_hex,line_hex,station_hex,operator,line_name,station_name\n',
      overrideCsv: overrideCsv,
    );
    final histories = const TransitHistoryParser().parse([
      _rawBlock(0, '1601000234FEC51BC5275F0600005AF0'),
      _rawBlock(1, '1601000234FEC527C517A70400005CF0'),
    ]);
    final firstPair = database.resolvePair(
      boardingCode: const StationCode(
        regionCode: 3,
        lineCode: 0xC5,
        stationCode: 0x1B,
      ),
      alightingCode: const StationCode(
        regionCode: 3,
        lineCode: 0xC5,
        stationCode: 0x27,
      ),
    );
    final secondPair = database.resolvePair(
      boardingCode: const StationCode(
        regionCode: 3,
        lineCode: 0xC5,
        stationCode: 0x27,
      ),
      alightingCode: const StationCode(
        regionCode: 3,
        lineCode: 0xC5,
        stationCode: 0x17,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: HistoryListPage(
            histories: histories,
            currentBalance: histories.first.balance,
            stationPairs: {0: firstPair, 1: secondPair},
            onScan: () {},
          ),
        ),
      ),
    );

    expect(find.text('古町  →  梅津寺'), findsOneWidget);
    expect(find.text('梅津寺  →  松山市'), findsOneWidget);
    expect(find.textContaining('聖蹟桜ヶ丘'), findsNothing);
    expect(find.textContaining('東府中'), findsNothing);

    await tester.tap(find.text('古町  →  梅津寺'));
    await tester.pumpAndSettle();
    expect(find.text('古町'), findsOneWidget);
    expect(find.text('梅津寺'), findsOneWidget);
    expect(find.textContaining('伊予鉄道'), findsWidgets);
    expect(find.textContaining('高浜線'), findsWidgets);
  });

  testWidgets('shows Iyotetsu without choosing bus or tram', (tester) async {
    final history = const TransitHistoryParser().parse([
      _rawBlock(0, '050D000F34FC0F3D00002F0700004FC0'),
    ]).single;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
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

    expect(find.text('버스·노면전차 이용'), findsOneWidget);
    expect(find.text('伊予鉄道'), findsOneWidget);
    expect(find.text('버스 이용'), findsNothing);
    expect(find.text('노면전차 이용'), findsNothing);
    expect(find.textContaining('市内電車'), findsNothing);
    expect(find.textContaining('伊予鉄バス'), findsNothing);

    await tester.tap(find.text('伊予鉄道'));
    await tester.pumpAndSettle();
    expect(find.text('버스·노면전차 이용'), findsWidgets);
    expect(find.text('버스 회사'), findsOneWidget);
    expect(find.text('伊予鉄道'), findsOneWidget);
    expect(find.text('승차역'), findsNothing);
    expect(find.text('하차역'), findsNothing);
  });

  testWidgets('shows the Iyotetsu Gunchu route with adjacent balance amount', (
    tester,
  ) async {
    const overrideCsv =
        'region_code,line_code,station_code,operator_name,line_name,station_name,evidence,source_note\n'
        '3,197,1,伊予鉄道,郡中線,郡中港,verified_fixture,test\n'
        '3,197,23,伊予鉄道,伊予鉄道郊外電車,松山市,verified_fixture,test\n';
    final database = AssetStationDatabase.fromCsv(
      'region,line,station,region_hex,line_hex,station_hex,operator,line_name,station_name\n',
      overrideCsv: overrideCsv,
    );
    final histories = const TransitHistoryParser().parse([
      _rawBlock(0, '1601000234FCC501C517FF04000051F0'),
      _rawBlock(1, '050D000F34FC0F3D00002F0700004FC0'),
    ]);
    final pair = database.resolvePair(
      boardingCode: const StationCode(
        regionCode: 3,
        lineCode: 0xC5,
        stationCode: 0x01,
      ),
      alightingCode: const StationCode(
        regionCode: 3,
        lineCode: 0xC5,
        stationCode: 0x17,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: HistoryListPage(
            histories: histories,
            currentBalance: histories.first.balance,
            stationPairs: {0: pair},
            onScan: () {},
          ),
        ),
      ),
    );

    expect(find.text('郡中港  →  松山市'), findsOneWidget);
    expect(find.text('-¥560'), findsOneWidget);
    expect(find.textContaining('高浜線'), findsNothing);
    expect(find.textContaining('京王線'), findsNothing);

    await tester.tap(find.text('郡中港  →  松山市'));
    await tester.pumpAndSettle();
    expect(find.text('伊予鉄道 · 郡中線'), findsNWidgets(2));
    expect(find.text('郡中港 · 郡中線'), findsOneWidget);
    expect(find.text('松山市 · 郡中線'), findsOneWidget);
    expect(find.text('-¥560'), findsOneWidget);
    expect(find.textContaining('高浜線'), findsNothing);
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

class _PendingCardReader implements CardReader {
  final Completer<CardScanResult> _result = Completer<CardScanResult>();
  bool cancelled = false;

  @override
  Future<void> cancel() async {
    cancelled = true;
    if (!_result.isCompleted) {
      _result.completeError(
        const CardScanException(CardScanFailureKind.cancelled, '스캔을 취소했습니다.'),
      );
    }
  }

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<CardScanResult> scan({
    Duration timeout = const Duration(seconds: 30),
  }) => _result.future;
}
