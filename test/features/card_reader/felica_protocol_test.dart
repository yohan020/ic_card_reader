import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/felica_protocol.dart';

void main() {
  final idm = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);

  test('builds a service 090F read command for one block', () {
    final command = FelicaProtocol.buildReadWithoutEncryptionCommand(
      idm: idm,
      blockIndex: 3,
    );

    expect(
      command,
      Uint8List.fromList([
        16,
        0x06,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        1,
        0x0F,
        0x09,
        1,
        0x80,
        3,
      ]),
    );
  });

  test('accepts a valid read response and extracts exactly 16 bytes', () {
    final block = List<int>.generate(16, (index) => index + 16);
    final response = Uint8List.fromList([29, 0x07, ...idm, 0, 0, 1, ...block]);

    expect(
      FelicaProtocol.parseReadWithoutEncryptionResponse(
        response,
        expectedIdm: idm,
      ),
      Uint8List.fromList(block),
    );
  });

  test('rejects status errors, IDm mismatch, and malformed lengths', () {
    Uint8List response({int status1 = 0, int firstIdmByte = 1}) {
      return Uint8List.fromList([
        29,
        0x07,
        firstIdmByte,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        status1,
        0,
        1,
        ...List<int>.filled(16, 1),
      ]);
    }

    expect(
      FelicaProtocol.parseReadWithoutEncryptionResponse(
        response(status1: 1),
        expectedIdm: idm,
      ),
      isNull,
    );
    expect(
      FelicaProtocol.parseReadWithoutEncryptionResponse(
        response(firstIdmByte: 9),
        expectedIdm: idm,
      ),
      isNull,
    );
    expect(
      FelicaProtocol.parseReadWithoutEncryptionResponse(
        Uint8List.fromList([12, 0x07, ...List<int>.filled(10, 0)]),
        expectedIdm: idm,
      ),
      isNull,
    );
  });

  test('treats a 00 00 terminal and process pair as an empty block', () {
    expect(
      FelicaProtocol.isEmptyBlock(
        Uint8List.fromList(const [
          0x00,
          0x00,
          0xFF,
          0xFF,
          0x34,
          0xE3,
          0x01,
          0x02,
          0x03,
          0x04,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00,
          0x00,
        ]),
      ),
      isTrue,
    );
  });
}
