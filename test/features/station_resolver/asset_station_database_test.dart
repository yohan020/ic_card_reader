import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/station_resolver/data/asset_station_database.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_resolution.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_name_display.dart';

void main() {
  late AssetStationDatabase database;

  setUpAll(() {
    final csv = File(
      'assets/data/stations/yoiko_station_codes.csv',
    ).readAsStringSync();
    final overrideCsv = File(
      'assets/data/stations/verified_station_overrides.csv',
    ).readAsStringSync();
    final koreanNamesCsv = File(
      'assets/data/stations/wikidata_station_names_ko.csv',
    ).readAsStringSync();
    database = AssetStationDatabase.fromCsv(
      csv,
      overrideCsv: overrideCsv,
      koreanNamesCsv: koreanNamesCsv,
    );
  });

  test('resolves the physical-card route through the safe 50 to 01 hint', () {
    final boarding = database.resolve(
      const StationCode(regionCode: 0x50, lineCode: 0xA5, stationCode: 0x78),
    );
    final alighting = database.resolve(
      const StationCode(regionCode: 0x50, lineCode: 0xAC, stationCode: 0x38),
    );

    expect(boarding.strategy, StationMatchStrategy.regionHint);
    expect(boarding.station?.stationName, '名鉄名古屋');
    expect(boarding.station?.stationNameKorean, '메이테쓰나고야역');
    expect(boarding.station?.lineName, '名古屋本線');
    expect(alighting.strategy, StationMatchStrategy.regionHint);
    expect(alighting.station?.stationName, '中部国際空港');
    expect(alighting.station?.lineName, '空港線');
  });

  test(
    'attaches a generated Korean label without changing the source name',
    () {
      const sourceCsv =
          '''region,line,station,x1,x2,x3,operator,line_name,station_name
1,165,120,,,,Meitetsu,名古屋本線,名鉄名古屋
''';
      const koreanCsv =
          '''station_name_ja,station_name_ko,wikidata_id,match_status,source
名鉄名古屋,메이테쓰 나고야,Q1,unique_korean_label,Wikidata CC0
''';
      final localized =
          AssetStationDatabase.fromCsv(
            sourceCsv,
            koreanNamesCsv: koreanCsv,
          ).resolve(
            const StationCode(regionCode: 1, lineCode: 165, stationCode: 120),
          );

      expect(localized.station?.stationName, '名鉄名古屋');
      expect(localized.station?.stationNameKorean, '메이테쓰 나고야');
      expect(
        displayStationName(
          japanese: localized.station!.stationName,
          korean: localized.station!.stationNameKorean,
          mode: StationNameDisplayMode.korean,
        ),
        '메이테쓰 나고야',
      );
      expect(
        displayStationName(
          japanese: localized.station!.stationName,
          korean: localized.station!.stationNameKorean,
          mode: StationNameDisplayMode.both,
        ),
        '메이테쓰 나고야 (名鉄名古屋)',
      );
    },
  );

  test('resolves normalized regions and the documented charge location', () {
    final meitetsuNagoya = database.resolve(
      const StationCode(regionCode: 0x01, lineCode: 0xA5, stationCode: 0x78),
    );
    final centralJapanAirport = database.resolve(
      const StationCode(regionCode: 0x01, lineCode: 0xAC, stationCode: 0x38),
    );
    final bakuroYokoyama = database.resolve(
      const StationCode(regionCode: 0x00, lineCode: 0xF1, stationCode: 0x09),
    );
    final ichigaya = database.resolve(
      const StationCode(regionCode: 0x00, lineCode: 0xF1, stationCode: 0x04),
    );
    final tenjinMinami = database.resolve(
      const StationCode(regionCode: 0x03, lineCode: 0xE9, stationCode: 0x1F),
    );

    expect(meitetsuNagoya.strategy, StationMatchStrategy.exactRegion);
    expect(meitetsuNagoya.station?.stationName, '名鉄名古屋');
    expect(centralJapanAirport.station?.stationName, '中部国際空港');
    expect(bakuroYokoyama.station?.stationName, '馬喰横山');
    expect(ichigaya.station?.stationName, '市ヶ谷');
    expect(tenjinMinami.strategy, StationMatchStrategy.exactRegion);
    expect(tenjinMinami.station?.stationName, '天神南');
    expect(tenjinMinami.station?.lineName, '3号線(七隈線)');
  });

  test('resolves the physical simple-gate route on the Takayama line', () {
    final pair = database.resolvePair(
      boardingCode: const StationCode(
        regionCode: 0x00,
        lineCode: 0x44,
        stationCode: 0x24,
      ),
      alightingCode: const StationCode(
        regionCode: 0x00,
        lineCode: 0x44,
        stationCode: 0x28,
      ),
    );

    expect(pair.boarding.strategy, StationMatchStrategy.exactRegion);
    expect(pair.boarding.station?.stationName, '高山');
    expect(pair.boarding.station?.lineName, '高山線');
    expect(pair.alighting.strategy, StationMatchStrategy.exactRegion);
    expect(pair.alighting.station?.stationName, '飛騨古川');
    expect(pair.alighting.station?.lineName, '高山線');
  });

  test('resolves the verified gate-window and station-charge locations', () {
    final shinagawa = database.resolve(
      const StationCode(regionCode: 0, lineCode: 0x01, stationCode: 0x07),
    );
    final tenjinMinami = database.resolve(
      const StationCode(regionCode: 3, lineCode: 0xE9, stationCode: 0x1F),
    );
    final nishitetsuFukuoka = database.resolve(
      const StationCode(regionCode: 3, lineCode: 0xD7, stationCode: 0x65),
    );

    expect(shinagawa.station?.stationName, '品川');
    expect(tenjinMinami.station?.stationName, '天神南');
    expect(nishitetsuFukuoka.station?.stationName, '西鉄福岡');
  });

  test('keeps ambiguous line and station codes as candidates', () {
    final resolution = database.resolve(
      const StationCode(regionCode: 0xFE, lineCode: 0x8C, stationCode: 0x22),
    );

    expect(resolution.isResolved, isFalse);
    expect(resolution.strategy, StationMatchStrategy.multipleCandidates);
    expect(resolution.candidates.length, greaterThan(1));
  });

  test('uses the shared trip region only when it is unique', () {
    final pair = database.resolvePair(
      boardingCode: const StationCode(
        regionCode: 0xFE,
        lineCode: 0x8C,
        stationCode: 0x22,
      ),
      alightingCode: const StationCode(
        regionCode: 0xFE,
        lineCode: 0xA5,
        stationCode: 0x78,
      ),
    );

    expect(pair.boarding.strategy, StationMatchStrategy.tripContext);
    expect(pair.boarding.station?.stationName, '金城ふ頭');
    expect(pair.alighting.station?.stationName, '名鉄名古屋');
  });

  test('resolves all Iyotetsu Takahama line overrides with evidence', () {
    const expected = <int, (String, String, String)>{
      0x17: ('松山市', 'verified_fixture', '伊予鉄道郊外電車'),
      0x19: ('大手町', 'inferred_sequence', '高浜線'),
      0x1B: ('古町', 'verified_fixture', '高浜線'),
      0x1D: ('衣山', 'inferred_sequence', '高浜線'),
      0x1F: ('西衣山', 'inferred_sequence', '高浜線'),
      0x21: ('山西', 'inferred_sequence', '高浜線'),
      0x23: ('三津', 'inferred_sequence', '高浜線'),
      0x25: ('港山', 'inferred_sequence', '高浜線'),
      0x27: ('梅津寺', 'verified_fixture', '高浜線'),
      0x29: ('高浜', 'inferred_sequence', '高浜線'),
    };

    for (final entry in expected.entries) {
      final resolution = database.resolve(
        StationCode(regionCode: 3, lineCode: 0xC5, stationCode: entry.key),
      );
      expect(resolution.strategy, StationMatchStrategy.exactRegion);
      expect(resolution.station?.stationName, entry.value.$1);
      expect(resolution.station?.operatorName, '伊予鉄道');
      expect(resolution.station?.lineName, entry.value.$3);
      expect(resolution.station?.evidence, entry.value.$2);
    }
  });

  test('never falls back across a known normalized region', () {
    final iyotetsuFurumachi = database.resolve(
      const StationCode(regionCode: 3, lineCode: 0xC5, stationCode: 0x1B),
    );
    final iyotetsuMatsuyama = database.resolve(
      const StationCode(regionCode: 3, lineCode: 0xC5, stationCode: 0x17),
    );
    final unregistered = database.resolve(
      const StationCode(regionCode: 3, lineCode: 0xC5, stationCode: 0x2B),
    );
    final keioSeisekiSakuragaoka = database.resolve(
      const StationCode(regionCode: 0, lineCode: 0xC5, stationCode: 0x1B),
    );
    final keioHigashiFuchu = database.resolve(
      const StationCode(regionCode: 0, lineCode: 0xC5, stationCode: 0x17),
    );

    expect(iyotetsuFurumachi.station?.stationName, '古町');
    expect(iyotetsuFurumachi.station?.stationName, isNot('聖蹟桜ヶ丘'));
    expect(iyotetsuMatsuyama.station?.stationName, '松山市');
    expect(iyotetsuMatsuyama.station?.stationName, isNot('東府中'));
    expect(unregistered.strategy, StationMatchStrategy.notFound);
    expect(unregistered.station, isNull);
    expect(keioSeisekiSakuragaoka.station?.stationName, '聖蹟桜ヶ丘');
    expect(keioHigashiFuchu.station?.stationName, '東府中');
  });

  test('resolves all Iyotetsu Gunchu line overrides with evidence', () {
    const stations = <int, String>{
      0x01: '郡中港',
      0x03: '郡中',
      0x05: '新川',
      0x07: '地蔵町',
      0x09: '松前',
      0x0B: '古泉',
      0x0D: '岡田',
      0x0F: '鎌田',
      0x11: '余戸',
      0x13: '土居田',
      0x15: '土橋',
      0x17: '松山市',
    };

    for (final entry in stations.entries) {
      final resolution = database.resolve(
        StationCode(regionCode: 3, lineCode: 0xC5, stationCode: entry.key),
      );
      expect(resolution.station?.stationName, entry.value);
      expect(resolution.station?.operatorName, '伊予鉄道');
      expect(
        resolution.station?.evidence,
        entry.key == 0x01 || entry.key == 0x17
            ? 'verified_fixture'
            : 'inferred_sequence',
      );
    }
  });

  test('resolves Iyotetsu line only from a verified route pair', () {
    ResolvedStationPair pair(int region, int from, int to, {int line = 0xC5}) =>
        database.resolvePair(
          boardingCode: StationCode(
            regionCode: region,
            lineCode: line,
            stationCode: from,
          ),
          alightingCode: StationCode(
            regionCode: region,
            lineCode: line,
            stationCode: to,
          ),
        );

    expect(pair(3, 0x01, 0x17).routeLineName, '郡中線');
    expect(pair(3, 0x0B, 0x13).routeLineName, '郡中線');
    expect(pair(3, 0x1B, 0x27).routeLineName, '高浜線');
    expect(pair(3, 0x27, 0x17).routeLineName, '高浜線');
    expect(pair(3, 0x17, 0x17).routeLineName, isNull);
    expect(pair(3, 0x01, 0x1B).routeLineName, isNull);
    expect(pair(0, 0x17, 0x1B).routeLineName, isNull);
    expect(pair(3, 0x01, 0x17, line: 0xC4).routeLineName, isNull);
  });
}
