import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'card_diagnostics.dart';

/// Developer opt-in trace: fixed protocol metadata only, never payload or IDm.
enum CardReadStage {
  routeSelected,
  icaPollingStart,
  icaPollingResponse,
  icaHistoryStart,
  icaHistoryResponse,
  icaRecordInvalid,
  scanFailed,
  scanSucceeded,
}

enum CardReadIssue {
  timedOut,
  platformError,
  cancelled,
  invalidResponse,
  noHistory,
  unsupportedTag,
  tagLost,
  unsupportedOperation,
  unexpectedError,
}

class CardReadTrace {
  const CardReadTrace({
    required this.stage,
    this.issue,
    this.initialSystemCode,
    this.icaRoute,
    this.blockIndex,
    this.response,
    this.platformCode,
  });
  final CardReadStage stage;
  final CardReadIssue? issue;
  final List<int>? initialSystemCode;
  final bool? icaRoute;
  final int? blockIndex;
  // Used transiently to extract fixed header fields; never retained by reader.
  final List<int>? response;
  final String? platformCode;

  String? formatForTerminal() {
    if (!cardDiagnosticsEnabled) return null;
    final reply = response;
    final readResponse =
        stage == CardReadStage.icaHistoryResponse &&
        reply != null &&
        reply.length >= 12 &&
        reply[1] == 7;
    const allowedPlatformCodes = {
      'IOException',
      'TagLostException',
      'IllegalStateException',
      'SecurityException',
      'tag_not_found',
    };
    final payload = {
      'schema': 1,
      'implementation': 'ica-898f-v1',
      'stage': stage.name,
      if (icaRoute != null) 'route': icaRoute! ? 'ica' : 'common',
      if (initialSystemCode?.length == 2)
        'initial_system_code': CardDiagnosticProtocol.hex(initialSystemCode!),
      if (blockIndex != null) 'block_index': blockIndex,
      if (issue != null) 'issue': issue!.name,
      if (allowedPlatformCodes.contains(platformCode))
        'platform_code': platformCode,
      if (reply != null) 'response_length': reply.length,
      if (reply != null && reply.length >= 2) 'response_code': reply[1],
      if (readResponse) 'status_flag_1': reply[10],
      if (readResponse) 'status_flag_2': reply[11],
    };
    return '[CARD_READ_TRACE] ${jsonEncode(payload)}';
  }
}

void emitCardReadTrace(CardReadTrace trace) {
  final text = trace.formatForTerminal();
  if (text != null) debugPrint(text);
}
