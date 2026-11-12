import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/core/localization/app_language.dart';
import 'package:ic_card_reader/src/core/localization/app_strings.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_scan_result.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/raw_history_block.dart';
import 'package:ic_card_reader/src/features/settings/presentation/settings_page.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_name_display.dart';

void main() {
  testWidgets('uses installed version in settings and licenses', (
    tester,
  ) async {
    const channel = MethodChannel('app.iccardreader/app_info');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) async => '2.3.4 (57)',
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(
          themeMode: ThemeMode.system,
          onThemeModeChanged: (_) {},
          onClearSession: () {},
          stationNameDisplayMode: StationNameDisplayMode.japanese,
          onStationNameDisplayModeChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('앱 버전'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    expect(find.text('2.3.4 (57)'), findsOneWidget);
    expect(find.text('1.0.0'), findsNothing);
    await tester.dragUntilVisible(
      find.text('오픈소스 라이선스'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await Scrollable.ensureVisible(
      tester.element(find.text('오픈소스 라이선스')),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('오픈소스 라이선스'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
    expect(find.text('2.3.4 (57)'), findsOneWidget);
  });

  for (final dark in [false, true]) {
    testWidgets(
      'language choices share one card and fit long values dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: SettingsPage(
              themeMode: ThemeMode.system,
              onThemeModeChanged: (_) {},
              onClearSession: () {},
              stationNameDisplayMode: StationNameDisplayMode.japaneseEnglish,
              onStationNameDisplayModeChanged: (_) {},
              onAppLanguageChanged: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        final group = find.byKey(const ValueKey('settings-language-group'));
        await tester.scrollUntilVisible(group, 160);
        expect(
          find.descendant(of: group, matching: find.text('App language')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: group, matching: find.text('Station names')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: group, matching: find.byType(Card)),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: group,
            matching: find.byIcon(Icons.language_rounded),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: group,
            matching: find.byIcon(Icons.translate_rounded),
          ),
          findsNothing,
        );
        expect(find.text('Japanese + English'), findsOneWidget);
        expect(
          tester.getTopLeft(find.text('Japanese + English')).dx,
          greaterThan(tester.getTopLeft(find.text('Station names')).dx),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('puts privacy last and hides development-only settings', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(
          themeMode: ThemeMode.system,
          onThemeModeChanged: (_) {},
          onClearSession: () {},
          stationNameDisplayMode: StationNameDisplayMode.japanese,
          onStationNameDisplayModeChanged: (_) {},
        ),
      ),
    );

    expect(find.text('기본 처리는 기기 안에서'), findsNothing);
    expect(find.text('개발자 정보'), findsNothing);

    await tester.scrollUntilVisible(find.text('개인정보 및 데이터'), 200);
    expect(find.text('앱 정보'), findsOneWidget);
    expect(find.text('개인정보 및 데이터'), findsOneWidget);
  });

  testWidgets('uses the app dialog style when clearing the current history', (
    tester,
  ) async {
    var cleared = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SettingsPage(
          result: CardScanResult(
            scannedAt: DateTime(2026, 8, 12),
            blocks: [
              RawHistoryBlock(
                index: 0,
                bytes: Uint8List.fromList(List<int>.filled(16, 0)),
              ),
            ],
          ),
          themeMode: ThemeMode.system,
          onThemeModeChanged: (_) {},
          onClearSession: () => cleared = true,
          stationNameDisplayMode: StationNameDisplayMode.japanese,
          onStationNameDisplayModeChanged: (_) {},
        ),
      ),
    );

    await tester.dragUntilVisible(
      find.text('현재 이용내역 지우기'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.ensureVisible(find.text('현재 이용내역 지우기'));
    await tester.pump();
    await tester.tap(find.text('현재 이용내역 지우기'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('clear-history-dialog')), findsOneWidget);
    expect(find.text('현재 이용내역을 지울까요?'), findsOneWidget);
    expect(find.text('실물 카드 안의 데이터는 변경되지 않습니다.'), findsOneWidget);

    final confirm = find.byKey(const ValueKey('confirm-clear-history'));
    final cancel = find.byKey(const ValueKey('cancel-clear-history'));
    expect(
      tester.getTopLeft(confirm).dy,
      lessThan(tester.getTopLeft(cancel).dy),
    );

    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(cleared, isTrue);
    expect(find.byKey(const ValueKey('clear-history-dialog')), findsNothing);
  });

  testWidgets(
    'language sheets are scrollable and dismiss without changing the selection',
    (tester) async {
      tester.view.physicalSize = const Size(667, 375);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      StationNameDisplayMode? chosen;
      AppLanguage? language;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: SettingsPage(
            themeMode: ThemeMode.system,
            onThemeModeChanged: (_) {},
            onClearSession: () {},
            stationNameDisplayMode: StationNameDisplayMode.japanese,
            onStationNameDisplayModeChanged: (value) => chosen = value,
            onAppLanguageChanged: (value) => language = value,
          ),
        ),
      );

      await tester.pumpAndSettle();
      final appLanguage = find.text('App language');
      await tester.ensureVisible(appLanguage);
      await tester.pumpAndSettle();
      await tester.tap(appLanguage);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      final bottomSheet = find.byType(BottomSheet);
      expect(
        find.descendant(of: bottomSheet, matching: find.byType(Divider)),
        findsNWidgets(3),
      );
      expect(
        find.descendant(
          of: bottomSheet,
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );
      final close = find.byTooltip('Close');
      expect(tester.getSize(close).shortestSide, greaterThanOrEqualTo(48));
      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(bottomSheet, findsNothing);
      expect(language, isNull);

      await tester.ensureVisible(appLanguage);
      await tester.pumpAndSettle();
      await tester.tap(appLanguage);
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(language, isNull);
      final stationNames = find.text('Station names');
      await tester.scrollUntilVisible(stationNames, 160);
      await tester.ensureVisible(stationNames);
      await tester.tap(stationNames);
      await tester.pumpAndSettle();
      final bilingual = find.byKey(
        const ValueKey(StationNameDisplayMode.japaneseEnglish),
      );
      await tester.ensureVisible(bilingual);
      await tester.tap(bilingual);
      await tester.pumpAndSettle();
      expect(chosen, StationNameDisplayMode.japaneseEnglish);
      expect(tester.takeException(), isNull);
    },
  );
}
