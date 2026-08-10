import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/station_resolver/data/asset_station_database.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_resolution.dart';

void main() {
  late AssetStationDatabase database;

  setUpAll(() {
    final csv = File(
      'assets/data/stations/yoiko_station_codes.csv',
    ).readAsStringSync();
    database = AssetStationDatabase.fromCsv(csv);
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
    expect(boarding.station?.lineName, '名古屋本線');
    expect(alighting.strategy, StationMatchStrategy.regionHint);
    expect(alighting.station?.stationName, '中部国際空港');
    expect(alighting.station?.lineName, '空港線');
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
}
