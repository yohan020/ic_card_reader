import 'dart:convert';
import 'dart:typed_data';

import '../../../core/localization/app_strings.dart';
import '../../station_resolver/domain/station_name_display.dart';
import '../../station_resolver/domain/station_resolution.dart';
import '../domain/amount_calculation.dart';
import '../domain/parsed_transit_history.dart';
import '../domain/transit_transaction_type.dart';
import 'transaction_history_labels.dart';

/// A display-only export: no raw blocks, card identifiers, or station database
/// dump. Amounts come from the full scan; filtering never recalculates them.
Uint8List createHistoryCsv({
  required List<ParsedTransitHistory> histories,
  required Map<int, ResolvedStationPair> stationPairs,
  required Map<int, StationResolution> transactionLocations,
  required StationNameDisplayMode stationNameDisplayMode,
  required AppLocalizations l10n,
}) {
  final rows = <String>[
    [
      l10n.csvDate,
      l10n.csvType,
      l10n.csvBoarding,
      l10n.csvAlighting,
      l10n.csvDescription,
      l10n.csvAmount,
      l10n.csvAmountStatus,
      l10n.csvBalance,
    ].map(csvTextCell).join(','),
  ];
  for (final history in histories) {
    final stations = stationPairs[history.rawBlock.index];
    final rail = history.transactionType == TransitTransactionType.rail;
    String station(StationResolution? resolution) {
      final record = resolution?.station;
      return record == null
          ? l10n.stationUnavailable
          : displayStationName(
              japanese: record.stationName,
              korean: record.stationNameKorean,
              english: record.stationNameEnglish,
              mode: stationNameDisplayMode,
            );
    }

    final description = switch (history.transactionType) {
      TransitTransactionType.rail => '',
      TransitTransactionType.bus => busOperatorLabel(history, l10n),
      TransitTransactionType.purchase => purchaseSummary(history, l10n),
      TransitTransactionType.charge => chargeSummary(
        history,
        l10n: l10n,
        transactionLocation: transactionLocations[history.rawBlock.index],
        stationNameDisplayMode: stationNameDisplayMode,
      ),
      TransitTransactionType.gateWindowProcessing => gateWindowSummary(
        history,
        l10n: l10n,
        transactionLocation: transactionLocations[history.rawBlock.index],
        stationNameDisplayMode: stationNameDisplayMode,
      ),
      TransitTransactionType.refund => l10n.refund,
      TransitTransactionType.adjustment => l10n.adjustment,
      TransitTransactionType.unknown => l10n.unknownTransactionSummary,
    };
    final calculation = history.amountCalculation;
    final value = calculation.amount;
    final known = calculation.isResolved && value != null && value >= 0;
    final amount = !known
        ? ''
        : calculation.status == AmountCalculationStatus.balanceIncrease
        ? '$value'
        : '${-value}';
    final status = known
        ? l10n.csvCalculated
        : calculation.status == AmountCalculationStatus.suspicious
        ? l10n.checkAmount
        : l10n.unavailableAmount;
    final date = history.usageDate;
    rows.add(
      [
        csvTextCell(
          date == null
              ? ''
              : '${date.year.toString().padLeft(4, '0')}-${_two(date.month)}-${_two(date.day)}',
        ),
        csvTextCell(transactionTypeLabel(history, l10n)),
        csvTextCell(rail ? station(stations?.boarding) : ''),
        csvTextCell(rail ? station(stations?.alighting) : ''),
        csvTextCell(description),
        amount,
        csvTextCell(status),
        '${history.balance}',
      ].join(','),
    );
  }
  // BOM for Excel's UTF-8 detection, RFC-style quoting and CRLF row endings.
  return Uint8List.fromList(utf8.encode('\uFEFF${rows.join('\r\n')}\r\n'));
}

String _two(int value) => value.toString().padLeft(2, '0');

/// Quoting handles separators/newlines; a text-only prefix also mitigates
/// spreadsheet formula execution. Typed numeric cells bypass this function.
String csvTextCell(String text) {
  var value = text.replaceAll('\u0000', '');
  if (RegExp(r'^[\s\x00-\x1f]*[=+\-@＝＋－＠]').hasMatch(value) ||
      RegExp(r'^[\x01-\x1f]').hasMatch(value)) {
    value = '\t$value';
  }
  return '"${value.replaceAll('"', '""')}"';
}
