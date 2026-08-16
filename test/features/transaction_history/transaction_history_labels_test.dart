import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/raw_history_block.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_resolution.dart';
import 'package:ic_card_reader/src/features/transaction_history/data/transit_history_parser.dart';
import 'package:ic_card_reader/src/features/transaction_history/presentation/transaction_history_labels.dart';

void main() {
  const parser = TransitHistoryParser();

  test('labels mobile charges without guessing a card brand or station', () {
    final regular = parser.parse([
      _block('1B023F00350302FD00003F0200005700'),
    ]).single;
    final benefit = parser.parse([
      _block('1B481E00342E9B810000020100041100'),
    ]).single;

    expect(chargeSummary(regular), '모바일에서 충전');
    expect(chargeMethodLabel(regular), '모바일');
    expect(chargeLocationDetail(regular), '확인할 수 없음');
    expect(chargeSummary(regular), isNot(contains('Suica')));
    expect(chargeSummary(regular), isNot(contains('PASMO')));
    expect(chargeSummary(benefit), '모바일 특전 충전');
    expect(chargeMethodLabel(benefit), '모바일 특전');
  });

  test('labels a station-gate charge with its resolved location', () {
    final history = parser.parse([
      _block('1A020000342CE91F00009F04000404C0'),
    ]).single;
    final location = _location(
      region: 3,
      line: 0xE9,
      station: 0x1F,
      stationName: '天神南',
      lineName: '3号線(七隈線)',
    );

    expect(chargeSummary(history, transactionLocation: location), '충전 · 天神南');
    expect(chargeMethodLabel(history), '역 개찰 단말');
    expect(
      chargeLocationDetail(history, transactionLocation: location),
      '天神南 · 3号線(七隈線)',
    );
  });

  test('labels only C8 C6 as cash-combined purchase', () {
    final cashCombined = parser.parse([
      _block('C8C60000342E5541A9F5480000040E00'),
    ]).single;
    final ordinary = parser.parse([
      _block('C846000034DD7C0F60DEC40300012100'),
    ]).single;

    expect(purchaseSummary(cashCombined), '물품 구매 · 현금 병용');
    expect(purchaseSummary(ordinary), '물품 구매');
  });

  test('labels 21 02 as a station terminal without guessing its location', () {
    final history = parser.parse([
      _block('21020000350DAC3800007B1700005E40'),
    ]).single;

    expect(chargeMethodLabel(history), '역 단말');
    expect(chargeSummary(history), '역 단말에서 충전');
    expect(chargeLocationDetail(history), '확인할 수 없음');
    expect(chargeSummary(history), isNot(contains('자동발권기')));
    expect(chargeSummary(history), isNot(contains('中部国際空港')));
  });

  test('labels Iyotetsu without choosing bus or tram', () {
    final history = parser.parse([
      _block('050D000F34FC0F3D00002F0700004FC0'),
    ]).single;

    expect(transactionTypeLabel(history), '버스·노면전차 이용');
    expect(busOperatorLabel(history), '伊予鉄道');
    expect(transactionTypeLabel(history), isNot('버스 이용'));
    expect(transactionTypeLabel(history), isNot('노면전차 이용'));
    expect(busOperatorLabel(history), isNot(contains('市内電車')));
    expect(busOperatorLabel(history), isNot(contains('伊予鉄バス')));
  });
}

RawHistoryBlock _block(String hexadecimal) => RawHistoryBlock(
  index: 0,
  bytes: Uint8List.fromList([
    for (var offset = 0; offset < hexadecimal.length; offset += 2)
      int.parse(hexadecimal.substring(offset, offset + 2), radix: 16),
  ]),
);

StationResolution _location({
  required int region,
  required int line,
  required int station,
  required String stationName,
  required String lineName,
}) {
  final code = StationCode(
    regionCode: region,
    lineCode: line,
    stationCode: station,
  );
  return StationResolution(
    requestedCode: code,
    strategy: StationMatchStrategy.exactRegion,
    station: StationRecord(
      code: code,
      operatorName: '',
      lineName: lineName,
      stationName: stationName,
      source: 'test',
    ),
  );
}
