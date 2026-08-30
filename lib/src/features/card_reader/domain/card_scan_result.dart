import 'raw_history_block.dart';
import 'current_gate_travel.dart';

class CardScanResult {
  const CardScanResult({
    required this.scannedAt,
    required this.blocks,
    this.currentGateTravel,
  });

  final DateTime scannedAt;
  final List<RawHistoryBlock> blocks;
  final CurrentGateTravel? currentGateTravel;
}

enum CardScanFailureKind {
  nfcUnavailable,
  unsupportedTag,
  tagLost,
  invalidResponse,
  noHistory,
  timedOut,
  cancelled,
  unknown,
}

class CardScanException implements Exception {
  const CardScanException(this.kind, this.message, {this.cause});

  final CardScanFailureKind kind;
  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
