import 'dart:typed_data';

const int felicaHistoryBlockLength = 16;
const int felicaHistoryBlockLimit = 20;

final class FelicaProtocol {
  const FelicaProtocol._();

  static Uint8List buildReadWithoutEncryptionCommand({
    required Uint8List idm,
    required int blockIndex,
  }) {
    if (idm.length != 8) {
      throw ArgumentError.value(idm.length, 'idm.length', 'must be 8');
    }
    if (blockIndex < 0 || blockIndex >= felicaHistoryBlockLimit) {
      throw RangeError.range(blockIndex, 0, felicaHistoryBlockLimit - 1);
    }

    // Service code 0x090F is little-endian on the wire: 0F 09.
    final command = <int>[
      0,
      0x06,
      ...idm,
      0x01,
      0x0F,
      0x09,
      0x01,
      0x80,
      blockIndex,
    ];
    command[0] = command.length;
    return Uint8List.fromList(command);
  }

  static Uint8List? parseReadWithoutEncryptionResponse(
    Uint8List response, {
    required Uint8List expectedIdm,
  }) {
    const headerLength = 13;
    if (expectedIdm.length != 8 || response.length < headerLength) return null;
    if (response[0] != response.length || response[1] != 0x07) return null;
    for (var index = 0; index < 8; index++) {
      if (response[index + 2] != expectedIdm[index]) return null;
    }
    if (response[10] != 0 || response[11] != 0) return null;
    final blockCount = response[12];
    if (blockCount != 1 ||
        response.length != headerLength + felicaHistoryBlockLength) {
      return null;
    }
    return Uint8List.fromList(response.sublist(headerLength));
  }

  static bool isEmptyBlock(Uint8List block) =>
      block.length >= 2 && block[0] == 0 && block[1] == 0;
}
