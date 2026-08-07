import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';

import '../domain/card_reader.dart';
import '../domain/card_scan_result.dart';
import '../domain/felica_protocol.dart';
import '../domain/raw_history_block.dart';
import '../domain/raw_history_fixture_log.dart';

class NfcManagerCardReader implements CardReader {
  NfcManagerCardReader({NfcManager? manager})
    : _manager = manager ?? NfcManager.instance;

  static final Uint8List _systemCode = Uint8List.fromList([0x00, 0x03]);
  static final Uint8List _historyServiceCode = Uint8List.fromList([0x0F, 0x09]);

  final NfcManager _manager;
  bool _sessionActive = false;
  bool _completed = false;
  Completer<CardScanResult>? _completer;

  @override
  Future<bool> isAvailable() async {
    final availability = await _manager.checkAvailability();
    return availability == NfcAvailability.enabled;
  }

  @override
  Future<CardScanResult> scan({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_sessionActive) {
      throw const CardScanException(
        CardScanFailureKind.unknown,
        '이미 NFC 스캔이 진행 중입니다.',
      );
    }
    if (!await isAvailable()) {
      throw const CardScanException(
        CardScanFailureKind.nfcUnavailable,
        'NFC를 사용할 수 없습니다. 기기 설정을 확인해 주세요.',
      );
    }

    _completed = false;
    _sessionActive = true;
    _completer = Completer<CardScanResult>();
    await _manager.startSession(
      pollingOptions: const {NfcPollingOption.iso18092},
      alertMessageIos: '교통계 IC 카드를 iPhone 상단에 가까이 대 주세요.',
      onDiscovered: _onDiscovered,
    );

    try {
      return await _completer!.future.timeout(
        timeout,
        onTimeout: () async {
          await _finish(
            error: const CardScanException(
              CardScanFailureKind.timedOut,
              '30초 동안 카드를 찾지 못했습니다.',
            ),
          );
          return _completer!.future;
        },
      );
    } finally {
      _sessionActive = false;
    }
  }

  Future<void> _onDiscovered(NfcTag tag) async {
    if (_completed) return;
    try {
      final blocks = await _readBlocks(tag);
      if (blocks == null) {
        throw const CardScanException(
          CardScanFailureKind.unsupportedTag,
          'NFC-F/FeliCa 교통계 IC 카드가 아닙니다.',
        );
      }
      if (blocks.isEmpty) {
        throw const CardScanException(
          CardScanFailureKind.noHistory,
          '읽을 수 있는 이용내역이 없습니다.',
        );
      }
      _logRawHistoryForFixture(blocks);
      await _finish(
        result: CardScanResult(
          scannedAt: DateTime.now(),
          blocks: List.unmodifiable(blocks),
        ),
      );
    } on CardScanException catch (error) {
      await _finish(error: error);
    } catch (error) {
      await _finish(
        error: CardScanException(
          CardScanFailureKind.tagLost,
          '카드 통신이 중단되었습니다. 카드를 움직이지 말고 다시 시도해 주세요.',
          cause: error,
        ),
      );
    }
  }

  void _logRawHistoryForFixture(List<RawHistoryBlock> blocks) {
    if (!kDebugMode) return;
    for (final line in buildRawHistoryFixtureLog(blocks)) {
      debugPrint(line);
    }
  }

  Future<List<RawHistoryBlock>?> _readBlocks(NfcTag tag) async {
    final android = NfcFAndroid.from(tag);
    if (android != null) return _readAndroid(android);
    final ios = FeliCaIos.from(tag);
    if (ios != null) return _readIos(ios);
    return null;
  }

  Future<List<RawHistoryBlock>> _readAndroid(NfcFAndroid tag) async {
    // IDm is used transiently for FeliCa commands and is never returned,
    // persisted, or logged.
    final idm = Uint8List.fromList(tag.tag.id);
    final blocks = <RawHistoryBlock>[];
    for (var index = 0; index < felicaHistoryBlockLimit; index++) {
      final response = await tag.transceive(
        FelicaProtocol.buildReadWithoutEncryptionCommand(
          idm: idm,
          blockIndex: index,
        ),
      );
      final bytes = FelicaProtocol.parseReadWithoutEncryptionResponse(
        response,
        expectedIdm: idm,
      );
      if (bytes == null) {
        if (index == 0) {
          throw const CardScanException(
            CardScanFailureKind.invalidResponse,
            '카드 응답 또는 상태 플래그가 올바르지 않습니다.',
          );
        }
        break;
      }
      if (FelicaProtocol.isEmptyBlock(bytes)) break;
      blocks.add(RawHistoryBlock(index: index, bytes: bytes));
    }
    return blocks;
  }

  Future<List<RawHistoryBlock>> _readIos(FeliCaIos tag) async {
    await tag.polling(
      systemCode: _systemCode,
      requestCode: FeliCaPollingRequestCodeIos.systemCode,
      timeSlot: FeliCaPollingTimeSlotIos.max1,
    );

    final blocks = <RawHistoryBlock>[];
    for (var index = 0; index < felicaHistoryBlockLimit; index++) {
      final response = await tag.readWithoutEncryption(
        serviceCodeList: [_historyServiceCode],
        blockList: [
          Uint8List.fromList([0x80, index]),
        ],
      );
      if (response.statusFlag1 != 0 || response.statusFlag2 != 0) {
        if (index == 0) {
          throw const CardScanException(
            CardScanFailureKind.invalidResponse,
            '카드 상태 플래그가 읽기 실패를 나타냅니다.',
          );
        }
        break;
      }
      if (response.blockData.length != 1 ||
          response.blockData.first.length != felicaHistoryBlockLength) {
        if (index == 0) {
          throw const CardScanException(
            CardScanFailureKind.invalidResponse,
            '카드 블록 길이가 올바르지 않습니다.',
          );
        }
        break;
      }
      final bytes = Uint8List.fromList(response.blockData.first);
      if (FelicaProtocol.isEmptyBlock(bytes)) break;
      blocks.add(RawHistoryBlock(index: index, bytes: bytes));
    }
    return blocks;
  }

  @override
  Future<void> cancel() async {
    if (!_sessionActive || _completed) return;
    await _finish(
      error: const CardScanException(
        CardScanFailureKind.cancelled,
        '스캔을 취소했습니다.',
      ),
    );
  }

  Future<void> _finish({
    CardScanResult? result,
    CardScanException? error,
  }) async {
    if (_completed) return;
    _completed = true;
    try {
      await _manager.stopSession(
        alertMessageIos: result == null ? null : 'IC 카드 이용내역을 읽었습니다.',
        errorMessageIos: error?.message,
      );
    } finally {
      final completer = _completer;
      if (completer != null && !completer.isCompleted) {
        if (result != null) {
          completer.complete(result);
        } else {
          completer.completeError(
            error ??
                const CardScanException(
                  CardScanFailureKind.unknown,
                  'NFC 스캔을 완료하지 못했습니다.',
                ),
          );
        }
      }
    }
  }
}
