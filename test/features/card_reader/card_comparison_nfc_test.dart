import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_diagnostics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/card_reader/data/nfc_manager_card_reader.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_comparison_session.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_scan_result.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/ica_protocol.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/raw_history_block.dart';
import 'package:ic_card_reader/src/features/transaction_history/data/transit_history_parser.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
// Test-only DTO construction for a real NFC-F reader callback.
// ignore: implementation_imports
import 'package:nfc_manager/src/nfc_manager_android/pigeon.g.dart';
import '../../support/ica_fixture.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_brand_identity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = BasicMessageChannel<Object?>(
    'dev.flutter.pigeon.nfc_manager.HostApiPigeon.nfcFTransceive',
    HostApiPigeon.pigeonChannelCodec,
  );
  final idm = Uint8List.fromList(List.generate(8, (i) => i + 1));
  final tag = NfcTag(
    data: TagPigeon(
      handle: 'comparison-test',
      id: idm,
      techList: ['android.nfc.tech.NfcF'],
      nfcF: NfcFPigeon(
        manufacturer: Uint8List(8),
        systemCode: Uint8List.fromList([0, 3]),
      ),
    ),
  );

  setUp(() {
    messenger.setMockDecodedMessageHandler(channel, (message) async {
      final command = (message! as List)[1] as Uint8List;
      final block = Uint8List(16);
      final service = command[11] | command[12] << 8;
      if (service == 0x090F && command.last == 0) {
        block[0] = 0x16;
        block[1] = 1;
        block[10] = 0xB0;
        block[11] = 4;
      }
      return [
        Uint8List.fromList([29, 7, ...idm, 0, 0, 1, ...block]),
      ];
    });
  });
  tearDown(() => messenger.setMockDecodedMessageHandler(channel, null));

  final brandPatterns = <({String name, Set<int> present, bool suica})>[
    (name: 'physical Suica', present: {0x1808, 0x18C8}, suica: true),
    (name: 'mobile Suica or regional family', present: {0x1808}, suica: true),
    (name: 'PASMO', present: {0x1CC8, 0x1D08}, suica: false),
    (name: 'ICOCA', present: {0x1A48, 0x1A88, 0x9608}, suica: false),
    (name: 'TOICA', present: {0x1E08, 0x1E48, 0x1E8B}, suica: false),
    (name: 'nimoca', present: {0x1F48, 0x1FC8, 0x2008}, suica: false),
    (name: 'Hayakaken', present: {0x2448, 0x2488}, suica: false),
    (name: 'PASMO incomplete', present: {0x1CC8}, suica: false),
    (name: 'ICOCA incomplete', present: {0x1A48, 0x1A88}, suica: false),
    (name: 'TOICA incomplete', present: {0x1E08, 0x1E48}, suica: false),
    (name: 'nimoca incomplete', present: {0x1F48, 0x1FC8}, suica: false),
    (name: 'Hayakaken incomplete', present: {0x2448}, suica: false),
    (name: 'unknown', present: {}, suica: false),
    (name: 'conflicting ICOCA', present: {0x1808, 0x1A48}, suica: false),
    (name: 'conflict in final batch', present: {0x1808, 0x2448}, suica: false),
    (name: 'Kitaca', present: {0x208B, 0x20CB}, suica: false),
    (name: 'manaca', present: {0x9888, 0x98CC}, suica: false),
    (name: 'SUGOCA', present: {0x21C8, 0x2208}, suica: false),
    (name: 'SUGOCA incomplete', present: {0x21C8}, suica: false),
    (name: 'SUGOCA second only', present: {0x2208}, suica: false),
    (name: 'SUGOCA conflict', present: {0x21C8, 0x2208, 0x1808}, suica: false),
    (name: 'PiTaPa not enabled', present: {0x1B88, 0x9748}, suica: false),
    (name: 'Kitaca incomplete', present: {0x208B}, suica: false),
    (name: 'manaca incomplete', present: {0x98CC}, suica: false),
    (
      name: 'Kitaca manaca conflict',
      present: {0x208B, 0x20CB, 0x9888},
      suica: false,
    ),
    (name: 'Suica Kitaca conflict', present: {0x1808, 0x208B}, suica: false),
  ];
  for (final comparison in [false, true]) {
    for (final sample in brandPatterns) {
      test(
        '${comparison ? 'comparison' : 'normal'} scan optional identity: ${sample.name}',
        () async {
          final requests = <int>[];
          final logs = <String>[];
          final savedPrint = debugPrint;
          debugPrint = (String? value, {int? wrapWidth}) {
            if (value != null) logs.add(value);
          };
          addTearDown(() => debugPrint = savedPrint);
          messenger.setMockDecodedMessageHandler(channel, (message) async {
            final command = (message! as List)[1] as Uint8List;
            requests.add(command[1]);
            if (command[1] == 2) {
              final codes = [
                for (var i = 0; i < command[10]; i++)
                  command[11 + i * 2] | (command[12 + i * 2] << 8),
              ];
              return [
                Uint8List.fromList([
                  11 + codes.length * 2,
                  3,
                  ...idm,
                  codes.length,
                  for (final code in codes)
                    ...sample.present.contains(code) ? [0, 0] : [255, 255],
                ]),
              ];
            }
            final block = Uint8List(16);
            if ((command[11] | command[12] << 8) == 0x090F &&
                command.last == 0) {
              block[0] = 0x16;
              block[1] = 1;
              block[10] = 0xB0;
              block[11] = 4;
            }
            return [
              Uint8List.fromList([29, 7, ...idm, 0, 0, 1, ...block]),
            ];
          });
          final manager = _Manager();
          final reader = NfcManagerCardReader(
            manager: manager,
            androidAdapterStates: const Stream.empty(),
          );
          final session = CardComparisonSession();
          addTearDown(session.dispose);
          final scan = comparison
              ? reader.scanForComparison(sessionKey: session.sessionKey)
              : reader.scan();
          await manager.started.future;
          manager.discovered!(tag);
          final result = await scan;
          expect(result.brandIdentity, switch (sample.name) {
            'Kitaca' => CardBrandIdentity.kitaca,
            'manaca' => CardBrandIdentity.manaca,
            'SUGOCA' => CardBrandIdentity.sugoca,
            'PASMO' => CardBrandIdentity.pasmo,
            'ICOCA' => CardBrandIdentity.icoca,
            'TOICA' => CardBrandIdentity.toica,
            'nimoca' => CardBrandIdentity.nimoca,
            'Hayakaken' => CardBrandIdentity.hayakaken,
            _ => sample.suica ? CardBrandIdentity.suicaFamily : null,
          });
          expect(
            const TransitHistoryParser().currentBalance(result.blocks),
            1200,
          );
          expect(result.diagnosticReport, isNull);
          expect(
            result.comparisonToken,
            comparison ? comparisonTokenFor(idm, session.sessionKey) : isNull,
          );
          expect(requests.where((code) => code == 2), hasLength(5));
          expect(requests.takeWhile((code) => code != 2), everyElement(6));
          expect(
            logs.where((log) => log.contains('CARD_DIAGNOSTICS')),
            isEmpty,
          );
          expect(logs.join(), isNot(contains('0102030405060708')));
          expect(manager.stops, 1);
        },
      );
    }
  }

  for (final comparison in [false, true]) {
    for (final failure in ['platform', 'invalid', 'timeout']) {
      test(
        '${comparison ? 'comparison' : 'normal'} optional brand $failure preserves successfully read history',
        () async {
          final pending = Completer<Object?>();
          var serviceRequests = 0;
          messenger.setMockDecodedMessageHandler(channel, (message) async {
            final command = (message! as List)[1] as Uint8List;
            if (command[1] == 2) {
              serviceRequests++;
              if (failure == 'timeout') return pending.future;
              if (failure == 'platform') {
                return ['IOException', 'not logged', null];
              }
              return [
                Uint8List.fromList([0]),
              ];
            }
            final block = Uint8List(16);
            if ((command[11] | command[12] << 8) == 0x090F &&
                command.last == 0) {
              block[0] = 0x16;
              block[1] = 1;
              block[10] = 0xB0;
              block[11] = 4;
            }
            return [
              Uint8List.fromList([29, 7, ...idm, 0, 0, 1, ...block]),
            ];
          });
          final manager = _Manager();
          final reader = NfcManagerCardReader(
            manager: manager,
            androidAdapterStates: const Stream.empty(),
          );
          final session = CardComparisonSession();
          addTearDown(session.dispose);
          final scan = comparison
              ? reader.scanForComparison(sessionKey: session.sessionKey)
              : reader.scan();
          await manager.started.future;
          manager.discovered!(tag);
          final elapsed = Stopwatch()..start();
          final result = await scan;
          expect(result.brandIdentity, isNull);
          expect(
            result.comparisonToken,
            comparison ? comparisonTokenFor(idm, session.sessionKey) : isNull,
          );
          expect(
            const TransitHistoryParser().currentBalance(result.blocks),
            1200,
          );
          expect(serviceRequests, 1);
          expect(elapsed.elapsed, lessThan(const Duration(seconds: 2)));
          if (!pending.isCompleted) pending.complete([Uint8List(1)]);
          await Future<void>.delayed(Duration.zero);
          expect(serviceRequests, 1);
          expect(manager.stops, 1);
        },
      );
    }
  }

  test(
    'ICa accepts read-only native channel responses without modifying them',
    () async {
      final services = <int>[];
      final nativePollingReply = Uint8List.fromList([
        20,
        1,
        ...idm,
        ...List.filled(8, 0),
        0x80,
        0xEF,
      ]).asUnmodifiableView();
      expect(
        () => nativePollingReply.fillRange(0, nativePollingReply.length, 0),
        throwsUnsupportedError,
      );
      // A decoded-message mock re-encodes into a writable buffer. Return raw
      // read-only ByteData to exercise the engine/native-buffer boundary instead.
      messenger.setMockMessageHandler(channel.name, (message) async {
        final args = channel.codec.decodeMessage(message) as List;
        final command = args[1] as Uint8List;
        final Uint8List response;
        if (command[1] == 0) {
          response = nativePollingReply;
        } else {
          services.add(command[11] | command[12] << 8);
          final bytes = command.last == 0 ? icaFixture().bytes : Uint8List(16);
          response = Uint8List.fromList([29, 7, ...idm, 0, 0, 1, ...bytes]);
        }
        return channel.codec.encodeMessage([response])!.asUnmodifiableView();
      });
      final manager = _Manager();
      final reader = NfcManagerCardReader(
        manager: manager,
        androidAdapterStates: const Stream.empty(),
      );
      final scan = reader.scan();
      await manager.started.future;
      manager.discovered!(_icaTag(idm));
      final result = await scan;
      expect(services, [0x898F, 0x898F]);
      expect(result.brandIdentity, CardBrandIdentity.ica);
      expect(const TransitHistoryParser().currentBalance(result.blocks), 1234);
      expect(nativePollingReply.sublist(2, 10), idm);
      expect(manager.stops, 1);
    },
  );

  test(
    'opt-in trace separates ICa polling failure from first history failure',
    () async {
      for (final failPolling in [true, false]) {
        final logs = <String>[];
        final saved = debugPrint;
        debugPrint = (String? value, {int? wrapWidth}) {
          if (value != null) logs.add(value);
        };
        try {
          messenger.setMockDecodedMessageHandler(channel, (message) async {
            final command = (message! as List)[1] as Uint8List;
            if (!failPolling && command[1] == 0) {
              return [
                Uint8List.fromList([
                  20,
                  1,
                  ...idm,
                  ...List.filled(8, 0),
                  0x80,
                  0xEF,
                ]),
              ];
            }
            return [
              'IOException',
              'SECRET_CARD_AND_NATIVE_ERROR',
              'SECRET_STACK',
            ];
          });
          final manager = _Manager();
          final reader = NfcManagerCardReader(
            manager: manager,
            androidAdapterStates: const Stream.empty(),
          );
          final scan = reader.scan();
          final expectation = expectLater(
            scan,
            throwsA(
              isA<CardScanException>().having(
                (e) => e.kind,
                'kind',
                CardScanFailureKind.tagLost,
              ),
            ),
          );
          await manager.started.future;
          manager.discovered!(_icaTag(idm));
          await expectation;
          if (cardDiagnosticsEnabled) {
            expect(logs, anyElement(contains('"stage":"routeSelected"')));
            expect(
              logs,
              anyElement(
                allOf(
                  contains(
                    '"stage":"${failPolling ? 'icaPollingStart' : 'icaHistoryStart'}"',
                  ),
                  contains('"issue":"platformError"'),
                ),
              ),
            );
            expect(logs, anyElement(contains('"stage":"scanFailed"')));
            expect(logs.join(), isNot(contains('SECRET')));
            expect(logs.join(), isNot(contains('0102030405060708')));
          } else {
            expect(logs, isEmpty);
          }
        } finally {
          debugPrint = saved;
        }
      }
    },
  );

  test(
    '80EF uses 898F and rejects a failed first read without common fallback',
    () async {
      // Diagnostic reproduction only, not a real ICa service-response fixture.
      final requested = <int>[];
      messenger.setMockDecodedMessageHandler(channel, (message) async {
        final command = (message! as List)[1] as Uint8List;
        if (command[1] == 0) {
          return [
            Uint8List.fromList([
              20,
              1,
              ...idm,
              ...List.filled(8, 0),
              0x80,
              0xEF,
            ]),
          ];
        }
        requested.add(command[11] | command[12] << 8);
        return [
          Uint8List.fromList([12, 7, ...idm, 1, 0xA1]),
        ];
      });
      final icaTag = NfcTag(
        data: TagPigeon(
          handle: 'ica-diagnostic-reproduction',
          id: idm,
          techList: ['android.nfc.tech.NfcF'],
          nfcF: NfcFPigeon(
            manufacturer: Uint8List(8),
            systemCode: Uint8List.fromList([0x80, 0xEF]),
          ),
        ),
      );
      final manager = _Manager();
      final reader = NfcManagerCardReader(
        manager: manager,
        androidAdapterStates: const Stream.empty(),
      );
      final scan = reader.scan();
      final expectation = expectLater(
        scan,
        throwsA(
          isA<CardScanException>().having(
            (e) => e.kind,
            'kind',
            CardScanFailureKind.invalidResponse,
          ),
        ),
      );
      await manager.started.future;
      manager.discovered!(icaTag);
      await expectation;
      expect(requested, [0x898F]);
      expect(manager.stops, 1);
    },
  );

  test(
    'ICa invalid polling, IDm, record date and read framing fail safely',
    () async {
      for (final mode in ['polling', 'idm', 'date', 'length']) {
        var calls = 0;
        messenger.setMockDecodedMessageHandler(channel, (message) async {
          calls++;
          final command = (message! as List)[1] as Uint8List;
          if (command[1] == 0) {
            return [
              Uint8List.fromList([
                20,
                1,
                ...idm,
                ...List.filled(8, 0),
                0x80,
                mode == 'polling' ? 0 : 0xEF,
              ]),
            ];
          }
          final block = icaFixture().bytes;
          if (mode == 'date') block[0] = block[1] = 0;
          final reply = Uint8List.fromList([29, 7, ...idm, 0, 0, 1, ...block]);
          if (mode == 'idm') reply[2] ^= 1;
          if (mode == 'length') reply[0] = 28;
          return [reply];
        });
        final manager = _Manager();
        final reader = NfcManagerCardReader(
          manager: manager,
          androidAdapterStates: const Stream.empty(),
        );
        final scan = reader.scan();
        final expectation = expectLater(
          scan,
          throwsA(
            isA<CardScanException>().having(
              (e) => e.kind,
              'kind',
              CardScanFailureKind.invalidResponse,
            ),
          ),
        );
        await manager.started.future;
        manager.discovered!(_icaTag(idm));
        await expectation;
        expect(calls, mode == 'polling' ? 1 : 2);
        expect(manager.stops, 1);
      }
    },
  );

  test('ICa empty records do not create a zero-yen card', () async {
    for (final byte in [0, 255]) {
      messenger.setMockDecodedMessageHandler(channel, (message) async {
        final command = (message! as List)[1] as Uint8List;
        return [
          command[1] == 0
              ? Uint8List.fromList([
                  20,
                  1,
                  ...idm,
                  ...List.filled(8, 0),
                  0x80,
                  0xEF,
                ])
              : Uint8List.fromList([
                  29,
                  7,
                  ...idm,
                  0,
                  0,
                  1,
                  ...List.filled(16, byte),
                ]),
        ];
      });
      final manager = _Manager();
      final reader = NfcManagerCardReader(
        manager: manager,
        androidAdapterStates: const Stream.empty(),
      );
      final scan = reader.scan();
      final expectation = expectLater(
        scan,
        throwsA(
          isA<CardScanException>().having(
            (e) => e.kind,
            'kind',
            CardScanFailureKind.noHistory,
          ),
        ),
      );
      await manager.started.future;
      manager.discovered!(_icaTag(idm));
      await expectation;
    }
  });

  for (final tailError in [false, true]) {
    test('ICa read limit and optional tail status ($tailError)', () async {
      var reads = 0;
      messenger.setMockDecodedMessageHandler(channel, (message) async {
        final command = (message! as List)[1] as Uint8List;
        if (command[1] == 0) {
          return [
            Uint8List.fromList([
              20,
              1,
              ...idm,
              ...List.filled(8, 0),
              0x80,
              0xEF,
            ]),
          ];
        }
        reads++;
        if (tailError && reads > 1) {
          return [
            Uint8List.fromList([12, 7, ...idm, 1, 0xA1]),
          ];
        }
        return [
          Uint8List.fromList([29, 7, ...idm, 0, 0, 1, ...icaFixture().bytes]),
        ];
      });
      final manager = _Manager();
      final reader = NfcManagerCardReader(
        manager: manager,
        androidAdapterStates: const Stream.empty(),
      );
      final scan = reader.scan();
      await manager.started.future;
      manager.discovered!(_icaTag(idm));
      final result = await scan;
      expect(result.blocks.length, tailError ? 1 : 20);
      expect(reads, tailError ? 2 : 20);
    });
  }

  test('cancelled brand lookup cannot leak into a later normal scan', () async {
    final firstProbe = Completer<void>();
    final oldReply = Completer<Object?>();
    var probes = 0;
    messenger.setMockDecodedMessageHandler(channel, (message) async {
      final command = (message! as List)[1] as Uint8List;
      if (command[1] == 2) {
        probes++;
        if (probes == 1) {
          firstProbe.complete();
          return oldReply.future;
        }
        return [
          Uint8List.fromList([
            11 + command[10] * 2,
            3,
            ...idm,
            command[10],
            ...List.filled(command[10] * 2, 255),
          ]),
        ];
      }
      final block = Uint8List(16);
      if ((command[11] | command[12] << 8) == 0x090F && command.last == 0) {
        block[0] = 0x16;
        block[1] = 1;
        block[10] = 0xB0;
        block[11] = 4;
      }
      return [
        Uint8List.fromList([29, 7, ...idm, 0, 0, 1, ...block]),
      ];
    });
    final manager = _Manager();
    final reader = NfcManagerCardReader(
      manager: manager,
      androidAdapterStates: const Stream.empty(),
    );
    final first = reader.scan();
    final cancelled = expectLater(first, throwsA(isA<CardScanException>()));
    await manager.started.future;
    manager.discovered!(tag);
    await firstProbe.future;
    await reader.cancel();
    await cancelled;
    manager.started = Completer<void>();
    final next = reader.scan();
    await manager.started.future;
    manager.discovered!(tag);
    final result = await next;
    expect(result.brandIdentity, isNull);
    expect(const TransitHistoryParser().currentBalance(result.blocks), 1200);
    oldReply.complete([
      Uint8List.fromList([21, 3, ...idm, 5, ...List.filled(10, 0)]),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(probes, 6); // one cancelled + five new; no old follow-up request.
    expect(manager.stops, 2);
  });

  test('ICa polling validates framing and system without exposing IDm', () {
    expect(IcaProtocol.pollingCommand(), [6, 0, 0x80, 0xEF, 1, 0]);
    final response = [20, 1, ...idm, ...List.filled(8, 0), 0x80, 0xEF];
    expect(IcaProtocol.parsePollingIdm(response), idm);
    for (final bad in <List<int>>[
      [],
      response.take(19).toList(),
      [...response]..[0] = 19,
      [...response]..[1] = 7,
      [...response]..[19] = 3,
      [...response, 0],
    ]) {
      expect(IcaProtocol.parsePollingIdm(bad), isNull);
    }
  });

  for (final comparison in [false, true]) {
    test(
      'ICa normal/comparison reads with selected IDm and no 090F/gate requests ($comparison)',
      () async {
        final selected = List.generate(8, (i) => i + 50);
        final services = <int>[];
        messenger.setMockDecodedMessageHandler(channel, (message) async {
          final command = (message! as List)[1] as Uint8List;
          if (command[1] == 0) {
            return [
              Uint8List.fromList([
                20,
                1,
                ...selected,
                ...List.filled(8, 0),
                0x80,
                0xEF,
              ]),
            ];
          }
          expect(command.sublist(2, 10), selected);
          services.add(command[11] | command[12] << 8);
          final block = command.last == 0 ? icaFixture().bytes : Uint8List(16);
          return [
            Uint8List.fromList([29, 7, ...selected, 0, 0, 1, ...block]),
          ];
        });
        final manager = _Manager();
        final reader = NfcManagerCardReader(
          manager: manager,
          androidAdapterStates: const Stream.empty(),
        );
        final session = CardComparisonSession();
        addTearDown(session.dispose);
        final scan = comparison
            ? reader.scanForComparison(sessionKey: session.sessionKey)
            : reader.scan();
        await manager.started.future;
        manager.discovered!(_icaTag(idm));
        final result = await scan;
        expect(services, [0x898F, 0x898F]);
        expect(result.currentGateTravel, isNull);
        expect(result.diagnosticReport, isNull);
        expect(result.blocks.single.format, HistoryRecordFormat.ica);
        expect(
          const TransitHistoryParser().currentBalance(result.blocks),
          1234,
        );
        expect(
          result.comparisonToken,
          comparison
              ? comparisonTokenFor(selected, session.sessionKey)
              : isNull,
        );
        expect(result.brandIdentity, CardBrandIdentity.ica);
        if (comparison) expect(session.accept(result).balance, 1234);
        expect(manager.stops, 1);
      },
    );
  }

  test(
    'cancelled ICa polling never issues history reads or completes another scan',
    () async {
      final polling = Completer<Object?>();
      var calls = 0;
      messenger.setMockDecodedMessageHandler(channel, (_) {
        calls++;
        return polling.future;
      });
      final manager = _Manager();
      final reader = NfcManagerCardReader(
        manager: manager,
        androidAdapterStates: const Stream.empty(),
      );
      final scan = reader.scan();
      final expectation = expectLater(scan, throwsA(isA<CardScanException>()));
      await manager.started.future;
      manager.discovered!(_icaTag(idm));
      while (calls == 0) {
        await Future<void>.delayed(Duration.zero);
      }
      await reader.cancel();
      await expectation;
      polling.complete([
        Uint8List.fromList([20, 1, ...idm, ...List.filled(8, 0), 0x80, 0xEF]),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(calls, 1);
      expect(manager.stops, 1);
    },
  );

  test(
    'cancel during adapter check prevents a late NFC session start',
    () async {
      final manager = _Manager()
        ..availabilityPending = Completer<NfcAvailability>();
      final reader = NfcManagerCardReader(
        manager: manager,
        androidAdapterStates: const Stream.empty(),
      );
      final session = CardComparisonSession();
      addTearDown(session.dispose);
      final scan = reader.scanForComparison(sessionKey: session.sessionKey);
      final expectation = expectLater(
        scan,
        throwsA(
          isA<CardScanException>().having(
            (e) => e.kind,
            'kind',
            CardScanFailureKind.cancelled,
          ),
        ),
      );
      await reader.cancel();
      manager.availabilityPending!.complete(NfcAvailability.enabled);
      await expectation;
      expect(manager.started.isCompleted, isFalse);
      expect(manager.stops, 0);
    },
  );

  test(
    'real reader returns session-only keyed identity, never on normal scans',
    () async {
      final manager = _Manager();
      final reader = NfcManagerCardReader(
        manager: manager,
        androidAdapterStates: const Stream.empty(),
      );
      final session = CardComparisonSession();
      addTearDown(session.dispose);
      final firstFuture = reader.scanForComparison(
        sessionKey: session.sessionKey,
      );
      await manager.started.future;
      manager.discovered!(tag);
      final first = await firstFuture;
      expect(
        first.comparisonToken,
        comparisonTokenFor(idm, session.sessionKey),
      );
      expect(first.blocks.first.bytes[10], 0xB0);
      session.accept(first);

      manager.started = Completer<void>();
      final normalFuture = reader.scan();
      await manager.started.future;
      manager.discovered!(tag);
      expect((await normalFuture).comparisonToken, isNull);

      manager.started = Completer<void>();
      final secondFuture = reader.scanForComparison(
        sessionKey: session.sessionKey,
      );
      await manager.started.future;
      manager.discovered!(tag);
      session.accept(await secondFuture);
      expect(session.cards.length, 1);
      expect(manager.stops, 3);
    },
  );

  test('cancelled callback cannot complete a later comparison scan', () async {
    final manager = _Manager();
    final reader = NfcManagerCardReader(
      manager: manager,
      androidAdapterStates: const Stream.empty(),
    );
    final session = CardComparisonSession();
    addTearDown(session.dispose);
    final cancelled = reader.scanForComparison(sessionKey: session.sessionKey);
    final expectation = expectLater(
      cancelled,
      throwsA(isA<CardScanException>()),
    );
    await manager.started.future;
    final oldCallback = manager.discovered!;
    await reader.cancel();
    await expectation;
    manager.started = Completer<void>();
    final next = reader.scanForComparison(sessionKey: session.sessionKey);
    var completed = false;
    next.then((_) => completed = true);
    await manager.started.future;
    oldCallback(tag);
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);
    manager.discovered!(tag);
    expect((await next).comparisonToken, isNotNull);
  });
}

NfcTag _icaTag(Uint8List idm) => NfcTag(
  data: TagPigeon(
    handle: 'ica-synthetic',
    id: idm,
    techList: ['android.nfc.tech.NfcF'],
    nfcF: NfcFPigeon(
      manufacturer: Uint8List(8),
      systemCode: Uint8List.fromList([0x80, 0xEF]),
    ),
  ),
);

class _Manager extends NfcManager {
  Completer<NfcAvailability>? availabilityPending;
  Completer<void> started = Completer<void>();
  void Function(NfcTag)? discovered;
  int stops = 0;
  @override
  Future<NfcAvailability> checkAvailability() async =>
      availabilityPending == null
      ? NfcAvailability.enabled
      : await availabilityPending!.future;
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<void> startSession({
    required Set<NfcPollingOption> pollingOptions,
    required void Function(NfcTag) onDiscovered,
    String? alertMessageIos,
    bool invalidateAfterFirstReadIos = true,
    void Function(NfcReaderSessionErrorIos)? onSessionErrorIos,
    bool noPlatformSoundsAndroid = false,
  }) async {
    discovered = onDiscovered;
    started.complete();
  }

  @override
  Future<void> stopSession({
    String? alertMessageIos,
    String? errorMessageIos,
  }) async {
    stops++;
  }
}
