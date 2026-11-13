import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/app_update/domain/app_update_service.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_reader.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_brand_identity.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_scan_result.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/card_reader_page.dart';
import 'package:ic_card_reader/src/features/station_resolver/data/asset_station_database.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_name_display.dart';
import 'package:ic_card_reader/src/features/transaction_history/data/transit_history_parser.dart';
import 'package:ic_card_reader/src/features/transaction_history/presentation/history_pages.dart';

import '../../support/ica_fixture.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'ICa bus and charge reuse filters, totals and details ($dark)',
      (tester) async {
        final histories = const TransitHistoryParser().parse([
          icaFixture(index: 0, delta: 1500, kind: 0x79),
          icaFixture(index: 1, delta: -230, kind: 0x5D),
          icaFixture(index: 2, delta: -240),
        ]);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: Scaffold(
              body: HistoryListPage(
                histories: histories,
                currentBalance: 1234,
                stationPairs: const {},
                onScan: () {},
              ),
            ),
          ),
        );
        Future<void> tapVisible(Finder target) async {
          await Scrollable.ensureVisible(tester.element(target), alignment: .5);
          await tester.pumpAndSettle();
          await tester.tap(target);
          await tester.pumpAndSettle();
        }

        await tapVisible(find.widgetWithText(FilterChip, '교통'));
        expect(find.text('버스 이용'), findsOneWidget);
        expect(find.text('유형 미확인'), findsNothing);
        expect(find.text('+¥1500'), findsNothing);
        expect(find.text('¥230'), findsOneWidget);
        await tapVisible(find.text('버스 이용'));
        expect(find.text('이용내역 상세'), findsOneWidget);
        expect(find.text('버스 회사 확인 불가'), findsOneWidget);
        expect(find.text('승차역'), findsNothing);
        expect(find.text('하차역'), findsNothing);
        expect(find.textContaining('할인'), findsNothing);
        await tester.pageBack();
        await tester.pumpAndSettle();

        await tapVisible(find.widgetWithText(FilterChip, '충전'));
        expect(find.text('충전 합계'), findsOneWidget);
        expect(find.text('¥1500'), findsOneWidget);
        expect(find.text('+¥1500'), findsOneWidget);
        expect(find.text('버스 이용'), findsNothing);
        await tapVisible(find.text('카드 충전'));
        expect(find.text('이용내역 상세'), findsOneWidget);
        expect(find.text('거래 유형'), findsOneWidget);
        expect(find.text('충전'), findsNWidgets(2));
        expect(find.text('확인할 수 없음'), findsNWidgets(2));
        expect(find.text('승차역'), findsNothing);
        await tester.pageBack();
        await tester.pumpAndSettle();

        await tapVisible(find.widgetWithText(FilterChip, '미확인'));
        expect(find.text('유형 미확인'), findsOneWidget);
        expect(find.text('버스 이용'), findsNothing);
        expect(find.text('-¥240'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'ICa normal scan shows balance and conservative history ($dark)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: CardReaderPage(
              reader: _Reader(),
              appUpdateService: _Updates(),
              stationDatabase: AssetStationDatabase.fromCsv(
                '지역,노선,역,사업자,노선명,역명,비고\n',
              ),
              themeMode: dark ? ThemeMode.dark : ThemeMode.light,
              onThemeModeChanged: (_) {},
              stationNameDisplayMode: StationNameDisplayMode.japanese,
              onStationNameDisplayModeChanged: (_) {},
            ),
          ),
        );
        await tester.scrollUntilVisible(
          find.text('IC 카드 스캔'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await Scrollable.ensureVisible(
          tester.element(find.text('IC 카드 스캔')),
          alignment: 0.5,
        );
        await tester.pump();
        await tester.tap(find.text('IC 카드 스캔'));
        await tester.pumpAndSettle();
        expect(find.text('ICa 카드를 읽었습니다'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('이용내역 보기'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await Scrollable.ensureVisible(
          tester.element(find.text('이용내역 보기')),
          alignment: 0.5,
        );
        await tester.pump();
        await tester.tap(find.text('이용내역 보기'));
        await tester.pumpAndSettle();
        expect(find.text('현재 ICa 잔액'), findsOneWidget);
        expect(find.text('¥1234'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('유형 미확인'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('유형 미확인'), findsOneWidget);
        expect(find.text('-¥230'), findsOneWidget);
        expect(find.text('2026.10.24'), findsOneWidget);
        expect(find.text('철도 이용'), findsNothing);
        expect(find.text('버스 이용'), findsNothing);
        await Scrollable.ensureVisible(
          tester.element(find.text('유형 미확인')),
          alignment: 0.5,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('유형 미확인'));
        await tester.pumpAndSettle();
        expect(find.text('이용내역 상세'), findsOneWidget);
        expect(find.text('이용 후 잔액 ¥1234'), findsOneWidget);
        expect(find.text('승차역'), findsNothing);
        expect(find.text('하차역'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _Reader implements CardReader {
  @override
  Future<CardScanResult> scan({
    Duration timeout = const Duration(seconds: 30),
  }) async => CardScanResult(
    scannedAt: DateTime(2026, 10, 24),
    blocks: [icaFixture()],
    brandIdentity: CardBrandIdentity.ica,
  );
  @override
  Future<CardReaderAvailability> checkAvailability() async =>
      CardReaderAvailability.enabled;
  @override
  Future<void> cancel() async {}
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<bool> openNfcSettings() async => false;
}

class _Updates implements AppUpdateService {
  @override
  Future<AppUpdateStatus> checkForUpdate() async =>
      const AppUpdateStatus.latest();
  @override
  Future<void> startUpdate(AppUpdateStatus status) async {}
}
