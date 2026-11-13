import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/core/widgets/app_ui.dart';
import 'package:ic_card_reader/src/features/app_update/domain/app_update_service.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_reader.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_scan_result.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/current_gate_travel.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/card_reader_page.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/scan_guidance.dart';
import 'package:ic_card_reader/src/features/settings/presentation/settings_page.dart';
import 'package:ic_card_reader/src/features/station_resolver/data/asset_station_database.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_name_display.dart';

void main() {
  for (final (availability, label) in [
    (CardReaderAvailability.enabled, 'NFC가 켜져 있어요'),
    (CardReaderAvailability.disabled, 'NFC를 켜 주세요'),
    (CardReaderAvailability.unsupported, '이 기기는 NFC 읽기를 지원하지 않아요'),
    (CardReaderAvailability.unknown, 'NFC 상태를 확인하지 못했어요'),
  ]) {
    testWidgets(
      'home reflects $availability without showing first-launch help',
      (tester) async {
        await _pumpHome(tester, _Reader()..availability = availability);
        expect(find.text(label), findsOneWidget);
        expect(find.byKey(const ValueKey('nfc-status-badge')), findsOneWidget);
        final badge = tester.widget<Container>(
          find.byKey(const ValueKey('nfc-status-badge')),
        );
        final decoration = badge.decoration! as BoxDecoration;
        expect(decoration.border, isNull);
        expect(decoration.borderRadius, BorderRadius.circular(999));
        expect(
          badge.padding,
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        );
        expect(tester.widget<Text>(find.text(label)).style?.fontSize, 12);
        expect(
          tester.widget<Text>(find.text('IC 카드를 스캔해 주세요')).style?.fontWeight,
          FontWeight.w700,
        );
        expect(find.text('카드 스캔 방법'), findsNothing);
        await tester.scrollUntilVisible(find.text('IC 카드 스캔'), 100);
        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'IC 카드 스캔'),
        );
        expect(
          button.onPressed == null,
          availability == CardReaderAvailability.unsupported,
        );
      },
    );
  }

  testWidgets('unknown availability can be checked again', (tester) async {
    final reader = _Reader()..availability = CardReaderAvailability.unknown;
    await _pumpHome(tester, reader);
    reader.availability = CardReaderAvailability.enabled;
    await _tapVisible(tester, find.text('다시 확인'));
    // Removing the action shrinks its lazy list item above the scroll offset.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 300));
    await tester.pump();
    expect(find.text('NFC가 켜져 있어요'), findsOneWidget);
  });

  testWidgets(
    'settings launch failure has a manual fallback; resume refreshes status',
    (tester) async {
      final reader = _Reader()
        ..availability = CardReaderAvailability.disabled
        ..settingsOpened = false;
      await _pumpHome(tester, reader);
      await _tapVisible(tester, find.text('NFC 설정 열기'));
      expect(reader.settingsCalls, 1);
      expect(
        find.text('NFC 설정을 열지 못했어요. 휴대폰 설정에서 NFC를 확인해 주세요.'),
        findsOneWidget,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      reader.availability = CardReaderAvailability.enabled;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 300));
      await tester.pump();
      expect(find.text('NFC가 켜져 있어요'), findsOneWidget);
    },
  );

  testWidgets('NFC disabled stays inline and permits a scan after enabling', (
    tester,
  ) async {
    final reader = _Reader()
      ..availability = CardReaderAvailability.disabled
      ..failure = CardScanFailureKind.nfcUnavailable;
    await _pumpHome(tester, reader);
    await _tapVisible(tester, find.text('IC 카드 스캔'));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 300));
    await tester.pump();
    expect(find.text('NFC 설정 열기'), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    reader.availability = CardReaderAvailability.enabled;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(find.text('NFC 설정 열기'), findsNothing);
    expect(find.text('IC 카드 스캔'), findsOneWidget);
  });

  testWidgets('NFC errors from history offer settings in a sheet', (
    tester,
  ) async {
    final reader = _Reader()
      ..availability = CardReaderAvailability.disabled
      ..failure = CardScanFailureKind.nfcUnavailable;
    await _pumpHome(tester, reader);
    await tester.tap(find.text('이용내역').last);
    await tester.pump();
    await tester.tap(find.byTooltip('IC 카드 스캔'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('NFC 설정 열기'), findsOneWidget);
    await _tapVisible(tester, find.text('NFC 설정 열기'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.byType(BottomSheet), findsNothing);
    expect(reader.settingsCalls, 1);
  });

  for (final kind in CardScanFailureKind.values) {
    testWidgets('failure $kind has safe guidance and actions', (tester) async {
      int retries = 0;
      int help = 0;
      int settings = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ScanFailureView(
              kind: kind,
              availability: kind == CardScanFailureKind.nfcUnavailable
                  ? CardReaderAvailability.disabled
                  : CardReaderAvailability.enabled,
              onRetry: () => retries++,
              onHelp: () => help++,
              onOpenSettings: () => settings++,
            ),
          ),
        ),
      );
      if (kind == CardScanFailureKind.cancelled) {
        expect(find.byType(NoticeBanner), findsNothing);
        return;
      }
      expect(find.byType(NoticeBanner), findsNothing);
      expect(
        find.byIcon(Icons.contactless_outlined),
        kind == CardScanFailureKind.noHistory ? findsNothing : findsOneWidget,
      );
      await tester.tap(find.text('스캔 도움말'));
      expect(help, 1);
      if (kind == CardScanFailureKind.nfcUnavailable) {
        await tester.tap(find.text('NFC 설정 열기'));
        expect(settings, 1);
      } else {
        await tester.tap(find.text('다시 스캔'));
        expect(retries, 1);
      }
      if (kind == CardScanFailureKind.noHistory) {
        expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
      }
      if (kind == CardScanFailureKind.timedOut) {
        expect(find.text('지원하는 교통카드인지 확인해 주세요'), findsNothing);
      }
    });
  }

  testWidgets(
    'scan failures use their kind, allow retries and preserve prior result',
    (tester) async {
      final reader = _Reader();
      await _pumpHome(tester, reader);
      await _tapVisible(tester, find.text('IC 카드 스캔'));
      await tester.pump();
      expect(find.text('스캔 완료'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await tester.pump();
      final priorResult = tester
          .widget<SettingsPage>(find.byType(SettingsPage, skipOffstage: false))
          .result;
      expect(priorResult, isNotNull);
      reader.failure = CardScanFailureKind.tagLost;
      await _tapVisible(tester, find.text('IC 카드 스캔'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('카드와 통신을 완료하지 못했어요'), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(
        tester
            .widget<SettingsPage>(
              find.byType(SettingsPage, skipOffstage: false),
            )
            .result,
        same(priorResult),
      );
      reader.failure = CardScanFailureKind.noHistory;
      await _tapVisible(tester, find.text('다시 스캔'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(find.text('읽을 수 있는 이용내역이 없어요'), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(
        tester
            .widget<SettingsPage>(
              find.byType(SettingsPage, skipOffstage: false),
            )
            .result,
        same(priorResult),
      );
      expect(find.textContaining('최근 스캔 ·'), findsNothing);
      expect(reader.scans, 3);
    },
  );

  testWidgets('cancel returns without an error and permits a new scan', (
    tester,
  ) async {
    final reader = _Reader()..pending = Completer<CardScanResult>();
    await _pumpHome(tester, reader);
    await _tapVisible(tester, find.text('IC 카드 스캔'));
    expect(find.text('카드 스캔'), findsOneWidget);
    expect(find.textContaining('스캔 대기 시간'), findsOneWidget);
    expect(find.text('카드가 감지되면 여러 블록을 차례로 읽습니다.'), findsNothing);
    await tester.tap(find.byTooltip('스캔 취소'));
    await tester.pump();
    expect(find.byType(ScanFailureView), findsNothing);
    reader.pending = null;
    reader.failure = CardScanFailureKind.timedOut;
    await _tapVisible(tester, find.text('IC 카드 스캔'));
    expect(find.text('시간 안에 스캔을 완료하지 못했어요'), findsOneWidget);
  });

  testWidgets('dismissed error does not return on resume or rebuild', (
    tester,
  ) async {
    final reader = _Reader()..failure = CardScanFailureKind.tagLost;
    await _pumpHome(tester, reader);
    await _tapVisible(tester, find.text('IC 카드 스캔'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.tap(find.byTooltip('안내 닫기'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(BottomSheet), findsNothing);
    expect(reader.scans, 1);
    expect(find.text('카드와 통신을 완료하지 못했어요'), findsNothing);
  });

  testWidgets('failure help replaces the sheet instead of stacking it', (
    tester,
  ) async {
    await _pumpHome(tester, _Reader()..failure = CardScanFailureKind.tagLost);
    await _tapVisible(tester, find.text('IC 카드 스캔'));
    await tester.pump(const Duration(milliseconds: 400));
    await _tapVisible(tester, find.text('스캔 도움말'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('카드 스캔 방법'), findsOneWidget);
    expect(find.byType(ScanFailureView), findsNothing);
    await tester.tap(find.byTooltip('도움말 닫기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('retry closes the outgoing sheet before scanning again', (
    tester,
  ) async {
    final reader = _Reader()..failure = CardScanFailureKind.tagLost;
    await _pumpHome(tester, reader);
    await _tapVisible(tester, find.text('IC 카드 스캔'));
    await tester.pump(const Duration(milliseconds: 400));
    reader.failure = null;
    reader.pending = Completer<CardScanResult>();
    await _tapVisible(tester, find.text('다시 스캔'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('카드 스캔'), findsOneWidget);
    expect(reader.scans, 2);
    final title = tester.widget<Text>(find.text('카드를 움직이지 말고\n가까이 대 주세요'));
    expect(title.style?.fontWeight, FontWeight.w700);
    await tester.tap(find.byTooltip('스캔 취소'));
    await tester.pump();
  });

  for (final dark in [false, true]) {
    for (final largeText in [false, true]) {
      testWidgets(
        'scan status fits content and centers dark=$dark large=$largeText',
        (tester) async {
          final width = largeText ? 320.0 : 430.0;
          tester.view.physicalSize = Size(width, 950);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final reader = _Reader()..pending = Completer<CardScanResult>();
          await _pumpHome(
            tester,
            reader,
            dark: dark,
            textScale: largeText ? 1.7 : 1,
          );
          await _tapVisible(tester, find.text('IC 카드 스캔'));
          final pill = find.byKey(const ValueKey('scan-status-pill'));
          await tester.ensureVisible(pill);
          await tester.pump();
          final label = find.text('교통카드를 대 주세요');
          expect(tester.getCenter(pill).dx, closeTo(width / 2, .1));
          // Background fits text + 15dp icon + 5dp gap + 20dp padding.
          expect(
            tester.getSize(pill).width,
            closeTo(tester.getSize(label).width + 40, .1),
          );
          expect(tester.getSize(pill).width, lessThanOrEqualTo(width - 48));
          expect(tester.widget<Text>(label).style!.fontSize, 12);
          expect(tester.widget<Text>(label).style!.color, AppColors.skyDark);
          expect(reader.scans, 1);
          expect(tester.takeException(), isNull);
          await tester.tap(find.byTooltip('스캔 취소'));
          await tester.pump();
          await tester.pump();
          expect(find.text('카드 스캔'), findsNothing);
          expect(reader.pending!.isCompleted, isTrue);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'failure sheet scrolls at large text in ${dark ? 'dark' : 'light'} mode',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _pumpHome(
          tester,
          _Reader()..failure = CardScanFailureKind.unsupportedTag,
          dark: dark,
          textScale: 1.5,
        );
        await _tapVisible(tester, find.text('IC 카드 스캔'));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(BottomSheet), findsOneWidget);
        await _tapVisible(tester, find.text('스캔 도움말'));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('카드 스캔 방법'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'help is optional, scrollable and readable in ${dark ? 'dark' : 'light'} mode',
      (tester) async {
        tester.view.physicalSize = const Size(360, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _pumpHome(tester, _Reader(), dark: dark, textScale: 1.5);
        await _tapVisible(tester, find.text('카드를 어디에 대야 하나요?'));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('카드 스캔 방법'), findsOneWidget);
        expect(
          find.bySemanticsLabel('휴대폰 뒷면에 실물 교통카드 한 장을 가까이 대는 예시'),
          findsOneWidget,
        );
        final close = find.text('닫기');
        await _tapVisible(tester, close);
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('카드 스캔 방법'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      150,
      scrollable: find.byType(Scrollable).last,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(finder);
  await tester.pump();
  await tester.pump();
}

Future<void> _pumpHome(
  WidgetTester tester,
  _Reader reader, {
  bool dark = false,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? AppTheme.dark : AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: CardReaderPage(
        reader: reader,
        stationDatabase: AssetStationDatabase.fromCsv(
          '지역,노선,역,사업자,노선명,역명,비고\n',
        ),
        appUpdateService: _Updates(),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        onThemeModeChanged: (_) {},
        stationNameDisplayMode: StationNameDisplayMode.japanese,
        onStationNameDisplayModeChanged: (_) {},
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

class _Reader implements CardReader {
  CardReaderAvailability availability = CardReaderAvailability.enabled;
  CardScanFailureKind? failure;
  Completer<CardScanResult>? pending;
  bool settingsOpened = true;
  int settingsCalls = 0;
  int scans = 0;
  @override
  Future<CardReaderAvailability> checkAvailability() async => availability;
  @override
  Future<bool> isAvailable() async =>
      availability == CardReaderAvailability.enabled;
  @override
  Future<bool> openNfcSettings() async {
    settingsCalls++;
    return settingsOpened;
  }

  @override
  Future<void> cancel() async {
    if (pending != null && !pending!.isCompleted) {
      pending!.completeError(
        const CardScanException(CardScanFailureKind.cancelled, 'cancelled'),
      );
    }
  }

  @override
  Future<CardScanResult> scan({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    scans++;
    if (pending != null) return pending!.future;
    if (failure != null) {
      throw CardScanException(failure!, 'Internal message must not appear');
    }
    return CardScanResult(
      scannedAt: DateTime(2026, 10, 19),
      blocks: const [],
      currentGateTravel: const CurrentGateTravel(
        entryLineCode: 0xE3,
        entryStationCode: 0x58,
      ),
    );
  }
}

class _Updates implements AppUpdateService {
  @override
  Future<AppUpdateStatus> checkForUpdate() async =>
      const AppUpdateStatus.latest();
  @override
  Future<void> startUpdate(AppUpdateStatus status) async {}
}
