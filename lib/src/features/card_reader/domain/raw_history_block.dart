import 'dart:typed_data';

import 'felica_protocol.dart';

enum HistoryRecordFormat { transit, ica }

class RawHistoryBlock {
  RawHistoryBlock({
    required this.index,
    required Uint8List bytes,
    this.format = HistoryRecordFormat.transit,
  }) : bytes = Uint8List.fromList(bytes) {
    if (bytes.length != felicaHistoryBlockLength) {
      throw ArgumentError.value(bytes.length, 'bytes.length', 'must be 16');
    }
  }

  final int index;
  final Uint8List bytes;
  final HistoryRecordFormat format;

  String get hexadecimal => bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join();
}
