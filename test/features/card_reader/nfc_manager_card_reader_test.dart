import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/card_reader/data/nfc_manager_card_reader.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_scan_result.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';

void main() {
  test(
    'asks for basic mode before starting when NFC reading is disabled',
    () async {
      final manager = _FakeNfcManager(availability: NfcAvailability.disabled);
      final reader = NfcManagerCardReader(
        manager: manager,
        androidAdapterStates: const Stream.empty(),
      );

      await expectLater(
        reader.scan(),
        throwsA(
          isA<CardScanException>().having(
            (error) => error.message,
            'message',
            contains('NFC를 기본 모드로 설정'),
          ),
        ),
      );
      expect(manager.startSessionCalls, 0);
    },
  );

  test(
    'ends safely without native teardown when NFC is switched off',
    () async {
      final manager = _FakeNfcManager();
      final adapterStates = StreamController<NfcAdapterStateAndroid>();
      final reader = NfcManagerCardReader(
        manager: manager,
        androidAdapterStates: adapterStates.stream,
      );

      final scan = reader.scan();
      await manager.sessionStarted.future;
      adapterStates.add(NfcAdapterStateAndroid.turningOff);

      await expectLater(
        scan,
        throwsA(
          isA<CardScanException>()
              .having(
                (error) => error.kind,
                'kind',
                CardScanFailureKind.nfcUnavailable,
              )
              .having(
                (error) => error.message,
                'message',
                contains('NFC를 기본 모드로 변경'),
              ),
        ),
      );
      expect(manager.stopSessionCalls, 0);

      await adapterStates.close();
    },
  );

  test(
    'polls Android availability when the adapter broadcast is missed',
    () async {
      final manager = _FakeNfcManager();
      final reader = NfcManagerCardReader(
        manager: manager,
        androidAdapterStates: const Stream.empty(),
        androidAvailabilityPollInterval: const Duration(milliseconds: 5),
      );

      final scan = reader.scan();
      await manager.sessionStarted.future;
      manager.availability = NfcAvailability.disabled;

      await expectLater(
        scan,
        throwsA(
          isA<CardScanException>().having(
            (error) => error.kind,
            'kind',
            CardScanFailureKind.nfcUnavailable,
          ),
        ),
      );
      expect(manager.stopSessionCalls, 0);

      final checksAfterCompletion = manager.checkAvailabilityCalls;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(manager.checkAvailabilityCalls, checksAfterCompletion);
    },
  );

  test('treats an Android availability error as an interrupted scan', () async {
    final manager = _FakeNfcManager();
    final reader = NfcManagerCardReader(
      manager: manager,
      androidAdapterStates: const Stream.empty(),
      androidAvailabilityPollInterval: const Duration(milliseconds: 5),
    );

    final scan = reader.scan();
    await manager.sessionStarted.future;
    manager.throwAvailabilityErrorAfterStart = true;

    await expectLater(
      scan,
      throwsA(
        isA<CardScanException>().having(
          (error) => error.kind,
          'kind',
          CardScanFailureKind.nfcUnavailable,
        ),
      ),
    );
    expect(manager.stopSessionCalls, 0);
  });
}

class _FakeNfcManager extends NfcManager {
  _FakeNfcManager({this.availability = NfcAvailability.enabled});

  NfcAvailability availability;
  bool throwAvailabilityErrorAfterStart = false;
  final sessionStarted = Completer<void>();
  int checkAvailabilityCalls = 0;
  int startSessionCalls = 0;
  int stopSessionCalls = 0;

  @override
  Future<NfcAvailability> checkAvailability() async {
    checkAvailabilityCalls++;
    if (sessionStarted.isCompleted && throwAvailabilityErrorAfterStart) {
      throw StateError('adapter unavailable');
    }
    return availability;
  }

  @override
  Future<bool> isAvailable() async => availability == NfcAvailability.enabled;

  @override
  Future<void> startSession({
    required Set<NfcPollingOption> pollingOptions,
    required void Function(NfcTag tag) onDiscovered,
    String? alertMessageIos,
    bool invalidateAfterFirstReadIos = true,
    void Function(NfcReaderSessionErrorIos)? onSessionErrorIos,
    bool noPlatformSoundsAndroid = false,
  }) async {
    startSessionCalls++;
    sessionStarted.complete();
  }

  @override
  Future<void> stopSession({
    String? alertMessageIos,
    String? errorMessageIos,
  }) async {
    stopSessionCalls++;
  }
}
