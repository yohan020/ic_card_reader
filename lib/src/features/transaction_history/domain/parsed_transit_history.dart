import '../../card_reader/domain/raw_history_block.dart';
import 'amount_calculation.dart';
import 'transit_transaction_type.dart';

class ParsedTransitHistory {
  const ParsedTransitHistory({
    required this.rawBlock,
    required this.usageDate,
    required this.terminalCode,
    required this.processCode,
    required this.regionCode,
    required this.boardingLineCode,
    required this.boardingStationCode,
    required this.alightingLineCode,
    required this.alightingStationCode,
    required this.balance,
    required this.transactionType,
    required this.amountCalculation,
  });

  final RawHistoryBlock rawBlock;
  final DateTime? usageDate;
  final int terminalCode;
  final int processCode;
  final int regionCode;
  final int boardingLineCode;
  final int boardingStationCode;
  final int alightingLineCode;
  final int alightingStationCode;
  final int balance;
  final TransitTransactionType transactionType;
  final AmountCalculation amountCalculation;

  ParsedTransitHistory copyWith({
    AmountCalculation? amountCalculation,
    TransitTransactionType? transactionType,
  }) {
    return ParsedTransitHistory(
      rawBlock: rawBlock,
      usageDate: usageDate,
      terminalCode: terminalCode,
      processCode: processCode,
      regionCode: regionCode,
      boardingLineCode: boardingLineCode,
      boardingStationCode: boardingStationCode,
      alightingLineCode: alightingLineCode,
      alightingStationCode: alightingStationCode,
      balance: balance,
      transactionType: transactionType ?? this.transactionType,
      amountCalculation: amountCalculation ?? this.amountCalculation,
    );
  }
}
