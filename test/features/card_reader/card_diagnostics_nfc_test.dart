import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/card_reader/data/nfc_manager_card_reader.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_diagnostics.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_scan_result.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
// Test-only construction of native NFC-F discovery data.
// ignore: implementation_imports
import 'package:nfc_manager/src/nfc_manager_android/pigeon.g.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = BasicMessageChannel<Object?>(
    'dev.flutter.pigeon.nfc_manager.HostApiPigeon.nfcFTransceive',
    HostApiPigeon.pigeonChannelCodec,
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final idm = Uint8List.fromList(List.generate(8, (i) => 0xA0 + i));
  final tag = NfcTag(
    data: TagPigeon(
      handle: 'diagnostic-test',
      id: idm,
      techList: ['android.nfc.tech.NfcF'],
      nfcF: NfcFPigeon(
        manufacturer: Uint8List.fromList([1, 1, 0, 0, 0, 0, 0, 0]),
        systemCode: Uint8List.fromList([0, 3]),
      ),
    ),
  );
  tearDown(() => messenger.setMockDecodedMessageHandler(channel, null));

  test(
    'support metadata works without developer flag and never reads card blocks',
    () async {
      final commands = <Uint8List>[];
      messenger.setMockDecodedMessageHandler(channel, (message) async {
        final command = (message! as List)[1] as Uint8List;
        commands.add(command);
        if (command[1] == 2) {
          return [
            _serviceReply(command, idm, present: {0x208B, 0x20CB}),
          ];
        }
        return [
          Uint8List.fromList([13, 13, ...idm, 1, 0, 3]),
        ];
      });
      final manager = _Manager();
      final reader = NfcManagerCardReader(
        manager: manager,
        androidAdapterStates: const Stream.empty(),
      );
      final scan = reader.scanSupportDiagnostics();
      await manager.started.future;
      manager.discovered!(tag);
      final report = await scan;
      expect(commands.map((c) => c[1]), [12, 2, 2, 2, 2]);
      expect(commands.where((c) => c[1] == 6), isEmpty);
      expect(report.serviceProbe!.presence.length, 19);
      expect(report.experimentalBrand.brand, DiagnosticBrand.kitaca);
      expect(manager.stops, 1);
    },
  );

  if (!cardDiagnosticsEnabled) {
    test(
      'default build refuses diagnostic scanning before starting NFC',
      () async {
        final manager = _Manager();
        final reader = NfcManagerCardReader(
          manager: manager,
          androidAdapterStates: const Stream.empty(),
        );
        await expectLater(
          reader.scanDiagnostics(),
          throwsA(isA<CardScanException>()),
        );
        expect(manager.started.isCompleted, isFalse);
      },
    );
  } else {
    test(
      'debug diagnostics sends bounded metadata commands, never reads history or balance',
      () async {
        final commands = <Uint8List>[];
        messenger.setMockDecodedMessageHandler(channel, (message) async {
          final command = (message! as List)[1] as Uint8List;
          commands.add(command);
          if (command[1] == 2) {
            return [
              _serviceReply(command, idm, present: {0x1A48, 0x1A88, 0x9608}),
            ];
          }
          return [
            Uint8List.fromList([15, 13, ...idm, 2, 0, 3, 0x86, 0xA7]),
          ];
        });
        final manager = _Manager();
        final reader = NfcManagerCardReader(
          manager: manager,
          androidAdapterStates: const Stream.empty(),
        );
        final scan = reader.scanDiagnostics();
        await manager.started.future;
        manager.discovered!(tag);
        final result = await scan;
        expect(commands.first, [10, 12, ...idm]);
        expect(commands.map((c) => c[1]), [12, 2, 2, 2, 2]);
        expect(commands.skip(1).map((c) => c[10]), [5, 5, 5, 4]);
        expect(result.systemCodes, ['0003', '86A7']);
        expect(result.systemCodeStatus, 'ok');
        expect(result.initialSystemCode, '0003');
        expect(result.pmm, '0101000000000000');
        expect(result.serviceProbe!.status, 'ok');
        expect(result.serviceProbe!.presence.length, 19);
        expect(result.serviceProbe!.presence[0x1A48], isTrue);
        expect(result.serviceProbe!.presence[0x1E08], isFalse);
        expect(
          result.formatForTerminal('Suica'),
          isNot(contains('A0A1A2A3A4A5A6A7')),
        );
        expect(manager.stops, 1);
      },
    );

    test(
      'malformed metadata is unknown, not unsupported-card evidence',
      () async {
        messenger.setMockDecodedMessageHandler(
          channel,
          (_) async => [
            Uint8List.fromList([11, 13, ...idm, 2]),
          ],
        );
        final manager = _Manager();
        final reader = NfcManagerCardReader(
          manager: manager,
          androidAdapterStates: const Stream.empty(),
        );
        final scan = reader.scanDiagnostics();
        await manager.started.future;
        manager.discovered!(tag);
        final result = await scan;
        expect(result.systemCodeStatus, 'invalid_response');
        expect(result.systemCodes, isEmpty);
        expect(result.systemCodeIssue, DiagnosticQueryIssue.invalidResponse);
        expect(result.serviceProbe!.status, 'skipped');
        expect(
          result.serviceProbe!.issue,
          DiagnosticQueryIssue.systemQueryFailed,
        );
      },
    );

    test('cancelled diagnostic callback cannot complete a new scan', () async {
      final reply = Completer<Object?>();
      var calls = 0;
      messenger.setMockDecodedMessageHandler(channel, (_) {
        calls++;
        return calls == 1
            ? reply.future
            : Future.value([
                Uint8List.fromList([13, 13, ...idm, 1, 0, 3]),
              ]);
      });
      final manager = _Manager();
      final reader = NfcManagerCardReader(
        manager: manager,
        androidAdapterStates: const Stream.empty(),
      );
      final first = reader.scanDiagnostics();
      final expectation = expectLater(first, throwsA(isA<CardScanException>()));
      await manager.started.future;
      manager.discovered!(tag);
      while (calls == 0) {
        await Future<void>.delayed(Duration.zero);
      }
      await reader.cancel();
      await expectation;
      manager.started = Completer<void>();
      final second = reader.scanDiagnostics();
      var completed = false;
      second.then((_) => completed = true);
      await manager.started.future;
      reply.complete([
        Uint8List.fromList([13, 13, ...idm, 1, 0, 3]),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(completed, isFalse);
      manager.discovered!(tag);
      expect((await second).systemCodeStatus, 'ok');
    });

    test(
      'other initial system skips all service probes even if 0003 is listed',
      () async {
        var calls = 0;
        messenger.setMockDecodedMessageHandler(channel, (_) async {
          calls++;
          return [
            Uint8List.fromList([15, 13, ...idm, 2, 0x80, 0xEF, 0, 3]),
          ];
        });
        final other = NfcTag(
          data: TagPigeon(
            handle: 'other-system',
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
        final scan = reader.scanDiagnostics();
        await manager.started.future;
        manager.discovered!(other);
        final result = await scan;
        expect(calls, 1);
        expect(
          result.serviceProbe!.issue,
          DiagnosticQueryIssue.systemNotSelected,
        );
        expect(result.serviceProbe!.presence, isEmpty);
      },
    );

    test(
      'system-query platform error aborts probes without leaking payload',
      () async {
        var calls = 0;
        messenger.setMockDecodedMessageHandler(channel, (_) async {
          calls++;
          return ['native_error', 'SECRET_SYSTEM_PAYLOAD', null];
        });
        final manager = _Manager();
        final reader = NfcManagerCardReader(
          manager: manager,
          androidAdapterStates: const Stream.empty(),
        );
        final scan = reader.scanDiagnostics();
        await manager.started.future;
        manager.discovered!(tag);
        final report = await scan;
        expect(calls, 1);
        expect(report.systemCodeStatus, 'unavailable');
        expect(report.systemCodeIssue, DiagnosticQueryIssue.platformError);
        expect(report.serviceProbe!.status, 'skipped');
        expect(
          report.serviceProbe!.issue,
          DiagnosticQueryIssue.systemQueryFailed,
        );
        expect(
          report.formatForTerminal('Suica'),
          isNot(contains('SECRET_SYSTEM_PAYLOAD')),
        );
      },
    );

    test(
      'partial probe stops at invalid response and leaves remaining codes unknown',
      () async {
        var calls = 0;
        messenger.setMockDecodedMessageHandler(channel, (message) async {
          final command = (message! as List)[1] as Uint8List;
          calls++;
          if (command[1] == 12) {
            return [
              Uint8List.fromList([13, 13, ...idm, 1, 0, 3]),
            ];
          }
          if (calls == 2) {
            return [
              _serviceReply(command, idm, present: {0x1A48}),
            ];
          }
          return [
            Uint8List.fromList([11, 3, ...idm, 5]),
          ];
        });
        final manager = _Manager();
        final reader = NfcManagerCardReader(
          manager: manager,
          androidAdapterStates: const Stream.empty(),
        );
        final scan = reader.scanDiagnostics();
        await manager.started.future;
        manager.discovered!(tag);
        final probe = (await scan).serviceProbe!;
        expect(calls, 3);
        expect(probe.status, 'partial');
        expect(probe.issue, DiagnosticQueryIssue.invalidResponse);
        expect(probe.presence.length, 5);
        expect(probe.presence[0x1A48], isTrue);
        expect(probe.presence[0x1A88], isFalse);
        expect(probe.presence[0x1E8B], isNull);
        expect((probe.toLogFields()['presence'] as Map)['1E8B'], 'unknown');
      },
    );

    test(
      'platform exception stays sanitized and never becomes absent',
      () async {
        messenger.setMockDecodedMessageHandler(channel, (message) async {
          final command = (message! as List)[1] as Uint8List;
          if (command[1] == 12) {
            return [
              Uint8List.fromList([13, 13, ...idm, 1, 0, 3]),
            ];
          }
          return [
            'native_error',
            'SECRET_NATIVE_PAYLOAD',
            {'raw': 'PRIVATE_TAG'},
          ];
        });
        final manager = _Manager();
        final reader = NfcManagerCardReader(
          manager: manager,
          androidAdapterStates: const Stream.empty(),
        );
        final scan = reader.scanDiagnostics();
        await manager.started.future;
        manager.discovered!(tag);
        final report = await scan;
        expect(report.serviceProbe!.status, 'unavailable');
        expect(report.serviceProbe!.issue, DiagnosticQueryIssue.platformError);
        final log = report.formatForTerminal('ICOCA');
        expect(log, isNot(contains('SECRET_NATIVE_PAYLOAD')));
        expect(log, isNot(contains('PRIVATE_TAG')));
        expect(report.serviceProbe!.presence, isEmpty);
      },
    );

    test(
      'probe timeout sends no additional requests or late results',
      () async {
        final pending = Completer<Object?>();
        var calls = 0;
        messenger.setMockDecodedMessageHandler(channel, (message) {
          final command = (message! as List)[1] as Uint8List;
          calls++;
          if (command[1] == 12) {
            return Future.value([
              Uint8List.fromList([13, 13, ...idm, 1, 0, 3]),
            ]);
          }
          return pending.future;
        });
        final manager = _Manager();
        final reader = NfcManagerCardReader(
          manager: manager,
          androidAdapterStates: const Stream.empty(),
        );
        final scan = reader.scanDiagnostics();
        await manager.started.future;
        manager.discovered!(tag);
        final probe = (await scan).serviceProbe!;
        expect(probe.issue, DiagnosticQueryIssue.timedOut);
        expect(probe.presence, isEmpty);
        expect(calls, 2);
        pending.complete([Uint8List(21)]);
        await Future<void>.delayed(Duration.zero);
        expect(calls, 2);
      },
    );

    test('cancelling while probing prevents later batches', () async {
      final pending = Completer<Object?>();
      final probing = Completer<void>();
      var calls = 0;
      messenger.setMockDecodedMessageHandler(channel, (message) {
        final command = (message! as List)[1] as Uint8List;
        calls++;
        if (command[1] == 12) {
          return Future.value([
            Uint8List.fromList([13, 13, ...idm, 1, 0, 3]),
          ]);
        }
        probing.complete();
        return pending.future;
      });
      final manager = _Manager();
      final reader = NfcManagerCardReader(
        manager: manager,
        androidAdapterStates: const Stream.empty(),
      );
      final scan = reader.scanDiagnostics();
      final expectation = expectLater(scan, throwsA(isA<CardScanException>()));
      await manager.started.future;
      manager.discovered!(tag);
      await probing.future;
      await reader.cancel();
      await expectation;
      pending.complete([
        _serviceReply(
          Uint8List.fromList(
            CardDiagnosticProtocol.requestServices(
              idm,
              diagnosticServiceCodes.take(5).toList(),
            ),
          ),
          idm,
          present: {0x1A48},
        ),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(calls, 2);
    });
  }
}

Uint8List _serviceReply(
  Uint8List command,
  List<int> idm, {
  Set<int> present = const {},
}) {
  final count = command[10];
  return Uint8List.fromList([
    11 + count * 2,
    3,
    ...idm,
    count,
    for (var i = 0; i < count; i++)
      ...(present.contains(command[11 + i * 2] | command[12 + i * 2] << 8)
          ? [0x34, 0x12]
          : [0xFF, 0xFF]),
  ]);
}

class _Manager extends NfcManager {
  Completer<void> started = Completer<void>();
  void Function(NfcTag)? discovered;
  int stops = 0;
  @override
  Future<NfcAvailability> checkAvailability() async => NfcAvailability.enabled;
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
