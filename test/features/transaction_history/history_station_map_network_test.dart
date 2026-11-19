import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/station_resolver/data/station_coordinate_repository.dart';
import 'package:ic_card_reader/src/features/station_resolver/data/station_map_network.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_name_display.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_resolution.dart';
import 'package:ic_card_reader/src/features/transaction_history/presentation/widgets/history_station_map.dart';

const _code = StationCode(regionCode: 0, lineCode: 1, stationCode: 1);
const _station = StationRecord(
  code: _code,
  operatorName: 'JR',
  lineName: '線',
  stationName: '東京',
  source: 'test',
);
const _resolved = StationResolution(
  requestedCode: _code,
  strategy: StationMatchStrategy.exactRegion,
  station: _station,
);
const _pair = ResolvedStationPair(boarding: _resolved, alighting: _resolved);
StationCoordinateRepository _repository() =>
    StationCoordinateRepository.fromJson(
      jsonEncode({
        'schema': 1,
        'records': [
          {
            'code': [0, 1, 1],
            'name': '東京',
            'operator': 'JR',
            'line': '線',
            'lat': 35.68,
            'lon': 139.76,
          },
        ],
      }),
    );
Widget _screen(HistoryStationMap map, {bool dark = false}) => MaterialApp(
  theme: dark ? AppTheme.dark : AppTheme.light,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.7)),
    child: child!,
  ),
  home: Scaffold(body: SingleChildScrollView(child: map)),
);
const _viewport = ValueKey('history-station-map-viewport');

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'offline avoids all maps and reconnect refresh restores them $dark',
      (tester) async {
        tester.view.physicalSize = const Size(320, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var online = false;
        var loads = 0;
        var checks = 0;
        var builds = 0;
        await tester.pumpWidget(
          _screen(
            HistoryStationMap(
              stations: _pair,
              displayMode: StationNameDisplayMode.japanese,
              checkNetwork: () async => online,
              networkChanges: const Stream<bool>.empty(),
              loadCoordinates: () async {
                loads++;
                return _repository();
              },
              checkConfiguration: () async {
                checks++;
                return true;
              },
              mapBuilder: (a, b, c, d) {
                builds++;
                return const ColoredBox(color: Colors.blue);
              },
            ),
            dark: dark,
          ),
        );
        await tester.pumpAndSettle();
        expect(loads, 0);
        expect(checks, 0);
        expect(builds, 0);
        expect(find.byKey(_viewport), findsNothing);
        expect(find.textContaining('인터넷 연결을 확인'), findsOneWidget);
        expect(find.text('지도 새로고침'), findsOneWidget);
        final buttonFinder = find.byKey(
          const ValueKey('history-station-map-refresh'),
        );
        final button = tester.widget<OutlinedButton>(buttonFinder);
        final scheme = (dark ? AppTheme.dark : AppTheme.light).colorScheme;
        final side = button.style!.side!.resolve({})!;
        expect(side.width, 1.3);
        expect(side.color, scheme.primary);
        expect(button.style!.foregroundColor!.resolve({}), scheme.primary);
        expect(button.style!.minimumSize!.resolve({}), const Size(144, 40));
        expect(button.style!.tapTargetSize, MaterialTapTargetSize.padded);
        expect(
          button.style!.padding!.resolve({}),
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        );
        expect(button.style!.textStyle!.resolve({})!.fontSize, 13);
        expect(tester.getCenter(buttonFinder).dx, closeTo(160, .1));
        expect(tester.getSize(buttonFinder).height, greaterThanOrEqualTo(48));
        expect(tester.getSize(buttonFinder).width, lessThan(288));
        expect(
          tester.getTopLeft(find.text('역 좌표: Wikidata · CC0')).dy -
              tester.getBottomLeft(buttonFinder).dy,
          closeTo(12, .1),
        );
        expect(find.text('지도 닫기'), findsNothing);
        await tester.tap(find.text('지도 새로고침'));
        await tester.pumpAndSettle();
        expect(loads, 0);
        online = true;
        await tester.tap(find.text('지도 새로고침'));
        await tester.pumpAndSettle();
        expect(loads, 1);
        expect(checks, 1);
        expect(builds, greaterThan(0));
        expect(find.byKey(_viewport), findsOneWidget);
        expect(find.text('지도 새로고침'), findsNothing);
        expect(find.text('파란 핀: 승차 · 붉은 핀: 하차'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'loss removes an existing map; regained connection waits for refresh',
    (tester) async {
      var online = true;
      var cancels = 0;
      final events = StreamController<bool>.broadcast(
        onCancel: () => cancels++,
      );
      addTearDown(events.close);
      await tester.pumpWidget(
        _screen(
          HistoryStationMap(
            stations: _pair,
            displayMode: StationNameDisplayMode.japanese,
            checkNetwork: () async => online,
            networkChanges: events.stream,
            loadCoordinates: () async => _repository(),
            checkConfiguration: () async => true,
            mapBuilder: (a, b, c, d) => const ColoredBox(color: Colors.blue),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(_viewport), findsOneWidget);
      expect(find.text('지도 새로고침'), findsNothing);
      online = false;
      events.add(false);
      await tester.pumpAndSettle();
      expect(find.byKey(_viewport), findsNothing);
      expect(find.text('지도 새로고침'), findsOneWidget);
      online = true;
      events.add(true);
      await tester.pumpAndSettle();
      expect(find.byKey(_viewport), findsNothing);
      await tester.tap(find.text('지도 새로고침'));
      await tester.pumpAndSettle();
      expect(find.byKey(_viewport), findsOneWidget);
      expect(find.text('지도 새로고침'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(cancels, 1);
    },
  );

  testWidgets(
    'loss cancels in-flight map opening and late coordinates stay hidden',
    (tester) async {
      var online = true;
      final pending = Completer<StationCoordinateRepository>();
      final events = StreamController<bool>.broadcast();
      addTearDown(events.close);
      await tester.pumpWidget(
        _screen(
          HistoryStationMap(
            stations: _pair,
            displayMode: StationNameDisplayMode.japanese,
            checkNetwork: () async => online,
            networkChanges: events.stream,
            loadCoordinates: () => pending.future,
            checkConfiguration: () async => true,
            mapBuilder: (a, b, c, d) => const ColoredBox(color: Colors.blue),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('지도 새로고침'), findsNothing);
      online = false;
      events.add(false);
      await tester.pumpAndSettle();
      pending.complete(_repository());
      await tester.pumpAndSettle();
      expect(find.byKey(_viewport), findsNothing);
      online = true;
      events.add(true);
      await tester.pumpAndSettle();
      expect(find.byKey(_viewport), findsNothing);
      await tester.tap(find.text('지도 새로고침'));
      await tester.pumpAndSettle();
      expect(find.byKey(_viewport), findsOneWidget);
    },
  );

  testWidgets('network is checked again before constructing the map', (
    tester,
  ) async {
    var checks = 0;
    await tester.pumpWidget(
      _screen(
        HistoryStationMap(
          stations: _pair,
          displayMode: StationNameDisplayMode.japanese,
          checkNetwork: () async => ++checks == 1,
          networkChanges: const Stream<bool>.empty(),
          loadCoordinates: () async => _repository(),
          checkConfiguration: () async => true,
          mapBuilder: (a, b, c, d) => throw StateError('network was lost'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(checks, 2);
    expect(find.byKey(_viewport), findsNothing);
    expect(find.textContaining('인터넷 연결을 확인'), findsOneWidget);
  });

  for (final issue in ['exception', 'timeout', 'stream']) {
    testWidgets('network $issue fails closed and offers refresh', (
      tester,
    ) async {
      final events = StreamController<bool>.broadcast();
      addTearDown(events.close);
      await tester.pumpWidget(
        _screen(
          HistoryStationMap(
            stations: _pair,
            displayMode: StationNameDisplayMode.japanese,
            checkNetwork: () => issue == 'timeout'
                ? Completer<bool>().future
                : Future.error(StateError('unavailable')),
            networkChanges: events.stream,
            loadCoordinates: () =>
                throw StateError('must not read coordinates offline'),
            checkConfiguration: () =>
                throw StateError('must not initialize maps offline'),
            mapBuilder: (a, b, c, d) =>
                throw StateError('must not construct maps offline'),
          ),
        ),
      );
      if (issue == 'stream') events.addError(StateError('monitor unavailable'));
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.byKey(_viewport), findsNothing);
      expect(find.text('지도 새로고침'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('platform network snapshot is true only for a true reply', (
    tester,
  ) async {
    const channel = MethodChannel('app.iccardreader/maps');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    for (final value in [true, false, null, 'invalid']) {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'isNetworkAvailable');
        return value;
      });
      expect(await StationMapNetwork.isOnline(), value == true);
    }
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(code: 'unavailable'),
    );
    expect(await StationMapNetwork.isOnline(), isFalse);
  });

  test('native network stream shares one listener and releases it', () async {
    const name = 'app.iccardreader/maps_network';
    const channel = MethodChannel(name);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    var listens = 0;
    var cancels = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'listen') listens++;
      if (call.method == 'cancel') cancels++;
      return null;
    });
    final a = <bool>[];
    final b = <bool>[];
    final first = StationMapNetwork.changes.listen(a.add);
    final second = StationMapNetwork.changes.listen(b.add);
    await Future<void>.delayed(Duration.zero);
    for (final value in [false, false, true]) {
      ServicesBinding.instance.channelBuffers.push(
        name,
        const StandardMethodCodec().encodeSuccessEnvelope(value),
        (_) {},
      );
      await Future<void>.delayed(Duration.zero);
    }
    expect(listens, 1);
    expect(a, [false, true]);
    expect(b, [false, true]);
    await first.cancel();
    expect(cancels, 0);
    await second.cancel();
    await Future<void>.delayed(Duration.zero);
    expect(cancels, 1);
    messenger.setMockMethodCallHandler(channel, null);
  });

  test(
    'Android bridge contract has validated capabilities and normal permission only',
    () {
      final monitor = File(
        'android/app/src/main/kotlin/app/iccardreader/ic_card_reader/MapNetworkMonitor.kt',
      ).readAsStringSync();
      final activity = File(
        'android/app/src/main/kotlin/app/iccardreader/ic_card_reader/MainActivity.kt',
      ).readAsStringSync();
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      expect(monitor, contains('NET_CAPABILITY_INTERNET'));
      expect(monitor, contains('NET_CAPABILITY_VALIDATED'));
      expect(monitor, contains('registerDefaultNetworkCallback'));
      expect(monitor, contains('unregisterNetworkCallback'));
      expect(activity, contains('isNetworkAvailable'));
      expect(activity, contains('cleanUpFlutterEngine'));
      expect(manifest, contains('android.permission.ACCESS_NETWORK_STATE'));
      expect(
        manifest,
        isNot(contains('android.permission.ACCESS_FINE_LOCATION')),
      );
    },
  );
}
