import 'card_scan_result.dart';

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
