import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_diagnostics.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_read_trace.dart';

void main() {
  test('trace is opt-in and excludes identifiers and history payload', () {
    final reply = [
      29,
      7,
      ...List.filled(8, 0xAB),
      1,
      0xA1,
      0,
      ...List.filled(16, 0xCD),
    ];
    final trace = CardReadTrace(
      stage: CardReadStage.icaHistoryResponse,
      blockIndex: 0,
      response: reply,
      platformCode: 'SECRET_ID_AND_ERROR_PAYLOAD',
    );
    final text = trace.formatForTerminal();
    if (!cardDiagnosticsEnabled) {
      expect(text, isNull);
      return;
    }
    final log = jsonDecode(text!.substring('[CARD_READ_TRACE] '.length)) as Map;
    expect(log, {
      'schema': 1,
      'implementation': 'ica-898f-v1',
      'stage': 'icaHistoryResponse',
      'block_index': 0,
      'response_length': 29,
      'response_code': 7,
      'status_flag_1': 1,
      'status_flag_2': 0xA1,
    });
    for (final forbidden in [
      'ABAB',
      'CDCD',
      'SECRET',
      'idm',
      'balance',
      'history_payload',
      'pmm',
      'message',
      'stack',
    ]) {
      expect(text, isNot(contains(forbidden)));
    }
  });
  test(
    'only read-response status headers, never polling address bytes, are logged',
    () {
      for (final stage in [
        CardReadStage.icaPollingResponse,
        CardReadStage.icaHistoryResponse,
      ]) {
        for (final reply in <List<int>>[
          [],
          [1],
          [20, 1, ...List.filled(18, 0xAA)],
        ]) {
          final text = CardReadTrace(
            stage: stage,
            response: reply,
          ).formatForTerminal();
          if (!cardDiagnosticsEnabled) {
            expect(text, isNull);
            continue;
          }
          expect(text, isNot(contains('status_flag')));
        }
      }
    },
  );
  test(
    'safe route and normalized issue can be shared without native messages',
    () {
      final text = const CardReadTrace(
        stage: CardReadStage.routeSelected,
        initialSystemCode: [0x80, 0xEF],
        icaRoute: true,
        issue: CardReadIssue.platformError,
        platformCode: 'IOException',
      ).formatForTerminal();
      if (!cardDiagnosticsEnabled) {
        expect(text, isNull);
        return;
      }
      expect(text, contains('"initial_system_code":"80EF"'));
      expect(text, contains('"route":"ica"'));
      expect(text, contains('"platform_code":"IOException"'));
      expect(text, contains('"issue":"platformError"'));
    },
  );
}
