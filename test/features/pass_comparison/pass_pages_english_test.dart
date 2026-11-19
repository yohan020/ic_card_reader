import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/widgets/pass_station_picker_field.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/kyoto_subway_1day_pass_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/enoden_noriorikun_pass_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/enokama_pass_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/fukuoka_city_subway_pass_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/hakone_freepass_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/hankyu_1day_pass_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/hiroden_pass_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/hokkaido_rail_pass_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/kintetsu_rail_pass_5day_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/kyoto_subway_bus_pass_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/nagasaki_electric_tramway_pass_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/okayama_kurashiki_gururin_pass_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/osaka_pass_station_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/pass_transit_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/sapporo_subway_pass_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/yui_rail_pass_data.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/pass_strings.dart';
import 'package:ic_card_reader/src/features/pass_comparison/domain/pass_comparison.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_name_display.dart';
import 'package:ic_card_reader/src/features/settings/presentation/pass_data_sources_page.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/enoden_noriorikun_pass_page.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/enokama_pass_page.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/fukuoka_city_subway_pass_page.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/hakone_freepass_page.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/hankyu_1day_pass_page.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/hiroden_pass_page.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/hokkaido_rail_pass_page.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/kintetsu_rail_pass_5day_page.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/kyoto_subway_1day_pass_page.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/kyoto_subway_bus_pass_page.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/nagasaki_electric_tramway_pass_page.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/okayama_kurashiki_gururin_pass_page.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/osaka_amazing_pass_prototype_page.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/pass_comparison_prototype_page.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/sapporo_subway_pass_page.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/yui_rail_pass_page.dart';

void expectEnglish(WidgetTester tester) {
  final korean = RegExp('[가-힣]');
  final remaining = tester
      .widgetList<Text>(find.byType(Text))
      .map((w) => w.data ?? w.textSpan?.toPlainText() ?? '')
      .where((s) => korean.hasMatch(s))
      .toList();
  expect(
    remaining,
    isEmpty,
    reason: 'App-owned Korean text remains in English UI',
  );
  expect(tester.takeException(), isNull);
}

