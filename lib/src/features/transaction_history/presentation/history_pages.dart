import 'package:flutter/material.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../issue_report/presentation/issue_report_page.dart';
import '../../issue_report/domain/issue_report_repository.dart';
import '../../station_resolver/domain/station_resolution.dart';
import '../domain/amount_calculation.dart';
import '../domain/parsed_transit_history.dart';
import '../domain/transit_transaction_type.dart';

class HistoryListPage extends StatefulWidget {
  const HistoryListPage({
    required this.histories,
    required this.currentBalance,
    required this.stationPairs,
    required this.onScan,
    super.key,
    this.issueReportRepository,
  });

  final List<ParsedTransitHistory> histories;
  final int? currentBalance;
  final Map<int, ResolvedStationPair> stationPairs;
  final VoidCallback onScan;
  final IssueReportRepository? issueReportRepository;

  @override
  State<HistoryListPage> createState() => _HistoryListPageState();
}

class _HistoryListPageState extends State<HistoryListPage> {
  _HistoryFilter _filter = _HistoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.histories.where(_filter.matches).toList();
    return AppPage(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '이용내역',
                    style: Theme.of(context).appBarTheme.titleTextStyle,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.histories.isEmpty
                        ? '카드를 스캔하면 최근 이용내역이 표시됩니다.'
                        : '최근 스캔 · ${widget.histories.length}개 기록',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filled(
              onPressed: widget.onScan,
              tooltip: 'IC 카드 스캔',
              icon: const Icon(Icons.nfc_rounded),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _CurrentBalanceCard(
          balance: widget.currentBalance,
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
                  label: Text(filter.label),
                  selected: _filter == filter,
                  onSelected: (_) => setState(() => _filter = filter),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (widget.histories.isEmpty)
          _EmptyHistory(hasCardData: widget.currentBalance != null)
        else if (filtered.isEmpty)
          const AppSurface(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: Text('해당 조건의 이용내역이 없습니다.')),
            ),
          )
        else
          for (final history in filtered) ...[
            _HistoryTile(
              history: history,
              stations: widget.stationPairs[history.rawBlock.index],
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => HistoryDetailPage(
                    history: history,
                    stations: widget.stationPairs[history.rawBlock.index],
                    issueReportRepository: widget.issueReportRepository,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _CurrentBalanceCard extends StatelessWidget {
  const _CurrentBalanceCard({
    required this.balance,
    required this.isInitializationBalance,
  });

  final int? balance;
  final bool isInitializationBalance;

  @override
  Widget build(BuildContext context) => AppSurface(
    padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.skySoft,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.account_balance_wallet_outlined,
            color: AppColors.skyDark,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '현재 카드 잔액',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                balance == null
                    ? '카드 스캔 후 표시'
                    : isInitializationBalance
                    ? '초기 잔액 기록 기준'
                    : '가장 최근 기록 기준',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Text(
          balance == null ? '—' : yen(balance!),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
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
            hasCardData ? '이 카드에는 표시할 이용내역이 없습니다' : '아직 읽은 이용내역이 없습니다',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            hasCardData ? '초기 잔액 기록만 확인되었습니다.' : '홈에서 IC 카드를 스캔해 주세요.',
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
    this.stations,
  });

  final ParsedTransitHistory history;
  final ResolvedStationPair? stations;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final amount = _amountText(history.amountCalculation);
    final typeColors = _typeColors(
      history.transactionType,
      Theme.of(context).brightness,
    );
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
          child: Row(
            children: [
              Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _typeLabel(history.transactionType),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          amount,
                          style: TextStyle(
                            color:
                                history.transactionType ==
                                    TransitTransactionType.charge
                                ? AppColors.success
                                : null,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _routeSummary(history, stations),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          formatDate(history.usageDate),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '잔액 ${yen(history.balance)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, size: 18),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
    this.issueReportRepository,
  });

  final ParsedTransitHistory history;
  final ResolvedStationPair? stations;
  final IssueReportRepository? issueReportRepository;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('이용내역 상세')),
    body: AppPage(
      children: [
        Row(
          children: [
            StatusPill(
              label: _typeLabel(history.transactionType),
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
                      label: '승차',
                      code: _boardingCode(history),
                      resolution: stations?.boarding,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    _RoutePoint(
                      label: '하차',
                      code: _alightingCode(history),
                      resolution: stations?.alighting,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
              ],
              Text(
                _amountText(history.amountCalculation),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color:
                      history.transactionType == TransitTransactionType.charge
                      ? AppColors.success
                      : null,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '이용 후 잔액 ${yen(history.balance)}',
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
            title: '금액을 계산할 수 없습니다',
            text: _amountUnavailableExplanation(history.amountCalculation),
          ),
        ],
        if (history.transactionType == TransitTransactionType.rail &&
            !_bothStationsResolved(stations)) ...[
          const SizedBox(height: 14),
          NoticeBanner(
            title: _hasMultipleCandidates(stations)
                ? '여러 역 후보가 있습니다'
                : '일부 역 정보 확인이 필요합니다',
            text: _hasMultipleCandidates(stations)
                ? '같은 노선·역 코드를 사용하는 후보가 여러 개라 임의로 확정하지 않았습니다. 원본 코드는 아래에서 확인할 수 있습니다.'
                : '데이터베이스에서 찾지 못한 역은 코드로 표시합니다. 확인되지 않은 역명을 임의로 추측하지 않습니다.',
            tone: NoticeTone.warning,
          ),
        ],
        const SizedBox(height: 24),
        const SectionLabel('상세 정보'),
        AppSurface(
          child: Column(
            children: [
              DetailLine(
                label: '거래 유형',
                value: _typeLabel(history.transactionType),
              ),
              const Divider(),
              DetailLine(
                label: '단말 / 처리 코드',
                value:
                    '${hexByte(history.terminalCode)} / ${hexByte(history.processCode)}',
                monospace: true,
              ),
              if (history.transactionType == TransitTransactionType.rail) ...[
                const Divider(),
                DetailLine(
                  label: '승차역',
                  value: _stationDetail(
                    stations?.boarding,
                    _boardingCode(history),
                  ),
                ),
                const Divider(),
                DetailLine(
                  label: '하차역',
                  value: _stationDetail(
                    stations?.alighting,
                    _alightingCode(history),
                  ),
                ),
              ],
              if (history.transactionType == TransitTransactionType.bus) ...[
                const Divider(),
                const DetailLine(label: '버스 회사', value: '미확인 · 회사 고유 코드 미해석'),
              ],
              const Divider(),
              DetailLine(label: '잔액', value: yen(history.balance)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 4),
          title: const Text(
            '기술 정보',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: const Text('문제 확인에 필요한 원본 16바이트 데이터'),
          children: [
            AppSurface(
              child: Column(
                children: [
                  DetailLine(
                    label: '블록',
                    value: '#${history.rawBlock.index + 1}',
                  ),
                  const Divider(),
                  DetailLine(
                    label: '원본 데이터',
                    value: history.rawBlock.hexadecimal,
                    monospace: true,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => IssueReportPage(
                history: history,
                stations: stations,
                repository: issueReportRepository,
              ),
            ),
          ),
          icon: const Icon(Icons.flag_outlined),
          label: const Text('이 내역의 오류 제보하기'),
        ),
      ],
    ),
  );
}

class _RoutePoint extends StatelessWidget {
  const _RoutePoint({required this.label, required this.code, this.resolution});

  final String label;
  final String code;
  final StationResolution? resolution;

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
          resolution?.station?.stationName ?? '역 정보 미등록',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        if (resolution?.station case final station?) ...[
          const SizedBox(height: 2),
          Text(
            station.lineName,
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
  String get label => switch (this) {
    _HistoryFilter.all => '전체',
    _HistoryFilter.transport => '교통',
    _HistoryFilter.purchase => '결제',
    _HistoryFilter.charge => '충전',
    _HistoryFilter.unknown => '미확인',
  };

  bool matches(ParsedTransitHistory history) => switch (this) {
    _HistoryFilter.all => true,
    _HistoryFilter.transport =>
      history.transactionType == TransitTransactionType.rail ||
          history.transactionType == TransitTransactionType.bus,
    _HistoryFilter.purchase =>
      history.transactionType == TransitTransactionType.purchase,
    _HistoryFilter.charge =>
      history.transactionType == TransitTransactionType.charge,
    _HistoryFilter.unknown =>
      history.transactionType == TransitTransactionType.unknown,
  };
}

String _typeLabel(TransitTransactionType type) => switch (type) {
  TransitTransactionType.rail => '철도 이용',
  TransitTransactionType.bus => '버스 이용',
  TransitTransactionType.purchase => '물품 구매',
  TransitTransactionType.charge => '충전',
  TransitTransactionType.refund => '환불',
  TransitTransactionType.adjustment => '정산',
  TransitTransactionType.unknown => '유형 미확인',
};

IconData _typeIcon(TransitTransactionType type) => switch (type) {
  TransitTransactionType.rail => Icons.train_rounded,
  TransitTransactionType.bus => Icons.directions_bus_rounded,
  TransitTransactionType.purchase => Icons.shopping_bag_outlined,
  TransitTransactionType.charge => Icons.add_card_rounded,
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

String _amountText(AmountCalculation calculation) =>
    switch (calculation.status) {
      AmountCalculationStatus.calculated => '-${yen(calculation.amount!)}',
      AmountCalculationStatus.balanceIncrease => '+${yen(calculation.amount!)}',
      AmountCalculationStatus.unavailable => '계산 불가',
      AmountCalculationStatus.suspicious => '금액 확인 필요',
    };

String _amountUnavailableExplanation(
  AmountCalculation calculation,
) => switch (calculation.unavailableReason) {
  AmountUnavailableReason.noOlderRecord =>
    '이 기록은 카드에 남아 있는 가장 오래된 이용내역입니다. 그보다 오래된 잔액 기록이 없어 잔액 차이로 이용 금액을 계산할 수 없습니다.',
  AmountUnavailableReason.balanceDidNotDecrease =>
    '이전 기록과 비교했을 때 잔액이 줄지 않았습니다. 충전·환불 등일 수 있어 일반 이용 금액으로 표시하지 않습니다.',
  null => '비교할 수 있는 잔액 정보가 부족해 이용 금액을 계산할 수 없습니다.',
};

String _boardingCode(ParsedTransitHistory history) =>
    '${hexByte(history.regionCode)}-${hexByte(history.boardingLineCode)}-${hexByte(history.boardingStationCode)}';
String _alightingCode(ParsedTransitHistory history) =>
    '${hexByte(history.regionCode)}-${hexByte(history.alightingLineCode)}-${hexByte(history.alightingStationCode)}';
String _routeSummary(
  ParsedTransitHistory history,
  ResolvedStationPair? stations,
) => switch (history.transactionType) {
  TransitTransactionType.rail =>
    '${stations?.boarding.station?.stationName ?? _boardingCode(history)}'
        '  →  '
        '${stations?.alighting.station?.stationName ?? _alightingCode(history)}',
  TransitTransactionType.bus => '버스 회사 미확인',
  TransitTransactionType.purchase => '물품 구매',
  TransitTransactionType.charge => '카드 충전',
  TransitTransactionType.refund => '환불',
  TransitTransactionType.adjustment => '정산',
  TransitTransactionType.unknown => '거래 유형을 확인할 수 없습니다',
};

String _stationDetail(StationResolution? resolution, String fallbackCode) {
  final station = resolution?.station;
  if (station == null) return '미등록 · $fallbackCode';
  return '${station.stationName} · ${station.lineName}';
}

bool _bothStationsResolved(ResolvedStationPair? stations) =>
    stations?.boarding.isResolved == true &&
    stations?.alighting.isResolved == true;

bool _hasMultipleCandidates(ResolvedStationPair? stations) =>
    stations?.boarding.strategy == StationMatchStrategy.multipleCandidates ||
    stations?.alighting.strategy == StationMatchStrategy.multipleCandidates;
