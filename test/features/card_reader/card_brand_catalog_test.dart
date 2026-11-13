import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_brand_catalog.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_diagnostics.dart';

void main() {
  test('catalog has unique ids, valid labels and broad regional coverage', () {
    expect(cardBrandCatalog.length, greaterThanOrEqualTo(70));
    expect(
      cardBrandCatalog.map((e) => e.id).toSet().length,
      cardBrandCatalog.length,
    );
    expect(
      cardBrandCatalog.map((e) => e.name).toSet().length,
      cardBrandCatalog.length,
    );
    expect(cardBrandCatalog.map((e) => e.group).toSet().length, 10);
    expect(cardBrandCatalog.where((e) => e.group == '전국 상호이용').length, 10);
    for (final brand in cardBrandCatalog) {
      expect(validateCardBrandLabel(brand.name), isNull, reason: brand.name);
    }
  });

  test('owned brands resolve by Korean, Roman and Japanese names', () {
    for (final entry in {
      '스이카': 'suica',
      '이코카': 'icoca',
      '토이카': 'toica',
      'はやかけん': 'hayakaken',
      '니모카': 'nimoca',
      '아이카': 'ica',
    }.entries) {
      expect(
        cardBrandCatalog.where((b) => b.matches(entry.key)).map((b) => b.id),
        contains(entry.value),
      );
    }
    expect(cardBrandCatalog.where((b) => b.matches('가나자와')).single.id, 'ica');
    expect(
      cardBrandCatalog.where((b) => b.matches(' TOI-CA ')).single.id,
      'toica',
    );
    expect(cardBrandCatalog.where((b) => b.matches('존재하지않는카드')), isEmpty);
  });

  test(
    'manual brand permits unknown names but rejects empty, long and unsafe labels',
    () {
      expect(validateCardBrandLabel('새로운 지역 카드'), isNull);
      expect(validateCardBrandLabel(' '), isNotNull);
      expect(validateCardBrandLabel('가' * 41), isNotNull);
      expect(validateCardBrandLabel('test\nlog'), isNotNull);
      expect(validateCardBrandLabel('test\u202Elog'), isNotNull);
      expect(validateCardBrandLabel('0102030405060708'), isNotNull);
    },
  );

  final idm = List.generate(8, (i) => i + 1);
  test(
    'system-code protocol validates framing and IDm without returning IDm',
    () {
      expect(CardDiagnosticProtocol.requestSystemCodes(idm), [10, 12, ...idm]);
      final response = [15, 13, ...idm, 2, 0, 3, 0x86, 0xA7];
      expect(CardDiagnosticProtocol.parseSystemCodes(response, idm), [
        '0003',
        '86A7',
      ]);
      for (final malformed in <List<int>>[
        [],
        [...response]..[0] = 14,
        [...response]..[1] = 7,
        [...response]..[2] = 99,
        [...response]..[10] = 3,
        [11, 13, ...idm, 0],
      ]) {
        expect(CardDiagnosticProtocol.parseSystemCodes(malformed, idm), isNull);
      }
      expect(
        () => CardDiagnosticProtocol.requestSystemCodes([1]),
        throwsArgumentError,
      );
    },
  );

  test('terminal output is gated and contains only allowlisted metadata', () {
    final report = CardDiagnosticReport(
      initialSystemCode: '0003',
      pmm: '0102030405060708',
      systemCodes: ['0003'],
      systemCodeStatus: 'ok',
    );
    if (!cardDiagnosticsEnabled) {
      expect(() => report.formatForTerminal('Suica'), throwsStateError);
    } else {
      final text = report.formatForTerminal('Suica');
      expect(text, contains('"manual_brand":"Suica"'));
      for (final forbidden in [
        'idm',
        'balance',
        'history',
        'comparisonToken',
      ]) {
        expect(text.toLowerCase(), isNot(contains(forbidden.toLowerCase())));
      }
      expect(() => report.formatForTerminal('bad\nlabel'), throwsArgumentError);
    }
  });
}
