import 'dart:typed_data';

import 'felica_protocol.dart';

class RawHistoryBlock {
  RawHistoryBlock({required this.index, required Uint8List bytes})
    : bytes = Uint8List.fromList(bytes) {
    if (bytes.length != felicaHistoryBlockLength) {
      throw ArgumentError.value(bytes.length, 'bytes.length', 'must be 16');
    }
  }

  final int index;
  final Uint8List bytes;

  String get hexadecimal => bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join();
}
