import 'raw_history_block.dart';
import 'current_gate_travel.dart';
import 'card_diagnostics.dart';
import 'card_brand_identity.dart';

class CardScanResult {
  const CardScanResult({
    required this.scannedAt,
    required this.blocks,
    this.currentGateTravel,
    this.comparisonToken,
    this.diagnosticReport,
    this.brandIdentity,
  });

  final DateTime scannedAt;
  final List<RawHistoryBlock> blocks;
  final CurrentGateTravel? currentGateTravel;

  /// Best-effort display hint for normal/comparison scans, not a card ID.
  /// Absent on unknown/iOS scans; never used for deduplication.
  final CardBrandIdentity? brandIdentity;

  /// Session-keyed token, never an IDm or a persistable card identifier.
  /// Absent from normal scans. Must not be serialized, logged or reported.
  final String? comparisonToken;

  /// Only populated by a developer or explicit metadata-only support scan.
  final CardDiagnosticReport? diagnosticReport;
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
