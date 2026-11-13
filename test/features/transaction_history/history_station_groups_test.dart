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

Map<String, dynamic> asset() =>
    jsonDecode(File(StationCoordinateRepository.assetPath).readAsStringSync())
        as Map<String, dynamic>;
AssetStationDatabase database() => AssetStationDatabase.fromCsv(
  File(AssetStationDatabase.assetPath).readAsStringSync(),
  overrideCsv: File(AssetStationDatabase.overrideAssetPath).readAsStringSync(),
);
StationCode code(List<dynamic> values) => StationCode(
  regionCode: values[0] as int,
  lineCode: values[1] as int,
  stationCode: values[2] as int,
);

void main() {
  test(
    'all reviewed groups preserve every member and never become one station',
    () {
      final data = asset();
      final repo = StationCoordinateRepository.fromJson(jsonEncode(data));
      final db = database();
      var members = 0;
      for (final dynamic g in data['groups'] as List) {
        final resolved = db.resolve(code(g['code'] as List));
        expect(repo.find(resolved), isNull);
        final set = repo.findLocations(resolved)!;
        expect(set.isGroup, isTrue);
        expect(set.points.length, (g['members'] as List).length);
        expect(
          set.points.map((p) => p.name),
          (g['members'] as List).map((dynamic p) => p['name']),
        );
        members += set.points.length;
        expect(() => set.points.clear(), throwsUnsupportedError);
      }
      expect((data['groups'] as List).length, 22);
      expect(members, 72);
    },
  );

  test('bad, duplicated, stale and point-colliding groups fail closed', () {
    final db = database();
    final original = asset();
    final first = (original['groups'] as List).first as Map<String, dynamic>;
    final resolution = db.resolve(code(first['code'] as List));
    for (final mutate
        in <void Function(Map<String, dynamic>, Map<String, dynamic>)>[
          (a, g) => (g['members'] as List).first['lat'] = 0,
          (a, g) => (g['members'] as List).first['name'] = '別駅',
          (a, g) => g['members'] = [],
          (a, g) => g['lat'] = 35,
          (a, g) => g['kind'] = 'area',
          (a, g) => (g['members'] as List).add((g['members'] as List).first),
          (a, g) => (a['groups'] as List).add(g),
          (a, g) =>
              (a['records'] as List).add({...g, 'lat': 35.0, 'lon': 139.0}),
        ]) {
      final changed = asset();
      final group = (changed['groups'] as List).first as Map<String, dynamic>;
      mutate(changed, group);
      final repo = StationCoordinateRepository.fromJson(jsonEncode(changed));
      expect(repo.findLocations(resolution), isNull);
    }
    final repo = StationCoordinateRepository.fromJson(jsonEncode(original));
    expect(
      repo.findLocations(
        StationResolution(
          requestedCode: resolution.requestedCode,
          strategy: StationMatchStrategy.multipleCandidates,
          station: resolution.station,
        ),
      ),
      isNull,
    );
    expect(
      repo.findLocations(
        StationResolution(
          requestedCode: resolution.requestedCode,
          strategy: StationMatchStrategy.exactRegion,
          station: StationRecord(
            code: resolution.station!.code,
            operatorName: '別会社',
            lineName: resolution.station!.lineName,
            stationName: resolution.station!.stationName,
            source: 'test',
          ),
        ),
      ),
      isNull,
    );
  });

  test('real facilities get their own positions, not a nearby station', () {
    final repo = StationCoordinateRepository.fromJson(jsonEncode(asset()));
    final db = database();
    for (final key in [
      [0, 96, 255],
      [0, 170, 99],
      [0, 209, 255],
      [1, 165, 126],
    ]) {
      final found = repo.findLocations(db.resolve(code(key)))!;
      expect(found.kind, 'facility');
      expect(found.points.length, 1);
    }
    expect(
      repo.findLocations(db.resolve(code([2, 162, 45]))),
      isNull,
    ); // Baggage ticket.
    expect(
      repo.findLocations(db.resolve(code([0, 0, 242]))),
      isNull,
    ); // Tokyo ward area.
    expect(() => StationMapLocations([]), throwsArgumentError);
  });

  test(
    'group markers retain all candidates, merge shared locations and draw no route',
    () {
      final from = StationMapLocations([
        const StationCoordinate(35, 139, name: 'A'),
        const StationCoordinate(36, 140, name: 'B'),
      ], kind: 'station_complex');
      final to = StationMapLocations([
        const StationCoordinate(36, 140, name: 'B'),
      ]);
      final map = buildStationGroupGoogleMap(from, to, 'A、B', 'B');
      expect(map.markers.length, 2);
      expect(
        map.markers.every((m) => m.infoWindow.title!.contains('후보')),
        isTrue,
      );
      expect(
        map.markers.any((m) => m.infoWindow.title!.contains('하차')),
        isTrue,
      );
      expect(
        map.markers.map((m) => m.position),
        containsAll([const LatLng(35, 139), const LatLng(36, 140)]),
      );
      expect(map.mapId, isNull);
      expect(map.polylines, isEmpty);
      expect(map.myLocationEnabled, isFalse);
      expect(map.mapToolbarEnabled, isFalse);
    },
  );

  for (final dark in [false, true]) {
    for (final route in [false, true]) {
      testWidgets(
        'group display opens automatically and fits narrow/large text $dark/$route',
        (tester) async {
          tester.view.physicalSize = const Size(320, 1100);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final db = database();
          final repo = StationCoordinateRepository.fromJson(
            jsonEncode(asset()),
          );
          final from = db.resolve(code(route ? [0, 128, 95] : [0, 128, 28]));
          final to = db.resolve(code([0, 1, 232]));
          var loads = 0;
          var builds = 0;
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(1.7)),
                child: child!,
              ),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: HistoryStationMap(
                    stations: ResolvedStationPair(
                      boarding: from,
                      alighting: to,
                    ),
                    displayMode: StationNameDisplayMode.japanese,
                    checkNetwork: () async => true,
                    networkChanges: const Stream<bool>.empty(),
                    loadCoordinates: () async {
                      loads++;
                      return repo;
                    },
                    checkConfiguration: () async => true,
                    mapBuilder: (a, b, c, d) =>
                        throw StateError('must not reduce group to one point'),
                    groupMapBuilder: (a, b, c, d) {
                      builds++;
                      expect(a.isGroup, isTrue);
                      expect(a.points.length, route ? 7 : 6);
                      return const ColoredBox(color: Colors.blue);
                    },
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(loads, 1);
          expect(builds, greaterThan(0));
          expect(find.text('복합역·구간의 후보 위치'), findsOneWidget);
          expect(find.text('파란 핀: 승차 · 붉은 핀: 하차'), findsOneWidget);
          expect(find.textContaining('실제 이용역이나 이동 경로'), findsNothing);
          expect(find.text('지도 보기'), findsNothing);
          expect(find.text('지도 닫기'), findsNothing);
          expect(find.text('지도 새로고침'), findsNothing);
          expect(
            find.byKey(const ValueKey('history-station-map-viewport')),
            findsOneWidget,
          );
          expect(loads, 1);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
