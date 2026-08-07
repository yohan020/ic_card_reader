import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/raw_history_block.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/raw_history_fixture_log.dart';

void main() {
  test('formats raw blocks without card identifiers or device metadata', () {
    final blocks = [
      RawHistoryBlock(
        index: 0,
        bytes: Uint8List.fromList(List<int>.generate(16, (index) => index)),
      ),
      RawHistoryBlock(
        index: 1,
        bytes: Uint8List.fromList(List<int>.filled(16, 0xAB)),
      ),
    ];

    final lines = buildRawHistoryFixtureLog(blocks);

    expect(lines, [
      'IC_CARD_FIXTURE_BEGIN count=2',
      'IC_CARD_BLOCK[0]=000102030405060708090A0B0C0D0E0F',
      'IC_CARD_BLOCK[1]=ABABABABABABABABABABABABABABABAB',
      'IC_CARD_FIXTURE_END',
    ]);
    expect(lines.join(), isNot(contains('IDm')));
    expect(lines.join(), isNot(contains('device')));
  });
}
