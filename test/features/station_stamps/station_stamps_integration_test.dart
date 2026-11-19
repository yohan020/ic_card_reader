import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/l10n/app_localizations.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_reader.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_scan_result.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/raw_history_block.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/card_reader_page.dart';
import 'package:ic_card_reader/src/features/settings/presentation/settings_page.dart';
import 'package:ic_card_reader/src/features/station_resolver/data/asset_station_database.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_name_display.dart';
import 'package:ic_card_reader/src/features/station_stamps/presentation/stamp_book_page.dart';

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'stamp_book_tutorial_seen_v1': true,
    }),
  );
  testWidgets('real scan-to-home-book path and settings delete retain scan', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: CardReaderPage(
          reader: _Reader(),
          stationDatabase: AssetStationDatabase.fromCsv(
            'region,line,station,region_hex,line_hex,station_hex,operator,line_name,station_name\n0,1,1,00,01,01,東日本旅客鉄道,fixture,東京\n0,2,1,00,02,01,東日本旅客鉄道,fixture,上野\n',
          ),
          themeMode: ThemeMode.light,
          onThemeModeChanged: (_) {},
          stationNameDisplayMode: StationNameDisplayMode.japanese,
          onStationNameDisplayModeChanged: (_) {},
        ),
      ),
    );
    // The established Home illustration intentionally repeats; do not wait
    // for all animation frames to settle while Home is active.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.scrollUntilVisible(find.text('IC 카드 스캔'), 120);
    await tester.tap(find.text('IC 카드 스캔'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final navigation = find.byType(NavigationBar);
    final tool = find.byKey(const ValueKey('home-stamp-book'));
    await tester.scrollUntilVisible(
      tool,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(tool);
    await tester.tap(tool);
    await _frame(tester);
    final page = tester.widget<StampBookPage>(find.byType(StampBookPage));
    expect(page.candidates, {'jr-east:tokyo', 'jr-east:ueno'});
    await tester.tap(find.byKey(const ValueKey('stamp-book-collect')));
    await _frame(tester);
    expect(page.session.count, 2);
    await tester.tap(find.byType(BackButton));
    await _frame(tester);
    await tester.tap(
      find.descendant(of: navigation, matching: find.text('설정')),
    );
    await _frame(tester);
    await tester.scrollUntilVisible(find.text('역 스탬프 전체 삭제'), 200);
    await tester.tap(find.text('역 스탬프 전체 삭제'));
    await _frame(tester);
    await tester.tap(find.byKey(const ValueKey('stamps-confirm-delete')));
    await _frame(tester);
    expect(page.session.count, 0);
    expect(
      tester.widget<SettingsPage>(find.byType(SettingsPage)).result,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _frame(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

class _Reader implements CardReader {
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<CardReaderAvailability> checkAvailability() async =>
      CardReaderAvailability.enabled;
  @override
  Future<bool> openNfcSettings() async => true;
  @override
  Future<void> cancel() async {}
  @override
  Future<CardScanResult> scan({
    Duration timeout = const Duration(seconds: 30),
  }) async => CardScanResult(
    scannedAt: DateTime(2026, 1, 1),
    blocks: [
      RawHistoryBlock(
        index: 0,
        bytes: Uint8List.fromList([
          0x16,
          1,
          0,
          0,
          0x34,
          0xe4,
          1,
          1,
          2,
          1,
          0xe2,
          3,
          0,
          0,
          1,
          0,
        ]),
      ),
    ],
  );
}
