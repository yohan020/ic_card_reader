import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/coin_locker/domain/coin_locker_catalog.dart';
import 'package:ic_card_reader/src/features/contactless/domain/contactless_catalog.dart';
import 'package:ic_card_reader/src/features/contactless/domain/contactless_station_name.dart';
import 'package:ic_card_reader/src/features/station_resolver/data/asset_station_database.dart';
import 'package:ic_card_reader/src/features/station_resolver/data/station_coordinate_repository.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_name_display.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_resolution.dart';
import 'package:ic_card_reader/src/features/transaction_history/presentation/widgets/history_station_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'history asset distinguishes identical Japanese names in Tokyo and Osaka',
    () async {
      final database = await AssetStationDatabase.load();
      String? name(int region, int line, int station) => database
          .resolve(
            StationCode(
              regionCode: region,
              lineCode: line,
              stationCode: station,
            ),
          )
          .station
          ?.stationNameEnglish;
      expect(name(0, 227, 52), 'Nihombashi');
      expect(name(2, 133, 37), 'Nippombashi');
      expect(name(3, 231, 15), 'Tenjin');
      expect(name(3, 231, 21), 'Hakata');
    },
  );

  test(
    'history English labels require matching code, station, operator and line',
    () {
      const code = StationCode(regionCode: 0, lineCode: 1, stationCode: 1);
      const english = '{"0/1/1":["東京","JR","東海道線","Tokyo"]}';
      String? name(String row) => AssetStationDatabase.fromCsv(
        'r,l,s,rh,lh,sh,op,line,ja\n$row',
        englishNamesJson: english,
      ).resolve(code).station?.stationNameEnglish;
      expect(name('0,1,1,00,01,01,JR,東海道線,東京'), 'Tokyo');
      expect(name('0,1,1,00,01,01,JR,別線,東京'), isNull);
      expect(name('0,1,1,00,01,01,別会社,東海道線,東京'), isNull);
      expect(name('0,1,1,00,01,01,JR,東海道線,別駅'), isNull);
    },
  );

  test(
    'all contactless detail records have English; search stays multilingual',
    () {
      final data =
          jsonDecode(
                utf8.decode(
                  gzip.decode(
                    File(
                      'assets/data/contactless/catalog.bin',
                    ).readAsBytesSync(),
                  ),
                ),
              )
              as Map<String, dynamic>;
      final catalog = ContactlessCatalog.fromJson(data);
      var records = 0;
      for (final line in catalog.lines) {
        for (final station in line.records('stations')) {
          records++;
          expect(
            contactlessStationEnglishName(
              line.id,
              station['id'] as String,
              station['name'] as String,
            ),
            isNotEmpty,
          );
        }
      }
      expect(records, 919);
      final inuyama = catalog.lines.firstWhere((l) => l.nameJa == '犬山線');
      for (final query in ['Inuyama Station', '犬山', '이누야마']) {
        expect(catalog.search(query, null), contains(inuyama));
      }
      final station = inuyama
          .records('stations')
          .firstWhere((s) => s['name'] == '犬山');
      expect(
        displayContactlessStationName(
          lineId: inuyama.id,
          stationId: station['id'] as String,
          japanese: '別駅',
          mode: StationNameDisplayMode.english,
        ),
        '別駅',
      );
    },
  );

  test(
    'all locker places have an English name and aliases do not merge places',
    () {
      final catalog = CoinLockerCatalog.fromJson(
        jsonDecode(
              File('assets/data/coin_locker/catalog.json').readAsStringSync(),
            )
            as Map<String, dynamic>,
      );
      expect(catalog.places, hasLength(1000));
      expect(catalog.places.every((p) => p.nameEn?.isNotEmpty == true), isTrue);
      final narita = catalog.places.singleWhere(
        (p) => p.id == 'narita_airport',
      );
      expect(catalog.search('Narita Airport Terminal 3'), contains(narita));
      final sai = catalog.places.singleWhere((p) => p.id == 'source_005996');
      expect(catalog.search('Saiin Station'), contains(sai));
      for (final query in ['Nipponbashi', '日本橋', '닛폰바시']) {
        expect(catalog.search(query).any((p) => p.region == '오사카부'), isTrue);
      }
      expect(
        catalog.search('Nihombashi').any((p) => p.region == '도쿄도'),
        isTrue,
      );
    },
  );

  test(
    'map group pins prefer each verified English member, not the group label',
    () {
      final boarding = StationMapLocations(const [
        StationCoordinate(35.1, 139.1, name: '甲駅', englishName: 'Station A'),
        StationCoordinate(35.2, 139.2, name: '乙駅'),
      ], kind: 'station_complex');
      final alighting = StationMapLocations(const [
        StationCoordinate(35.3, 139.3, name: '丙駅', englishName: 'Station C'),
      ]);
      final map = buildStationGroupGoogleMap(
        boarding,
        alighting,
        'Combined',
        'Destination',
        englishStationNames: true,
      );
      final titles = map.markers.map((m) => m.infoWindow.title);
      expect(titles.any((s) => s!.endsWith('Station A')), isTrue);
      expect(titles.any((s) => s!.endsWith('乙駅')), isTrue);
      expect(titles.any((s) => s!.endsWith('Station C')), isTrue);
      final bilingualMap = buildStationGroupGoogleMap(
        boarding,
        alighting,
        'Combined',
        'Destination',
        bilingualStationNames: true,
      );
      final bilingualTitles = bilingualMap.markers.map(
        (m) => m.infoWindow.title,
      );
      expect(bilingualTitles.any((s) => s!.endsWith('甲駅 (Station A)')), isTrue);
      expect(bilingualTitles.any((s) => s!.endsWith('乙駅')), isTrue);
      expect(bilingualTitles.any((s) => s!.endsWith('丙駅 (Station C)')), isTrue);
    },
  );
}
