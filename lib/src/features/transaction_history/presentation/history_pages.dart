import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../card_reader/presentation/card_brand_name.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../core/widgets/main_page_header.dart';
import '../../card_reader/domain/raw_history_block.dart';
import '../../card_reader/domain/card_brand_identity.dart';
import '../../card_reader/presentation/widgets/card_brand_icon.dart';
import '../../issue_report/presentation/issue_report_page.dart';
import '../../issue_report/domain/issue_report_repository.dart';
import '../../station_resolver/domain/station_resolution.dart';
import '../../station_resolver/domain/station_name_display.dart';
import '../domain/amount_calculation.dart';
import '../domain/history_total.dart';
import '../domain/parsed_transit_history.dart';
import '../domain/transit_transaction_type.dart';
import 'transaction_history_labels.dart';
import 'widgets/history_station_map.dart';

class HistoryListPage extends StatefulWidget {
  const HistoryListPage({
    required this.histories,
    required this.currentBalance,
    required this.stationPairs,
    required this.onScan,
    super.key,
    this.issueReportRepository,
    this.transactionLocations = const {},
    this.stationNameDisplayMode = StationNameDisplayMode.japanese,
    this.brandIdentity,
  });

  final List<ParsedTransitHistory> histories;
  final int? currentBalance;
  final CardBrandIdentity? brandIdentity;
  final Map<int, ResolvedStationPair> stationPairs;
  final VoidCallback onScan;
  final IssueReportRepository? issueReportRepository;
  final Map<int, StationResolution> transactionLocations;
  final StationNameDisplayMode stationNameDisplayMode;

  @override
  State<HistoryListPage> createState() => _HistoryListPageState();
}

