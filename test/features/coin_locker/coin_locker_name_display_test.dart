import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/core/localization/app_strings.dart';
import 'package:ic_card_reader/src/features/coin_locker/domain/coin_locker_catalog.dart';
import 'package:ic_card_reader/src/features/coin_locker/presentation/coin_locker_page.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_name_display.dart';

CoinLockerCatalog _catalog() => CoinLockerCatalog(
  places: [
    for (final mapped in [true, false])
      CoinLockerPlace(
        id: mapped ? 'mapped' : 'unmapped',
        region: '도쿄도',
        nameKo: mapped ? '시부야' : '翻訳未登録 · 事業者',
        nameJa: mapped ? '渋谷' : '翻訳未登録（事業者）',
        kind: 'station',
        aliases: mapped ? ['시부야', '渋谷'] : ['翻訳未登録'],
        sources: [
          CoinLockerSource(
            id: 'miitsuketa',
            links: [
              CoinLockerLink(
                label: '위치 안내',
                uri: Uri.parse('https://coin-locker.net/shibuya/'),
              ),
            ],
          ),
        ],
      ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bundled = CoinLockerCatalog.fromJson(
    jsonDecode(File('assets/data/coin_locker/catalog.json').readAsStringSync())
        as Map<String, dynamic>,
  );

  test('all locker link labels and cautions have English display values', () {
    final untranslated = RegExp(r'[가-힣ぁ-んァ-ヶ一-龯]');
    for (final place in bundled.places) {
      for (final source in place.sources) {
        expect(source.englishName, isNot(contains(untranslated)));
        for (final link in source.links) {
          expect(link.englishLabel(place), isNotEmpty);
          expect(link.englishLabel(place), isNot(contains(untranslated)));
          if (link.caution != null) {
            expect(
              link.englishCaution,
              isNot(
                'Check the guide for its exact scope and current locker information.',
              ),
            );
          }
        }
      }
    }
  });

  testWidgets(
    'English locker area, source and article labels with Japanese + English station name',
    (tester) async {
      final shinagawa = bundled.places.singleWhere(
        (place) => place.id == 'shinagawa',
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: CoinLockerPage(
            stationNameDisplayMode: StationNameDisplayMode.japaneseEnglish,
            load: () async => CoinLockerCatalog(places: [shinagawa]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Find coin lockers'), findsOneWidget);
      expect(find.text('Tokyo'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('locker-place-shinagawa')));
      await tester.pumpAndSettle();
      expect(find.text('品川'), findsOneWidget);
      expect(find.text('Shinagawa'), findsWidgets);
      expect(find.text('Coin Locker Miitsuketa'), findsOneWidget);
      expect(find.text('Coin Locker Shiori'), findsOneWidget);
      expect(find.text('Coin Locker Guide'), findsOneWidget);
      expect(find.text('JR Shinagawa Station'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  const preview = bool.fromEnvironment('LOCKER_NAME_PREVIEW');
  if (preview) {
    setUpAll(() async {
      for (final font in {
        'LockerNames': 'C:/Windows/Fonts/NotoSansKR-VF.ttf',
        'LockerNamesJa': 'C:/Windows/Fonts/NotoSansJP-VF.ttf',
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
  for (final mode in StationNameDisplayMode.values) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 3.0]) {
        testWidgets('locker names ${mode.name} dark=$dark scale=$scale', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var theme = dark ? AppTheme.dark : AppTheme.light;
          if (preview) {
            final textTheme = theme.textTheme.apply(fontFamily: 'LockerNames');
            theme = theme.copyWith(
              textTheme: textTheme.copyWith(
                bodyMedium: textTheme.bodyMedium?.copyWith(
                  fontFamilyFallback: const ['LockerNamesJa'],
                ),
              ),
              appBarTheme: theme.appBarTheme.copyWith(
                titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
                  fontFamily: 'LockerNames',
                ),
              ),
            );
          }
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: RepaintBoundary(
                  key: const ValueKey('name-preview'),
                  child: CoinLockerPage(
                    stationNameDisplayMode: mode,
                    load: () async => _catalog(),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          // Searching remains bilingual, regardless of the selected display.
          await tester.enterText(find.byType(TextField), '시부야');
          await tester.pumpAndSettle();
          final card = find.byKey(const ValueKey('locker-place-mapped'));
          expect(
            find.descendant(of: card, matching: find.text('시부야')),
            (mode == StationNameDisplayMode.japanese ||
                    mode == StationNameDisplayMode.japaneseEnglish ||
                    mode == StationNameDisplayMode.english)
                ? findsNothing
                : findsOneWidget,
          );
          expect(
            find.descendant(of: card, matching: find.text('渋谷')),
            mode == StationNameDisplayMode.korean
                ? findsNothing
                : findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          if (preview && scale == 1) {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('name-preview')),
            );
            await tester.runAsync(() async {
              final image = await boundary.toImage(pixelRatio: 1);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final dir = Directory('.private-backups/locker-names-2026-11-05');
              await dir.create(recursive: true);
              await File(
                '${dir.path}/${mode.name}-${dark ? 'dark' : 'light'}.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          await tester.enterText(find.byType(TextField), '翻訳未登録');
          await tester.pumpAndSettle();
          final fallback = find.byKey(const ValueKey('locker-place-unmapped'));
          expect(
            find.descendant(of: fallback, matching: find.text('翻訳未登録（事業者）')),
            findsOneWidget,
          );
          expect(
            find.descendant(of: fallback, matching: find.text('翻訳未登録 · 事業者')),
            findsNothing,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets(
    'mode changes keep the search, expanded links and loaded catalog',
    (tester) async {
      var mode = StationNameDisplayMode.korean;
      var loads = 0;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return CoinLockerPage(
                stationNameDisplayMode: mode,
                load: () async {
                  loads++;
                  return _catalog();
                },
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '시부야');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('locker-toggle-mapped')));
      await tester.pumpAndSettle();
      for (final next in [
        StationNameDisplayMode.japanese,
        StationNameDisplayMode.both,
      ]) {
        update(() => mode = next);
        await tester.pumpAndSettle();
        expect(find.text('위치 안내'), findsOneWidget);
        expect(find.text('코인락커 미이츠케타'), findsOneWidget);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          '시부야',
        );
        expect(loads, 1);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('locker-place-mapped')),
            matching: find.text('渋谷'),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );
}
