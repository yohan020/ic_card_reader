import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_brand_identity.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/raw_history_block.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/card_brand_icon.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/card_brand_icon_frame.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_resolution.dart';
import 'package:ic_card_reader/src/features/transaction_history/domain/amount_calculation.dart';
import 'package:ic_card_reader/src/features/transaction_history/domain/parsed_transit_history.dart';
import 'package:ic_card_reader/src/features/transaction_history/domain/transit_transaction_type.dart';
import 'package:ic_card_reader/src/features/transaction_history/presentation/history_pages.dart';

const _visualPreview = bool.fromEnvironment('HISTORY_BALANCE_VISUAL_PREVIEW');

void main() {
  if (_visualPreview) {
    setUpAll(() async {
      for (final font in {
        'HistoryPreview': 'C:/Windows/Fonts/malgun.ttf',
        'MaterialIcons':
            'C:/Users/yohan/Desktop/project/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      }.entries) {
        await (FontLoader(font.key)..addFont(
              Future.value(
                ByteData.sublistView(await File(font.value).readAsBytes()),
              ),
            ))
            .load();
      }
    });
  }

  for (final dark in [false, true]) {
    for (final (size, scale) in [
      (const Size(390, 844), 1.0),
      (const Size(320, 740), 2.0),
      (const Size(844, 390), 1.0),
      (const Size(800, 1024), 1.0),
    ]) {
      testWidgets(
        'A2 balance and daily rows dark=$dark size=$size scale=$scale',
        (tester) async {
          final records = _records();
          await _pump(tester, records, dark: dark, size: size, scale: scale);
          final hero = find.byKey(const ValueKey('history-current-balance'));
          final amount = find.byKey(
            const ValueKey('history-current-balance-amount'),
          );
          final cardIcon = find.byType(CardBrandIcon);
          expect(tester.getSize(cardIcon), cardBrandBalanceSize);
          expect(find.byKey(const ValueKey('toica-icon-tile')), findsNothing);
          expect(
            tester.getRect(cardIcon).center.dx,
            closeTo(size.width / 2, .1),
          );
          expect(tester.getRect(amount).center.dx, closeTo(size.width / 2, .1));
          expect(
            tester.getRect(amount).top,
            greaterThan(tester.getRect(cardIcon).bottom),
          );
          expect(tester.widget<Text>(amount).style!.fontSize, 40);
          expect(
            tester.widget<Text>(amount).style!.fontWeight,
            FontWeight.w600,
          );
          expect(
            tester.getRect(amount).right,
            lessThanOrEqualTo(tester.getRect(hero).right),
          );
          final context = tester.element(hero);
          expect(
            Theme.of(context).scaffoldBackgroundColor,
            dark ? const Color(0xFF10171C) : AppColors.canvas,
          );
          expect(
            Theme.of(context).navigationBarTheme.backgroundColor,
            dark ? const Color(0xFF151E24) : Colors.white,
          );
          expect(tester.takeException(), isNull);
          await _preview(
            tester,
            '${dark ? 'dark' : 'light'}_${size.width.toInt()}_hero',
          );

          await _visible(tester, find.byKey(const ValueKey('history-row-0')));
          expect(find.text('2026.10.02'), findsOneWidget);
          final firstGroup = find.byKey(const ValueKey('history-date-group-0'));
          for (final index in [0, 1]) {
            expect(
              find.descendant(
                of: firstGroup,
                matching: find.byKey(ValueKey('history-row-$index')),
              ),
              findsOneWidget,
            );
            final tile = find.byKey(ValueKey('history-type-icon-$index'));
            expect(tester.getSize(tile), const Size(44, 44));
            final icon = tester.widget<Icon>(
              find.descendant(of: tile, matching: find.byType(Icon)),
            );
            expect(
              icon.size,
              isNull,
            ); // Preserve inherited Material glyph size.
            expect(IconTheme.of(tester.element(tile)).size, 24);
          }
          expect(
            find.descendant(of: firstGroup, matching: find.text('2026.10.02')),
            findsNothing,
          );
          expect(
            find.descendant(of: firstGroup, matching: find.byType(Divider)),
            findsOneWidget,
          );
          await _preview(
            tester,
            '${dark ? 'dark' : 'light'}_${size.width.toInt()}_rows',
          );
          await _visible(tester, find.byKey(const ValueKey('history-row-3')));
          expect(find.text('2026.10.01'), findsOneWidget);
          await _visible(tester, find.byKey(const ValueKey('history-row-4')));
          expect(find.text('날짜 확인 불가'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'calendar grouping preserves unsorted source order and unknown dates',
    (tester) async {
      final records = [
        _record(0, DateTime(2026, 10, 2, 23), TransitTransactionType.purchase),
        _record(1, DateTime(2026, 10, 2, 1), TransitTransactionType.bus),
        _record(2, null, TransitTransactionType.unknown),
        _record(3, DateTime(2026, 10, 1), TransitTransactionType.charge),
        _record(4, DateTime(2026, 10, 2), TransitTransactionType.rail),
      ];
      await _pump(tester, records, size: const Size(800, 1800));
      expect(find.text('2026.10.02'), findsNWidgets(2));
      expect(find.text('날짜 확인 불가'), findsOneWidget);
      expect(find.byKey(const ValueKey('history-date-group-1')), findsNothing);
      for (var index = 0; index < 4; index++) {
        final current = find.byKey(ValueKey('history-row-$index'));
        final next = find.byKey(ValueKey('history-row-${index + 1}'));
        expect(
          tester.getTopLeft(current).dy,
          lessThan(tester.getTopLeft(next).dy),
        );
      }
      expect(records.map((record) => record.rawBlock.index), [0, 1, 2, 3, 4]);
    },
  );

  testWidgets(
    'each grouped row opens its original record and returns to filter',
    (tester) async {
      final records = _records();
      await _pump(tester, records);
      for (final index in [0, 1, 2, 3, 4]) {
        final row = find.byKey(ValueKey('history-row-$index'));
        await _visible(tester, row);
        await tester.tap(row);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<HistoryDetailPage>(find.byType(HistoryDetailPage))
              .history,
          same(records[index]),
        );
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
      await _visible(
        tester,
        find.widgetWithText(FilterChip, '교통'),
        delta: -200,
      );
      await tester.tap(find.widgetWithText(FilterChip, '교통'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('history-row-0')), findsNothing);
      await _visible(tester, find.byKey(const ValueKey('history-row-1')));
      expect(find.text('2026.10.02'), findsOneWidget);
      expect(find.text('2026.10.01'), findsOneWidget);
      expect(find.text('날짜 확인 불가'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'empty and unknown balance are not fabricated; scan callback survives',
    (tester) async {
      var scans = 0;
      await _pump(tester, const [], balance: null, onScan: () => scans++);
      expect(find.text('—'), findsOneWidget);
      expect(find.text('카드 스캔 후 표시'), findsOneWidget);
      expect(find.byKey(const ValueKey('history-filter-total')), findsNothing);
      await tester.tap(find.byTooltip('IC 카드 스캔'));
      await tester.pump();
      expect(scans, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reduced motion total expands and switches filter labels safely',
    (tester) async {
      await _pump(tester, _records());
      final toggle = find.byKey(const ValueKey('history-filter-total-toggle'));
      await _visible(tester, toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('history-filter-total-details')),
        findsOneWidget,
      );
      for (final (filter, title) in [
        ('충전', '충전 합계'),
        ('미확인', '미확인 기록'),
        ('전체', '지출 합계'),
      ]) {
        final chip = find.widgetWithText(FilterChip, filter);
        await _visible(tester, chip, delta: -160);
        await tester.tap(chip);
        await tester.pumpAndSettle();
        await _visible(tester, toggle);
        expect(find.text(title), findsOneWidget);
        expect(
          find.byKey(const ValueKey('history-filter-total-details')),
          findsNothing,
        );
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('history-filter-total-details')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('large balance remains complete under enlarged text', (
    tester,
  ) async {
    await _pump(
      tester,
      const [],
      balance: 999999,
      size: const Size(320, 740),
      scale: 2,
    );
    final amount = tester.widget<Text>(
      find.byKey(const ValueKey('history-current-balance-amount')),
    );
    expect(amount.data, '¥999999');
    expect(amount.maxLines, isNull);
    expect(amount.overflow, isNot(TextOverflow.ellipsis));
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact brand icons elsewhere retain approved 42dp tile', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Center(child: CardBrandIcon(identity: CardBrandIdentity.toica)),
        ),
      ),
    );
    expect(tester.getSize(find.byType(CardBrandIcon)), const Size(42, 42));
    expect(find.byKey(const ValueKey('toica-icon-tile')), findsOneWidget);
    expect(tester.getSize(find.byType(CustomPaint).last), const Size(34, 24));
    expect(find.byType(CardBrandIconBalanceScope), findsNothing);
  });
}

Future<void> _visible(
  WidgetTester tester,
  Finder finder, {
  double delta = 160,
}) async {
  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: find.byType(Scrollable).first,
    maxScrolls: 60,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _pump(
  WidgetTester tester,
  List<ParsedTransitHistory> records, {
  bool dark = false,
  Size size = const Size(390, 844),
  double scale = 1,
  int? balance = 3240,
  VoidCallback? onScan,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  var theme = dark ? AppTheme.dark : AppTheme.light;
  if (_visualPreview) {
    theme = theme.copyWith(
      textTheme: theme.textTheme.apply(fontFamily: 'HistoryPreview'),
      appBarTheme: theme.appBarTheme.copyWith(
        titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
          fontFamily: 'HistoryPreview',
        ),
      ),
    );
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: RepaintBoundary(
          key: const ValueKey('history-preview'),
          child: child,
        ),
      ),
      home: Scaffold(
        bottomNavigationBar: NavigationBar(
          selectedIndex: 1,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), label: '홈'),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              label: '이용내역',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              label: '설정',
            ),
          ],
        ),
        body: SafeArea(
          child: HistoryListPage(
            histories: records,
            currentBalance: balance,
            brandIdentity: CardBrandIdentity.toica,
            stationPairs: {1: _pair()},
            onScan: onScan ?? () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _preview(WidgetTester tester, String name) async {
  if (!_visualPreview) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('history-preview')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('.dart_tool/history_balance_preview');
      await directory.create(recursive: true);
      await File(
        '${directory.path}/$name.png',
      ).writeAsBytes(data!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

List<ParsedTransitHistory> _records() => [
  _record(0, DateTime(2026, 10, 2), TransitTransactionType.purchase),
  _record(1, DateTime(2026, 10, 2), TransitTransactionType.rail),
  _record(2, DateTime(2026, 10, 1), TransitTransactionType.bus),
  _record(3, DateTime(2026, 10, 1), TransitTransactionType.charge),
  _record(4, null, TransitTransactionType.unknown),
];

ParsedTransitHistory _record(
  int index,
  DateTime? date,
  TransitTransactionType type,
) => ParsedTransitHistory(
  rawBlock: RawHistoryBlock(index: index, bytes: Uint8List(16)),
  usageDate: date,
  terminalCode: 0x16,
  processCode: 1,
  regionCode: 0,
  boardingLineCode: 1,
  boardingStationCode: 1,
  alightingLineCode: 1,
  alightingStationCode: 2,
  balance: 3240 + index * 300,
  transactionType: type,
  busOperatorName: type == TransitTransactionType.bus ? '시내버스' : null,
  amountCalculation: type == TransitTransactionType.charge
      ? const AmountCalculation.balanceIncrease(1500)
      : type == TransitTransactionType.unknown
      ? const AmountCalculation.unavailable()
      : const AmountCalculation.calculated(300),
);

ResolvedStationPair _pair() {
  StationResolution station(int code, String name) {
    final stationCode = StationCode(
      regionCode: 0,
      lineCode: 1,
      stationCode: code,
    );
    return StationResolution(
      requestedCode: stationCode,
      strategy: StationMatchStrategy.exactRegion,
      station: StationRecord(
        code: stationCode,
        operatorName: '합성 철도',
        lineName: '예시선',
        stationName: name,
        source: 'synthetic',
      ),
    );
  }

  return ResolvedStationPair(
    boarding: station(1, '신주쿠'),
    alighting: station(2, '시부야'),
  );
}