class _HistoryListPageState extends State<HistoryListPage> {
  _HistoryFilter _filter = _HistoryFilter.all;
  bool _totalExpanded = false;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.histories.where(_filter.matches).toList();
    final dateGroups = _groupByDate(filtered);
    return AppPage(
      padding: MainPageHeader.pagePadding,
      children: [
        MainPageHeader(title: strings(context).history, onScan: widget.onScan),
        _CurrentBalanceCard(
          balance: widget.currentBalance,
          brandIdentity: widget.brandIdentity,
          isInitializationBalance:
              widget.currentBalance != null && widget.histories.isEmpty,
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filter in _HistoryFilter.values) ...[
                FilterChip(
                  label: Text(filter.label(strings(context))),
                  selected: _filter == filter,
                  onSelected: (_) => setState(() {
                    _filter = filter;
                    _totalExpanded = false;
                  }),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (filtered.isNotEmpty) ...[
          _HistoryTotalCard(
            title: _filter.totalLabel(strings(context)),
            total: HistoryTotal.calculate(filtered, kind: _filter.totalKind),
            expanded: _totalExpanded,
            onToggle: () => setState(() => _totalExpanded = !_totalExpanded),
          ),
          const SizedBox(height: 14),
        ],
        if (widget.histories.isEmpty)
          _EmptyHistory(hasCardData: widget.currentBalance != null)
        else if (filtered.isEmpty)
          AppSurface(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: Text(strings(context).noMatchingHistory)),
            ),
          )
        else
          for (final group in dateGroups)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                  child: Semantics(
                    header: true,
                    child: Text(
                      group.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                AppSurface(
                  key: ValueKey(
                    'history-date-group-${group.records.first.rawBlock.index}',
                  ),
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Column(
                      children: [
                        for (final (index, history)
                            in group.records.indexed) ...[
                          if (index > 0)
                            const Divider(height: 1, indent: 14, endIndent: 14),
                          _HistoryTile(
                            key: ValueKey(
                              'history-row-${history.rawBlock.index}',
                            ),
                            history: history,
                            stations:
                                widget.stationPairs[history.rawBlock.index],
                            transactionLocation: widget
                                .transactionLocations[history.rawBlock.index],
                            stationNameDisplayMode:
                                widget.stationNameDisplayMode,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => HistoryDetailPage(
                                  history: history,
                                  stations: widget
                                      .stationPairs[history.rawBlock.index],
                                  transactionLocation:
                                      widget.transactionLocations[history
                                          .rawBlock
                                          .index],
                                  stationNameDisplayMode:
                                      widget.stationNameDisplayMode,
                                  issueReportRepository:
                                      widget.issueReportRepository,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
      ],
    );
  }
}

class _HistoryDateGroup {
  _HistoryDateGroup(this.label, ParsedTransitHistory first) : records = [first];

  final String label;
  final List<ParsedTransitHistory> records;
}

/// Group adjacent calendar dates without sorting or changing card record order.
/// Unknown dates retain their existing label, never borrowing a nearby date.
List<_HistoryDateGroup> _groupByDate(List<ParsedTransitHistory> histories) {
  final groups = <_HistoryDateGroup>[];
  for (final history in histories) {
    final label = formatDate(history.usageDate);
    if (groups.isEmpty || groups.last.label != label) {
      groups.add(_HistoryDateGroup(label, history));
    } else {
      groups.last.records.add(history);
    }
  }
  return groups;
}

class _HistoryTotalCard extends StatelessWidget {
  const _HistoryTotalCard({
    required this.title,
    required this.total,
    required this.expanded,
    required this.onToggle,
  });

  final String title;
  final HistoryTotal total;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final unidentified = total.kind == HistoryTotalKind.unidentified;
    final isCharge = total.kind == HistoryTotalKind.charge;
    final explanation = unidentified
        ? strings(context).unknownTotalExplanation
        : isCharge
        ? strings(context).topUpTotalExplanation
        : strings(context).spendingTotalExplanation;
    return AppSurface(
      key: const ValueKey('history-filter-total'),
      padding: EdgeInsets.zero,
      child: Semantics(
        button: true,
        expanded: expanded,
        child: InkWell(
          key: const ValueKey('history-filter-total-toggle'),
          onTap: onToggle,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _HistoryTotalTransition(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        unidentified
                            ? Icons.help_outline_rounded
                            : Icons.calculate_outlined,
                        size: 18,
                        color: AppColors.accent(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (unidentified)
                        Expanded(
                          child: Text(
                            strings(
                              context,
                            ).unknownRecordCount(total.recordCount),
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else if (total.amount != null)
                        Expanded(
                          child: Text(
                            yen(total.amount!),
                            key: const ValueKey('history-filter-total-amount'),
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        key: const ValueKey('history-filter-total-chevron'),
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  if (!unidentified && total.amount == null) ...[
                    const SizedBox(height: 7),
                    Text(
                      isCharge
                          ? strings(context).noTopUpTotal
                          : strings(context).noSpendingTotal,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (expanded) ...[
                    const Divider(height: 24),
                    if (!unidentified)
                      Text(
                        strings(
                          context,
                        ).totalCount(total.includedCount, total.excludedCount),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      strings(context).recentTotalHint(explanation),
                      key: const ValueKey('history-filter-total-details'),
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryTotalTransition extends StatelessWidget {
  const _HistoryTotalTransition({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery.disableAnimationsOf(context)
      ? child
      : AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          curve: Curves.easeInOut,
          child: child,
        );
}

class _CurrentBalanceCard extends StatelessWidget {
  const _CurrentBalanceCard({
    required this.balance,
    required this.isInitializationBalance,
    this.brandIdentity,
  });

  final int? balance;
  final bool isInitializationBalance;
  final CardBrandIdentity? brandIdentity;

  @override
  Widget build(BuildContext context) => AppSurface(
    key: const ValueKey('history-current-balance'),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    child: Column(
      children: [
        CardBrandIcon(identity: brandIdentity, prominent: true),
        const SizedBox(height: 10),
        Text(
          brandIdentity?.label == null
              ? strings(context).currentBalance
              : strings(context).currentBrandBalance(
                  cardBrandName(brandIdentity!, strings(context)),
                ),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          balance == null ? '—' : yen(balance!),
          key: const ValueKey('history-current-balance-amount'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w600,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          balance == null
              ? strings(context).balanceAfterScan
              : isInitializationBalance
              ? strings(context).initialBalanceBasis
              : strings(context).latestBalanceBasis,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.hasCardData});

  final bool hasCardData;

  @override
  Widget build(BuildContext context) => AppSurface(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 34),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 46,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 14),
          Text(
            hasCardData
                ? strings(context).noDisplayableHistory
                : strings(context).noHistoryYet,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            hasCardData
                ? strings(context).initialBalanceOnly
                : strings(context).scanFromHome,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.history,
    required this.onTap,
    super.key,
    this.stations,
    this.transactionLocation,
    this.stationNameDisplayMode = StationNameDisplayMode.japanese,
  });

  final ParsedTransitHistory history;
  final ResolvedStationPair? stations;
  final StationResolution? transactionLocation;
  final StationNameDisplayMode stationNameDisplayMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final amount = _amountText(history.amountCalculation, strings(context));
    final typeColors = _typeColors(
      history.transactionType,
      Theme.of(context).brightness,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              key: ValueKey('history-type-icon-${history.rawBlock.index}'),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: typeColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _typeIcon(history.transactionType),
                color: typeColors.foreground,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final stacked =
                      constraints.maxWidth < 200 ||
                      MediaQuery.textScalerOf(context).scale(15) > 20;
                  final title = Text(
                    transactionTypeLabel(history, strings(context)),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  );
                  final amountLabel = Text(
                    amount,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color:
                          history.amountCalculation.status ==
                              AmountCalculationStatus.unavailable
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : history.transactionType ==
                                TransitTransactionType.charge
                          ? AppColors.success
                          : null,
                      fontWeight:
                          history.amountCalculation.status ==
                              AmountCalculationStatus.unavailable
                          ? FontWeight.w500
                          : FontWeight.w700,
                      fontSize:
                          history.amountCalculation.status ==
                              AmountCalculationStatus.unavailable
                          ? 14
                          : 16,
                    ),
                  );
                  final route = Text(
                    _routeSummary(
                      strings(context),
                      history,
                      stations,
                      transactionLocation,
                      stationNameDisplayMode,
                    ),
                    maxLines: stacked ? null : 1,
                    overflow: stacked ? null : TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  );
                  final balance = Text(
                    strings(context).balanceValue(yen(history.balance)),
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (stacked) ...[
                        title,
                        Align(
                          alignment: Alignment.centerRight,
                          child: amountLabel,
                        ),
                      ] else
                        Row(
                          children: [
                            Expanded(child: title),
                            const SizedBox(width: 8),
                            amountLabel,
                          ],
                        ),
                      const SizedBox(height: 2),
                      if (stacked) route,
                      if (stacked) const SizedBox(height: 3),
                      Row(
                        children: [
                          if (!stacked) ...[
                            Expanded(child: route),
                            const SizedBox(width: 8),
                          ],
                          Expanded(child: balance),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded, size: 18),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryDetailPage extends StatelessWidget {
  const HistoryDetailPage({
    required this.history,
    super.key,
    this.stations,
    this.transactionLocation,
    this.issueReportRepository,
    this.stationNameDisplayMode = StationNameDisplayMode.japanese,
  });

  final ParsedTransitHistory history;
  final ResolvedStationPair? stations;
  final StationResolution? transactionLocation;
  final IssueReportRepository? issueReportRepository;
  final StationNameDisplayMode stationNameDisplayMode;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(strings(context).historyDetail)),
    body: SafeArea(
      top: false,
      child: AppPage(
        children: [
          Row(
            children: [
              StatusPill(
                label: transactionTypeLabel(history, strings(context)),
                icon: _typeIcon(history.transactionType),
              ),
              const Spacer(),
              Text(
                formatDate(history.usageDate),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppSurface(
            child: Column(
              children: [
                if (history.transactionType == TransitTransactionType.rail) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _RoutePoint(
                        label: strings(context).boarding,
                        code: _boardingCode(history),
                        resolution: stations?.boarding,
                        routeOperatorName: stations?.routeOperatorName,
                        routeLineName: stations?.routeLineName,
                        stationNameDisplayMode: stationNameDisplayMode,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      _RoutePoint(
                        label: strings(context).alighting,
                        code: _alightingCode(history),
                        resolution: stations?.alighting,
                        routeOperatorName: stations?.routeOperatorName,
                        routeLineName: stations?.routeLineName,
                        stationNameDisplayMode: stationNameDisplayMode,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                ],
                Text(
                  _amountText(history.amountCalculation, strings(context)),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color:
                        history.amountCalculation.status ==
                            AmountCalculationStatus.unavailable
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : history.transactionType ==
                              TransitTransactionType.charge
                        ? AppColors.success
                        : null,
                    fontSize:
                        history.amountCalculation.status ==
                            AmountCalculationStatus.unavailable
                        ? 18
                        : null,
                    fontWeight:
                        history.amountCalculation.status ==
                            AmountCalculationStatus.unavailable
                        ? FontWeight.w500
                        : FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings(context).balanceAfterValue(yen(history.balance)),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (history.amountCalculation.status ==
              AmountCalculationStatus.unavailable) ...[
            const SizedBox(height: 14),
            NoticeBanner(
              title: strings(context).cantCalculateAmount,
              text: history.rawBlock.format == HistoryRecordFormat.ica
                  ? strings(context).icaZeroAmount
                  : _amountUnavailableExplanation(
                      history.amountCalculation,
                      strings(context),
                    ),
            ),
          ],
          if (history.transactionType == TransitTransactionType.rail &&
              !_bothStationsResolved(stations)) ...[
            const SizedBox(height: 14),
            NoticeBanner(
              title: _hasMultipleCandidates(stations)
                  ? strings(context).multipleStationCandidates
                  : strings(context).stationInfoNeedsReview,
              text: _hasMultipleCandidates(stations)
                  ? strings(context).multipleStationHint
                  : strings(context).stationInfoNeedsReviewHint,
              tone: NoticeTone.warning,
            ),
          ],
          const SizedBox(height: 24),
          SectionLabel(strings(context).details),
          AppSurface(
            child: Column(
              children: [
                DetailLine(
                  label: strings(context).transactionType,
                  value: transactionTypeLabel(history, strings(context)),
                ),
                if (history.transactionType == TransitTransactionType.rail) ...[
                  const Divider(),
                  DetailLine(
                    label: strings(context).boardingStation,
                    value: _stationDetail(
                      strings(context),
                      stations?.boarding,
                      _boardingCode(history),
                      routeLineName: stations?.routeLineName,
                      stationNameDisplayMode: stationNameDisplayMode,
                    ),
                  ),
                  const Divider(),
                  DetailLine(
                    label: strings(context).alightingStation,
                    value: _stationDetail(
                      strings(context),
                      stations?.alighting,
                      _alightingCode(history),
                      routeLineName: stations?.routeLineName,
                      stationNameDisplayMode: stationNameDisplayMode,
                    ),
                  ),
                ],
                if (history.transactionType == TransitTransactionType.bus) ...[
                  const Divider(),
                  DetailLine(
                    label: strings(context).busOperator,
                    value: busOperatorLabel(history, strings(context)),
                  ),
                ],
                if (history.transactionType ==
                    TransitTransactionType.purchase) ...[
                  if (isCashCombinedPurchase(history)) ...[
                    const Divider(),
                    DetailLine(
                      label: strings(context).paymentMethod,
                      value: strings(context).combinedCash,
                    ),
                  ],
                  if (history.transactionDateTime != null) ...[
                    const Divider(),
                    DetailLine(
                      label: strings(context).transactionTime,
                      value: _formatTime(history.transactionDateTime!),
                    ),
                  ],
                ],
                if (history.transactionType ==
                    TransitTransactionType.charge) ...[
                  const Divider(),
                  DetailLine(
                    label: strings(context).topUpMethod,
                    value: chargeMethodLabel(history, strings(context)),
                  ),
                  const Divider(),
                  DetailLine(
                    label: strings(context).topUpLocation,
                    value: chargeLocationDetail(
                      l10n: strings(context),
                      history,
                      transactionLocation: transactionLocation,
                      stationNameDisplayMode: stationNameDisplayMode,
                    ),
                  ),
                ],
                if (history.transactionType ==
                    TransitTransactionType.gateWindowProcessing) ...[
                  const Divider(),
                  DetailLine(
                    label: strings(context).processingLocation,
                    value: chargeLocationDetail(
                      l10n: strings(context),
                      history,
                      transactionLocation: transactionLocation,
                      stationNameDisplayMode: stationNameDisplayMode,
                    ),
                  ),
                  const Divider(),
                  DetailLine(
                    label: strings(context).processingDetail,
                    value: strings(context).unknown,
                  ),
                ],
                const Divider(),
                DetailLine(
                  label: strings(context).balance,
                  value: yen(history.balance),
                ),
              ],
            ),
          ),
          if (history.transactionType == TransitTransactionType.rail) ...[
            const SizedBox(height: 24),
            HistoryStationMap(
              stations: stations,
              displayMode: stationNameDisplayMode,
            ),
          ],
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => IssueReportPage(
                  history: history,
                  stations: stations,
                  transactionLocation: transactionLocation,
                  repository: issueReportRepository,
                ),
              ),
            ),
            icon: const Icon(Icons.flag_outlined),
            label: Text(strings(context).reportTransaction),
          ),
        ],
      ),
    ),
  );
}

class _RoutePoint extends StatelessWidget {
  const _RoutePoint({
    required this.label,
    required this.code,
    this.resolution,
    this.routeOperatorName,
    this.routeLineName,
    required this.stationNameDisplayMode,
  });

  final String label;
  final String code;
  final StationResolution? resolution;
  final String? routeOperatorName;
  final String? routeLineName;
  final StationNameDisplayMode stationNameDisplayMode;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          resolution?.station == null
              ? strings(context).stationNotRegistered
              : displayStationName(
                  japanese: resolution!.station!.stationName,
                  korean: resolution!.station!.stationNameKorean,
                  english: resolution!.station!.stationNameEnglish,
                  mode: stationNameDisplayMode,
                ),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        if (resolution?.station case final station?) ...[
          const SizedBox(height: 2),
          Text(
            routeLineName == null
                ? (station.operatorName.isEmpty
                      ? station.lineName
                      : '${station.operatorName} · ${station.lineName}')
                : '${routeOperatorName ?? station.operatorName} · $routeLineName',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          code,
          style: TextStyle(
            color: Theme.of(context).colorScheme.outline,
            fontFamily: 'monospace',
            fontSize: 11,
          ),
        ),
      ],
    ),
  );
}

enum _HistoryFilter { all, transport, purchase, charge, unknown }

extension on _HistoryFilter {
  HistoryTotalKind get totalKind => switch (this) {
    _HistoryFilter.charge => HistoryTotalKind.charge,
    _HistoryFilter.unknown => HistoryTotalKind.unidentified,
    _ => HistoryTotalKind.spending,
  };

  String totalLabel(AppLocalizations l10n) => switch (this) {
    _HistoryFilter.all => l10n.spendingTotal,
    _HistoryFilter.transport => l10n.spendingTotal,
    _HistoryFilter.purchase => l10n.spendingTotal,
    _HistoryFilter.charge => l10n.topUpTotal,
    _HistoryFilter.unknown => l10n.unknownRecords,
  };

  String label(AppLocalizations l10n) => switch (this) {
    _HistoryFilter.all => l10n.all,
    _HistoryFilter.transport => l10n.transport,
    _HistoryFilter.purchase => l10n.purchases,
    _HistoryFilter.charge => l10n.topUp,
    _HistoryFilter.unknown => l10n.unconfirmed,
  };

  bool matches(ParsedTransitHistory history) => switch (this) {
    _HistoryFilter.all => true,
    _HistoryFilter.transport =>
      history.transactionType == TransitTransactionType.rail ||
          history.transactionType == TransitTransactionType.bus ||
          history.transactionType ==
              TransitTransactionType.gateWindowProcessing,
    _HistoryFilter.purchase =>
      history.transactionType == TransitTransactionType.purchase,
    _HistoryFilter.charge =>
      history.transactionType == TransitTransactionType.charge,
    _HistoryFilter.unknown =>
      history.transactionType == TransitTransactionType.unknown,
  };
}

IconData _typeIcon(TransitTransactionType type) => switch (type) {
  TransitTransactionType.rail => Icons.train_rounded,
  TransitTransactionType.bus => Icons.directions_bus_rounded,
  TransitTransactionType.purchase => Icons.shopping_bag_outlined,
  TransitTransactionType.charge => Icons.add_card_rounded,
  TransitTransactionType.gateWindowProcessing => Icons.meeting_room_outlined,
  TransitTransactionType.refund => Icons.currency_yen_rounded,
  TransitTransactionType.adjustment => Icons.tune_rounded,
  TransitTransactionType.unknown => Icons.help_outline_rounded,
};

({Color background, Color foreground}) _typeColors(
  TransitTransactionType type,
  Brightness brightness,
) {
  final colors = switch (type) {
    TransitTransactionType.rail => (
      background: const Color(0xFFDDF7F4),
      foreground: const Color(0xFF07877F),
    ),
    TransitTransactionType.bus => (
      background: const Color(0xFFE1F1FD),
      foreground: const Color(0xFF2E8DD5),
    ),
    TransitTransactionType.purchase => (
      background: const Color(0xFFE3F5F2),
      foreground: const Color(0xFF318B83),
    ),
    TransitTransactionType.charge => (
      background: const Color(0xFFDDF7E8),
      foreground: const Color(0xFF219653),
    ),
    TransitTransactionType.gateWindowProcessing => (
      background: const Color(0xFFE8EEF9),
      foreground: const Color(0xFF4A67A1),
    ),
    TransitTransactionType.refund => (
      background: const Color(0xFFFCE8EC),
      foreground: const Color(0xFFD16B7B),
    ),
    TransitTransactionType.adjustment => (
      background: const Color(0xFFEDE7FB),
      foreground: const Color(0xFF7656C4),
    ),
    TransitTransactionType.unknown => (
      background: const Color(0xFFFFEBCF),
      foreground: const Color(0xFFB66A0C),
    ),
  };
  if (brightness == Brightness.light) return colors;
  return (
    background: colors.foreground.withValues(alpha: .22),
    foreground: Color.lerp(colors.foreground, Colors.white, .28)!,
  );
}

String _amountText(AmountCalculation calculation, AppLocalizations l10n) =>
    switch (calculation.status) {
      AmountCalculationStatus.calculated => '-${yen(calculation.amount!)}',
      AmountCalculationStatus.balanceIncrease => '+${yen(calculation.amount!)}',
      AmountCalculationStatus.unavailable => l10n.unavailableAmount,
      AmountCalculationStatus.suspicious => l10n.checkAmount,
    };

String _amountUnavailableExplanation(
  AmountCalculation calculation,
  AppLocalizations l10n,
) => switch (calculation.unavailableReason) {
  AmountUnavailableReason.noOlderRecord => l10n.oldestRecord,
  AmountUnavailableReason.balanceDidNotDecrease => l10n.noDecrease,
  null => l10n.notEnoughBalances,
};

String _boardingCode(ParsedTransitHistory history) =>
    '${hexByte(history.regionCode)}-${hexByte(history.boardingLineCode)}-${hexByte(history.boardingStationCode)}';
String _alightingCode(ParsedTransitHistory history) =>
    '${hexByte(history.regionCode)}-${hexByte(history.alightingLineCode)}-${hexByte(history.alightingStationCode)}';
String _routeSummary(
  AppLocalizations l10n,
  ParsedTransitHistory history,
  ResolvedStationPair? stations,
  StationResolution? transactionLocation,
  StationNameDisplayMode stationNameDisplayMode,
) => switch (history.transactionType) {
  TransitTransactionType.rail =>
    '${_displayStation(stations?.boarding, _boardingCode(history), stationNameDisplayMode, l10n)}'
        '  →  '
        '${_displayStation(stations?.alighting, _alightingCode(history), stationNameDisplayMode, l10n)}',
  TransitTransactionType.bus => history.busOperatorName ?? l10n.unknownBus,
  TransitTransactionType.purchase => purchaseSummary(history, l10n),
  TransitTransactionType.charge => chargeSummary(
    history,
    l10n: l10n,
    transactionLocation: transactionLocation,
    stationNameDisplayMode: stationNameDisplayMode,
  ),
  TransitTransactionType.gateWindowProcessing => gateWindowSummary(
    history,
    l10n: l10n,
    transactionLocation: transactionLocation,
    stationNameDisplayMode: stationNameDisplayMode,
  ),
  TransitTransactionType.refund => l10n.refund,
  TransitTransactionType.adjustment => l10n.adjustment,
  TransitTransactionType.unknown => l10n.unknownTransactionSummary,
};

String _formatTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}:'
    '${value.second.toString().padLeft(2, '0')}';

String _stationDetail(
  AppLocalizations l10n,
  StationResolution? resolution,
  String fallbackCode, {
  String? routeLineName,
  required StationNameDisplayMode stationNameDisplayMode,
}) {
  final station = resolution?.station;
  if (station == null) return l10n.stationUnavailable;
  return '${displayStationName(japanese: station.stationName, korean: station.stationNameKorean, english: station.stationNameEnglish, mode: stationNameDisplayMode)} · ${routeLineName ?? station.lineName}';
}

String _displayStation(
  StationResolution? resolution,
  String fallbackCode,
  StationNameDisplayMode mode,
  AppLocalizations l10n,
) {
  final station = resolution?.station;
  return station == null
      ? l10n.stationUnavailable
      : displayStationName(
          japanese: station.stationName,
          korean: station.stationNameKorean,
          english: station.stationNameEnglish,
          mode: mode,
        );
}

bool _bothStationsResolved(ResolvedStationPair? stations) =>
    stations?.boarding.isResolved == true &&
    stations?.alighting.isResolved == true;

bool _hasMultipleCandidates(ResolvedStationPair? stations) =>
    stations?.boarding.strategy == StationMatchStrategy.multipleCandidates ||
    stations?.alighting.strategy == StationMatchStrategy.multipleCandidates;
