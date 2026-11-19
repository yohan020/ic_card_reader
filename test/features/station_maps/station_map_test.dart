import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/l10n/app_localizations.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/coin_locker/domain/coin_locker_catalog.dart';
import 'package:ic_card_reader/src/features/station_maps/domain/station_map_catalog.dart';
import 'package:ic_card_reader/src/features/station_maps/data/station_map_repository.dart';
import 'package:ic_card_reader/src/features/station_maps/presentation/station_map_page.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_name_display.dart';

Map<String, dynamic> rawMaps() =>
    jsonDecode(File('assets/data/station_maps/catalog.json').readAsStringSync())
        as Map<String, dynamic>;
CoinLockerCatalog names() => CoinLockerCatalog.fromJson(
  jsonDecode(File('assets/data/coin_locker/catalog.json').readAsStringSync())
      as Map<String, dynamic>,
);
StationMapCatalog fixture() => StationMapCatalog.fromJson(rawMaps(), names());

Widget app(
  Widget page, {
  String language = 'ko',
  bool dark = false,
  double scale = 1,
}) => RepaintBoundary(
  key: const ValueKey('map-app-preview'),
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: Locale(language),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: const bool.fromEnvironment('STATION_MAP_PREVIEW')
        ? (dark ? AppTheme.dark : AppTheme.light).copyWith(
            textTheme: (dark ? AppTheme.dark : AppTheme.light).textTheme.apply(
              fontFamily: 'Preview',
            ),
            primaryTextTheme: (dark ? AppTheme.dark : AppTheme.light)
                .primaryTextTheme
                .apply(fontFamily: 'Preview'),
            filledButtonTheme: FilledButtonThemeData(
              style: (dark ? AppTheme.dark : AppTheme.light)
                  .filledButtonTheme
                  .style
                  ?.copyWith(
                    textStyle: const WidgetStatePropertyAll(
                      TextStyle(
                        fontFamily: 'Preview',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
            ),
            appBarTheme: (dark ? AppTheme.dark : AppTheme.light).appBarTheme
                .copyWith(
                  titleTextStyle:
                      const TextStyle(
                        fontFamily: 'Preview',
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ).copyWith(
                        color: (dark ? AppTheme.dark : AppTheme.light)
                            .colorScheme
                            .onSurface,
                      ),
                ),
          )
        : dark
        ? AppTheme.dark
        : AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
      child: child!,
    ),
    home: RepaintBoundary(key: const ValueKey('map-preview'), child: page),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const preview = bool.fromEnvironment('STATION_MAP_PREVIEW');
  if (preview) {
    setUpAll(() async {
      for (final entry in {
        'Preview': 'C:/Windows/Fonts/malgun.ttf',
        'MaterialIcons':
            'C:/Users/yohan/Desktop/project/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      }.entries) {
        await (FontLoader(entry.key)..addFont(
              Future.value(
                ByteData.sublistView(await File(entry.value).readAsBytes()),
              ),
            ))
            .load();
      }
    });
  }
  test(
    'asset contains only verified links and retains searchable multilingual place IDs',
    () {
      final catalog = fixture();
      expect(catalog.browserCatalog.places.length, 881);
      expect(catalog.links.values.expand((x) => x).length, 1090);
      for (final q in ['도쿄', '東京', 'Tokyo']) {
        expect(
          catalog.browserCatalog.search(q).map((p) => p.id),
          contains('tokyo'),
        );
      }
      expect(catalog.browserCatalog.search('도쿄', region: '교토부'), isEmpty);
      expect(
        catalog.links.values
            .expand((x) => x)
            .every((m) => isAllowedStationMapUri(m.uri)),
        isTrue,
      );
    },
  );
  test('unsafe schemes, credentials, suffix hosts and ports rejected', () {
    for (final u in [
      'http://www.jreast.co.jp/a',
      'https://www.jreast.co.jp.evil.test/a',
      'https://bad@www.jreast.co.jp/a',
      'https://www.jreast.co.jp:99/a',
      'javascript:alert(1)',
      'file:///tmp/a',
    ]) {
      expect(isAllowedStationMapUri(Uri.parse(u)), isFalse, reason: u);
    }
  });
  test('schema rejects unknown place IDs and duplicate maps', () {
    final raw = rawMaps();
    (raw['places'] as List).first['placeId'] = 'not_a_station';
    expect(
      () => StationMapCatalog.fromJson(raw, names()),
      throwsFormatException,
    );
    final second = rawMaps();
    final rows = second['places'] as List;
    rows.add(rows.first);
    expect(
      () => StationMapCatalog.fromJson(second, names()),
      throwsFormatException,
    );
  });
  test(
    'repository caches its future and supports generated bundled data',
    () async {
      final bundle = _Bundle(), repo = StationMapRepository(bundle: _Bundle());
      final first = repo.load(), second = repo.load();
      expect(identical(first, second), isTrue);
      expect((await first).browserCatalog.places.length, 881);
      final another = StationMapRepository(bundle: bundle);
      await another.load();
      await another.load();
      expect(bundle.loads['assets/data/station_maps/catalog.json'], 1);
    },
  );
  for (final language in ['ko', 'en']) {
    for (final mode in StationNameDisplayMode.values) {
      testWidgets(
        'station settings $language $mode apply to list and map links',
        (tester) async {
          final data = fixture();
          await tester.pumpWidget(
            app(
              StationMapPage(
                load: () => Future.value(data),
                stationNameDisplayMode: mode,
              ),
              language: language,
            ),
          );
          await tester.pumpAndSettle();
          final toggle = find.byKey(const ValueKey('locker-toggle-tokyo'));
          await tester.tap(toggle);
          await tester.pumpAndSettle();
          final name = switch (mode) {
            StationNameDisplayMode.korean => '도쿄',
            StationNameDisplayMode.both => '도쿄',
            StationNameDisplayMode.english => 'Tokyo',
            StationNameDisplayMode.japaneseEnglish => '東京',
            _ => '東京',
          };
          expect(find.text(name), findsWidgets);
          expect(
            find.text(language == 'en' ? 'JR East' : 'JR 동일본'),
            findsOneWidget,
          );
          expect(
            find.textContaining(
              language == 'en' ? 'Station name settings' : '역명 표기 설정',
            ),
            findsNothing,
          );
          expect(
            find.byKey(const ValueKey('station-map-help')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  for (final language in ['ko', 'en']) {
    for (final dark in [false, true]) {
      for (final spec in [
        (const Size(375, 812), 1.0),
        (const Size(320, 740), 2.0),
        (const Size(844, 390), 1.0),
        (const Size(768, 1024), 1.0),
      ]) {
        testWidgets(
          'locker layout reused $language dark=$dark ${spec.$1} scale=${spec.$2}',
          (tester) async {
            tester.view.physicalSize = spec.$1;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final semantics = tester.ensureSemantics();
            await tester.pumpWidget(
              app(
                StationMapPage(
                  load: () => Future.value(fixture()),
                  stationNameDisplayMode:
                      StationNameDisplayMode.japaneseEnglish,
                ),
                language: language,
                dark: dark,
                scale: spec.$2,
              ),
            );
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const ValueKey('locker-toggle-tokyo')));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            if (preview && spec.$1.width == 375) {
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(const ValueKey('map-preview')),
              );
              await tester.runAsync(() async {
                final image = await boundary.toImage(pixelRatio: 2);
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final file = File(
                  '.dart_tool/station-map-preview/$language-$dark.png',
                );
                await file.parent.create(recursive: true);
                await file.writeAsBytes(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }
            final help = find.byKey(const ValueKey('station-map-help'));
            expect(tester.getSize(help).width, greaterThanOrEqualTo(48));
            expect(tester.getSize(help).height, greaterThanOrEqualTo(48));
            await tester.tap(help);
            await tester.pumpAndSettle();
            expect(
              find.text(
                language == 'en'
                    ? 'Official maps from station operators open in your browser.'
                    : '운영사가 제공하는 공식 구내도를 외부 브라우저에서 열어요.',
              ),
              findsOneWidget,
            );
            expect(
              find.textContaining(
                language == 'en' ? 'Station name settings' : '역명 표기 설정',
              ),
              findsOneWidget,
            );
            expect(
              find.textContaining(
                language == 'en' ? 'Each map covers' : '지도는 운영사별',
              ),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
            if (preview && spec.$1.width == 375) {
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(const ValueKey('map-app-preview')),
              );
              await tester.runAsync(() async {
                final image = await boundary.toImage(pixelRatio: 2);
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                await File(
                  '.dart_tool/station-map-preview/help-$language-$dark.png',
                ).writeAsBytes(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }
            await tester.tap(find.byTooltip(language == 'en' ? 'Close' : '닫기'));
            await tester.pumpAndSettle();
            expect(
              find.text(language == 'en' ? 'JR East' : 'JR 동일본'),
              findsOneWidget,
            );
            semantics.dispose();
          },
        );
      }
    }
  }
  testWidgets(
    'A map card groups operators and keeps compact accessible links',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final data = fixture();
      await tester.pumpWidget(
        app(
          StationMapPage(
            load: () async => data,
            stationNameDisplayMode: StationNameDisplayMode.korean,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '시부야');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('locker-toggle-shibuya')));
      await tester.pumpAndSettle();
      final body = find.byKey(const ValueKey('station-maps-shibuya'));
      final links = data.links['shibuya']!;
      expect(
        find.descendant(of: body, matching: find.byType(Divider)),
        findsNWidgets(links.map((l) => l.operatorJa).toSet().length - 1),
      );
      for (final link in links) {
        expect(
          tester
              .getSize(find.byKey(ValueKey('station-map-link-${link.id}')))
              .height,
          greaterThanOrEqualTo(48),
        );
      }
      for (final repeated in [
        '공식 구내도',
        'Official map',
        '일본어',
        'Japanese',
        '영어',
        'English',
      ]) {
        expect(find.text(repeated), findsNothing);
      }
      expect(find.text('이노카시라선'), findsOneWidget);
      expect(find.text('게이오 전철'), findsNothing);
      expect(
        find.descendant(of: body, matching: find.text('시부야')),
        findsNothing,
      );
      expect(tester.getSize(body).height, lessThan(300));
      expect(tester.takeException(), isNull);
      if (preview) {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('map-preview')),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '.dart_tool/station-map-preview/A-shibuya.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    },
  );
  testWidgets(
    'plain header help stays reachable and dismissal preserves query',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(
        app(StationMapPage(load: () => Future.value(fixture()))),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '도쿄');
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      final help = find.byKey(const ValueKey('station-map-help'));
      expect(
        find.ancestor(of: help, matching: find.byType(AppBar)),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Scaffold>(find.byType(Scaffold).first)
            .floatingActionButton,
        isNull,
      );
      expect(tester.getCenter(help).dx, greaterThan(375 / 2));
      expect(tester.getCenter(help).dy, lessThan(80));
      expect(
        tester.widget<IconButton>(help).style?.backgroundColor?.resolve({}),
        isNull,
      );
      expect(tester.getBottomRight(help).dy, lessThanOrEqualTo(512));
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      await tester.tap(help);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('확인'));
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '도쿄',
      );
      expect(find.text('구내도 이용 안내'), findsNothing);
    },
  );
  testWidgets('search collapses previous result; empty search can be cleared', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(StationMapPage(load: () => Future.value(fixture()))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('locker-toggle-tokyo')));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'not-an-existing-station');
    await tester.pumpAndSettle();
    expect(find.textContaining('연결된 안내를 찾지 못했어요'), findsOneWidget);
    await tester.tap(find.byTooltip('검색어 지우기'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('locker-toggle-tokyo')), findsOneWidget);
    expect(find.text('JR 동일본'), findsNothing);
  });
  testWidgets('failed open retries and never adds search or settings to URL', (
    tester,
  ) async {
    final calls = <Uri>[];
    await tester.pumpWidget(
      app(
        StationMapPage(
          load: () => Future.value(fixture()),
          openLink: (u) async {
            calls.add(u);
            return calls.length > 1;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('locker-toggle-tokyo')));
    await tester.pumpAndSettle();
    final link = fixture().links['tokyo']!.first;
    await tester.tap(find.byKey(ValueKey('station-map-link-${link.id}')));
    await tester.pumpAndSettle();
    expect(find.text('다시 열기'), findsOneWidget);
    await tester.tap(find.text('다시 열기'));
    await tester.pumpAndSettle();
    expect(calls, [link.uri, link.uri]);
    expect(find.text('다시 열기'), findsNothing);
  });
  testWidgets('loading failure retry recovers', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      app(
        StationMapPage(
          load: () async {
            if (attempts++ == 0) throw StateError('fixture');
            return fixture();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('다시 불러오기'), findsOneWidget);
    await tester.tap(find.text('다시 불러오기'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('locker-toggle-tokyo')), findsOneWidget);
  });
}

class _Bundle extends CachingAssetBundle {
  final loads = <String, int>{};
  @override
  Future<ByteData> load(String key) async {
    loads[key] = (loads[key] ?? 0) + 1;
    return ByteData.sublistView(await File(key).readAsBytes());
  }
}
