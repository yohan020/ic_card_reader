import 'card_scan_result.dart';
import 'card_diagnostics.dart';

enum CardReaderAvailability { enabled, disabled, unsupported, unknown }

abstract interface class CardReader {
  Future<bool> isAvailable();

  /// Adapter state only: enabled does not prove NFC-F/FeliCa support.
  Future<CardReaderAvailability> checkAvailability();

  /// Opens system settings without changing the user's NFC setting.
  Future<bool> openNfcSettings();

  Future<CardScanResult> scan({Duration timeout = const Duration(seconds: 30)});

  Future<void> cancel();
}

/// Optional capability: identity is scoped to one in-memory comparison only.
abstract interface class ComparisonCardReader {
  Future<CardScanResult> scanForComparison({required List<int> sessionKey});
}

/// Opt-in debug capability; independent of normal balance/history support.
abstract interface class DiagnosticCardReader {
  Future<CardDiagnosticReport> scanDiagnostics();
}

/// Explicit user-initiated support scan, including release builds. Metadata
/// only; does not read history, write, log or transmit anything.
abstract interface class SupportCardReader {
  Future<CardDiagnosticReport> scanSupportDiagnostics();
}
