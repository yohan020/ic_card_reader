import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_brand_identity.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_reader.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_scan_result.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/raw_history_block.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/card_reader_page.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/suica_card_icon.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/card_brand_icon_frame.dart';
import 'package:ic_card_reader/src/features/station_resolver/data/asset_station_database.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_name_display.dart';
import 'package:ic_card_reader/src/features/transaction_history/presentation/history_pages.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('Suica icon visual ${dark ? 'dark' : 'light'}', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: Scaffold(
            body: Center(
              child: RepaintBoundary(
                key: const ValueKey('suica-icon-preview'),
                child: ColoredBox(
                  color: dark
                      ? AppTheme.dark.scaffoldBackgroundColor
                      : AppTheme.light.scaffoldBackgroundColor,
                  child: SizedBox(
                    width: 184,
                    height: 184,
                    child: Center(
                      child: Transform.scale(
                        scale: 4,
                        child: const SuicaCardIcon(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await expectLater(
        find.byKey(const ValueKey('suica-icon-preview')),
        matchesGoldenFile(
          'goldens/suica_card_icon_${dark ? 'dark' : 'light'}.png',
        ),
      );
    });
  }
  for (final dark in [false, true]) {
    for (final scale in [1.0, 1.7]) {
      testWidgets('Suica balance icon only, dark=$dark scale=$scale', (
        tester,
      ) async {
        Future<void> show(CardBrandIdentity? identity) => tester.pumpWidget(
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
                histories: const [],
                currentBalance: 1200,
                brandIdentity: identity,
                stationPairs: const {},
                onScan: () {},
              ),
            ),
          ),
        );
        await show(CardBrandIdentity.suicaFamily);
        final icon = find.byType(SuicaCardIcon);
        expect(icon, findsOneWidget);
        expect(tester.getSize(icon), cardBrandBalanceSize);
        expect(find.byKey(const ValueKey('suica-icon-tile')), findsNothing);
        expect(
          tester.getSize(
            find.descendant(of: icon, matching: find.byType(CustomPaint)),
          ),
          cardBrandBalanceSize,
        );
        expect(find.text('현재 스이카 잔액'), findsOneWidget);
        expect(find.text('¥1200'), findsOneWidget);
        expect(
          find.byIcon(Icons.account_balance_wallet_outlined),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
        await show(null);
        expect(find.byType(SuicaCardIcon), findsNothing);
        expect(
          find.byIcon(Icons.account_balance_wallet_outlined),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final identity in CardBrandIdentity.values) {
    testWidgets(
      'normal ${identity.name} result reaches history and next card clears identity',
      (tester) async {
        final reader = _Reader(initialBrand: identity);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: CardReaderPage(
              reader: reader,
              stationDatabase: AssetStationDatabase.fromCsv(
                '지역,노선,역,사업자,노선명,역명,비고\n',
              ),
              themeMode: ThemeMode.light,
              onThemeModeChanged: (_) {},
              stationNameDisplayMode: StationNameDisplayMode.japanese,
              onStationNameDisplayModeChanged: (_) {},
            ),
          ),
        );
        Future<void> tapVisible(Finder target) async {
          await tester.scrollUntilVisible(
            target,
            150,
            scrollable: find.byType(Scrollable).first,
          );
          await Scrollable.ensureVisible(tester.element(target), alignment: .5);
          await tester.pump();
          await tester.tap(target);
          // The home card has a repeating animation. Wait for the expected screen
          // instead of requiring every animation in the app to stop.
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 350));
          await tester.pump();
        }

        await tapVisible(find.text('IC 카드 스캔'));
        expect(find.text('${identity.label} 카드를 읽었습니다'), findsOneWidget);
        await tapVisible(find.text('이용내역 보기'));
        expect(
          find.byType(SuicaCardIcon),
          identity == CardBrandIdentity.suicaFamily
              ? findsOneWidget
              : findsNothing,
        );
        expect(find.text('현재 ${identity.label} 잔액'), findsOneWidget);
        await tester.tap(find.byTooltip('IC 카드 스캔'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tapVisible(find.text('이용내역 보기'));
        expect(find.byType(SuicaCardIcon), findsNothing);
        expect(
          find.byIcon(Icons.account_balance_wallet_outlined),
          findsOneWidget,
        );
        expect(find.text('현재 카드 잔액'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _Reader implements CardReader {
  _Reader({this.initialBrand = CardBrandIdentity.suicaFamily});
  final CardBrandIdentity initialBrand;
  int scans = 0;
  @override
  Future<CardScanResult> scan({
    Duration timeout = const Duration(seconds: 30),
  }) async => CardScanResult(
    scannedAt: DateTime(2026, 10, 25),
    brandIdentity: scans++ == 0 ? initialBrand : null,
    blocks: [
      RawHistoryBlock(
        index: 0,
        bytes: Uint8List.fromList([
          0x16,
          1,
          0,
          0,
          0x34,
          0x19,
          0,
          0,
          0,
          0,
          0xB0,
          4,
          0,
          0,
          0,
          0,
        ]),
      ),
    ],
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
