import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_diagnostics.dart';

void main() {
  test('SUGOCA normal-scan pair is complete, exclusive and local only', () {
    CardServiceProbeReport probe(
      Set<int> present, {
      int? unknown,
      String status = 'ok',
    }) => CardServiceProbeReport(
      status: status,
      presence: {
        for (final code in normalScanBrandServiceCodes)
          code: code == unknown ? null : present.contains(code),
      },
    );
    const pair = {0x21C8, 0x2208};
    final result = identifyObservedServiceBrand(
      probe(pair),
      includeSugoca: true,
    );
    expect(result.brand, DiagnosticBrand.sugoca);
    expect(result.reason, DiagnosticBrandReason.publicServicePattern);
    for (final present in [
      <int>{},
      {0x21C8},
      {0x2208},
      {...pair, 0x1808},
      {...pair, 0x1A48},
      {...pair, 0x98CC},
    ]) {
      expect(
        identifyObservedServiceBrand(probe(present), includeSugoca: true).brand,
        isNull,
      );
    }
    for (final code in normalScanBrandServiceCodes) {
      expect(
        identifyObservedServiceBrand(
          probe(pair, unknown: code),
          includeSugoca: true,
        ).brand,
        isNull,
      );
    }
    expect(
      identifyObservedServiceBrand(
        probe(pair, status: 'partial'),
        includeSugoca: true,
      ).brand,
      isNull,
    );
    // Existing developer/support reports retain their nineteen-code contract.
    expect(identifyObservedServiceBrand(probe(pair)).brand, isNull);
    final fields = probe(pair).toLogFields()['presence'] as Map;
    expect(fields.length, 19);
    expect(fields.containsKey('21C8'), isFalse);
    expect(fields.containsKey('2208'), isFalse);
    expect(normalScanBrandServiceCodes.toSet().length, 21);
  });
  test(
    'public Kitaca/manaca pairs are identified without PMm or manual labels',
    () {
      for (final (codes, brand) in [
        ([0x208B, 0x20CB], DiagnosticBrand.kitaca),
        ([0x9888, 0x98CC], DiagnosticBrand.manaca),
      ]) {
        final result = _report(codes).experimentalBrand;
        expect(result.brand, brand);
        expect(result.reason, DiagnosticBrandReason.publicServicePattern);
        for (final single in codes) {
          expect(_report([single]).experimentalBrand.brand, isNull);
        }
        expect(_report([...codes, 0x1808]).experimentalBrand.brand, isNull);
        expect(
          _report(codes, unknown: codes.first).experimentalBrand.brand,
          isNull,
        );
      }
    },
  );
  test(
    'manual brand may be omitted but provided labels are still validated',
    () {
      final report = _report([0x1E08, 0x1E48, 0x1E8B]);
      if (!cardDiagnosticsEnabled) {
        expect(() => report.formatForTerminal(), throwsStateError);
        return;
      }
      final text = report.formatForTerminal();
      final log =
          jsonDecode(text.substring('[CARD_DIAGNOSTICS] '.length)) as Map;
      expect(log['manual_brand'], isNull);
      expect(log['experimental_identification']['brand'], 'toica');
      expect(report.formatForTerminal(null), text);
      for (final invalid in ['', ' ', 'bad\nlabel']) {
        expect(() => report.formatForTerminal(invalid), throwsArgumentError);
      }
    },
  );

  // Sanitized user observations: no IDm, balance, blocks or travel history.
  final observations =
      <
        ({
          String name,
          DiagnosticBrand expected,
          List<int> services,
          String pmm,
        })
      >[
        (
          name: 'physical Suica',
          expected: DiagnosticBrand.suicaFamily,
          services: [0x1808, 0x18C8],
          pmm: '053143454682B7FF',
        ),
        (
          name: 'mobile Suica',
          expected: DiagnosticBrand.suicaFamily,
          services: [0x1808],
          pmm: '01168B868FBECBFF',
        ),
        (
          name: 'mobile PASMO',
          expected: DiagnosticBrand.pasmo,
          services: [0x1CC8, 0x1D08],
          pmm: '01168B868FBECBFF',
        ),
        (
          name: 'physical ICOCA',
          expected: DiagnosticBrand.icoca,
          services: [0x1A48, 0x1A88, 0x9608],
          pmm: '0136428247459AFF',
        ),
        (
          name: 'physical TOICA retry',
          expected: DiagnosticBrand.toica,
          services: [0x1E08, 0x1E48, 0x1E8B],
          pmm: '0136428247459AFF',
        ),
        (
          name: 'physical Hayakaken',
          expected: DiagnosticBrand.hayakaken,
          services: [0x2448, 0x2488],
          pmm: '053143454682B7FF',
        ),
        (
          name: 'physical nimoca',
          expected: DiagnosticBrand.nimoca,
          services: [0x1F48, 0x1FC8, 0x2008],
          pmm: '053143454682B7FF',
        ),
        (
          name: 'regional KURURU is family only',
          expected: DiagnosticBrand.suicaFamily,
          services: [0x1808],
          pmm: '063143454682B7FF',
        ),
      ];
  for (final sample in observations) {
    test('observed ${sample.name}', () {
      final report = _report(sample.services, pmm: sample.pmm);
      expect(report.experimentalBrand.brand, sample.expected);
      // Shared PMm is never used as a brand, mobile or product discriminator.
      expect(
        _report(sample.services, pmm: null).experimentalBrand.brand,
        sample.expected,
      );
    });
  }

  test('observed physical ICa uses active 80EF, no service probe required', () {
    final report = CardDiagnosticReport(
      initialSystemCode: '80EF',
      pmm: '0136428247459AFF',
      systemCodes: ['80EF'],
      systemCodeStatus: 'ok',
      serviceProbe: CardServiceProbeReport(
        status: 'skipped',
        issue: DiagnosticQueryIssue.systemNotSelected,
      ),
    );
    expect(report.experimentalBrand.brand, DiagnosticBrand.ica);
    expect(
      report.experimentalBrand.reason,
      DiagnosticBrandReason.observedSystemCode,
    );
  });

  test(
    'original TOICA 0000/platform error is unknown, not a negative brand',
    () {
      final report = CardDiagnosticReport(
        initialSystemCode: '0000',
        pmm: '0136428247459AFF',
        systemCodes: [],
        systemCodeStatus: 'unavailable',
        systemCodeIssue: DiagnosticQueryIssue.platformError,
        serviceProbe: CardServiceProbeReport(status: 'skipped'),
      );
      expect(report.experimentalBrand.brand, isNull);
      expect(
        report.experimentalBrand.reason,
        DiagnosticBrandReason.systemQueryFailed,
      );
    },
  );

  test('partial, failed, missing and unknown probes cannot select a brand', () {
    for (final status in ['partial', 'unavailable', 'skipped']) {
      expect(
        _report([0x1808], probeStatus: status).experimentalBrand.brand,
        isNull,
      );
    }
    expect(_report([0x1808], unknown: 0x2448).experimentalBrand.brand, isNull);
    expect(
      _report([
        0x1808,
      ], probeIssue: DiagnosticQueryIssue.timedOut).experimentalBrand.brand,
      isNull,
    );
    final noProbe = CardDiagnosticReport(
      initialSystemCode: '0003',
      pmm: null,
      systemCodes: ['0003'],
      systemCodeStatus: 'ok',
    );
    expect(noProbe.experimentalBrand.brand, isNull);
  });

  test('incomplete positive groups and all absent do not guess', () {
    for (final present in <List<int>>[
      [],
      [0x1A48],
      [0x1E08, 0x1E48],
      [0x1F48],
      [0x1CC8],
      [0x2448],
      [0x18C8],
    ]) {
      final result = _report(present).experimentalBrand;
      expect(result.brand, isNull);
      expect(result.reason, DiagnosticBrandReason.unmatchedPattern);
    }
  });

  test('one conflicting service invalidates an otherwise full pattern', () {
    for (final sample in observations) {
      final other = sample.expected == DiagnosticBrand.icoca ? 0x1808 : 0x1A48;
      final result = _report([...sample.services, other]).experimentalBrand;
      expect(result.brand, isNull);
      expect(result.reason, DiagnosticBrandReason.conflictingServices);
    }
  });

  test('system errors and wrong active systems override matching services', () {
    for (final status in ['unavailable', 'timed_out', 'invalid_response']) {
      expect(
        _report([0x1808], systemStatus: status).experimentalBrand.brand,
        isNull,
      );
    }
    expect(
      _report([
        0x1808,
      ], systemIssue: DiagnosticQueryIssue.other).experimentalBrand.brand,
      isNull,
    );
    for (final initial in <String?>[null, '0000', 'FE00', '80EF']) {
      expect(
        _report([0x1808], initial: initial).experimentalBrand.brand,
        isNull,
      );
    }
    expect(
      _report([0x1808], systems: ['86A7']).experimentalBrand.brand,
      isNull,
    );
    expect(
      _report([], systems: ['0003', 'FE00', '86A7']).experimentalBrand.brand,
      isNull,
    );
    expect(
      _report([], systems: ['0003', 'FE00', '927A']).experimentalBrand.brand,
      isNull,
    );
  });

  test(
    'manual label is separate; logs are gated and candidate, not confirmed',
    () {
      final report = _report([0x1A48, 0x1A88, 0x9608]);
      if (!cardDiagnosticsEnabled) {
        expect(() => report.formatForTerminal('TOICA'), throwsStateError);
        return;
      }
      for (final manual in ['TOICA', 'Suica', '직접 입력 카드']) {
        final text = report.formatForTerminal(manual);
        final log =
            jsonDecode(text.substring('[CARD_DIAGNOSTICS] '.length)) as Map;
        expect(log['schema'], 3);
        expect(log['manual_brand'], manual);
        expect(log['experimental_identification']['brand'], 'icoca');
        expect(log['experimental_identification']['status'], 'candidate');
        for (final forbidden in ['idm', 'balance', 'history', 'key_version']) {
          expect(text.toLowerCase(), isNot(contains(forbidden)));
        }
      }
    },
  );
}

CardDiagnosticReport _report(
  List<int> present, {
  String? pmm,
  String? initial = '0003',
  List<String> systems = const ['0003'],
  String systemStatus = 'ok',
  DiagnosticQueryIssue? systemIssue,
  String probeStatus = 'ok',
  DiagnosticQueryIssue? probeIssue,
  int? unknown,
}) => CardDiagnosticReport(
  initialSystemCode: initial,
  pmm: pmm,
  systemCodes: systems,
  systemCodeStatus: systemStatus,
  systemCodeIssue: systemIssue,
  serviceProbe: CardServiceProbeReport(
    status: probeStatus,
    issue: probeIssue,
    presence: {
      for (final code in diagnosticServiceCodes)
        code: code == unknown ? null : present.contains(code),
    },
  ),
);
