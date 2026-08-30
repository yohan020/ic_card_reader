import 'dart:typed_data';

/// A currently open rail journey inferred from FeliCa gate services.
///
/// This is deliberately only emitted when the newest 108F record is an entry
/// event and its station agrees with 10CB. The service blocks themselves are
/// not retained, displayed, or sent anywhere.
class CurrentGateTravel {
  const CurrentGateTravel({
    required this.entryLineCode,
    required this.entryStationCode,
  });

  final int entryLineCode;
  final int entryStationCode;

  static CurrentGateTravel? fromFeliCaServiceBlocks({
    required Uint8List? latestGateHistoryBlock,
    required Uint8List? sfEntryBlock,
  }) {
    if (latestGateHistoryBlock == null ||
        sfEntryBlock == null ||
        latestGateHistoryBlock.length != 16 ||
        sfEntryBlock.length != 16) {
      return null;
    }

    // Verified with physical Tokyo Metro entry fixtures. Other operators are
    // intentionally shown only after their service bytes satisfy this same
    // conservative relationship.
    const entryEvent = 0xA0;
    if (latestGateHistoryBlock[0] != entryEvent) return null;

    final lineCode = latestGateHistoryBlock[2];
    final stationCode = latestGateHistoryBlock[3];
    if (lineCode == 0 && stationCode == 0) return null;
    if (sfEntryBlock[0] != lineCode || sfEntryBlock[1] != stationCode) {
      return null;
    }

    return CurrentGateTravel(
      entryLineCode: lineCode,
      entryStationCode: stationCode,
    );
  }
}
