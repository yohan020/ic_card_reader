import '../../station_resolver/domain/station_resolution.dart';
import '../domain/parsed_transit_history.dart';
import '../domain/transit_transaction_type.dart';
import '../../station_resolver/domain/station_name_display.dart';

bool isTicketMachineCharge(ParsedTransitHistory history) =>
    history.terminalCode == 0x08 && history.processCode == 0x02;

bool isStoreTerminalCharge(ParsedTransitHistory history) =>
    history.terminalCode == 0xC8 && history.processCode == 0x49;

bool isStationGateCharge(ParsedTransitHistory history) =>
    history.terminalCode == 0x1A && history.processCode == 0x02;

bool isStationTerminalCharge(ParsedTransitHistory history) =>
    history.terminalCode == 0x21 && history.processCode == 0x02;

bool isMobileCharge(ParsedTransitHistory history) =>
    history.terminalCode == 0x1B && history.processCode == 0x02;

bool isMobileBenefitCharge(ParsedTransitHistory history) =>
    history.terminalCode == 0x1B && history.processCode == 0x48;

bool isCashCombinedPurchase(ParsedTransitHistory history) =>
    history.terminalCode == 0xC8 && history.processCode == 0xC6;

bool isGateWindowProcessing(ParsedTransitHistory history) =>
    history.terminalCode == 0x1A && history.processCode == 0x06;

bool isBusOrTramModeUnknown(ParsedTransitHistory history) =>
    history.regionCode == 0x03 &&
    history.terminalCode == 0x05 &&
    history.processCode == 0x0D &&
    history.boardingLineCode == 0x0F &&
    history.boardingStationCode == 0x3D;

String transactionTypeLabel(ParsedTransitHistory history) {
  if (isBusOrTramModeUnknown(history)) return '버스·노면전차 이용';
  return switch (history.transactionType) {
    TransitTransactionType.rail => '철도 이용',
    TransitTransactionType.bus => '버스 이용',
    TransitTransactionType.purchase => '물품 구매',
    TransitTransactionType.charge => '충전',
    TransitTransactionType.gateWindowProcessing => '개찰 창구 처리',
    TransitTransactionType.refund => '환불',
    TransitTransactionType.adjustment => '정산',
    TransitTransactionType.unknown => '유형 미확인',
  };
}

String chargeMethodLabel(ParsedTransitHistory history) {
  if (isTicketMachineCharge(history)) return '자동발권기';
  if (isStationGateCharge(history)) return '역 개찰 단말';
  if (isStationTerminalCharge(history)) return '역 단말';
  if (isMobileCharge(history)) return '모바일';
  if (isMobileBenefitCharge(history)) return '모바일 특전';
  if (isStoreTerminalCharge(history)) return '매장 단말';
  return '확인할 수 없음';
}

String chargeSummary(
  ParsedTransitHistory history, {
  StationResolution? transactionLocation,
  StationNameDisplayMode stationNameDisplayMode =
      StationNameDisplayMode.japanese,
}) {
  if (isTicketMachineCharge(history)) {
    final stationName = _displayLocationStation(
      transactionLocation,
      stationNameDisplayMode,
    );
    return stationName == null ? '자동발권기에서 충전' : '자동발권기에서 충전 · $stationName';
  }
  if (isStationGateCharge(history)) {
    final stationName = _displayLocationStation(
      transactionLocation,
      stationNameDisplayMode,
    );
    return stationName == null ? '역 개찰 단말에서 충전' : '충전 · $stationName';
  }
  if (isStationTerminalCharge(history)) return '역 단말에서 충전';
  if (isMobileBenefitCharge(history)) return '모바일 특전 충전';
  if (isMobileCharge(history)) return '모바일에서 충전';
  if (isStoreTerminalCharge(history)) return '매장에서 충전';
  return '카드 충전';
}

String chargeLocationDetail(
  ParsedTransitHistory history, {
  StationResolution? transactionLocation,
  StationNameDisplayMode stationNameDisplayMode =
      StationNameDisplayMode.japanese,
}) {
  if (!isTicketMachineCharge(history) &&
      !isStationGateCharge(history) &&
      !isGateWindowProcessing(history)) {
    return '확인할 수 없음';
  }
  final station = transactionLocation?.station;
  if (station != null) {
    return '${displayStationName(japanese: station.stationName, korean: station.stationNameKorean, mode: stationNameDisplayMode)} · ${station.lineName}';
  }
  final code = transactionLocationCode(history);
  return code == null ? '확인할 수 없음' : '미등록 · $code';
}

String busOperatorLabel(ParsedTransitHistory history) =>
    history.busOperatorName ?? '미확인 · 회사 고유 코드 미해석';

String purchaseSummary(ParsedTransitHistory history) =>
    isCashCombinedPurchase(history) ? '물품 구매 · 현금 병용' : '물품 구매';

String gateWindowSummary(
  ParsedTransitHistory history, {
  StationResolution? transactionLocation,
  StationNameDisplayMode stationNameDisplayMode =
      StationNameDisplayMode.japanese,
}) {
  final stationName = _displayLocationStation(
    transactionLocation,
    stationNameDisplayMode,
  );
  return stationName == null ? '개찰 창구 처리' : '개찰 창구 처리 · $stationName';
}

String? _displayLocationStation(
  StationResolution? resolution,
  StationNameDisplayMode mode,
) {
  final station = resolution?.station;
  if (station == null) return null;
  return displayStationName(
    japanese: station.stationName,
    korean: station.stationNameKorean,
    mode: mode,
  );
}

String? transactionLocationCode(ParsedTransitHistory history) {
  if (!history.hasTransactionLocationCode) return null;
  return '${_hexByte(history.transactionLocationRegionCode!)}-'
      '${_hexByte(history.transactionLocationLineCode!)}-'
      '${_hexByte(history.transactionLocationStationCode!)}';
}

String _hexByte(int value) =>
    value.toRadixString(16).padLeft(2, '0').toUpperCase();
