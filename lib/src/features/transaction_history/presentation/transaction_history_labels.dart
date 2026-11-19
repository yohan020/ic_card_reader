import '../../station_resolver/domain/station_resolution.dart';

import '../../../core/localization/app_strings.dart';
import '../domain/parsed_transit_history.dart';
import '../domain/transit_transaction_type.dart';
import '../../station_resolver/domain/station_name_display.dart';

final _korean = AppLocalizationsKo();

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

String transactionTypeLabel(
  ParsedTransitHistory history, [
  AppLocalizations? l10n,
]) {
  l10n ??= _korean;
  if (isBusOrTramModeUnknown(history)) return l10n.busOrTram;
  return switch (history.transactionType) {
    TransitTransactionType.rail => l10n.railRide,
    TransitTransactionType.bus => l10n.busRide,
    TransitTransactionType.purchase => l10n.purchase,
    TransitTransactionType.charge => l10n.topUp,
    TransitTransactionType.gateWindowProcessing => l10n.gateWindow,
    TransitTransactionType.refund => l10n.refund,
    TransitTransactionType.adjustment => l10n.adjustment,
    TransitTransactionType.unknown => l10n.unknownType,
  };
}

String chargeMethodLabel(
  ParsedTransitHistory history, [
  AppLocalizations? l10n,
]) {
  l10n ??= _korean;
  if (isTicketMachineCharge(history)) return l10n.ticketMachine;
  if (isStationGateCharge(history)) return l10n.stationGateTerminal;
  if (isStationTerminalCharge(history)) return l10n.stationTerminal;
  if (isMobileCharge(history)) return l10n.mobile;
  if (isMobileBenefitCharge(history)) return l10n.mobileBenefit;
  if (isStoreTerminalCharge(history)) return l10n.storeTerminal;
  return l10n.unknown;
}

String chargeSummary(
  ParsedTransitHistory history, {
  AppLocalizations? l10n,
  StationResolution? transactionLocation,
  StationNameDisplayMode stationNameDisplayMode =
      StationNameDisplayMode.japanese,
}) {
  l10n ??= _korean;
  if (isTicketMachineCharge(history)) {
    final stationName = _displayLocationStation(
      transactionLocation,
      stationNameDisplayMode,
    );
    return stationName == null
        ? l10n.ticketMachineTopUp
        : l10n.ticketMachineTopUpAt(stationName);
  }
  if (isStationGateCharge(history)) {
    final stationName = _displayLocationStation(
      transactionLocation,
      stationNameDisplayMode,
    );
    return stationName == null
        ? l10n.gateTerminalTopUp
        : l10n.topUpAt(stationName);
  }
  if (isStationTerminalCharge(history)) return l10n.stationTerminalTopUp;
  if (isMobileBenefitCharge(history)) return l10n.mobileBenefitTopUp;
  if (isMobileCharge(history)) return l10n.mobileTopUp;
  if (isStoreTerminalCharge(history)) return l10n.storeTopUp;
  return l10n.cardTopUp;
}

String chargeLocationDetail(
  ParsedTransitHistory history, {
  AppLocalizations? l10n,
  StationResolution? transactionLocation,
  StationNameDisplayMode stationNameDisplayMode =
      StationNameDisplayMode.japanese,
}) {
  l10n ??= _korean;
  if (!isTicketMachineCharge(history) &&
      !isStationGateCharge(history) &&
      !isGateWindowProcessing(history)) {
    return l10n.unknown;
  }
  final station = transactionLocation?.station;
  if (station != null) {
    return '${displayStationName(japanese: station.stationName, korean: station.stationNameKorean, english: station.stationNameEnglish, mode: stationNameDisplayMode)} · ${station.lineName}';
  }
  return l10n.stationUnavailable;
}

String busOperatorLabel(
  ParsedTransitHistory history, [
  AppLocalizations? l10n,
]) => history.busOperatorName ?? (l10n ?? _korean).unknownBusOperator;

String purchaseSummary(
  ParsedTransitHistory history, [
  AppLocalizations? l10n,
]) => isCashCombinedPurchase(history)
    ? (l10n ?? _korean).purchaseWithCash
    : (l10n ?? _korean).purchase;

String gateWindowSummary(
  ParsedTransitHistory history, {
  AppLocalizations? l10n,
  StationResolution? transactionLocation,
  StationNameDisplayMode stationNameDisplayMode =
      StationNameDisplayMode.japanese,
}) {
  l10n ??= _korean;
  final stationName = _displayLocationStation(
    transactionLocation,
    stationNameDisplayMode,
  );
  return stationName == null ? l10n.gateWindow : l10n.gateWindowAt(stationName);
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
    english: station.stationNameEnglish,
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
