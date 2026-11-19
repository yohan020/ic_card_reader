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
import 'package:ic_card_reader/src/features/coin_locker/presentation/coin_locker_page.dart';
import 'package:ic_card_reader/src/features/station_maps/domain/station_map_catalog.dart';
import 'package:ic_card_reader/src/features/station_maps/presentation/station_map_page.dart';
import '../station_stamps/stamp_test_support.dart' show previewTextTheme;

const preview = bool.fromEnvironment('GUIDE_SHELL_PREVIEW');
void main() {
  final lockers = CoinLockerCatalog.fromJson(
    jsonDecode(File('assets/data/coin_locker/catalog.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  final maps = StationMapCatalog.fromJson(
    jsonDecode(File('assets/data/station_maps/catalog.json').readAsStringSync())
        as Map<String, dynamic>,
    lockers,
  );
  if (preview) {
    setUpAll(() async {
      for (final font in {
        'Preview': 'C:/Windows/Fonts/malgun.ttf',
        'PreviewLatin': 'C:/Windows/Fonts/arial.ttf',
        'PreviewJapanese': 'C:/Windows/Fonts/YuGothR.ttc',
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
  for (final kind in ['lockers', 'maps']) {
    for (final lang in ['ko', 'en']) {
      for (final dark in [false, true]) {
        for (final scale in [1.0, 2.0]) {
          testWidgets('guide shell $kind $lang dark=$dark scale=$scale', (
            tester,
          ) async {
            tester.view.physicalSize = Size(scale == 1 ? 390 : 320, 844);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final base = dark ? AppTheme.dark : AppTheme.light;
            final theme = preview
                ? base.copyWith(
                    textTheme: previewTextTheme(base.textTheme).apply(
                      fontFamilyFallback: const [
                        'PreviewLatin',
                        'PreviewJapanese',
                      ],
                    ),
                    primaryTextTheme: previewTextTheme(base.primaryTextTheme)
                        .apply(
                          fontFamilyFallback: const [
                            'PreviewLatin',
                            'PreviewJapanese',
                          ],
                        ),
                    appBarTheme: base.appBarTheme.copyWith(
                      titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(
                        fontFamily: 'Preview',
                      ),
                    ),
                  )
                : base;
            await tester.pumpWidget(
              RepaintBoundary(
                key: const ValueKey('guide-shell-preview'),
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  locale: Locale(lang),
                  theme: theme,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: kind == 'lockers'
                      ? CoinLockerPage(load: () async => lockers)
                      : StationMapPage(load: () async => maps),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final field = tester.widget<TextField>(find.byType(TextField));
            expect(field.style!.fontSize, 15);
            final border =
                field.decoration!.enabledBorder! as OutlineInputBorder;
            final context = tester.element(find.byType(TextField));
            expect(border.borderSide.color, AppColors.outline(context));
            expect(border.borderRadius, BorderRadius.circular(13));
            final appBar = tester.widget<AppBar>(find.byType(AppBar));
            expect(appBar.titleTextStyle, isNull);
            expect(appBar.backgroundColor, isNull);
            await tester.enterText(
              find.byType(TextField),
              lang == 'ko' ? '시부야' : 'Shibuya',
            );
            await tester.pumpAndSettle();
            final toggles = find.byWidgetPredicate(
              (w) =>
                  w is InkWell &&
                  w.key is ValueKey<String> &&
                  (w.key! as ValueKey<String>).value.startsWith(
                    'locker-toggle-',
                  ),
            );
            expect(toggles, findsWidgets);
            await tester.tap(toggles.first);
            await tester.pumpAndSettle();
            expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
            expect(tester.takeException(), isNull);
            if (preview) {
              await tester.runAsync(() async {
                final boundary = tester.renderObject<RenderRepaintBoundary>(
                  find.byKey(const ValueKey('guide-shell-preview')),
                );
                final picture = await boundary.toImage(pixelRatio: 2);
                final bytes = await picture.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final dir = Directory('.dart_tool/guide-shell-preview')
                  ..createSync(recursive: true);
                await File(
                  '${dir.path}/$kind-$lang-$dark-$scale.png',
                ).writeAsBytes(bytes!.buffer.asUint8List());
                picture.dispose();
              });
            }
          });
        }
      }
    }
  }
}