Widget app(Widget page, {bool dark = false}) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: dark ? AppTheme.dark : AppTheme.light,
  builder: (context, child) => PassNameScope(
    mode: StationNameDisplayMode.english,
    child: MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(1.3), disableAnimations: true),
      child: child!,
    ),
  ),
  home: page,
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await const EnodenNoriorikunPassDataRepository().load();
    await const EnokamaPassDataRepository().load();
    await const FukuokaCitySubwayPassDataRepository().load();
    await const HakoneFreepassDataRepository().load();
    await const Hankyu1DayPassDataRepository().load();
    await const HirodenPassDataRepository().load();
    await const HokkaidoRailPassDataRepository().load();
    await const KintetsuRailPass5DayDataRepository().load();
    await const KyotoSubwayBusPassDataRepository().load();
    await KyotoSubway1DayPassDataRepository().load();
    await const NagasakiElectricTramwayPassDataRepository().load();
    await const OkayamaKurashikiGururinPassDataRepository().load();
    await const OsakaPassStationDataRepository().load();
    await const PassTransitDataRepository().load();
    await const SapporoSubwayPassDataRepository().load();
    await const YuiRailPassDataRepository().load();
  });
  final pages = <Widget>[
    const EnodenNoriorikunPassPage(),
    const EnokamaPassPage(),
    const FukuokaCitySubwayPassPage(),
    const HakoneFreepassPage(),
    const Hankyu1DayPassPage(),
    const HirodenPassPage(),
    const HokkaidoRailPassPage(),
    const KintetsuRailPass5DayPage(),
    const KyotoSubway1DayPassPage(),
    const KyotoSubwayBusPassPage(),
    const NagasakiElectricTramwayPassPage(),
    const OkayamaKurashikiGururinPassPage(),
    const OsakaAmazingPassPrototypePage(),
    const PassComparisonPrototypePage(),
    const PassComparisonPrototypePage(initialProduct: PassProduct.tokunai1Day),
    const SapporoSubwayPassPage(),
    const YuiRailPassPage(),
  ];
  for (var i = 0; i < pages.length; i++) {
    for (final locale in ['ko', 'en']) {
      testWidgets('Pass family $i compact empty fare hint $locale', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light,
            home: pages[i],
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        final hint = find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              (widget.data == '두 역을 선택하면 운임을 자동으로 확인합니다.' ||
                  widget.data == '두 지점을 선택하면 성인 일반 운임을 확인합니다.' ||
                  widget.data ==
                      'Choose two stations to see the fare automatically.' ||
                  widget.data ==
                      'Choose two locations to see the adult regular fare.'),
        );
        await tester.scrollUntilVisible(hint.first, 180);
        expect(hint, findsWidgets);
        for (final text in tester.widgetList<Text>(hint)) {
          expect(text.style?.fontSize, 11);
        }
        expect(tester.takeException(), isNull);
      });
    }
    testWidgets(
      'Pass family $i English search, selected fields and journey result',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(app(pages[i]));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        for (var end = 0; end < 2; end++) {
          final fields = find.byType(PassStationPickerField);
          for (var step = 0; step < 8 && fields.evaluate().isEmpty; step++) {
            await tester.drag(
              find.byType(Scrollable).first,
              const Offset(0, -350),
            );
            await tester.pumpAndSettle();
          }
          expect(fields, findsAtLeastNWidgets(2));
          await tester.ensureVisible(fields.at(end));
          await tester.pumpAndSettle();
          await tester.tap(fields.at(end));
          await tester.pumpAndSettle();
          expectEnglish(tester);
          await tester.enterText(find.byType(TextField).first, 'a');
          await tester.pumpAndSettle();
          expectEnglish(tester);
          final candidates = find.byType(ListTile);
          expect(candidates, findsWidgets);
          final selected = candidates.at(
            end == 1 && candidates.evaluate().length > 1 ? 1 : 0,
          );
          await tester.ensureVisible(selected);
          await tester.pumpAndSettle();
          await tester.tap(selected);
          await tester.pumpAndSettle();
          expectEnglish(tester);
        }
        for (var step = 0; step < 8; step++) {
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -400),
          );
          await tester.pumpAndSettle();
          expectEnglish(tester);
        }
        final result = find.text('View comparison');
        if (result.evaluate().isNotEmpty) {
          await tester.ensureVisible(result.last);
          await tester.pumpAndSettle();
          await tester.tap(result.last);
          await tester.pumpAndSettle();
          expectEnglish(tester);
        }
      },
    );
    for (final dark in [false, true]) {
      testWidgets('Pass family $i English input and result dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(app(pages[i], dark: dark));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)),
        );
        await tester.pumpAndSettle();
        expectEnglish(tester);
        final options = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.button == true &&
              widget.properties.selected != null,
        );
        final optionCount = options.evaluate().length;
        for (var option = 0; option < optionCount; option++) {
          await tester.ensureVisible(options.at(option));
          await tester.pumpAndSettle();
          await tester.tap(options.at(option));
          await tester.pumpAndSettle();
          expectEnglish(tester);
        }
        final scroll = find.byType(Scrollable).first;
        for (var step = 0; step < 6; step++) {
          await tester.drag(scroll, const Offset(0, -450));
          await tester.pumpAndSettle();
          expectEnglish(tester);
        }
        final button = find.text('View comparison');
        if (button.evaluate().isNotEmpty) {
          await tester.ensureVisible(button.last);
          await tester.pumpAndSettle();
          await tester.tap(button.last);
          await tester.pumpAndSettle();
          expectEnglish(tester);
        }
      });
    }
  }
  testWidgets(
    'All 17 source details are English and retain original licensing',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(app(const PassDataSourcesPage()));
      await tester.pumpAndSettle();
      expectEnglish(tester);
      for (
        var step = 0;
        step < 12 && find.byType(ListTile).evaluate().isEmpty;
        step++
      ) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -450));
        await tester.pumpAndSettle();
      }
      expect(find.byType(ListTile), findsNWidgets(17));
      for (var i = 0; i < 17; i++) {
        final tile = find.byType(ListTile).at(i);
        await tester.ensureVisible(tile);
        await tester.pumpAndSettle();
        await tester.tap(tile);
        await tester.pumpAndSettle();
        expectEnglish(tester);
        expect(find.text('Fare calculation basis'), findsOneWidget);
        for (var step = 0; step < 7; step++) {
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -450),
          );
          await tester.pumpAndSettle();
          expectEnglish(tester);
        }
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
    },
  );
}
