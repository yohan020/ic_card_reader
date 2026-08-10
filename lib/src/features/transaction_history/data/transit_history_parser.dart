import '../../card_reader/domain/raw_history_block.dart';
import '../domain/amount_calculation.dart';
import '../domain/parsed_transit_history.dart';
import '../domain/transit_transaction_type.dart';

class TransitHistoryParser {
  const TransitHistoryParser();

  static const version = 'phase2-parser-v1';

  int? currentBalance(List<RawHistoryBlock> blocks) {
    for (final block in blocks) {
      if (_isEmptyBlock(block)) return null;
      return block.bytes[10] | (block.bytes[11] << 8);
    }
    return null;
  }

  List<ParsedTransitHistory> parse(List<RawHistoryBlock> blocks) {
    final parsed = blocks
        .takeWhile((block) => !_isEmptyBlock(block))
        .map(_parseBlock)
        .toList(growable: false);
    final finalized = [
      for (var index = 0; index < parsed.length; index++)
        _finalizeRecord(parsed, index),
    ];
    return finalized
        .where((history) => !_isInitializationRecord(history.rawBlock))
        .toList(growable: false);
  }

  bool _isEmptyBlock(RawHistoryBlock block) =>
      block.bytes[0] == 0 && block.bytes[1] == 0;

  bool _isInitializationRecord(RawHistoryBlock block) {
    final terminal = block.bytes[0];
    final process = block.bytes[1];
    return process == 0x07 &&
        (terminal == 0x08 || terminal == 0x12 || terminal == 0x22);
  }

  ParsedTransitHistory _finalizeRecord(
    List<ParsedTransitHistory> parsed,
    int index,
  ) {
    final current = parsed[index];
    final older = index + 1 < parsed.length ? parsed[index + 1] : null;
    final transactionType = _classifyTransaction(current, older);
    final amountCalculation = older == null
        ? const AmountCalculation.unavailable(
            reason: AmountUnavailableReason.noOlderRecord,
          )
        : _calculateAmount(current, older, transactionType);
    return current.copyWith(
      transactionType: transactionType,
      amountCalculation: amountCalculation,
    );
  }

  ParsedTransitHistory _parseBlock(RawHistoryBlock block) {
    final bytes = block.bytes;
    return ParsedTransitHistory(
      rawBlock: block,
      usageDate: _parseDate(bytes[4], bytes[5]),
      terminalCode: bytes[0],
      processCode: bytes[1],
      regionCode: bytes[15],
      boardingLineCode: bytes[6],
      boardingStationCode: bytes[7],
      alightingLineCode: bytes[8],
      alightingStationCode: bytes[9],
      balance: bytes[10] | (bytes[11] << 8),
      // Transaction codes have not yet been verified against physical-card
      // ground truth. Preserve UNKNOWN instead of inferring rail by default.
      transactionType: TransitTransactionType.unknown,
      amountCalculation: const AmountCalculation.unavailable(),
    );
  }

  DateTime? _parseDate(int highByte, int lowByte) {
    final year = 2000 + (highByte >> 1);
    final month = ((highByte & 0x01) << 3) | (lowByte >> 5);
    final day = lowByte & 0x1F;
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }

    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  AmountCalculation _calculateAmount(
    ParsedTransitHistory current,
    ParsedTransitHistory older,
    TransitTransactionType transactionType,
  ) {
    final currentDate = current.usageDate;
    final olderDate = older.usageDate;
    if (currentDate == null || olderDate == null) {
      return const AmountCalculation.suspicious();
    }
    if (olderDate.isAfter(currentDate)) {
      return const AmountCalculation.suspicious();
    }

    final balanceChange = current.balance - older.balance;
    if (transactionType == TransitTransactionType.charge && balanceChange > 0) {
      return AmountCalculation.balanceIncrease(balanceChange);
    }

    final deduction = -balanceChange;
    if (deduction <= 0) {
      // A balance increase or no change must not be displayed as a fare.
      return const AmountCalculation.unavailable(
        reason: AmountUnavailableReason.balanceDidNotDecrease,
      );
    }
    return AmountCalculation.calculated(deduction);
  }

  TransitTransactionType _classifyTransaction(
    ParsedTransitHistory current,
    ParsedTransitHistory? older,
  ) {
    final terminal = current.terminalCode;
    final process = current.processCode;
    if (terminal == 0x16 && process == 0x01) {
      return TransitTransactionType.rail;
    }
    if (terminal == 0x05 && process == 0x0D) {
      return TransitTransactionType.bus;
    }
    if ((terminal == 0xC7 || terminal == 0xC8) && process == 0x46) {
      return TransitTransactionType.purchase;
    }
    if (terminal == 0xC8 &&
        process == 0x49 &&
        older != null &&
        current.balance > older.balance) {
      return TransitTransactionType.charge;
    }
    return TransitTransactionType.unknown;
  }
}
