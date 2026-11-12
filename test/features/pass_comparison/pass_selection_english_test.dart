import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/pass_transit_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/pass_selection_page.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/pass_strings.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/widgets/pass_result_scope_note.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/widgets/pass_segment_remove_button.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/widgets/pass_station_picker_field.dart';

final emptyData = PassTransitData(
  generatedAt: DateTime(2026),
  source: 'test',
  stations: [],
  fares: [],
);

Widget app(Widget page, {bool dark = false, double scale = 1}) => MaterialApp(
  key: page.key,
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: dark ? AppTheme.dark : AppTheme.light,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
    child: child!,
  ),
  home: page,
);

void main() {
  for (final dark in [false, true]) {
    for (final size in [const Size(320, 800), const Size(800, 400)]) {
      testWidgets('English regional selection fits size=$size dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          app(
            PassSelectionPage(initialTransitData: emptyData),
            dark: dark,
            scale: 2,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Compare transit passes'), findsOneWidget);
        for (final region in [
          'Hokkaido',
          'Tokyo & Kanto',
          'Kansai',
          'Chugoku',
          'Kyushu',
          'Okinawa',
          'Tohoku',
          'Chubu',
          'Shikoku',
        ]) {
          await tester.scrollUntilVisible(find.text(region), 220);
          expect(find.text(region), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      });
    }
    testWidgets(
      'all 17 pass cards have English names and descriptions dark=$dark',
      (tester) async {
        final titles = <PassRegion, List<String>>{
          PassRegion.hokkaido: [
            'Sapporo Subway One-Day Ticket',
            'Hokkaido Rail Pass',
          ],
          PassRegion.kanto: [
            'Tokyo Subway Ticket',
            'Enoshima-Kamakura Freepass',
            'Enoden One-Day Pass',
            'Hakone Freepass',
            'Tokunai Pass',
          ],
          PassRegion.kansai: [
            'Kyoto Subway One-Day Pass',
            'Osaka Amazing Pass',
            'Kyoto Subway & Bus One-Day Pass',
            'Hankyu One-Day Pass',
            'KINTETSU RAIL PASS',
          ],
          PassRegion.chugoku: [
            'Okayama & Kurashiki tabiwa Gururin Pass',
            'Hiroden Tram Pass',
          ],
          PassRegion.kyushu: [
            'Nagasaki Electric Tramway Pass',
            'Fukuoka City Subway One-Day Pass',
          ],
          PassRegion.okinawa: ['Yui Rail Pass'],
        };
        for (final entry in titles.entries) {
          await tester.pumpWidget(
            app(
              PassSelectionPage(
                key: ValueKey(entry.key),
                initialTransitData: emptyData,
                region: entry.key,
              ),
              dark: dark,
              scale: 1.7,
            ),
          );
          await tester.pumpAndSettle();
          for (final title in entry.value) {
            await tester.scrollUntilVisible(find.text(title), 250);
            expect(find.text(title), findsOneWidget);
            expect(tester.takeException(), isNull);
          }
          await tester.scrollUntilVisible(find.text('Calculation basis'), 250);
          for (final widget in tester.widgetList<Text>(find.byType(Text))) {
            expect(
              RegExp('[가-힣]').hasMatch(widget.data ?? ''),
              isFalse,
              reason: widget.data,
            );
          }
        }
      },
    );
  }

  testWidgets(
    'pass common fields, semantics and singular/plural are localized',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  PassStationPickerField(
                    label: '출발',
                    stationName: null,
                    onTap: () {},
                  ),
                  PassSegmentRemoveButton(onPressed: () {}),
                  const PassResultScopeNote(),
                  Text(strings(context).passCount(1)),
                  Text(strings(context).passCount(2)),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Departure'), findsOneWidget);
      expect(find.text('Choose station'), findsOneWidget);
      expect(find.byTooltip('Remove journey'), findsOneWidget);
      expect(
        find.text('An estimated comparison based on the journeys you entered.'),
        findsOneWidget,
      );
      expect(find.text('1 pass'), findsOneWidget);
      expect(find.text('2 passes'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('^Search Departure station')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets(
    'all registered static pass copy resolves in English and Korean',
    (tester) async {
      final ko =
          jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync()) as Map;
      final en =
          jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map;
      for (final locale in ['en', 'ko']) {
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                for (final key in ko.keys.whereType<String>().where(
                  (k) =>
                      k.startsWith('pass') && !(ko[k] as String).contains('{'),
                )) {
                  final value = ko[key] as String;
                  if (RegExp('[가-힣]').hasMatch(value)) {
                    expect(
                      passText(context, value),
                      locale == 'en' ? en[key] : value,
                      reason: key,
                    );
                  }
                }
                return const SizedBox();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );
}
