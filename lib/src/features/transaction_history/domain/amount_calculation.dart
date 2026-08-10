enum AmountCalculationStatus {
  calculated,
  balanceIncrease,
  unavailable,
  suspicious,
}

enum AmountUnavailableReason { noOlderRecord, balanceDidNotDecrease }

class AmountCalculation {
  const AmountCalculation._({
    required this.status,
    this.amount,
    this.unavailableReason,
  });

  const AmountCalculation.calculated(int amount)
    : this._(status: AmountCalculationStatus.calculated, amount: amount);

  const AmountCalculation.balanceIncrease(int amount)
    : this._(status: AmountCalculationStatus.balanceIncrease, amount: amount);

  const AmountCalculation.unavailable({AmountUnavailableReason? reason})
    : this._(
        status: AmountCalculationStatus.unavailable,
        unavailableReason: reason,
      );

  const AmountCalculation.suspicious()
    : this._(status: AmountCalculationStatus.suspicious);

  final AmountCalculationStatus status;
  final int? amount;
  final AmountUnavailableReason? unavailableReason;

  bool get isResolved =>
      status == AmountCalculationStatus.calculated ||
      status == AmountCalculationStatus.balanceIncrease;
}
