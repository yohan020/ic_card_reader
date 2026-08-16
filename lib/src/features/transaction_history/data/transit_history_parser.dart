import '../../card_reader/domain/raw_history_block.dart';
import '../domain/amount_calculation.dart';
import '../domain/parsed_transit_history.dart';
import '../domain/transit_transaction_type.dart';

class TransitHistoryParser {
  const TransitHistoryParser();

  static const version = 'phase2-parser-v6.1';

  static const _conventionalRailGateTerminals = <int>{
    0x16, // General ticket gate.
    0x17, // Simple ticket gate.
    0x1A, // Ticket gate terminal.
    0x1D, // Transfer or connecting ticket gate.
  };

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
    final transactionType = _classifyTransaction(current);
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
    final terminal = bytes[0];
    final process = bytes[1];
    final regionCode = (bytes[15] >> 6) & 0x03;
    final hasStationTransactionLocation =
        (process == 0x02 && (terminal == 0x08 || terminal == 0x1A)) ||
        (terminal == 0x1A && process == 0x06);
    final hasTransactionLocationCode = bytes[6] != 0 || bytes[7] != 0;
    final usageDate = _parseDate(bytes[4], bytes[5]);
    return ParsedTransitHistory(
      rawBlock: block,
      usageDate: usageDate,
      terminalCode: terminal,
      processCode: process,
      regionCode: regionCode,
      boardingLineCode: bytes[6],
      boardingStationCode: bytes[7],
      alightingLineCode: bytes[8],
      alightingStationCode: bytes[9],
      balance: bytes[10] | (bytes[11] << 8),
      // Transaction codes have not yet been verified against physical-card
      // ground truth. Preserve UNKNOWN instead of inferring rail by default.
      transactionType: TransitTransactionType.unknown,
      amountCalculation: const AmountCalculation.unavailable(),
      transactionDateTime: _parsePurchaseDateTime(
        usageDate,
        process: process,
        highByte: bytes[6],
        lowByte: bytes[7],
      ),
      busOperatorName: _busOperatorName(
        regionCode: regionCode,
        terminal: terminal,
        process: process,
        byte6: bytes[6],
        byte7: bytes[7],
      ),
      transactionLocationRegionCode:
          hasStationTransactionLocation && hasTransactionLocationCode
          ? regionCode
          : null,
      transactionLocationLineCode:
          hasStationTransactionLocation && hasTransactionLocationCode
          ? bytes[6]
          : null,
      transactionLocationStationCode:
          hasStationTransactionLocation && hasTransactionLocationCode
          ? bytes[7]
          : null,
    );
  }

  DateTime? _parsePurchaseDateTime(
    DateTime? date, {
    required int process,
    required int highByte,
    required int lowByte,
  }) {
    if (date == null || (process != 0x46 && process != 0xC6)) return null;
    final packed = (highByte << 8) | lowByte;
    final hour = packed >> 11;
    final minute = (packed >> 5) & 0x3F;
    final second = (packed & 0x1F) * 2;
    if (hour > 23 || minute > 59 || second > 59) return null;
    return DateTime(date.year, date.month, date.day, hour, minute, second);
  }

  String? _busOperatorName({
    required int regionCode,
    required int terminal,
    required int process,
    required int byte6,
    required int byte7,
  }) {
    if (regionCode == 0x03 &&
        terminal == 0x05 &&
        process == 0x0F &&
        byte6 == 0x0A &&
        byte7 == 0x01) {
      return '西日本鉄道';
    }
    if (regionCode == 0x01 &&
        terminal == 0x05 &&
        process == 0x0D &&
        byte6 == 0x0D &&
        byte7 == 0x2A) {
      return '名古屋市交通局 市バス';
    }
    if (regionCode == 0x03 &&
        terminal == 0x05 &&
        process == 0x0D &&
        byte6 == 0x0F &&
        byte7 == 0x3D) {
      return '伊予鉄道';
    }
    return null;
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
    if (transactionType == TransitTransactionType.charge) {
      return balanceChange > 0
          ? AmountCalculation.balanceIncrease(balanceChange)
          : const AmountCalculation.suspicious();
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

  TransitTransactionType _classifyTransaction(ParsedTransitHistory current) {
    final terminal = current.terminalCode;
    final process = current.processCode;
    if (terminal == 0x1A && process == 0x06) {
      return TransitTransactionType.gateWindowProcessing;
    }
    if (process == 0x46) {
      return TransitTransactionType.purchase;
    }
    if (terminal == 0xC8 && process == 0xC6) {
      return TransitTransactionType.purchase;
    }
    if (terminal == 0x05 && (process == 0x0D || process == 0x0F)) {
      return TransitTransactionType.bus;
    }
    if (process == 0x02 ||
        (terminal == 0x1B && process == 0x48) ||
        (terminal == 0xC8 && process == 0x49)) {
      return TransitTransactionType.charge;
    }
    final hasBoardingCode =
        current.boardingLineCode != 0 || current.boardingStationCode != 0;
    final hasAlightingCode =
        current.alightingLineCode != 0 || current.alightingStationCode != 0;
    if (process == 0x01 &&
        _conventionalRailGateTerminals.contains(terminal) &&
        hasBoardingCode &&
        hasAlightingCode) {
      return TransitTransactionType.rail;
    }
    return TransitTransactionType.unknown;
  }
}
