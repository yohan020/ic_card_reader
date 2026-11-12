import 'dart:typed_data';

import 'package:ic_card_reader/src/features/card_reader/domain/raw_history_block.dart';

// Synthetic records from the documented layout, never user-card dumps.
RawHistoryBlock icaFixture({
  int index = 0,
  int balance = 1234,
  int delta = -230,
  int kind = 0,
  int year = 2026,
  int month = 10,
  int day = 24,
}) {
  final bytes = Uint8List(16);
  bytes[0] = ((year - 2000) << 1) | (month >> 3);
  bytes[1] = ((month & 7) << 5) | day;
  bytes[10] = kind;
  final packed = (delta ~/ 10) & 0xFFF;
  bytes[11] = 0xA0 | (packed >> 8);
  bytes[12] = packed & 0xFF;
  bytes[13] = balance >> 8;
  bytes[14] = balance & 0xFF;
  return RawHistoryBlock(
    index: index,
    bytes: bytes,
    format: HistoryRecordFormat.ica,
  );
}
