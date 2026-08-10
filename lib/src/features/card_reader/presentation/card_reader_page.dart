import 'package:flutter/material.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../issue_report/domain/issue_report_repository.dart';
import '../../settings/presentation/settings_page.dart';
import '../../station_resolver/data/asset_station_database.dart';
import '../../station_resolver/domain/station_resolution.dart';
import '../../transaction_history/data/transit_history_parser.dart';
import '../../transaction_history/domain/amount_calculation.dart';
import '../../transaction_history/domain/parsed_transit_history.dart';
import '../../transaction_history/domain/transit_transaction_type.dart';
import '../../transaction_history/presentation/history_pages.dart';
import '../data/nfc_manager_card_reader.dart';
import '../domain/card_reader.dart';
import '../domain/card_scan_result.dart';

class CardReaderPage extends StatefulWidget {
  const CardReaderPage({
    required this.themeMode,
    required this.onThemeModeChanged,
    super.key,
    this.reader,
    this.stationDatabase,
    this.issueReportRepository,
  });

  final CardReader? reader;
  final AssetStationDatabase? stationDatabase;
  final IssueReportRepository? issueReportRepository;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<CardReaderPage> createState() => _CardReaderPageState();
}

class _CardReaderPageState extends State<CardReaderPage> {
  late final CardReader _reader = widget.reader ?? NfcManagerCardReader();
  late final Future<AssetStationDatabase> _stationDatabase =
      widget.stationDatabase != null
      ? Future.value(widget.stationDatabase)
      : AssetStationDatabase.load();
  static const _historyParser = TransitHistoryParser();

  CardScanResult? _result;
  String? _message;
  int _selectedTab = 0;
  _ReaderFlow _flow = _ReaderFlow.main;
  bool _cancelRequested = false;
  Map<int, ResolvedStationPair> _stationPairs = const {};

  List<ParsedTransitHistory> get _histories =>
      _result == null ? const [] : _historyParser.parse(_result!.blocks);

  int? get _currentBalance =>
      _result == null ? null : _historyParser.currentBalance(_result!.blocks);

  Future<void> _startScan() async {
    setState(() {
      _cancelRequested = false;
      _message = null;
      _flow = _ReaderFlow.scanning;
    });

    try {
      final result = await _reader.scan();
      if (!mounted || _cancelRequested) return;
      final histories = _historyParser.parse(result.blocks);
      Map<int, ResolvedStationPair> stationPairs = const {};
      try {
        stationPairs = await _resolveStations(histories);
      } catch (_) {
        // Station enrichment must never turn a successful NFC read into an
        // error. Raw codes remain available as the safe fallback.
      }
      if (!mounted || _cancelRequested) return;
      setState(() {
        _result = result;
        _stationPairs = stationPairs;
        _flow = _ReaderFlow.success;
      });
    } on CardScanException catch (error) {
      if (!mounted || _cancelRequested) return;
      setState(() {
        _message = error.message;
        _flow = _ReaderFlow.main;
      });
    } catch (_) {
      if (!mounted || _cancelRequested) return;
      setState(() {
        _message = '예상하지 못한 오류가 발생했습니다. 다시 시도해 주세요.';
        _flow = _ReaderFlow.main;
      });
    }
  }

  Future<void> _cancelScan() async {
    _cancelRequested = true;
    if (mounted) setState(() => _flow = _ReaderFlow.main);
    await _reader.cancel();
  }

  Future<Map<int, ResolvedStationPair>> _resolveStations(
    List<ParsedTransitHistory> histories,
  ) async {
    final database = await _stationDatabase;
    final resolved = <int, ResolvedStationPair>{};
    for (final history in histories) {
      if (history.transactionType != TransitTransactionType.rail) continue;
      resolved[history.rawBlock.index] = database.resolvePair(
        boardingCode: StationCode(
          regionCode: history.regionCode,
          lineCode: history.boardingLineCode,
          stationCode: history.boardingStationCode,
        ),
        alightingCode: StationCode(
          regionCode: history.regionCode,
          lineCode: history.alightingLineCode,
          stationCode: history.alightingStationCode,
        ),
      );
    }
    return resolved;
  }

  void _openHistory() => setState(() {
    _flow = _ReaderFlow.main;
    _selectedTab = 1;
  });

