import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/pass_named_place.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/pass_strings.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_name_display.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('All pass data families expose English names without changing IDs', () async {
    final hokkaidoFixture = HokkaidoRailPassData.fromBinary(
      stationsCsv: File(
        'assets/data/pass_comparison/hokkaido_rail_pass_stations_2026.csv',
      ).readAsStringSync(),
      minimumFaresBinary: ByteData.sublistView(
        File(
          'assets/data/pass_comparison/hokkaido_rail_pass_minimum_fares_2026.bin',
        ).readAsBytesSync(),
      ),
      limitedExpressSafePairsCsv: File(
        'assets/data/pass_comparison/hokkaido_rail_pass_limited_express_safe_pairs_2026.csv',
      ).readAsStringSync(),
    );
    final catalogs = <List<PassNamedPlace>>[
      (await const EnodenNoriorikunPassDataRepository().load()).stations,
      (await const EnokamaPassDataRepository().load()).stations,
      (await const EnokamaPassDataRepository().load()).origins,
      (await const Hankyu1DayPassDataRepository().load()).stations,
      hokkaidoFixture.stations,
      (await const KyotoSubwayBusPassDataRepository().load()).stations,
      (await const OsakaPassStationDataRepository().load()).stations,
      (await const FukuokaCitySubwayPassDataRepository().load()).stations,
      (await const HirodenPassDataRepository().load()).stations,
      (await const KintetsuRailPass5DayDataRepository().load()).stations,
      (await const NagasakiElectricTramwayPassDataRepository().load()).stations,
      (await const OkayamaKurashikiGururinPassDataRepository().load()).stations,
      (await const PassTransitDataRepository().load()).stations,
      (await const SapporoSubwayPassDataRepository().load()).stations,
      (await const YuiRailPassDataRepository().load()).stations,
      (await const HakoneFreepassDataRepository().load()).places,
      (await const HakoneFreepassDataRepository().load()).departures,
    ];
    for (final catalog in catalogs) {
      expect(catalog, isNotEmpty);
      expect(
        catalog.where((s) => s.nameEn.trim().isEmpty),
        isEmpty,
        reason:
            'Missing English names: ${catalog.where((s) => s.nameEn.isEmpty).map((s) => s.nameJa)}',
      );
    }
    final enoden = await const EnodenNoriorikunPassDataRepository().load();
    final hankyu = await const Hankyu1DayPassDataRepository().load();
    final enokama = await const EnokamaPassDataRepository().load();
    final hokkaido = hokkaidoFixture;
    final kyoto = await const KyotoSubwayBusPassDataRepository().load();
    final osaka = await const OsakaPassStationDataRepository().load();
    expect(
      enoden.search(enoden.stations.first.nameEn),
      contains(enoden.stations.first),
    );
    expect(
      hankyu.search(hankyu.stations.first.nameEn),
      contains(hankyu.stations.first),
    );
    expect(
      enokama.searchOrigins(enokama.origins.first.nameEn),
      contains(enokama.origins.first),
    );
    expect(
      enokama.searchStations(enokama.stations.first.nameEn),
      contains(enokama.stations.first),
    );
    expect(
      hokkaido.search(hokkaido.stations.first.nameEn),
      contains(hokkaido.stations.first),
    );
    expect(
      kyoto.search(kyoto.stations.first.nameEn),
      contains(kyoto.stations.first),
    );
    expect(
      osaka.search(osaka.stations.first.nameEn),
      contains(osaka.stations.first),
    );
    expect(enoden.search('Railway'), isEmpty);
    expect(hankyu.search('Hankyu Railway'), isEmpty);
    expect(kyoto.search('Municipal Subway'), isEmpty);
  });
  for (final mode in StationNameDisplayMode.values) {
    testWidgets(
      'Station mode $mode is independent of English UI and follows pushed routes',
      (tester) async {
        const station = EnodenStation(
          id: 'enoden_en01',
          nameJa: '藤沢',
          nameKo: '후지사와역',
          kilometer: 0,
        );
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) =>
                PassNameScope(mode: mode, child: child!),
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => Text(station.passName(context)),
                  ),
                ),
                child: Text(station.passName(context)),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final expected = displayStationName(
          japanese: '藤沢',
          korean: '후지사와',
          english: station.nameEn,
          mode: mode,
        );
        expect(find.text(expected), findsOneWidget);
        await tester.tap(find.byType(TextButton));
        await tester.pumpAndSettle();
        expect(find.text(expected), findsOneWidget);
      },
    );
  }
}
