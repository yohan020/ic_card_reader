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
    this.transactionDateTime,
    this.busOperatorName,
    this.transactionLocationRegionCode,
    this.transactionLocationLineCode,
    this.transactionLocationStationCode,
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
  final DateTime? transactionDateTime;
  final String? busOperatorName;
  final int? transactionLocationRegionCode;
  final int? transactionLocationLineCode;
  final int? transactionLocationStationCode;

  int get sequenceNumber =>
      (rawBlock.bytes[12] << 16) |
      (rawBlock.bytes[13] << 8) |
      rawBlock.bytes[14];

  bool get hasTransactionLocationCode =>
      transactionLocationRegionCode != null &&
      transactionLocationLineCode != null &&
      transactionLocationStationCode != null;

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
      transactionDateTime: transactionDateTime,
      busOperatorName: busOperatorName,
      transactionLocationRegionCode: transactionLocationRegionCode,
      transactionLocationLineCode: transactionLocationLineCode,
      transactionLocationStationCode: transactionLocationStationCode,
    );
  }
}
