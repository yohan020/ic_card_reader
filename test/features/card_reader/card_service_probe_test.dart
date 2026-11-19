import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_diagnostics.dart';

void main() {
  final idm = List.generate(8, (i) => i + 1);
  const codes = [0x1A48, 0x1E08];
  test('request-service command is bounded, allowlisted and little endian', () {
    expect(CardDiagnosticProtocol.requestServices(idm, codes), [
      15,
      2,
      ...idm,
      2,
      0x48,
      0x1A,
      0x08,
      0x1E,
    ]);
    for (final invalid in <List<int>>[
      [],
      [0x090F],
      diagnosticServiceCodes.take(6).toList(),
    ]) {
      expect(
        () => CardDiagnosticProtocol.requestServices(idm, invalid),
        throwsArgumentError,
      );
    }
    expect(
      () => CardDiagnosticProtocol.requestServices([1], codes),
      throwsArgumentError,
    );
  });

  test(
    'only successful well-formed FFFF means absent; key versions are discarded',
    () {
      final response = [15, 3, ...idm, 2, 0, 0, 0xFF, 0xFF];
      expect(
        CardDiagnosticProtocol.parseServicePresence(response, idm, codes),
        {0x1A48: true, 0x1E08: false},
      );
      for (final bad in <List<int>>[
        [],
        [...response]..[0] = 14,
        [...response]..[1] = 7,
        [...response]..[2] = 99,
        [...response]..[10] = 1,
        [...response, 0],
        response.take(14).toList(),
      ]) {
        expect(
          CardDiagnosticProtocol.parseServicePresence(bad, idm, codes),
          isNull,
        );
      }
    },
  );

  test(
    'logs contain fixed service presence only, immutable and unknown by default',
    () {
      final state = <int, bool?>{0x1A48: true, 0x1E08: false};
      final probe = CardServiceProbeReport(
        status: 'partial',
        issue: DiagnosticQueryIssue.platformError,
        presence: state,
      );
      state[0x1A48] = false;
      final fields = probe.toLogFields();
      final values = fields['presence'] as Map;
      expect(values.length, 19);
      expect(values['1A48'], 'present');
      expect(values['1E08'], 'absent');
      expect(values['1A88'], 'unknown');
      final text = jsonEncode(fields);
      for (final disallowed in ['key_version', 'idm', 'balance', 'history']) {
        expect(text, isNot(contains(disallowed)));
      }
      expect(() => probe.presence[0x1A48] = false, throwsUnsupportedError);
    },
  );
}
