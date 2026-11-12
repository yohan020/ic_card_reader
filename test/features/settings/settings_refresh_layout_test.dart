import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/core/localization/app_strings.dart';
import 'package:ic_card_reader/src/features/settings/presentation/settings_page.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_name_display.dart';

void main() {
  for (final language in ['ko', 'en']) {
    for (final dark in [false, true]) {
      for (final width in [320.0, 390.0]) {
        for (final scale in [1.0, 2.0]) {
          testWidgets(
            'settings A layout $language dark=$dark width=$width scale=$scale',
            (tester) async {
              tester.view.physicalSize = Size(width, 900);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);
              ThemeMode? theme;
              await tester.pumpWidget(
                MaterialApp(
                  theme: dark ? AppTheme.dark : AppTheme.light,
                  locale: Locale(language),
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: SettingsPage(
                    themeMode: ThemeMode.system,
                    onThemeModeChanged: (value) => theme = value,
                    onClearSession: () {},
                    stationNameDisplayMode:
                        StationNameDisplayMode.japaneseEnglish,
                    onStationNameDisplayModeChanged: (_) {},
                    onAppLanguageChanged: (_) {},
                  ),
                ),
              );
              await tester.pumpAndSettle();
              final group = find.byKey(
                const ValueKey('settings-language-group'),
              );
              expect(
                find.descendant(of: group, matching: find.byType(Card)),
                findsOneWidget,
              );
              expect(
                find.descendant(
                  of: group,
                  matching: find.byKey(const ValueKey('theme-mode-selector')),
                ),
                findsOneWidget,
              );
              if (scale == 1 && language == 'ko') {
                expect(
                  tester
                      .getSize(
                        find.byKey(const ValueKey('theme-mode-selector')),
                      )
                      .height,
                  50,
                );
              }
              final languageTitle = language == 'en' ? 'App language' : '앱 언어';
              final stationTitle = language == 'en' ? 'Station names' : '역명 표기';
              expect(
                find.descendant(of: group, matching: find.text(languageTitle)),
                findsOneWidget,
              );
              expect(
                find.descendant(of: group, matching: find.text(stationTitle)),
                findsOneWidget,
              );
              for (final mode in ThemeMode.values) {
                final option = find.byKey(
                  ValueKey('settings-theme-${mode.name}'),
                );
                expect(tester.getSize(option).height, greaterThanOrEqualTo(48));
                final fill = find.byKey(
                  ValueKey('settings-theme-fill-${mode.name}'),
                );
                expect(
                  tester.getSize(fill).height,
                  tester.getSize(option).height - 8,
                );
                expect(
                  tester.getTopLeft(fill).dy - tester.getTopLeft(option).dy,
                  4,
                );
                await tester.tap(option);
                expect(theme, mode == ThemeMode.system ? isNull : mode);
              }
              theme = null;
              final darkOption = find.byKey(
                const ValueKey('settings-theme-dark'),
              );
              await tester.tapAt(
                tester.getTopLeft(darkOption) + const Offset(10, 2),
              );
              expect(theme, ThemeMode.dark);
              expect(tester.takeException(), isNull);
              final info = find.text(
                language == 'en' ? 'Open-source licenses' : '오픈소스 라이선스',
              );
              await tester.scrollUntilVisible(info, 160);
              await tester.ensureVisible(info);
              await tester.pumpAndSettle();
              final icon = tester.widget<Icon>(
                find.byIcon(Icons.description_outlined),
              );
              expect(icon.size, 20);
              final title = tester.widget<Text>(info);
              expect(title.style?.fontSize, 14);
              expect(title.style?.fontWeight, FontWeight.w600);
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }
}
