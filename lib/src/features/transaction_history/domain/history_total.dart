import 'amount_calculation.dart';
import 'parsed_transit_history.dart';
import 'transit_transaction_type.dart';

enum HistoryTotalKind { spending, charge, unidentified }

/// Adds amounts already calculated from the complete scan. Filtering must not
/// recalculate balance differences between the remaining records.
class HistoryTotal {
  const HistoryTotal._({
    required this.kind,
    required this.recordCount,
    required this.includedCount,
    required this.amount,
  });

  factory HistoryTotal.calculate(
    Iterable<ParsedTransitHistory> records, {
    required HistoryTotalKind kind,
  }) {
    var recordCount = 0;
    var includedCount = 0;
    var sum = 0;
    for (final history in records) {
      recordCount++;
      final calculation = history.amountCalculation;
      final value = calculation.amount;
      final eligible = switch (kind) {
        HistoryTotalKind.spending =>
          (history.transactionType == TransitTransactionType.rail ||
                  history.transactionType == TransitTransactionType.bus ||
                  history.transactionType == TransitTransactionType.purchase) &&
              calculation.status == AmountCalculationStatus.calculated,
        HistoryTotalKind.charge =>
          history.transactionType == TransitTransactionType.charge &&
              calculation.status == AmountCalculationStatus.balanceIncrease,
        HistoryTotalKind.unidentified => false,
      };
      if (!eligible || value == null || value <= 0) continue;
      sum += value;
      includedCount++;
    }
    return HistoryTotal._(
      kind: kind,
      recordCount: recordCount,
      includedCount: includedCount,
      // Unknown/unavailable amounts are not equivalent to a genuine zero.
      amount: includedCount == 0 ? null : sum,
    );
  }

  final HistoryTotalKind kind;
  final int recordCount;
  final int includedCount;
  final int? amount;
  int get excludedCount => recordCount - includedCount;
}
