import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/app_update/domain/app_update_service.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_comparison_session.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_brand_identity.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_reader.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_scan_result.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/raw_history_block.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/card_comparison_page.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/card_reader_page.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/card_brand_icon.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/icoca_card_icon.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/pasmo_card_icon.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/pitapa_card_icon.dart';
import 'package:ic_card_reader/src/features/station_resolver/data/asset_station_database.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_name_display.dart';
import 'package:ic_card_reader/src/features/transaction_history/presentation/history_pages.dart';

const _visualPreview = bool.fromEnvironment('CARD_COMPARISON_VISUAL_PREVIEW');

void main() {
  if (_visualPreview) {
    setUpAll(() async {
      for (final entry in {
        'ComparisonPreview': 'C:/Windows/Fonts/malgun.ttf',
        'MaterialIcons':
            'C:/Users/yohan/Desktop/project/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      }.entries) {
        final loader = FontLoader(entry.key)
          ..addFont(
            Future.value(
              ByteData.sublistView(await File(entry.value).readAsBytes()),
            ),
          );
        await loader.load();
      }
    });
    for (final dark in [false, true]) {
      testWidgets('applied comparison visual preview dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(430, 950);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final reader = _Reader()
          ..incoming.addAll([(1, 3200), (2, 800), (3, 1600), (4, 1234)])
          ..brands.addAll({
            1: CardBrandIdentity.icoca,
            2: CardBrandIdentity.icoca,
            3: CardBrandIdentity.pasmo,
            4: CardBrandIdentity.ica,
          });
        await _pump(tester, reader, dark: dark);
        await _tap(tester, find.text('비교 열기'));
        for (var i = 0; i < 4; i++) {
          await _tap(tester, find.text('카드 추가'));
        }
        await tester.pump(const Duration(seconds: 5));
        await _frames(tester);
        await tester.drag(find.byType(Scrollable).last, const Offset(0, 1000));
        await _frames(tester);
        expect(tester.takeException(), isNull);
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('comparison-preview')),
        );
        await tester.runAsync(() async {
          final rendered = await boundary.toImage(pixelRatio: 1.5);
          try {
            final bytes = await rendered.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final dir = Directory('.dart_tool/card_comparison_preview');
            await dir.create(recursive: true);
            await File(
              '${dir.path}/comparison_${dark ? 'dark' : 'light'}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
          } finally {
            rendered.dispose();
          }
        });
        await _tap(tester, find.text('전체 삭제'));
        await tester.runAsync(() async {
          final rendered = await boundary.toImage(pixelRatio: 1.5);
          try {
            final bytes = await rendered.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '.dart_tool/card_comparison_preview/clear_${dark ? 'dark' : 'light'}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
          } finally {
            rendered.dispose();
          }
        });
      });
    }
  }
  for (final dark in [false, true]) {
    testWidgets('Suica names and compact vertically centered balance ($dark)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 950);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final reader = _Reader()
        ..incoming.addAll([(1, 900), (2, 800)])
        ..brands.addAll({
          1: CardBrandIdentity.suicaFamily,
          2: CardBrandIdentity.suicaFamily,
        });
      await _pump(tester, reader, dark: dark);
      await _tap(tester, find.text('비교 열기'));
      await _tap(tester, find.text('카드 추가'));
      await _tap(tester, find.text('카드 추가'));
      expect(find.text('스이카'), findsOneWidget);
      expect(find.text('스이카1'), findsOneWidget);
      expect(find.text('스이카 계열'), findsNothing);
      final first = find.byKey(const ValueKey('compared-card-1'));
      final second = find.byKey(const ValueKey('compared-card-2'));
      for (final entry in [(first, '¥900'), (second, '¥800')]) {
        final amount = find.descendant(
          of: entry.$1,
          matching: find.text(entry.$2),
        );
        expect(
          tester.getCenter(amount).dy,
          closeTo(tester.getCenter(entry.$1).dy, .1),
        );
        final text = tester.widget<Text>(amount);
        expect(text.style!.fontSize, 20);
        expect(text.style!.fontWeight, FontWeight.w600);
        final icon = find.descendant(
          of: entry.$1,
          matching: find.byType(CardBrandIcon),
        );
        expect(tester.getSize(icon), const Size(42, 42));
        expect(
          tester
              .widgetList<Padding>(
                find.descendant(of: entry.$1, matching: find.byType(Padding)),
              )
              .any(
                (padding) =>
                    padding.padding == const EdgeInsets.fromLTRB(16, 12, 0, 12),
              ),
          isTrue,
        );
      }
      expect(
        tester.getRect(second).top - tester.getRect(first).bottom,
        closeTo(10, .1),
      );
      expect(tester.takeException(), isNull);
    });
    testWidgets(
      'brand naming, icons, rename, unknown rescan and per-card details ($dark)',
      (tester) async {
        final reader = _Reader()
          ..incoming.addAll([(1, 1200), (2, 500), (3, 700), (1, 900)])
          ..brands.addAll({
            1: CardBrandIdentity.icoca,
            2: CardBrandIdentity.icoca,
            3: CardBrandIdentity.pasmo,
          });
        await _pump(tester, reader, dark: dark);
        await _tap(tester, find.text('비교 열기'));
        for (var i = 0; i < 3; i++) {
          await _tap(tester, find.text('카드 추가'));
        }
        expect(find.text('이코카'), findsOneWidget);
        expect(find.text('이코카1'), findsOneWidget);
        expect(find.text('파스모'), findsOneWidget);
        expect(find.byType(IcocaCardIcon), findsNWidgets(2));
        expect(find.byType(PasmoCardIcon), findsOneWidget);
        expect(find.byType(PitapaCardIcon), findsNothing);
        await _menu(tester, '이코카', '이름 변경');
        await tester.enterText(find.byType(TextFormField), '아빠 카드');
        await _tap(tester, find.text('변경'));
        reader.brands.remove(1); // optional probe unavailable on this rescan.
        await _tap(tester, find.text('카드 추가'));
        expect(find.text('비교 중인 카드 3장'), findsOneWidget);
        expect(find.text('아빠 카드'), findsOneWidget);
        expect(find.text('¥900'), findsOneWidget);
        expect(find.byType(IcocaCardIcon), findsNWidgets(2));
        await _tap(tester, find.text('아빠 카드'));
        expect(find.text('현재 이코카 잔액'), findsOneWidget);
        expect(find.byType(IcocaCardIcon), findsOneWidget);
        await tester.pageBack();
        await _frames(tester);
        await _menu(tester, '이코카1', '삭제');
        reader.incoming.add((4, 800));
        reader.brands[4] = CardBrandIdentity.icoca;
        await _tap(tester, find.text('카드 추가'));
        expect(find.text('이코카2'), findsOneWidget);
        expect(find.text('이코카1'), findsNothing);
        await _tap(tester, find.text('전체 삭제'));
        await _tap(
          tester,
          find.byKey(const ValueKey('comparison-clear-cancel')),
        );
        expect(find.text('비교 중인 카드 3장'), findsOneWidget);
        expect(find.text('아빠 카드'), findsOneWidget);
        await _tap(tester, find.text('전체 삭제'));
        await _tap(
          tester,
          find.byKey(const ValueKey('comparison-clear-confirm')),
        );
        reader.incoming.add((5, 400));
        reader.brands[5] = CardBrandIdentity.icoca;
        await _tap(tester, find.text('카드 추가'));
        expect(find.text('이코카'), findsOneWidget);
        expect(find.text('비교 중인 카드 1장'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'all ten brands preserve approved icons at narrow large text ($dark)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final reader = _Reader();
        await _pump(tester, reader, dark: dark, scale: 1.7);
        await _tap(tester, find.text('비교 열기'));
        var id = 1;
        for (final brand in CardBrandIdentity.values) {
          reader.incoming.add((id, 65535));
          reader.brands[id++] = brand;
          await _tap(tester, find.text('카드 추가'));
          final tile = find.byKey(ValueKey('compared-card-${id - 1}'));
          await tester.scrollUntilVisible(
            tile,
            150,
            scrollable: find.byType(Scrollable).last,
          );
          await tester.ensureVisible(tile);
          await _frames(tester);
          expect(
            find.descendant(of: tile, matching: find.text(brand.label)),
            findsOneWidget,
          );
          final icon = find.descendant(
            of: tile,
            matching: find.byType(CardBrandIcon),
          );
          expect(tester.getSize(icon), const Size(42, 42));
          expect(tester.widget<CardBrandIcon>(icon).identity, brand);
          expect(
            find.descendant(of: tile, matching: find.byType(PitapaCardIcon)),
            findsNothing,
          );
          expect(tester.takeException(), isNull);
        }
        await tester.scrollUntilVisible(
          find.text('비교 중인 카드 10장'),
          -300,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.text('비교 중인 카드 10장'), findsOneWidget);
      },
    );
    testWidgets(
      'adds, deduplicates, renames, opens details and clears (${dark ? 'dark' : 'light'})',
      (tester) async {
        final reader = _Reader()
          ..incoming.addAll([(1, 1200), (2, 500), (1, 900)]);
        await _pump(tester, reader, dark: dark);
        await _tap(tester, find.text('비교 열기'));
        await _tap(tester, find.text('카드 추가'));
        await _tap(tester, find.text('카드 추가'));
        expect(find.text('비교 중인 카드 2장'), findsOneWidget);
        await _menu(tester, '카드 1', '이름 변경');
        await tester.enterText(find.byType(TextFormField), '엄마 카드');
        await _tap(tester, find.text('변경'));
        await _tap(tester, find.text('카드 추가'));
        expect(find.text('비교 중인 카드 2장'), findsOneWidget);
        expect(find.text('엄마 카드'), findsOneWidget);
        expect(find.text('¥900'), findsOneWidget);
        expect(find.text('¥1200'), findsNothing);
        await _tap(tester, find.text('엄마 카드'));
        expect(find.text('현재 카드 잔액'), findsOneWidget);
        expect(find.text('¥900'), findsOneWidget);
        await _tap(tester, find.text('철도 이용').first);
        expect(find.text('이용내역 상세'), findsOneWidget);
        await tester.pageBack();
        await _frames(tester);
        await tester.pageBack();
        await _frames(tester);
        await _menu(tester, '카드 2', '삭제');
        expect(find.text('비교 중인 카드 1장'), findsOneWidget);
        await _tap(tester, find.text('전체 삭제'));
        await _tap(
          tester,
          find.byKey(const ValueKey('comparison-clear-confirm')),
        );
        expect(find.text('비교 중인 카드 0장'), findsOneWidget);
        expect(find.text('엄마 카드'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'comparison list fits narrow large text (${dark ? 'dark' : 'light'})',
      (tester) async {
        tester.view.physicalSize = const Size(360, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final reader = _Reader()..incoming.add((1, 65535));
        await _pump(tester, reader, dark: dark, scale: 1.5);
        await _tap(tester, find.text('비교 열기'));
        await _tap(tester, find.text('카드 추가'));
        expect(find.text('¥65535'), findsOneWidget);
        await _menu(tester, '카드 1', '이름 변경');
        await tester.enterText(find.byType(TextFormField), '이름이 긴 가족의 교통카드');
        await _tap(tester, find.text('변경'));
        expect(find.text('이름이 긴 가족의 교통카드'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'cancel and late completion never append; retries are serialized',
    (tester) async {
      final reader = _Reader()..incoming.add((1, 700));
      await _pump(tester, reader);
      await _tap(tester, find.text('비교 열기'));
      await _tap(tester, find.text('카드 추가'));
      reader.pending = Completer<CardScanResult>();
      await _tap(tester, find.text('카드 추가'));
      expect(find.text('비교 스캔 중'), findsOneWidget);
      await _tap(tester, find.text('취소'));
      expect(find.text('비교 중인 카드 1장'), findsOneWidget);
      expect(reader.cancelCalls, 1);
      reader.pending = null;
      reader.incoming.add((2, 800));
      await _tap(tester, find.text('카드 추가'));
      expect(find.text('비교 중인 카드 2장'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failure retry and wrong-card rescan preserve prior snapshots', (
    tester,
  ) async {
    final reader = _Reader()..incoming.add((1, 700));
    await _pump(tester, reader);
    await _tap(tester, find.text('비교 열기'));
    await _tap(tester, find.text('카드 추가'));
    reader.failure = CardScanFailureKind.tagLost;
    await _tap(tester, find.text('카드 추가'));
    expect(find.text('카드와 통신을 완료하지 못했어요'), findsOneWidget);
    reader.failure = null;
    reader.incoming.add((2, 800));
    await _tap(tester, find.widgetWithText(FilledButton, '다시 스캔'));
    expect(find.text('비교 중인 카드 2장'), findsOneWidget);
    reader.incoming.add((2, 100));
    await _menu(tester, '카드 1', '다시 스캔');
    expect(find.text('¥700'), findsOneWidget);
    expect(find.text('¥800'), findsOneWidget);
    expect(find.textContaining('선택한 카드와 다른 카드'), findsOneWidget);
  });

  testWidgets('exit confirmation clears session and rotates its identity key', (
    tester,
  ) async {
    final reader = _Reader()..incoming.addAll([(1, 1000), (1, 900)]);
    await _pump(tester, reader);
    await _tap(tester, find.text('비교 열기'));
    await _tap(tester, find.text('카드 추가'));
    final previousKey = reader.keys.single;
    await _tap(tester, find.byTooltip('비교 종료'));
    await _tap(tester, find.text('취소'));
    expect(find.text('카드 1'), findsOneWidget);
    await _tap(tester, find.byTooltip('비교 종료'));
    await _tap(tester, find.text('종료'));
    await _tap(tester, find.text('비교 열기'));
    expect(find.text('비교 중인 카드 0장'), findsOneWidget);
    await _tap(tester, find.text('카드 추가'));
    expect(reader.keys.last, isNot(previousKey));
    expect(find.text('카드 1'), findsOneWidget);
    expect(find.text('¥900'), findsOneWidget);
  });

  testWidgets('comparison never replaces the home single-card result', (
    tester,
  ) async {
    final reader = _Reader()..incoming.add((1, 100));
    await _pump(tester, reader, home: true);
    await _tap(tester, find.widgetWithText(FilledButton, 'IC 카드 스캔'));
    await _tap(tester, find.widgetWithText(FilledButton, '이용내역 보기'));
    expect(find.text('¥4321'), findsOneWidget);
    await _tap(tester, find.text('홈').last);
    await _tap(tester, find.text('여러 카드 잔액 비교'));
    await _tap(tester, find.text('카드 추가'));
    expect(find.text('¥100'), findsOneWidget);
    await _tap(tester, find.byTooltip('비교 종료'));
    await _tap(tester, find.text('종료'));
    await _tap(tester, find.text('이용내역').last);
    expect(find.text('¥4321'), findsOneWidget);
    final history = tester.widget<HistoryListPage>(
      find.byType(HistoryListPage),
    );
    expect(history.currentBalance, 4321);
    expect(history.histories.first.balance, 4321);
    expect(find.byType(CardComparisonPage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _frames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  // A transient success snackbar can cover a bottom-aligned add button on a
  // narrow viewport. Wait for dismissal before the next simulated tap.
  if (find.byType(SnackBar).evaluate().isNotEmpty) {
    await tester.pump(const Duration(seconds: 5));
    await _frames(tester);
  }
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      150,
      scrollable: find.byType(Scrollable).last,
    );
  }
  await tester.ensureVisible(finder);
  await _frames(tester);
  await tester.tap(finder);
  await _frames(tester);
}

Future<void> _menu(WidgetTester tester, String card, String action) async {
  await _tap(tester, find.byTooltip('$card 메뉴'));
  await _tap(tester, find.text(action));
}

Future<void> _pump(
  WidgetTester tester,
  _Reader reader, {
  bool dark = false,
  double scale = 1,
  bool home = false,
}) async {
  final database = AssetStationDatabase.fromCsv('지역,노선,역,사업자,노선명,역명,비고\n');
  await tester.pumpWidget(
    MaterialApp(
      theme: _visualPreview
          ? (dark ? AppTheme.dark : AppTheme.light).copyWith(
              textTheme: (dark ? AppTheme.dark : AppTheme.light).textTheme
                  .apply(fontFamily: 'ComparisonPreview'),
              primaryTextTheme: (dark ? AppTheme.dark : AppTheme.light)
                  .primaryTextTheme
                  .apply(fontFamily: 'ComparisonPreview'),
            )
          : dark
          ? AppTheme.dark
          : AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: RepaintBoundary(
          key: const ValueKey('comparison-preview'),
          child: child!,
        ),
      ),
      home: home
          ? CardReaderPage(
              reader: reader,
              stationDatabase: database,
              appUpdateService: _Updates(),
              themeMode: ThemeMode.light,
              onThemeModeChanged: (_) {},
              stationNameDisplayMode: StationNameDisplayMode.japanese,
              onStationNameDisplayModeChanged: (_) {},
            )
          : Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CardComparisonPage(
                          reader: reader,
                          stationDatabase: Future.value(database),
                          stationNameDisplayMode:
                              StationNameDisplayMode.japanese,
                          scanScreenBuilder: (cancel) => Scaffold(
                            body: Column(
                              children: [
                                const Text('비교 스캔 중'),
                                TextButton(
                                  onPressed: cancel,
                                  child: const Text('취소'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('비교 열기'),
                ),
              ),
            ),
    ),
  );
  await _frames(tester);
}

class _Reader implements CardReader, ComparisonCardReader {
  final incoming = Queue<(int, int)>();
  final keys = <List<int>>[];
  final brands = <int, CardBrandIdentity>{};
  CardScanFailureKind? failure;
  Completer<CardScanResult>? pending;
  int cancelCalls = 0;
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<CardReaderAvailability> checkAvailability() async =>
      CardReaderAvailability.enabled;
  @override
  Future<bool> openNfcSettings() async => true;
  @override
  Future<void> cancel() async {
    cancelCalls++;
    if (pending != null && !pending!.isCompleted) {
      pending!.completeError(
        const CardScanException(CardScanFailureKind.cancelled, 'cancelled'),
      );
    }
  }

  @override
  Future<CardScanResult> scan({
    Duration timeout = const Duration(seconds: 30),
  }) async => _result(4321);
  @override
  Future<CardScanResult> scanForComparison({
    required List<int> sessionKey,
  }) async {
    keys.add(List.of(sessionKey));
    if (pending != null) return pending!.future;
    if (failure != null) throw CardScanException(failure!, 'internal detail');
    final (id, balance) = incoming.removeFirst();
    return _result(
      balance,
      token: comparisonTokenFor(List.filled(8, id), sessionKey),
      brand: brands[id],
    );
  }
}

CardScanResult _result(
  int balance, {
  String? token,
  CardBrandIdentity? brand,
}) => CardScanResult(
  scannedAt: DateTime(2026, 10, 23, 14, 32),
  comparisonToken: token,
  brandIdentity: brand,
  blocks: [
    for (var index = 0; index < 2; index++)
      RawHistoryBlock(
        index: index,
        bytes: Uint8List.fromList([
          0x16,
          0x01,
          0,
          0,
          0x35,
          0x57,
          0xA5,
          0x78,
          0xAC,
          0x38,
          (balance + index * 100) & 255,
          (balance + index * 100) >> 8,
          0,
          0,
          0,
          0,
        ]),
      ),
  ],
);

class _Updates implements AppUpdateService {
  @override
  Future<AppUpdateStatus> checkForUpdate() async =>
      const AppUpdateStatus.latest();
  @override
  Future<void> startUpdate(AppUpdateStatus status) async {}
}
