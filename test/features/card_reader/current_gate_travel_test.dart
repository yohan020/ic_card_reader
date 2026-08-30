import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/current_gate_travel.dart';

void main() {
  test('detects a verified entry that agrees with the SF entry service', () {
    final travel = CurrentGateTravel.fromFeliCaServiceBlocks(
      latestGateHistoryBlock: _block('A000E358200635191559000000000000'),
      sfEntryBlock: _block('E3580000000000000000000000000000'),
    );

    expect(travel?.entryLineCode, 0xE3);
    expect(travel?.entryStationCode, 0x58);
  });

  test('does not show travel after a verified exit event', () {
    final travel = CurrentGateTravel.fromFeliCaServiceBlocks(
      latestGateHistoryBlock: _block('2000E358200435191551D10000000000'),
      sfEntryBlock: _block('E32F0000000000000000000000000000'),
    );

    expect(travel, isNull);
  });

  test('does not infer a journey when the two services disagree', () {
    final travel = CurrentGateTravel.fromFeliCaServiceBlocks(
      latestGateHistoryBlock: _block('A000E358200635191559000000000000'),
      sfEntryBlock: _block('E32F0000000000000000000000000000'),
    );

    expect(travel, isNull);
  });
}

Uint8List _block(String hexadecimal) => Uint8List.fromList([
  for (var offset = 0; offset < hexadecimal.length; offset += 2)
    int.parse(hexadecimal.substring(offset, offset + 2), radix: 16),
]);
