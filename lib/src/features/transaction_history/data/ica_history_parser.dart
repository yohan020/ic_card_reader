import '../../card_reader/domain/raw_history_block.dart';
import '../domain/amount_calculation.dart';
import '../domain/parsed_transit_history.dart';
import '../domain/transit_transaction_type.dart';

/// ICa 898F record layout, independently implemented from the MIT reference:
/// webarata3/ica_reader @ df8993b0, lib/model/ica.dart.
/// Transaction kinds: http://jennychan.web.fc2.com/format/ica.html (898F).
/// Keep undocumented kinds and all location/operator semantics unknown.
class IcaHistoryParser {
  const IcaHistoryParser();
  static const version = 'ica-898f-v2';

  static bool isEmpty(List<int> bytes) =>
      bytes.every((b) => b == 0) || bytes.every((b) => b == 0xFF);

  static DateTime? recordDate(List<int> bytes) {
    if (bytes.length != 16) return null;
    final year = 2000 + (bytes[0] >> 1);
    final month = ((bytes[0] & 1) << 3) | (bytes[1] >> 5);
    final day = bytes[1] & 0x1F;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }

  int? currentBalance(List<RawHistoryBlock> blocks) {
    if (blocks.isEmpty || !_valid(blocks.first)) return null;
    final bytes = blocks.first.bytes;
    return (bytes[13] << 8) | bytes[14];
  }

  bool _valid(RawHistoryBlock block) =>
      block.format == HistoryRecordFormat.ica &&
      !isEmpty(block.bytes) &&
      recordDate(block.bytes) != null;

  List<ParsedTransitHistory> parse(List<RawHistoryBlock> blocks) => [
    for (final block in blocks.takeWhile(_valid)) _parse(block),
  ];

  ParsedTransitHistory _parse(RawHistoryBlock block) {
    final bytes = block.bytes;
    // A signed 12-bit balance change in units of 10 yen; not a fare type.
    final packed = ((bytes[11] & 0x0F) << 8) | bytes[12];
    final delta = (packed >= 0x800 ? packed - 0x1000 : packed) * 10;
    return ParsedTransitHistory(
      rawBlock: block,
      usageDate: recordDate(bytes),
      // No transit-090F terminal/process/station semantics in these bytes.
      terminalCode: 0,
      processCode: 0,
      regionCode: 0,
      boardingLineCode: 0,
      boardingStationCode: 0,
      alightingLineCode: 0,
      alightingStationCode: 0,
      balance: (bytes[13] << 8) | bytes[14],
      transactionType: _transactionType(bytes[10], delta),
      amountCalculation: delta < 0
          ? AmountCalculation.calculated(-delta)
          : delta > 0
          ? AmountCalculation.balanceIncrease(delta)
          : const AmountCalculation.unavailable(),
    );
  }

  TransitTransactionType _transactionType(int kind, int delta) {
    // Byte 10 is ICa's own kind field, NOT a transit-090F process code.
    // 5 = bus terminal; 3/D = down/up ride; 9 = top-up (5/7 terminal).
    // Never infer bus from a negative delta alone: ICa also supports rail.
    if ((kind == 0x53 || kind == 0x5D) && delta < 0) {
      return TransitTransactionType.bus;
    }
    if ((kind == 0x59 || kind == 0x79) && delta > 0) {
      return TransitTransactionType.charge;
    }
    return TransitTransactionType.unknown;
  }
}