  void _clearSession() {
    setState(() {
      _result = null;
      _message = null;
      _stationPairs = const {};
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('현재 세션의 이용내역을 지웠습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    if (_flow == _ReaderFlow.scanning) {
      return _ScanScreen(onCancel: _cancelScan);
    }
    if (_flow == _ReaderFlow.success) {
      return _ScanSuccessScreen(
        result: _result!,
        histories: _histories,
        onOpenHistory: _openHistory,
        onScanAgain: _startScan,
        onClose: () => setState(() => _flow = _ReaderFlow.main),
      );
    }

    final pages = [
      _HomePage(
        result: _result,
        histories: _histories,
        stationPairs: _stationPairs,
        message: _message,
        animateCard: _selectedTab == 0,
        onScan: _startScan,
        onOpenHistory: _openHistory,
      ),
      HistoryListPage(
        histories: _histories,
        currentBalance: _currentBalance,
        issueReportRepository: widget.issueReportRepository,
        stationPairs: _stationPairs,
        onScan: _startScan,
      ),
      SettingsPage(
        result: _result,
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
        onClearSession: _clearSession,
      ),
    ];

    return Scaffold(
      appBar: _selectedTab == 0
          ? AppBar(
              toolbarHeight: 68,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('IC 카드 리더'),
                  const SizedBox(height: 2),
                  Text(
                    _result == null
                        ? '카드를 준비해 주세요'
                        : '최근 스캔 · ${formatDateTime(_result!.scannedAt)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : null,
      body: SafeArea(
        child: IndexedStack(index: _selectedTab, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: '이용내역',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: '설정',
          ),
        ],
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({
    required this.result,
    required this.histories,
    required this.stationPairs,
    required this.message,
    required this.animateCard,
    required this.onScan,
    required this.onOpenHistory,
  });

  final CardScanResult? result;
  final List<ParsedTransitHistory> histories;
  final Map<int, ResolvedStationPair> stationPairs;
  final String? message;
  final bool animateCard;
  final VoidCallback onScan;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final latest = histories.isEmpty ? null : histories.first;
    final latestStations = latest == null
        ? null
        : stationPairs[latest.rawBlock.index];
    return AppPage(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Center(child: IcCardArt(animated: animateCard, size: 300)),
        Text(
          'IC 카드를 스캔해 주세요',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          '카드를 기기 뒷면 NFC 위치에 대면\n최근 이용내역을 읽어옵니다.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 13),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StatusPill(
              label: 'NFC 사용 가능',
              icon: Icons.nfc_rounded,
              color: AppColors.success,
            ),
            SizedBox(width: 8),
            StatusPill(label: '베타 · 실기기 검증 중'),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onScan,
          icon: const Icon(Icons.nfc_rounded),
          label: const Text('IC 카드 스캔'),
        ),
        if (message != null) ...[
          const SizedBox(height: 13),
          NoticeBanner(
            title: '카드를 읽지 못했습니다',
            text: message!,
            tone: NoticeTone.danger,
          ),
        ],
        const SizedBox(height: 26),
        SectionLabel(
          '최근 이용내역',
          trailing: result == null
              ? null
              : TextButton(
                  onPressed: onOpenHistory,
                  child: const Text('전체 보기'),
                ),
        ),
        if (result == null)
          const AppSurface(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, color: AppColors.skyDark),
                  SizedBox(width: 12),
                  Expanded(child: Text('아직 스캔한 카드가 없습니다.')),
                ],
              ),
            ),
          )
        else if (latest == null)
          const AppSurface(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text('읽은 카드에서 표시할 수 있는 이용내역을 찾지 못했습니다.'),
            ),
          )
        else
          AppSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.skySoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: AppColors.skyDark,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatDate(latest.usageDate),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _homeHistorySummary(latest, latestStations),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _homeAmountText(latest.amountCalculation),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Divider(),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Text(
                      '이용 후 잔액',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      yen(latest.balance),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        const AppSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('지원 카드', style: TextStyle(fontWeight: FontWeight.w900)),
              SizedBox(height: 7),
              Text(
                'Suica · PASMO · ICOCA 등 일본 전국호환 교통계 IC 카드',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              SizedBox(height: 7),
              Text(
                'PiTaPa 포스트페이 및 일부 거래는 지원되지 않을 수 있습니다.',
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 14,
              color: AppColors.skyDark,
            ),
            SizedBox(width: 5),
            Flexible(
              child: Text(
                '카드 데이터는 이 기기에서만 처리합니다',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.skyDark),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ScanScreen extends StatefulWidget {
  const _ScanScreen({required this.onCancel});

  final VoidCallback onCancel;

  @override
  State<_ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<_ScanScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 30),
  )..forward();

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        onPressed: widget.onCancel,
        icon: const Icon(Icons.close_rounded),
        tooltip: '스캔 취소',
      ),
      title: const Text('카드 스캔'),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
        children: [
          const Center(child: IcCardArt(animated: true, size: 250)),
          const SizedBox(height: 10),
          const StatusPill(
            label: '카드 감지 대기 · 이용내역 읽기 준비',
            icon: Icons.sync_rounded,
          ),
          const SizedBox(height: 16),
          Text(
            '카드를 움직이지 말고\n가까이 대 주세요',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 9),
          Text(
            '카드가 감지되면 여러 블록을 차례로 읽습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, _) {
              final remainingSeconds = (30 * (1 - _progressController.value))
                  .ceil();
              return Column(
                children: [
                  LinearProgressIndicator(
                    value: _progressController.value,
                    borderRadius: const BorderRadius.all(Radius.circular(999)),
                    semanticsLabel: '카드 스캔 진행률',
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '남은 시간 $remainingSeconds초',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 42),
          OutlinedButton.icon(
            onPressed: widget.onCancel,
            icon: const Icon(Icons.close_rounded),
            label: const Text('스캔 취소'),
          ),
          const SizedBox(height: 12),
          Text(
            '오류가 발생해도 앱을 종료하지 않고 다시 시도할 수 있습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              fontSize: 11,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ScanSuccessScreen extends StatelessWidget {
  const _ScanSuccessScreen({
    required this.result,
    required this.histories,
    required this.onOpenHistory,
    required this.onScanAgain,
    required this.onClose,
  });

  final CardScanResult result;
  final List<ParsedTransitHistory> histories;
  final VoidCallback onOpenHistory;
  final VoidCallback onScanAgain;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final unresolved = histories.where(_needsReview).length;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
        ),
        title: const Text('스캔 완료'),
      ),
      body: AppPage(
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.success,
                size: 46,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '카드를 읽었습니다',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 7),
          Text(
            formatDateTime(result.scannedAt),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          AppSurface(
            child: Row(
              children: [
                Expanded(
                  child: _SuccessMetric(
                    icon: Icons.view_module_outlined,
                    value: '${result.blocks.length}',
                    label: '읽은 블록',
                  ),
                ),
                const SizedBox(height: 62, child: VerticalDivider()),
                Expanded(
                  child: _SuccessMetric(
                    icon: Icons.receipt_long_outlined,
                    value: '${histories.length}',
                    label: '해석한 내역',
                  ),
                ),
                const SizedBox(height: 62, child: VerticalDivider()),
                Expanded(
                  child: _SuccessMetric(
                    icon: Icons.help_outline_rounded,
                    value: '$unresolved',
                    label: '확인 필요',
                  ),
                ),
              ],
            ),
          ),
          if (unresolved > 0) ...[
            const SizedBox(height: 14),
            const NoticeBanner(
              title: '일부 정보는 아직 확인 중입니다',
              text:
                  '원본 기록은 정상적으로 읽었습니다. 역명과 거래 유형 데이터베이스가 연결되면 더 자세히 표시할 수 있습니다.',
              tone: NoticeTone.warning,
            ),
          ],
          const SizedBox(height: 14),
          const NoticeBanner(
            title: '읽은 이용내역은 이 기기 안에만 표시됩니다',
            text: '카드 IDm 원문은 저장하거나 화면에 표시하지 않습니다.',
            tone: NoticeTone.privacy,
          ),
          const SizedBox(height: 26),
          FilledButton.icon(
            onPressed: onOpenHistory,
            icon: const Icon(Icons.receipt_long_rounded),
            label: const Text('이용내역 보기'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onScanAgain,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('다시 스캔'),
          ),
        ],
      ),
    );
  }
}

class _SuccessMetric extends StatelessWidget {
  const _SuccessMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
      const SizedBox(height: 6),
      Text(
        value,
        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 11,
        ),
      ),
    ],
  );
}

