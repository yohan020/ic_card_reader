import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/station_resolver/data/asset_station_database.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_resolution.dart';
import 'package:ic_card_reader/src/features/station_stamps/domain/station_stamp_session.dart';

StationResolution resolved(
  String name, {
  String operator = '東日本旅客鉄道',
  int region = 0,
  int line = 1,
}) {
  final code = StationCode(regionCode: region, lineCode: line, stationCode: 1);
  return StationResolution(
    requestedCode: code,
    strategy: StationMatchStrategy.exactRegion,
    station: StationRecord(
      code: code,
      operatorName: operator,
      lineName: 'fixture',
      stationName: name,
      source: 'synthetic',
    ),
  );
}

ResolvedStationPair pair(StationResolution a, StationResolution b) =>
    ResolvedStationPair(boarding: a, alighting: b);

void main() {
  test('30 unique stations; labels exactly reuse existing curated names', () {
    final raw =
        jsonDecode(
              File(
                'assets/data/pass_comparison/tokunai_jr_data.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final rows = raw['stations'] as List;
    expect(yamanoteStampStations.length, 30);
    expect(yamanoteStampStations.map((s) => s.id).toSet().length, 30);
    for (final s in yamanoteStampStations) {
      final row = rows.cast<Map<String, dynamic>>().singleWhere(
        (r) => r['nameJa'] == s.japanese,
      );
      expect([s.korean, s.english], [row['nameKo'], row['nameEn']]);
    }
  });
  test(
    'same JR station under different lines is deduplicated; no intermediate stations',
    () {
      final candidates = StationStampSession.candidates([
        pair(resolved('東京'), resolved('上野', line: 2)),
        pair(resolved('東京', line: 3), resolved('東京', line: 2)),
      ]);
      expect(candidates, {'jr-east:tokyo', 'jr-east:ueno'});
    },
  );
  test(
    'other operators, connecting codes, regions and unresolved stations excluded',
    () {
      final unknown = StationResolution(
        requestedCode: const StationCode(
          regionCode: 0,
          lineCode: 0,
          stationCode: 0,
        ),
        strategy: StationMatchStrategy.multipleCandidates,
      );
      expect(
        StationStampSession.candidates([
          pair(
            resolved('東京', operator: '東京地下鉄'),
            resolved('東京', operator: '東海旅客鉄道'),
          ),
          pair(resolved('東京', operator: '連絡駅'), resolved('大塚', region: 3)),
          pair(unknown, resolved('東京都区内')),
        ]),
        isEmpty,
      );
    },
  );
  test('all 30 have exact JR region-zero primary database entries', () {
    final database = AssetStationDatabase.fromCsv(
      File(AssetStationDatabase.assetPath).readAsStringSync(),
    );
    final csv = File(AssetStationDatabase.assetPath).readAsLinesSync().skip(1);
    final found = <String>{};
    for (final row in csv) {
      final f = row.split(',');
      if (f.length < 9 || f[0] != '0' || f[6] != '東日本旅客鉄道') continue;
      final r = database.resolve(
        StationCode(
          regionCode: 0,
          lineCode: int.parse(f[1]),
          stationCode: int.parse(f[2]),
        ),
      );
      found.addAll(StationStampSession.candidates([pair(r, r)]));
    }
    final yamanoteIds = yamanoteStampStations.map((s) => s.id).toSet();
    expect(found.intersection(yamanoteIds), yamanoteIds);
  });
  test('collect whitelist/deduplication, completion and reset', () {
    final session = StationStampSession();
    addTearDown(session.dispose);
    expect(session.collect(['invalid', 'jr-east:tokyo', 'jr-east:tokyo']), 1);
    expect(session.collect(['jr-east:tokyo']), 0);
    expect(() => session.collected.add('invalid'), throwsUnsupportedError);
    session.collect(yamanoteStampStations.map((s) => s.id));
    expect(session.completeFor(yamanoteStampLine), true);
    session.clear();
    expect(session.count, 0);
    final restarted = StationStampSession();
    expect(restarted.count, 0);
    restarted.dispose();
  });
}
