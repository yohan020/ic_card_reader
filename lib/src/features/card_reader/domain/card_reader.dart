import 'card_scan_result.dart';

abstract interface class CardReader {
  Future<bool> isAvailable();

  Future<CardScanResult> scan({Duration timeout = const Duration(seconds: 30)});

  Future<void> cancel();
}
