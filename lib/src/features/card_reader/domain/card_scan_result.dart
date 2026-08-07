import 'raw_history_block.dart';

class CardScanResult {
  const CardScanResult({required this.scannedAt, required this.blocks});

  final DateTime scannedAt;
  final List<RawHistoryBlock> blocks;
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
