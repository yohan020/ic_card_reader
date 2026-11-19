import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/l10n/app_localizations.dart';
import 'package:ic_card_reader/l10n/app_localizations_en.dart';
import 'package:ic_card_reader/l10n/app_localizations_ko.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/raw_history_block.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_name_display.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_resolution.dart';
import 'package:ic_card_reader/src/features/transaction_history/data/history_csv_saver.dart';
import 'package:ic_card_reader/src/features/transaction_history/domain/amount_calculation.dart';
import 'package:ic_card_reader/src/features/transaction_history/domain/parsed_transit_history.dart';
import 'package:ic_card_reader/src/features/transaction_history/domain/transit_transaction_type.dart';
import 'package:ic_card_reader/src/features/transaction_history/presentation/history_csv.dart';
import 'package:ic_card_reader/src/features/transaction_history/presentation/history_pages.dart';

void main() {
  for (final english in [false, true]) {
    for (final mode in StationNameDisplayMode.values) {
      test(
        'CSV locale=$english station=$mode, numeric values and no raw data',
        () {
          final l10n = english ? AppLocalizationsEn() : AppLocalizationsKo();
          final bytes = createHistoryCsv(
            histories: records(),
            stationPairs: {0: pair()},
            transactionLocations: {},
            stationNameDisplayMode: mode,
            l10n: l10n,
          );
          expect(bytes.take(3), [0xef, 0xbb, 0xbf]);
          final text = utf8.decode(bytes);
          expect(text, contains('"${l10n.csvDate}"'));
          expect(text, contains('"${l10n.railRide}"'));
          expect(text, contains('"2026-11-13"'));
          expect(text, contains(',-210,"${l10n.csvCalculated}",790'));
          expect(text, contains(',1000,"${l10n.csvCalculated}",1000'));
          expect(text, contains(',"${l10n.unavailableAmount}",500'));
          expect(text, contains(',"${l10n.checkAmount}",600'));
          expect(
            text,
            contains(
              '"${displayStationName(japanese: '試験駅甲', korean: '예시역갑', english: 'Example A', mode: mode)}"',
            ),
          );
          expect(text, isNot(contains('rawBlock')));
          expect(text, isNot(contains('stationCode')));
          expect(text, isNot(contains('IDm')));
          expect(text, isNot(contains('¥')));
          expect(text.endsWith('\r\n'), isTrue);
        },
      );
    }
  }
  test(
    'CSV quoting, formula prefixes, multiline text, and typed numeric cells',
    () {
      expect(csvTextCell('a,"b"\nc'), '"a,""b""\nc"');
      for (final input in [
        '=SUM(1,2)',
        '+1',
        '-1',
        '@test',
        '  =1',
        '\r=1',
        '\t=1',
        '＝1',
        '＋1',
        '－1',
        '＠1',
      ]) {
        expect(csvTextCell(input).startsWith('"\t'), isTrue);
      }
      expect(csvTextCell('abc'), '"abc"');
      expect(csvTextCell('a\u0000b'), '"ab"');
    },
  );
  test(
    'filter export preserves full-scan amounts, order and missing values',
    () {
      final selected = [records()[2], records()[0]];
      final text = utf8.decode(
        createHistoryCsv(
          histories: selected,
          stationPairs: {},
          transactionLocations: {},
          stationNameDisplayMode: StationNameDisplayMode.english,
          l10n: AppLocalizationsEn(),
        ),
      );
      final rows = text.split('\r\n');
      expect(rows.length, 4);
      expect(rows[1], startsWith('"","Purchase"'));
      expect(
        rows[1],
        contains(',,"${AppLocalizationsEn().unavailableAmount}",500'),
      );
      expect(rows[2], contains('"${AppLocalizationsEn().stationUnavailable}"'));
      expect(rows[2], contains(',-210,'));
    },
  );
  test(
    'unmapped English station falls back to Japanese, never invents a name',
    () {
      final resolution = pair().boarding;
      final station = resolution.station!;
      final fallback = StationResolution(
        requestedCode: resolution.requestedCode,
        strategy: resolution.strategy,
        station: StationRecord(
          code: station.code,
          operatorName: 'Synthetic',
          lineName: 'Synthetic',
          stationName: '試験駅甲',
          source: 'synthetic',
        ),
      );
      final text = utf8.decode(
        createHistoryCsv(
          histories: [records().first],
          stationPairs: {
            0: ResolvedStationPair(boarding: fallback, alighting: fallback),
          },
          transactionLocations: {},
          stationNameDisplayMode: StationNameDisplayMode.english,
          l10n: AppLocalizationsEn(),
        ),
      );
      expect(text, contains('"試験駅甲","試験駅甲"'));
    },
  );

  TestWidgetsFlutterBinding.ensureInitialized();
  for (final saved in [true, false]) {
    test(
      'platform saver forwards exact bytes and cancellation=$saved',
      () async {
        final bytes = Uint8List.fromList([239, 187, 191, 65]);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(AndroidHistoryCsvSaver.channel, (
              call,
            ) async {
              expect(call.method, 'save');
              expect(
                call.arguments['filename'],
                'ic-card-history-20261113.csv',
              );
              expect(call.arguments['bytes'], bytes);
              expect(
                (call.arguments as Map).keys,
                unorderedEquals(['filename', 'bytes']),
              );
              return saved;
            });
        addTearDown(
          () => TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .setMockMethodCallHandler(AndroidHistoryCsvSaver.channel, null),
        );
        expect(
          await const AndroidHistoryCsvSaver().save(
            filename: 'ic-card-history-20261113.csv',
            bytes: bytes,
          ),
          saved,
        );
      },
    );
  }

  for (final english in [false, true]) {
    for (final dark in [false, true]) {
      for (final spec in [
        (const Size(375, 812), 1.0),
        (const Size(320, 740), 2.0),
        (const Size(844, 390), 1.0),
        (const Size(768, 1024), 3.0),
      ]) {
        testWidgets('export sheet locale=$english dark=$dark size=$spec', (
          tester,
        ) async {
          final semantics = tester.ensureSemantics();
          final saver = FakeSaver();
          await pumpHistory(
            tester,
            saver,
            english: english,
            dark: dark,
            size: spec.$1,
            scale: spec.$2,
          );
          final export = find.byKey(const ValueKey('history-export'));
          expect(tester.getSize(export), const Size(48, 48));
          expect(find.byIcon(Icons.nfc_rounded), findsNothing);
          expect(
            find.bySemanticsLabel(english ? 'Export CSV' : 'CSV 내보내기'),
            findsWidgets,
          );
          semantics.dispose();
          await tester.tap(export);
          await tester.pumpAndSettle();
          final option = find.byKey(const ValueKey('export-scope-filtered'));
          await tester.ensureVisible(option);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(option);
          await tester.pumpAndSettle();
          expect(saver.exports, hasLength(1));
          final text = utf8.decode(saver.exports.single);
          expect(text, contains('Example A'));
          expect(text, contains(english ? 'Transaction type' : '거래 유형'));
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
  testWidgets(
    'no export for unscanned or balance-only card; no history scan action',
    (tester) async {
      for (final balance in <int?>[null, 700]) {
        await pumpHistory(tester, FakeSaver(), histories: [], balance: balance);
        expect(find.byKey(const ValueKey('history-export')), findsNothing);
        expect(find.byIcon(Icons.nfc_rounded), findsNothing);
      }
    },
  );
  testWidgets(
    'filtered exports only selected type, all still exports full card',
    (tester) async {
      final saver = FakeSaver();
      await pumpHistory(tester, saver);
      final charge = find.widgetWithText(FilterChip, '충전');
      await tester.ensureVisible(charge);
      await tester.tap(charge);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('history-export')));
      await tester.tap(find.byKey(const ValueKey('history-export')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('export-scope-filtered')));
      await tester.pumpAndSettle();
      expect(utf8.decode(saver.exports.single).split('\r\n').length, 3);
      expect(utf8.decode(saver.exports.single), contains(',1000,'));
      await tester.tap(find.byKey(const ValueKey('history-export')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('export-scope-all')));
      await tester.pumpAndSettle();
      expect(utf8.decode(saver.exports.last).split('\r\n').length, 6);
    },
  );
  testWidgets('empty filter disables filtered export, keeps full-card export', (
    tester,
  ) async {
    final saver = FakeSaver();
    await pumpHistory(tester, saver, histories: [records().first]);
    await tester.ensureVisible(find.widgetWithText(FilterChip, '충전'));
    await tester.tap(find.widgetWithText(FilterChip, '충전'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('history-export')));
    await tester.tap(find.byKey(const ValueKey('history-export')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ListTile>(find.byKey(const ValueKey('export-scope-filtered')))
          .enabled,
      isFalse,
    );
    await tester.tap(find.byKey(const ValueKey('export-scope-all')));
    await tester.pumpAndSettle();
    expect(saver.exports, hasLength(1));
  });
  testWidgets(
    'sheet close and system cancellation do not claim saved; errors are localized',
    (tester) async {
      final saver = FakeSaver()..saved = false;
      await pumpHistory(tester, saver);
      await tester.tap(find.byKey(const ValueKey('history-export')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();
      expect(saver.exports, isEmpty);
      await tester.tap(find.byKey(const ValueKey('history-export')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('export-scope-all')));
      await tester.pumpAndSettle();
      expect(find.text('CSV 파일을 저장했어요.'), findsNothing);
      saver.fail = true;
      await tester.tap(find.byKey(const ValueKey('history-export')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('export-scope-all')));
      await tester.pumpAndSettle();
      expect(find.text('CSV 파일을 저장하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    },
  );
  testWidgets(
    'pending save blocks repeat action and snapshots the current card',
    (tester) async {
      final saver = FakeSaver()..pending = Completer<bool>();
      await pumpHistory(tester, saver, histories: [records().first]);
      await tester.tap(find.byKey(const ValueKey('history-export')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('export-scope-all')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('history-export')))
            .onPressed,
        isNull,
      );
      expect(saver.exports, hasLength(1));
      await tester.pumpWidget(const SizedBox());
      saver.pending!.complete(true);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(utf8.decode(saver.exports.single).split('\r\n').length, 3);
    },
  );
}

class FakeSaver implements HistoryCsvSaver {
  final exports = <Uint8List>[];
  bool saved = true;
  bool fail = false;
  Completer<bool>? pending;
  @override
  Future<bool> save({
    required String filename,
    required Uint8List bytes,
  }) async {
    expect(filename, matches(r'^ic-card-history-[0-9-]+\.csv$'));
    exports.add(bytes);
    if (fail) throw PlatformException(code: 'SAVE_FAILED');
    return pending?.future ?? saved;
  }
}

Future<void> pumpHistory(
  WidgetTester tester,
  HistoryCsvSaver saver, {
  bool english = false,
  bool dark = false,
  Size size = const Size(390, 844),
  double scale = 1,
  List<ParsedTransitHistory>? histories,
  int? balance = 790,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? AppTheme.dark : AppTheme.light,
      locale: Locale(english ? 'en' : 'ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: Scaffold(
          body: HistoryListPage(
            histories: histories ?? records(),
            currentBalance: balance,
            stationPairs: {0: pair()},
            onScan: () => fail('History must not start a scan'),
            stationNameDisplayMode: StationNameDisplayMode.english,
            csvSaver: saver,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<ParsedTransitHistory> records() => [
  record(
    0,
    TransitTransactionType.rail,
    const AmountCalculation.calculated(210),
    790,
  ),
  record(
    1,
    TransitTransactionType.charge,
    const AmountCalculation.balanceIncrease(1000),
    1000,
  ),
  record(
    2,
    TransitTransactionType.purchase,
    const AmountCalculation.unavailable(),
    500,
  ),
  record(
    3,
    TransitTransactionType.unknown,
    const AmountCalculation.suspicious(),
    600,
  ),
];
ParsedTransitHistory record(
  int index,
  TransitTransactionType type,
  AmountCalculation amount,
  int balance,
) => ParsedTransitHistory(
  rawBlock: RawHistoryBlock(index: index, bytes: Uint8List(16)),
  usageDate: index == 2 ? null : DateTime(2026, 11, 13),
  terminalCode: 0x16,
  processCode: 1,
  regionCode: 0,
  boardingLineCode: 1,
  boardingStationCode: 1,
  alightingLineCode: 1,
  alightingStationCode: 2,
  balance: balance,
  transactionType: type,
  amountCalculation: amount,
);
ResolvedStationPair pair() {
  StationResolution station(
    int index,
    String japanese,
    String korean,
    String english,
  ) {
    final code = StationCode(regionCode: 0, lineCode: 1, stationCode: index);
    return StationResolution(
      requestedCode: code,
      strategy: StationMatchStrategy.exactRegion,
      station: StationRecord(
        code: code,
        operatorName: 'Synthetic',
        lineName: 'Synthetic',
        stationName: japanese,
        stationNameKorean: korean,
        stationNameEnglish: english,
        source: 'synthetic',
      ),
    );
  }

  return ResolvedStationPair(
    boarding: station(1, '試験駅甲', '예시역갑', 'Example A'),
    alighting: station(2, '試験駅乙', '예시역을', 'Example B'),
  );
}
