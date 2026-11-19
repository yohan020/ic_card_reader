import 'dart:typed_data';

/// ICa profile facts: webarata3/ica_reader, commit df8993b0 (MIT).
/// See assets/licenses/ica-reader-MIT.txt. Never log polling replies or IDm.
abstract final class IcaProtocol {
  static const historyService = 0x898F;

  static bool isSystemCode(List<int> bytes) =>
      bytes.length == 2 && bytes[0] == 0x80 && bytes[1] == 0xEF;

  static Uint8List pollingCommand() =>
      Uint8List.fromList([6, 0, 0x80, 0xEF, 1, 0]);

  static Uint8List? parsePollingIdm(List<int> response) {
    if (response.length != 20 ||
        response[0] != 20 ||
        response[1] != 1 ||
        response[18] != 0x80 ||
        response[19] != 0xEF) {
      return null;
    }
    return Uint8List.fromList(response.sublist(2, 10));
  }
}