enum _ReaderFlow { main, scanning, success }

bool _needsReview(ParsedTransitHistory history) {
  if (history.usageDate == null ||
      history.transactionType == TransitTransactionType.unknown) {
    return true;
  }
  return switch (history.amountCalculation.status) {
    AmountCalculationStatus.suspicious => true,
    AmountCalculationStatus.unavailable =>
      history.amountCalculation.unavailableReason !=
          AmountUnavailableReason.noOlderRecord,
    AmountCalculationStatus.calculated ||
    AmountCalculationStatus.balanceIncrease => false,
  };
}

String _homeAmountText(AmountCalculation calculation) =>
    switch (calculation.status) {
      AmountCalculationStatus.calculated => '-${yen(calculation.amount!)}',
      AmountCalculationStatus.balanceIncrease => '+${yen(calculation.amount!)}',
      AmountCalculationStatus.unavailable => '계산 불가',
      AmountCalculationStatus.suspicious => '확인 필요',
    };

String _homeHistorySummary(
  ParsedTransitHistory history,
  ResolvedStationPair? stations,
) => switch (history.transactionType) {
  TransitTransactionType.rail =>
    '${_stationLabel(stations?.boarding, _stationCode(history, boarding: true))}'
        '  →  '
        '${_stationLabel(stations?.alighting, _stationCode(history, boarding: false))}',
  TransitTransactionType.bus => '버스 회사 미확인',
  TransitTransactionType.purchase => '물품 구매',
  TransitTransactionType.charge => '카드 충전',
  TransitTransactionType.refund => '환불',
  TransitTransactionType.adjustment => '정산',
  TransitTransactionType.unknown => '거래 유형 미확인',
};

String _stationCode(ParsedTransitHistory history, {required bool boarding}) =>
    '${hexByte(history.regionCode)}-'
    '${hexByte(boarding ? history.boardingLineCode : history.alightingLineCode)}-'
    '${hexByte(boarding ? history.boardingStationCode : history.alightingStationCode)}';

String _stationLabel(StationResolution? resolution, String fallbackCode) =>
    resolution?.station?.stationName ?? fallbackCode;
