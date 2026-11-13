import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/station_resolver/data/asset_station_database.dart';
import 'package:ic_card_reader/src/features/station_resolver/data/station_coordinate_repository.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_name_display.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_resolution.dart';
import 'package:ic_card_reader/src/features/transaction_history/presentation/widgets/history_station_map.dart';

const code = StationCode(regionCode: 0, lineCode: 1, stationCode: 2);
const station = StationRecord(
  code: code,
  operatorName: 'JR',
  lineName: '線',
  stationName: '東京',
  stationNameKorean: '도쿄',
  source: 'test',
);
const resolved = StationResolution(
  requestedCode: code,
  strategy: StationMatchStrategy.exactRegion,
  station: station,
);
const pair = ResolvedStationPair(boarding: resolved, alighting: resolved);
const row = <String, Object>{
  'code': [0, 1, 2],
  'operator': 'JR',
  'line': '線',
  'name': '東京',
  'lat': 35.68,
  'lon': 139.76,
};
StationCoordinateRepository repository([
  List<Map<String, Object>> rows = const [row],
]) => StationCoordinateRepository.fromJson(
  jsonEncode({'schema': 1, 'records': rows}),
);

void main() {
  testWidgets('bundled coordinate loader preserves lookups across compute', (
    tester,
  ) async {
    final rows =
        (jsonDecode(
                  File(
                    StationCoordinateRepository.assetPath,
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>)['records']
            as List;
    final loaded = await tester.runAsync(
      () => StationCoordinateRepository.load(),
    );
    expect(loaded, isNotNull);
    for (final dynamic raw in rows) {
      final key = raw['code'] as List;
      final code = StationCode(
        regionCode: key[0] as int,
        lineCode: key[1] as int,
        stationCode: key[2] as int,
      );
      final resolution = StationResolution(
        requestedCode: code,
        strategy: StationMatchStrategy.exactRegion,
        station: StationRecord(
          code: code,
          operatorName: raw['operator'] as String,
          lineName: raw['line'] as String,
          stationName: raw['name'] as String,
          source: 'test',
        ),
      );
      expect(
        loaded!.find(resolution),
        isNotNull,
        reason: '$key ${raw['name']}',
      );
    }
    final groups =
        (jsonDecode(
                  File(
                    StationCoordinateRepository.assetPath,
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>)['groups']
            as List;
    for (final dynamic group in groups) {
      final key = group['code'] as List;
      final code = StationCode(
        regionCode: key[0] as int,
        lineCode: key[1] as int,
        stationCode: key[2] as int,
      );
      final resolution = StationResolution(
        requestedCode: code,
        strategy: StationMatchStrategy.exactRegion,
        station: StationRecord(
          code: code,
          operatorName: group['operator'] as String,
          lineName: group['line'] as String,
          stationName: group['name'] as String,
          source: 'test',
        ),
      );
      expect(loaded!.find(resolution), isNull);
      expect(
        loaded.findLocations(resolution)!.points.length,
        (group['members'] as List).length,
      );
    }
  });

  test('full code and all station identity fields must match', () {
    final repo = repository();
    expect(repo.find(resolved)?.latitude, 35.68);
    expect(repo.find(null), isNull);
    for (final strategy in [
      StationMatchStrategy.multipleCandidates,
      StationMatchStrategy.notFound,
      StationMatchStrategy.notApplicable,
    ]) {
      expect(
        repo.find(
          StationResolution(
            requestedCode: code,
            strategy: strategy,
            station: station,
          ),
        ),
        isNull,
      );
    }
    for (final changed in [
      const StationRecord(
        code: code,
        operatorName: '別',
        lineName: '線',
        stationName: '東京',
        source: 'test',
      ),
      const StationRecord(
        code: code,
        operatorName: 'JR',
        lineName: '別',
        stationName: '東京',
        source: 'test',
      ),
      const StationRecord(
        code: code,
        operatorName: 'JR',
        lineName: '線',
        stationName: '別',
        source: 'test',
      ),
      const StationRecord(
        code: StationCode(regionCode: 1, lineCode: 1, stationCode: 2),
        operatorName: 'JR',
        lineName: '線',
        stationName: '東京',
        source: 'test',
      ),
    ]) {
      expect(
        repo.find(
          StationResolution(
            requestedCode: code,
            strategy: StationMatchStrategy.exactRegion,
            station: changed,
          ),
        ),
        isNull,
      );
    }
  });

  test('duplicates, invalid coordinates and schemas are rejected', () {
    expect(repository([row, row]).find(resolved), isNull);
    for (final invalid in [
      {...row, 'lat': 0},
      {...row, 'lon': 180},
      {...row, 'lat': '35'},
      {
        ...row,
        'code': [0, 1],
      },
      {...row, 'name': null},
    ]) {
      final repo = StationCoordinateRepository.fromJson(
        jsonEncode({
          'schema': 1,
          'records': [invalid],
        }),
      );
      expect(repo.find(resolved), isNull);
    }
    expect(
      () => StationCoordinateRepository.fromJson('{"schema":2,"records":[]}'),
      throwsFormatException,
    );
  });

  test('all shipped coordinates resolve against current station database', () {
    final json = File(StationCoordinateRepository.assetPath).readAsStringSync();
    final repo = StationCoordinateRepository.fromJson(json);
    final database = AssetStationDatabase.fromCsv(
      File(AssetStationDatabase.assetPath).readAsStringSync(),
      overrideCsv: File(
        AssetStationDatabase.overrideAssetPath,
      ).readAsStringSync(),
    );
    final rows = (jsonDecode(json) as Map<String, dynamic>)['records'] as List;
    expect(rows.length, 8479);
    for (final raw in rows) {
      final key = raw['code'] as List;
      final resolution = database.resolve(
        StationCode(
          regionCode: key[0] as int,
          lineCode: key[1] as int,
          stationCode: key[2] as int,
        ),
      );
      expect(repo.find(resolution), isNotNull, reason: '$key ${raw['name']}');
    }
    // Public position cross-checks for familiar, distinct stations.
    for (final (name, lat, lon) in [
      ('東京', 35.68, 139.77),
      ('新宿', 35.69, 139.70),
      ('京都', 34.99, 135.76),
      ('大阪', 34.70, 135.50),
    ]) {
      final matches = rows.where((dynamic r) => r['name'] == name).toList();
      expect(matches, isNotEmpty);
      for (final dynamic r in matches) {
        expect((r['lat'] as num).toDouble(), closeTo(lat, .04));
        expect((r['lon'] as num).toDouble(), closeTo(lon, .04));
      }
    }
  });

  test(
    'native map uses ordinary markers without map ID, routes or location',
    () {
      final map = buildStationGoogleMap(
        const StationCoordinate(35, 139),
        const StationCoordinate(36, 140),
        'A',
        'B',
      );
      expect(map.mapId, isNull);
      expect(map.markerType, GoogleMapMarkerType.marker);
      expect(map.markers.length, 2);
      expect(
        map.markers.map((marker) => marker.infoWindow.title),
        containsAll(['승차 · A', '하차 · B']),
      );
      expect(map.polylines, isEmpty);
      expect(map.myLocationEnabled, isFalse);
      expect(map.myLocationButtonEnabled, isFalse);
      expect(map.mapToolbarEnabled, isFalse);
      final same = buildStationGoogleMap(
        const StationCoordinate(35, 139),
        const StationCoordinate(35, 139),
        'A',
        'A',
      );
      expect(same.markers.length, 1);
      expect(same.markers.single.infoWindow.title, '승차·하차 · A');
    },
  );

  test('every runtime station code is covered or explicitly withheld', () {
    final repo = StationCoordinateRepository.fromJson(
      File(StationCoordinateRepository.assetPath).readAsStringSync(),
    );
    final database = AssetStationDatabase.fromCsv(
      File(AssetStationDatabase.assetPath).readAsStringSync(),
      overrideCsv: File(
        AssetStationDatabase.overrideAssetPath,
      ).readAsStringSync(),
    );
    final codes = <StationCode>{};
    for (final path in [
      AssetStationDatabase.assetPath,
      AssetStationDatabase.overrideAssetPath,
    ]) {
      for (final line in File(
        path,
      ).readAsLinesSync().skip(1).where((line) => line.trim().isNotEmpty)) {
        final parts = line.split(',');
        codes.add(
          StationCode(
            regionCode: int.parse(parts[0]),
            lineCode: int.parse(parts[1]),
            stationCode: int.parse(parts[2]),
          ),
        );
      }
    }
    final exclusions =
        (jsonDecode(
                  File(
                    'tool/station_coordinate_exclusions.json',
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>)['records']
            as List;
    exclusions.addAll(
      (jsonDecode(
                File(
                  'tool/station_coordinate_withheld.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>)['records']
          as List,
    );
    final additional =
        jsonDecode(
              File(
                'tool/station_coordinate_additional_locations.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final addedKeys = {
      for (final dynamic r in [
        ...additional['records'] as List,
        ...additional['groups'] as List,
      ])
        (r['code'] as List).join('/'),
    };
    exclusions.removeWhere(
      (dynamic r) => addedKeys.contains((r['code'] as List).join('/')),
    );
    final excluded = {
      for (final dynamic row in exclusions)
        (row['code'] as List).join('/'): row,
    };
    expect(codes.length, 8558);
    expect(excluded.length, 57);
    var covered = 0;
    for (final code in codes) {
      final resolution = database.resolve(code);
      final key = '${code.regionCode}/${code.lineCode}/${code.stationCode}';
      final point = repo.findLocations(resolution);
      if (excluded.containsKey(key)) {
        expect(point, isNull, reason: key);
        expect(resolution.station?.stationName, excluded[key]['name']);
      } else {
        expect(
          point,
          isNotNull,
          reason: '$key ${resolution.station?.stationName}',
        );
        covered++;
      }
    }
    expect(covered, 8501);
    final fukuoka = repo.find(
      database.resolve(
        const StationCode(regionCode: 3, lineCode: 215, stationCode: 101),
      ),
    );
    final dazaifu = repo.find(
      database.resolve(
        const StationCode(regionCode: 3, lineCode: 216, stationCode: 4),
      ),
    );
    expect(fukuoka, isNotNull);
    expect(dazaifu, isNotNull);
    expect(fukuoka!.latitude, closeTo(33.59, .01));
    expect(fukuoka.longitude, closeTo(130.40, .01));
    expect(dazaifu!.latitude, closeTo(33.519, .001));
    expect(dazaifu.longitude, closeTo(130.5314, .001));
  });

  for (final dark in [false, true]) {
    for (final scale in [1.0, 1.7]) {
      testWidgets(
        'online map opens automatically without refresh button $dark/$scale',
        (tester) async {
          tester.view.physicalSize = const Size(320, 1100);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var loads = 0;
          var checks = 0;
          var maps = 0;
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: HistoryStationMap(
                    stations: pair,
                    displayMode: StationNameDisplayMode.korean,
                    checkNetwork: () async => true,
                    networkChanges: const Stream<bool>.empty(),
                    loadCoordinates: () async {
                      loads++;
                      return repository();
                    },
                    checkConfiguration: () async {
                      checks++;
                      return true;
                    },
                    mapBuilder: (from, to, fromName, toName) {
                      maps++;
                      expect(fromName, '도쿄');
                      return const ColoredBox(color: Colors.blue);
                    },
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(loads, 1);
          expect(checks, 1);
          expect(maps, greaterThan(0));
          expect(find.text('지도 보기'), findsNothing);
          expect(find.text('승차 · 도쿄\n하차 · 도쿄'), findsNothing);
          expect(find.textContaining('역 위치 참고용'), findsNothing);
          expect(find.textContaining('Google에 연결'), findsNothing);
          expect(find.textContaining('IP 주소'), findsNothing);
          expect(find.text('파란 핀: 승차 · 붉은 핀: 하차'), findsOneWidget);
          expect(
            tester
                .getSize(
                  find.byKey(const ValueKey('history-station-map-viewport')),
                )
                .height,
            220,
          );
          expect(find.text('지도 닫기'), findsNothing);
          expect(find.text('지도 새로고침'), findsNothing);
          expect(loads, 1);
          expect(
            find.byKey(const ValueKey('history-station-map-viewport')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final issue in ['missing', 'configuration', 'asset']) {
    testWidgets('non-network $issue fallback has no refresh button', (
      tester,
    ) async {
      var checked = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryStationMap(
              stations: issue == 'missing' ? null : pair,
              displayMode: StationNameDisplayMode.japanese,
              checkNetwork: () async => true,
              networkChanges: const Stream<bool>.empty(),
              loadCoordinates: () async {
                if (issue == 'asset') throw const FormatException('test');
                return repository();
              },
              checkConfiguration: () async {
                checked = true;
                return false;
              },
              mapBuilder: (a, b, c, d) =>
                  throw StateError('must not create map'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('지도 새로고침'), findsNothing);
      expect(checked, issue == 'configuration');
      expect(
        find.byKey(const ValueKey('history-station-map-viewport')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('auto map reserves height, loads once and hides refresh', (
    tester,
  ) async {
    final pending = Completer<StationCoordinateRepository>();
    var loads = 0;
    Widget screen(ResolvedStationPair stations) => MaterialApp(
      home: Scaffold(
        body: HistoryStationMap(
          stations: stations,
          displayMode: StationNameDisplayMode.korean,
          checkNetwork: () async => true,
          networkChanges: const Stream<bool>.empty(),
          loadCoordinates: () {
            loads++;
            return pending.future;
          },
          checkConfiguration: () async => true,
          mapBuilder: (a, b, c, d) => const ColoredBox(color: Colors.blue),
        ),
      ),
    );
    await tester.pumpWidget(screen(pair));
    await tester.pump();
    expect(loads, 1);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('history-station-map-loading')))
          .height,
      220,
    );
    expect(find.text('지도 보기'), findsNothing);
    await tester.pumpWidget(
      screen(
        const ResolvedStationPair(boarding: resolved, alighting: resolved),
      ),
    );
    expect(loads, 1);
    pending.complete(repository());
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('history-station-map-viewport')),
      findsOneWidget,
    );
    await tester.pumpWidget(screen(pair));
    await tester.pumpAndSettle();
    expect(loads, 1);
    expect(find.text('지도 닫기'), findsNothing);
    expect(
      find.byKey(const ValueKey('history-station-map-viewport')),
      findsOneWidget,
    );
    expect(find.text('지도 새로고침'), findsNothing);
  });

  testWidgets('a late coordinate load cannot reopen a replaced detail', (
    tester,
  ) async {
    final pending = Completer<StationCoordinateRepository>();
    var loads = 0;
    var checks = 0;
    Widget screen(ResolvedStationPair? stations) => MaterialApp(
      home: Scaffold(
        body: HistoryStationMap(
          stations: stations,
          displayMode: StationNameDisplayMode.korean,
          checkNetwork: () async => true,
          networkChanges: const Stream<bool>.empty(),
          loadCoordinates: () {
            loads++;
            return loads == 1 ? pending.future : Future.value(repository());
          },
          checkConfiguration: () async {
            checks++;
            return true;
          },
          mapBuilder: (a, b, c, d) =>
              throw StateError('stale map must not appear'),
        ),
      ),
    );
    await tester.pumpWidget(screen(pair));
    await tester.pumpWidget(screen(null));
    await tester.pumpAndSettle();
    pending.complete(repository());
    await tester.pumpAndSettle();
    expect(checks, 0);
    expect(
      find.byKey(const ValueKey('history-station-map-viewport')),
      findsNothing,
    );
    expect(find.text('지도 새로고침'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('late configuration and a disposed screen cannot show old maps', (
    tester,
  ) async {
    final configuration = Completer<bool>();
    var checks = 0;
    Widget screen(ResolvedStationPair? stations) => MaterialApp(
      home: Scaffold(
        body: HistoryStationMap(
          stations: stations,
          displayMode: StationNameDisplayMode.korean,
          checkNetwork: () async => true,
          networkChanges: const Stream<bool>.empty(),
          loadCoordinates: () async => repository(),
          checkConfiguration: () {
            checks++;
            return configuration.future;
          },
          mapBuilder: (a, b, c, d) =>
              throw StateError('stale map must not appear'),
        ),
      ),
    );
    await tester.pumpWidget(screen(pair));
    await tester.pump();
    expect(checks, 1);
    await tester.pumpWidget(screen(null));
    await tester.pumpAndSettle();
    configuration.complete(true);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('history-station-map-viewport')),
      findsNothing,
    );
    final late = Completer<StationCoordinateRepository>();
    await tester.pumpWidget(
      MaterialApp(
        home: HistoryStationMap(
          stations: pair,
          displayMode: StationNameDisplayMode.korean,
          checkNetwork: () async => true,
          networkChanges: const Stream<bool>.empty(),
          loadCoordinates: () => late.future,
          checkConfiguration: () async => true,
          mapBuilder: (a, b, c, d) =>
              throw StateError('disposed map must not appear'),
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    late.complete(repository());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
