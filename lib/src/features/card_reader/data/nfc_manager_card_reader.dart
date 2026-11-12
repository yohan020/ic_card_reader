import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';

import '../domain/card_reader.dart';
import '../domain/card_diagnostics.dart';
import '../domain/card_comparison_session.dart';
import '../domain/card_scan_result.dart';
import '../domain/current_gate_travel.dart';
import '../domain/felica_protocol.dart';
import '../domain/raw_history_block.dart';
import '../domain/ica_protocol.dart';
import '../domain/card_read_trace.dart';
import '../domain/card_brand_identity.dart';
import '../../transaction_history/data/ica_history_parser.dart';

class NfcManagerCardReader
    implements
        CardReader,
        ComparisonCardReader,
        DiagnosticCardReader,
        SupportCardReader {
  NfcManagerCardReader({
    NfcManager? manager,
    Stream<NfcAdapterStateAndroid>? androidAdapterStates,
    Duration androidAvailabilityPollInterval = const Duration(
      milliseconds: 500,
    ),
  }) : _manager = manager ?? NfcManager.instance,
       _androidAvailabilityPollInterval = androidAvailabilityPollInterval,
       _androidAdapterStates =
           androidAdapterStates ??
           (defaultTargetPlatform == TargetPlatform.android
               ? NfcManagerAndroid.instance.onStateChanged
               : null);

  static final Uint8List _systemCode = Uint8List.fromList([0x00, 0x03]);
  static final Uint8List _historyServiceCode = Uint8List.fromList([0x0F, 0x09]);
  static final Uint8List _gateHistoryServiceCode = Uint8List.fromList([
    0x8F,
    0x10,
  ]);
  static final Uint8List _sfEntryServiceCode = Uint8List.fromList([0xCB, 0x10]);
  static const _gateHistoryService = 0x108F;
  static const _sfEntryService = 0x10CB;

  final NfcManager _manager;
  final Stream<NfcAdapterStateAndroid>? _androidAdapterStates;
  final Duration _androidAvailabilityPollInterval;
  bool _sessionActive = false;
  bool _completed = false;
  bool _availabilityCheckInFlight = false;
  int _scanGeneration = 0;
  int _cancellationEpoch = 0;
  Completer<CardScanResult>? _completer;
  StreamSubscription<NfcAdapterStateAndroid>? _adapterStateSubscription;
  Timer? _availabilityPollTimer;

  @override
  Future<bool> isAvailable() async {
    final availability = await _manager.checkAvailability();
    return availability == NfcAvailability.enabled;
  }

  @override
  Future<CardReaderAvailability> checkAvailability() async {
    try {
      return switch (await _manager.checkAvailability()) {
        NfcAvailability.enabled => CardReaderAvailability.enabled,
        NfcAvailability.disabled => CardReaderAvailability.disabled,
        NfcAvailability.unsupported => CardReaderAvailability.unsupported,
      };
    } catch (_) {
      return CardReaderAvailability.unknown;
    }
  }

  @override
  Future<bool> openNfcSettings() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await const MethodChannel(
            'app.iccardreader/nfc_settings',
          ).invokeMethod<bool>('open') ??
          false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<CardScanResult> scan({
    Duration timeout = const Duration(seconds: 30),
  }) => _scan(timeout: timeout);

  @override
  Future<CardDiagnosticReport> scanDiagnostics() async {
    if (!cardDiagnosticsEnabled ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      throw const CardScanException(
        CardScanFailureKind.unsupportedTag,
        '명시적으로 활성화한 Android 개발 버전에서만 사용할 수 있어요.',
      );
    }
    final result = await _scan(
      timeout: const Duration(seconds: 30),
      diagnostics: true,
    );
    return result.diagnosticReport!;
  }

  @override
  Future<CardDiagnosticReport> scanSupportDiagnostics() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw const CardScanException(
        CardScanFailureKind.unsupportedTag,
        '카드 인식 진단은 NFC-F를 지원하는 Android 기기에서 사용할 수 있어요.',
      );
    }
    final result = await _scan(
      timeout: const Duration(seconds: 30),
      diagnostics: true,
    );
    return result.diagnosticReport!;
  }

  @override
  Future<CardScanResult> scanForComparison({required List<int> sessionKey}) {
    if (defaultTargetPlatform != TargetPlatform.android ||
        sessionKey.length != 32) {
      throw const CardScanException(
        CardScanFailureKind.unsupportedTag,
        '여러 카드 비교는 NFC-F 읽기를 지원하는 Android 기기에서 사용할 수 있어요.',
      );
    }
    return _scan(
      timeout: const Duration(seconds: 30),
      comparisonKey: sessionKey,
    );
  }

  Future<CardScanResult> _scan({
    required Duration timeout,
    List<int>? comparisonKey,
    bool diagnostics = false,
  }) async {
    final cancellationEpoch = _cancellationEpoch;
    if (_sessionActive) {
      throw const CardScanException(
        CardScanFailureKind.unknown,
        '이미 NFC 스캔이 진행 중입니다.',
      );
    }
    if (!await isAvailable()) {
      throw const CardScanException(
        CardScanFailureKind.nfcUnavailable,
        'NFC 읽기 기능을 사용할 수 없습니다. Samsung 기기는 NFC를 기본 모드로 설정해 주세요.',
      );
    }
    if (cancellationEpoch != _cancellationEpoch) {
      throw const CardScanException(
        CardScanFailureKind.cancelled,
        '스캔을 취소했습니다.',
      );
    }

    _completed = false;
    _sessionActive = true;
    final scanGeneration = ++_scanGeneration;
    final key = comparisonKey == null
        ? null
        : Uint8List.fromList(comparisonKey);
    _completer = Completer<CardScanResult>();
    _adapterStateSubscription = _androidAdapterStates?.listen(
      _onAndroidAdapterStateChanged,
    );

    try {
      await _manager.startSession(
        pollingOptions: const {NfcPollingOption.iso18092},
        alertMessageIos: '교통계 IC 카드를 iPhone 상단에 가까이 대 주세요.',
        onDiscovered: (tag) =>
            _onDiscovered(tag, scanGeneration, key, diagnostics),
      );
      _startAndroidAvailabilityPolling(scanGeneration);
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
      key?.fillRange(0, key.length, 0);
      _availabilityPollTimer?.cancel();
      _availabilityPollTimer = null;
      await _adapterStateSubscription?.cancel();
      _adapterStateSubscription = null;
      // Do not retain the last scan's records/token through a completed Future.
      _completer = null;
      _sessionActive = false;
    }
  }

  void _startAndroidAvailabilityPolling(int scanGeneration) {
    if (_androidAdapterStates == null) return;
    _availabilityPollTimer?.cancel();
    _availabilityPollTimer = Timer.periodic(
      _androidAvailabilityPollInterval,
      (_) => unawaited(_verifyAndroidAvailability(scanGeneration)),
    );
  }

  Future<void> _verifyAndroidAvailability(int scanGeneration) async {
    if (scanGeneration != _scanGeneration ||
        !_sessionActive ||
        _completed ||
        _availabilityCheckInFlight) {
      return;
    }
    _availabilityCheckInFlight = true;
    try {
      final availability = await _manager.checkAvailability();
      if (scanGeneration != _scanGeneration ||
          availability == NfcAvailability.enabled ||
          _completed) {
        return;
      }
      await _finishForUnavailableNfc();
    } catch (_) {
      if (scanGeneration == _scanGeneration && !_completed) {
        await _finishForUnavailableNfc();
      }
    } finally {
      _availabilityCheckInFlight = false;
    }
  }

  void _onAndroidAdapterStateChanged(NfcAdapterStateAndroid state) {
    if (!_sessionActive || _completed) return;
    if (state != NfcAdapterStateAndroid.turningOff &&
        state != NfcAdapterStateAndroid.off) {
      return;
    }
    unawaited(_finishForUnavailableNfc());
  }

  Future<void> _finishForUnavailableNfc() => _finish(
    error: const CardScanException(
      CardScanFailureKind.nfcUnavailable,
      'NFC 읽기 기능이 꺼졌습니다. Samsung 기기는 NFC를 기본 모드로 변경한 뒤 다시 시도해 주세요.',
    ),
    stopPlatformSession: false,
  );

  Future<void> _onDiscovered(
    NfcTag tag,
    int generation,
    List<int>? key,
    bool diagnostics,
  ) async {
    if (_completed || generation != _scanGeneration) return;
    try {
      if (diagnostics) {
        final report = await _readDiagnostics(tag, generation);
        if (_completed || generation != _scanGeneration) return;
        await _finish(
          result: CardScanResult(
            scannedAt: DateTime.now(),
            blocks: const [],
            diagnosticReport: report,
          ),
        );
        return;
      }
      final read = await _readBlocks(tag, key, generation);
      if (_completed || generation != _scanGeneration) return;
      if (read == null) {
        throw const CardScanException(
          CardScanFailureKind.unsupportedTag,
          'NFC-F/FeliCa 교통계 IC 카드가 아닙니다.',
        );
      }
      if (read.blocks.isEmpty && read.currentGateTravel == null) {
        throw const CardScanException(
          CardScanFailureKind.noHistory,
          '읽을 수 있는 이용내역이 없습니다.',
        );
      }
      final brandIdentity =
          read.brandIdentity ?? await _readScanBrand(tag, generation);
      if (_completed || generation != _scanGeneration) return;
      _traceRead(generation, CardReadStage.scanSucceeded);
      await _finish(
        result: CardScanResult(
          scannedAt: DateTime.now(),
          blocks: List.unmodifiable(read.blocks),
          currentGateTravel: read.currentGateTravel,
          comparisonToken: read.comparisonToken,
          brandIdentity: brandIdentity,
        ),
      );
    } on CardScanException catch (error) {
      if (_completed || generation != _scanGeneration) return;
      _traceRead(
        generation,
        CardReadStage.scanFailed,
        issue: switch (error.kind) {
          CardScanFailureKind.invalidResponse => CardReadIssue.invalidResponse,
          CardScanFailureKind.noHistory => CardReadIssue.noHistory,
          CardScanFailureKind.cancelled => CardReadIssue.cancelled,
          CardScanFailureKind.unsupportedTag => CardReadIssue.unsupportedTag,
          CardScanFailureKind.timedOut => CardReadIssue.timedOut,
          _ => CardReadIssue.unexpectedError,
        },
      );
      await _finish(error: error);
    } catch (error) {
      if (_completed || generation != _scanGeneration) return;
      _traceRead(
        generation,
        CardReadStage.scanFailed,
        issue: _readIssue(error),
        platformCode: error is PlatformException ? error.code : null,
      );
      await _finish(
        error: CardScanException(
          CardScanFailureKind.tagLost,
          '카드 통신이 중단되었습니다. 카드를 움직이지 말고 다시 시도해 주세요.',
          cause: error,
        ),
      );
    }
  }

  Future<CardDiagnosticReport> _readDiagnostics(
    NfcTag tag,
    int generation,
  ) async {
    // Only reached through the gated developer entry or the explicit support
    // capability. Both paths perform metadata-only reads; no terminal output.
    final android = NfcFAndroid.from(tag);
    if (android == null || android.tag.id.length != 8) {
      throw const CardScanException(
        CardScanFailureKind.unsupportedTag,
        'NFC-F/FeliCa 메타데이터를 확인할 수 없는 카드예요.',
      );
    }
    // Transient protocol addressing only; never include IDm in report/logs.
    final idm = Uint8List.fromList(android.tag.id);
    try {
      var codes = <String>[];
      var status = 'unavailable';
      DiagnosticQueryIssue? issue;
      try {
        final response = await android
            .transceive(
              Uint8List.fromList(
                CardDiagnosticProtocol.requestSystemCodes(idm),
              ),
            )
            .timeout(const Duration(seconds: 3));
        final parsed = CardDiagnosticProtocol.parseSystemCodes(response, idm);
        if (parsed == null) {
          status = 'invalid_response';
          issue = DiagnosticQueryIssue.invalidResponse;
        } else {
          status = 'ok';
          codes = parsed;
        }
      } on TimeoutException {
        status = 'timed_out';
        issue = DiagnosticQueryIssue.timedOut;
      } on PlatformException {
        issue = DiagnosticQueryIssue.platformError;
      } catch (_) {
        issue = DiagnosticQueryIssue.other;
      }
      _requireDiagnosticActive(generation);
      final initialCode = android.systemCode.length == 2
          ? CardDiagnosticProtocol.hex(android.systemCode)
          : null;
      final CardServiceProbeReport probe;
      if (initialCode != '0003') {
        // Do not send system-0003 requests to ICa or silently switch systems.
        probe = CardServiceProbeReport(
          status: 'skipped',
          issue: DiagnosticQueryIssue.systemNotSelected,
        );
      } else if (status != 'ok') {
        // A timed-out native transceive may still be in flight. No new command.
        probe = CardServiceProbeReport(
          status: 'skipped',
          issue: DiagnosticQueryIssue.systemQueryFailed,
        );
      } else {
        probe = await _probeDiagnosticServices(android, idm, generation);
      }
      _requireDiagnosticActive(generation);
      return CardDiagnosticReport(
        initialSystemCode: initialCode,
        pmm: android.manufacturer.length == 8
            ? CardDiagnosticProtocol.hex(android.manufacturer)
            : null,
        systemCodes: codes,
        systemCodeStatus: status,
        systemCodeIssue: issue,
        serviceProbe: probe,
      );
    } finally {
      idm.fillRange(0, idm.length, 0);
    }
  }

  void _requireDiagnosticActive(int generation) {
    if (_completed || generation != _scanGeneration) {
      throw const CardScanException(
        CardScanFailureKind.cancelled,
        '진단을 취소했습니다.',
      );
    }
  }

  Future<CardServiceProbeReport> _probeDiagnosticServices(
    NfcFAndroid tag,
    List<int> idm,
    int generation, {
    Duration? totalBudget,
    List<int> serviceCodes = diagnosticServiceCodes,
  }) async {
    final presence = <int, bool?>{};
    final elapsed = Stopwatch()..start();
    DiagnosticQueryIssue? issue;
    // Bounded allowlist batches, no enumeration or automatic retry.
    for (
      var offset = 0;
      offset < serviceCodes.length;
      offset += diagnosticServicesPerQuery
    ) {
      _requireDiagnosticActive(generation);
      final remaining = totalBudget == null
          ? null
          : totalBudget - elapsed.elapsed;
      if (remaining != null && remaining <= Duration.zero) {
        issue = DiagnosticQueryIssue.timedOut;
        break;
      }
      final requestTimeout =
          remaining != null && remaining < const Duration(milliseconds: 1500)
          ? remaining
          : const Duration(milliseconds: 1500);
      final batch = serviceCodes
          .skip(offset)
          .take(diagnosticServicesPerQuery)
          .toList();
      try {
        final response = await tag
            .transceive(
              Uint8List.fromList(
                CardDiagnosticProtocol.requestServices(idm, batch),
              ),
            )
            .timeout(requestTimeout);
        _requireDiagnosticActive(generation);
        final parsed = CardDiagnosticProtocol.parseServicePresence(
          response,
          idm,
          batch,
        );
        if (parsed == null) {
          issue = DiagnosticQueryIssue.invalidResponse;
          break;
        }
        presence.addAll(parsed);
      } on CardScanException {
        rethrow;
      } on TimeoutException {
        issue = DiagnosticQueryIssue.timedOut;
        break;
      } on PlatformException {
        issue = DiagnosticQueryIssue.platformError;
        break;
      } catch (_) {
        issue = DiagnosticQueryIssue.other;
        break;
      }
    }
    _requireDiagnosticActive(generation);
    return CardServiceProbeReport(
      status: issue == null
          ? 'ok'
          : (presence.isEmpty ? 'unavailable' : 'partial'),
      issue: issue,
      presence: presence,
    );
  }

  Future<CardBrandIdentity?> _readScanBrand(NfcTag tag, int generation) async {
    final android = NfcFAndroid.from(tag);
    // Only the already selected national transit system is eligible. Never
    // probe ICa/80EF, switch systems, or infer identity from PMm/IDm.
    if (android == null ||
        android.tag.id.length != 8 ||
        !listEquals(android.systemCode, const [0x00, 0x03])) {
      return null;
    }
    final idm = Uint8List.fromList(android.tag.id);
    try {
      // History and entry-state reads have already succeeded. Metadata is
      // optional, read-only (02), at most five requests and 900ms total.
      final probe = await _probeDiagnosticServices(
        android,
        idm,
        generation,
        totalBudget: const Duration(milliseconds: 900),
        serviceCodes: normalScanBrandServiceCodes,
      );
      return switch (identifyObservedServiceBrand(
        probe,
        includeSugoca: true,
      ).brand) {
        DiagnosticBrand.suicaFamily => CardBrandIdentity.suicaFamily,
        DiagnosticBrand.kitaca => CardBrandIdentity.kitaca,
        DiagnosticBrand.manaca => CardBrandIdentity.manaca,
        DiagnosticBrand.sugoca => CardBrandIdentity.sugoca,
        DiagnosticBrand.pasmo => CardBrandIdentity.pasmo,
        DiagnosticBrand.icoca => CardBrandIdentity.icoca,
        DiagnosticBrand.toica => CardBrandIdentity.toica,
        DiagnosticBrand.nimoca => CardBrandIdentity.nimoca,
        DiagnosticBrand.hayakaken => CardBrandIdentity.hayakaken,
        _ => null,
      };
    } catch (_) {
      // Do not lose successfully read history when optional metadata fails.
      return null;
    } finally {
      idm.fillRange(0, idm.length, 0);
    }
  }

  Future<_CardReadData?> _readBlocks(
    NfcTag tag,
    List<int>? key,
    int generation,
  ) async {
    final android = NfcFAndroid.from(tag);
    if (android != null) {
      _traceRead(
        generation,
        CardReadStage.routeSelected,
        initialSystemCode: android.systemCode,
        icaRoute: IcaProtocol.isSystemCode(android.systemCode),
      );
      if (IcaProtocol.isSystemCode(android.systemCode)) {
        return _readAndroidIca(android, key, generation);
      }
      return _readAndroid(android, key);
    }
    final ios = FeliCaIos.from(tag);
    if (ios != null) return _readIos(ios);
    return null;
  }

  Future<_CardReadData> _readAndroidIca(
    NfcFAndroid tag,
    List<int>? key,
    int generation,
  ) async {
    final pollingReply = await _transceiveIca(
      tag,
      IcaProtocol.pollingCommand(),
      generation: generation,
      start: CardReadStage.icaPollingStart,
      response: CardReadStage.icaPollingResponse,
    );
    _requireDiagnosticActive(generation);
    final idm = IcaProtocol.parsePollingIdm(pollingReply);
    // Native channel replies can be read-only. Do not overwrite plugin-owned
    // buffers. parsePollingIdm creates our writable copy, cleared in finally.
    // The native reply stays transient and never enters reports or logs.
    if (idm == null) {
      throw const CardScanException(
        CardScanFailureKind.invalidResponse,
        'ICa 시스템 응답을 확인하지 못했습니다. 카드를 다시 대 주세요.',
      );
    }
    try {
      final token = key == null ? null : comparisonTokenFor(idm, key);
      final blocks = <RawHistoryBlock>[];
      for (var index = 0; index < felicaHistoryBlockLimit; index++) {
        _requireDiagnosticActive(generation);
        final reply = await _transceiveIca(
          tag,
          FelicaProtocol.buildReadWithoutEncryptionCommand(
            idm: idm,
            blockIndex: index,
            serviceCode: IcaProtocol.historyService,
          ),
          generation: generation,
          start: CardReadStage.icaHistoryStart,
          response: CardReadStage.icaHistoryResponse,
          blockIndex: index,
        );
        _requireDiagnosticActive(generation);
        final bytes = FelicaProtocol.parseReadWithoutEncryptionResponse(
          reply,
          expectedIdm: idm,
        );
        if (bytes == null) {
          if (index > 0) break;
          throw const CardScanException(
            CardScanFailureKind.invalidResponse,
            'ICa 이용내역 응답을 확인하지 못했습니다.',
          );
        }
        if (IcaHistoryParser.isEmpty(bytes)) break;
        if (IcaHistoryParser.recordDate(bytes) == null) {
          _traceRead(
            generation,
            CardReadStage.icaRecordInvalid,
            blockIndex: index,
          );
          if (index > 0) break;
          throw const CardScanException(
            CardScanFailureKind.invalidResponse,
            '확인되지 않은 ICa 기록 형식입니다.',
          );
        }
        blocks.add(
          RawHistoryBlock(
            index: index,
            bytes: bytes,
            format: HistoryRecordFormat.ica,
          ),
        );
      }
      // Assign only after successful 80EF polling and validated ICa history.
      // No additional service probe or PMm/IDm-based guess is needed.
      return _CardReadData(
        blocks: blocks,
        comparisonToken: token,
        brandIdentity: CardBrandIdentity.ica,
      );
    } finally {
      idm.fillRange(0, idm.length, 0);
    }
  }

  CardReadIssue _readIssue(Object error) => switch (error) {
    TimeoutException() => CardReadIssue.timedOut,
    PlatformException() => CardReadIssue.platformError,
    UnsupportedError() => CardReadIssue.unsupportedOperation,
    _ => CardReadIssue.unexpectedError,
  };

  void _traceRead(
    int generation,
    CardReadStage stage, {
    CardReadIssue? issue,
    List<int>? initialSystemCode,
    bool? icaRoute,
    int? blockIndex,
    List<int>? reply,
    String? platformCode,
  }) {
    if (_completed || generation != _scanGeneration) return;
    emitCardReadTrace(
      CardReadTrace(
        stage: stage,
        issue: issue,
        initialSystemCode: initialSystemCode,
        icaRoute: icaRoute,
        blockIndex: blockIndex,
        response: reply,
        platformCode: platformCode,
      ),
    );
  }

  Future<Uint8List> _transceiveIca(
    NfcFAndroid tag,
    Uint8List command, {
    required int generation,
    required CardReadStage start,
    required CardReadStage response,
    int? blockIndex,
  }) async {
    _requireDiagnosticActive(generation);
    _traceRead(generation, start, blockIndex: blockIndex);
    try {
      final reply = await tag
          .transceive(command)
          .timeout(const Duration(seconds: 3));
      _requireDiagnosticActive(generation);
      _traceRead(generation, response, blockIndex: blockIndex, reply: reply);
      return reply;
    } on CardScanException {
      rethrow;
    } catch (error) {
      _traceRead(
        generation,
        start,
        blockIndex: blockIndex,
        issue: _readIssue(error),
        platformCode: error is PlatformException ? error.code : null,
      );
      rethrow;
    }
  }

  Future<_CardReadData> _readAndroid(NfcFAndroid tag, List<int>? key) async {
    // IDm is used transiently for FeliCa commands and is never returned,
    // persisted, or logged.
    final idm = Uint8List.fromList(tag.tag.id);
    final token = key == null ? null : comparisonTokenFor(idm, key);
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
    return _CardReadData(
      blocks: blocks,
      currentGateTravel: await _readAndroidCurrentGateTravel(tag, idm),
      comparisonToken: token,
    );
  }

  Future<_CardReadData> _readIos(FeliCaIos tag) async {
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
    return _CardReadData(
      blocks: blocks,
      currentGateTravel: await _readIosCurrentGateTravel(tag),
    );
  }

  Future<CurrentGateTravel?> _readAndroidCurrentGateTravel(
    NfcFAndroid tag,
    Uint8List idm,
  ) async {
    try {
      final latestGateHistoryBlock = await _readAndroidServiceBlock(
        tag,
        idm: idm,
        serviceCode: _gateHistoryService,
      );
      final sfEntryBlock = await _readAndroidServiceBlock(
        tag,
        idm: idm,
        serviceCode: _sfEntryService,
      );
      return CurrentGateTravel.fromFeliCaServiceBlocks(
        latestGateHistoryBlock: latestGateHistoryBlock,
        sfEntryBlock: sfEntryBlock,
      );
    } catch (_) {
      // Gate services are optional. A service read failure must not turn a
      // successful 090F history read into a failed scan.
      return null;
    }
  }

  Future<Uint8List?> _readAndroidServiceBlock(
    NfcFAndroid tag, {
    required Uint8List idm,
    required int serviceCode,
  }) async {
    final response = await tag.transceive(
      FelicaProtocol.buildReadWithoutEncryptionCommand(
        idm: idm,
        blockIndex: 0,
        serviceCode: serviceCode,
      ),
    );
    return FelicaProtocol.parseReadWithoutEncryptionResponse(
      response,
      expectedIdm: idm,
    );
  }

  Future<CurrentGateTravel?> _readIosCurrentGateTravel(FeliCaIos tag) async {
    try {
      final latestGateHistoryBlock = await _readIosServiceBlock(
        tag,
        serviceCode: _gateHistoryServiceCode,
      );
      final sfEntryBlock = await _readIosServiceBlock(
        tag,
        serviceCode: _sfEntryServiceCode,
      );
      return CurrentGateTravel.fromFeliCaServiceBlocks(
        latestGateHistoryBlock: latestGateHistoryBlock,
        sfEntryBlock: sfEntryBlock,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _readIosServiceBlock(
    FeliCaIos tag, {
    required Uint8List serviceCode,
  }) async {
    final response = await tag.readWithoutEncryption(
      serviceCodeList: [serviceCode],
      blockList: [
        Uint8List.fromList(const [0x80, 0]),
      ],
    );
    if (response.statusFlag1 != 0 ||
        response.statusFlag2 != 0 ||
        response.blockData.length != 1 ||
        response.blockData.first.length != felicaHistoryBlockLength) {
      return null;
    }
    return Uint8List.fromList(response.blockData.first);
  }

  @override
  Future<void> cancel() async {
    _cancellationEpoch++;
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
    bool stopPlatformSession = true,
  }) async {
    if (_completed) return;
    _completed = true;
    _availabilityPollTimer?.cancel();
    _availabilityPollTimer = null;
    try {
      if (stopPlatformSession) {
        await _manager.stopSession(
          alertMessageIos: result == null ? null : 'IC 카드 이용내역을 읽었습니다.',
          errorMessageIos: error?.message,
        );
      }
    } catch (_) {
      // Session teardown failures must not leak from the plugin callback.
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

class _CardReadData {
  const _CardReadData({
    required this.blocks,
    this.currentGateTravel,
    this.comparisonToken,
    this.brandIdentity,
  });

  final List<RawHistoryBlock> blocks;
  final CurrentGateTravel? currentGateTravel;
  final String? comparisonToken;
  final CardBrandIdentity? brandIdentity;
}
