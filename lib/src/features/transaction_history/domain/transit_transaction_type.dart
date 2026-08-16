enum TransitTransactionType {
  rail,
  bus,
  purchase,
  charge,
  gateWindowProcessing,
  refund,
  adjustment,
  unknown,
}

extension TransitTransactionTypeWireName on TransitTransactionType {
  String get wireName => switch (this) {
    TransitTransactionType.gateWindowProcessing => 'GATE_WINDOW_PROCESSING',
    _ => name.toUpperCase(),
  };
}
