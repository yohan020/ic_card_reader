import 'raw_history_block.dart';

List<String> buildRawHistoryFixtureLog(List<RawHistoryBlock> blocks) {
  return [
    'IC_CARD_FIXTURE_BEGIN count=${blocks.length}',
    for (final block in blocks)
      'IC_CARD_BLOCK[${block.index}]=${block.hexadecimal}',
    'IC_CARD_FIXTURE_END',
  ];
}
