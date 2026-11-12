import 'dart:async';

import '../../../core/localization/app_strings.dart';

import 'package:flutter/material.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../issue_report/domain/issue_report_repository.dart';
import '../../station_resolver/data/asset_station_database.dart';
import '../../station_resolver/domain/station_name_display.dart';
import '../../station_resolver/domain/station_resolution.dart';
import '../../transaction_history/data/transit_history_parser.dart';
import '../../transaction_history/domain/transit_transaction_type.dart';
import '../../transaction_history/presentation/history_pages.dart';
import '../domain/card_comparison_session.dart';
import '../domain/card_reader.dart';
import '../domain/card_scan_result.dart';
import 'scan_guidance.dart';
import 'card_brand_name.dart';
import 'widgets/card_brand_icon.dart';
import 'widgets/card_comparison_clear_dialog.dart';
import 'widgets/card_comparison_exit_dialog.dart';

enum _CardAction { rename, rescan, remove }

class CardComparisonPage extends StatefulWidget {
  const CardComparisonPage({
    required this.reader,
    required this.stationDatabase,
    required this.stationNameDisplayMode,
    required this.scanScreenBuilder,
    this.issueReportRepository,
    super.key,
  });
  final CardReader reader;
  final Future<AssetStationDatabase> stationDatabase;
  final StationNameDisplayMode stationNameDisplayMode;
  final IssueReportRepository? issueReportRepository;
  final Widget Function(VoidCallback onCancel) scanScreenBuilder;

  @override
  State<CardComparisonPage> createState() => _CardComparisonPageState();
}

class _CardComparisonPageState extends State<CardComparisonPage> {
  final _session = CardComparisonSession();
  bool _busy = false;
  bool _scanning = false;
  bool _cancelled = false;
  bool _allowExit = false;
  bool _exitPromptOpen = false;

  @override
  void dispose() {
    _cancelled = true;
    if (_busy) unawaited(widget.reader.cancel().catchError((Object _) {}));
    _session.dispose();
    super.dispose();
  }

  void _notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _scan({int? replacingId}) async {
    if (_busy) return;
    final reader = widget.reader;
    if (reader is! ComparisonCardReader) {
      _notice(strings(context).comparisonUnavailable);
      return;
    }
    setState(() {
      _busy = true;
      _scanning = true;
      _cancelled = false;
    });
    CardScanFailureKind? failure;
    try {
      final result = await (reader as ComparisonCardReader).scanForComparison(
        sessionKey: _session.sessionKey,
      );
      if (!mounted || _cancelled) return;
      final before = _session.cards.length;
      final card = _session.accept(result, replacingId: replacingId);
      final displayName = _cardDisplayName(card, strings(context));
      _notice(
        before == _session.cards.length
            ? strings(context).comparisonUpdated(displayName)
            : strings(context).comparisonAdded(displayName),
      );
    } on CardComparisonException catch (error) {
      if (mounted && !_cancelled) {
        final l10n = strings(context);
        _notice(switch (error.kind) {
          CardComparisonFailure.unidentified => l10n.comparisonUnidentified,
          CardComparisonFailure.balanceUnavailable =>
            l10n.comparisonBalanceUnavailable,
          CardComparisonFailure.differentCard => l10n.comparisonDifferentCard,
          CardComparisonFailure.limit => l10n.comparisonAtLimit,
        });
      }
    } on CardScanException catch (error) {
      if (!_cancelled && error.kind != CardScanFailureKind.cancelled) {
        failure = error.kind;
      }
    } catch (_) {
      if (!_cancelled) failure = CardScanFailureKind.unknown;
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _scanning = false;
        });
      }
    }
    if (!mounted || failure == null) return;
    CardReaderAvailability availability;
    try {
      availability = await widget.reader.checkAvailability();
    } catch (_) {
      availability = CardReaderAvailability.unknown;
    }
    if (!mounted) return;
    final action = await showScanFailure(
      context,
      kind: failure,
      availability: availability,
    );
    if (!mounted) return;
    if (action == ScanFailureAction.retry) {
      await _scan(replacingId: replacingId);
    } else if (action == ScanFailureAction.help) {
      await showScanHelp(context);
    } else if (action == ScanFailureAction.settings) {
      try {
        if (!await widget.reader.openNfcSettings() && mounted) {
          _notice(strings(context).checkNfcSettings);
        }
      } catch (_) {
        if (mounted) _notice(strings(context).checkNfcSettings);
      }
    }
  }

  Future<void> _cancel() async {
    if (!_busy || _cancelled) return;
    _cancelled = true;
    try {
      await widget.reader.cancel();
    } catch (_) {
      if (mounted) _notice(strings(context).scanStillEnding);
    }
  }

  Future<bool> _confirmExit() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => const CardComparisonExitDialog(),
        ) ??
        false;
  }

  Future<void> _leave() async {
    if (_exitPromptOpen) return;
    if (_busy) {
      await _cancel();
      return;
    }
    _exitPromptOpen = true;
    final leave = _session.cards.isEmpty || await _confirmExit();
    _exitPromptOpen = false;
    if (!mounted || !leave) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    setState(() => _allowExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _rename(ComparedCard card) async {
    final controller = TextEditingController(
      text: _cardDisplayName(card, strings(context)),
    );
    final formKey = GlobalKey<FormState>();
    ModalRoute<dynamic>? dialogRoute;
    try {
      final name = await showDialog<String>(
        context: context,
        builder: (context) {
          dialogRoute = ModalRoute.of(context);
          return AlertDialog(
            title: Text(strings(context).renameCard),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: controller,
                maxLength: 24,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: strings(context).cardName,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? strings(context).enterCardName
                    : null,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(strings(context).cancel),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context, controller.text.trim());
                  }
                },
                child: Text(strings(context).saveName),
              ),
            ],
          );
        },
      );
      if (mounted && name != null) {
        setState(() => _session.rename(card.id, name));
      }
    } finally {
      // Wait for the closing route to release its text field before disposal.
      await dialogRoute?.completed;
      controller.dispose();
    }
  }

  Future<void> _details(ComparedCard card) async {
    final rescan = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _ComparisonHistoryPage(
          card: card,
          stationDatabase: widget.stationDatabase,
          stationNameDisplayMode: widget.stationNameDisplayMode,
          issueReportRepository: widget.issueReportRepository,
        ),
      ),
    );
    if (mounted && rescan == true) await _scan(replacingId: card.id);
  }

  void _help() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings(context).compareBalances,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(strings(context).comparisonHelpHint),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope<void>(
    canPop: _allowExit || (!_busy && _session.cards.isEmpty),
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) unawaited(_leave());
    },
    child: _scanning
        ? widget.scanScreenBuilder(() => unawaited(_cancel()))
        : Scaffold(
            appBar: AppBar(
              title: Text(strings(context).compareBalances),
              leading: IconButton(
                onPressed: _leave,
                tooltip: strings(context).exitComparison,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              actions: [
                IconButton(
                  onPressed: _help,
                  tooltip: strings(context).comparisonHelp,
                  icon: const Icon(Icons.help_outline_rounded),
                ),
              ],
            ),
            body: SafeArea(
              child: AppPage(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          strings(
                            context,
                          ).comparingCount(_session.cards.length),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _busy || _session.cards.isEmpty
                            ? null
                            : () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (_) =>
                                      const CardComparisonClearDialog(),
                                );
                                if (confirmed == true &&
                                    mounted &&
                                    context.mounted) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).clearSnackBars();
                                  setState(_session.clear);
                                }
                              },
                        child: Text(strings(context).deleteAll),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_session.cards.isNotEmpty) ...[
                    Text(
                      strings(context).tapCardHistory,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_session.cards.isEmpty)
                    AppSurface(
                      child: Column(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 36,
                            color: AppColors.skyDark,
                          ),
                          SizedBox(height: 12),
                          Text(strings(context).addCardsToCompare),
                          SizedBox(height: 6),
                          Text(
                            strings(context).scanOneAtATime,
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  for (final card in _session.cards) ...[
                    AppSurface(
                      key: ValueKey('compared-card-${card.id}'),
                      padding: EdgeInsets.zero,
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _busy ? null : () => _details(card),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  0,
                                  12,
                                ),
                                child: _ComparedCardSummary(card: card),
                              ),
                            ),
                          ),
                          PopupMenuButton<_CardAction>(
                            tooltip: strings(context).cardMenu(
                              _cardDisplayName(card, strings(context)),
                            ),
                            enabled: !_busy,
                            onSelected: (action) async {
                              switch (action) {
                                case _CardAction.rename:
                                  await _rename(card);
                                case _CardAction.rescan:
                                  await _scan(replacingId: card.id);
                                case _CardAction.remove:
                                  setState(() => _session.remove(card.id));
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: _CardAction.rename,
                                child: Text(strings(context).rename),
                              ),
                              PopupMenuItem(
                                value: _CardAction.rescan,
                                child: Text(strings(context).scanAgain),
                              ),
                              PopupMenuItem(
                                value: _CardAction.remove,
                                child: Text(strings(context).delete),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed:
                        _busy ||
                            _session.cards.length >=
                                CardComparisonSession.maxCards
                        ? null
                        : () => _scan(),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(strings(context).addCard),
                  ),
                  if (_session.cards.length >= CardComparisonSession.maxCards)
                    Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        strings(context).comparisonLimit,
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
  );
}

class _ComparedCardSummary extends StatelessWidget {
  const _ComparedCardSummary({required this.card});

  final ComparedCard card;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final amountStyle = TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.accent(context),
      );
      final textScaler = MediaQuery.textScalerOf(context);
      final amountMeasure = TextPainter(
        text: TextSpan(
          text: yen(card.balance),
          style: DefaultTextStyle.of(context).style.merge(amountStyle),
        ),
        textDirection: Directionality.of(context),
        textScaler: textScaler,
      )..layout();
      // Keep the existing type scale. Stack only when the amount and at
      // least four title glyphs cannot fit, rather than squeezing the icon
      // or shrinking/wrapping the balance across lines.
      final stacked =
          constraints.maxWidth <
          42 + 12 + amountMeasure.width + textScaler.scale(14) * 4 + 12;
      amountMeasure.dispose();
      final name = Text(
        _cardDisplayName(card, strings(context)),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      );
      final amount = Text(
        yen(card.balance),
        textAlign: TextAlign.end,
        style: amountStyle,
      );
      final timestamp = Text(
        strings(context).checkedAt(formatDateTime(card.result.scannedAt)),
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
      final icon = CardBrandIcon(identity: card.brandIdentity);
      if (stacked) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                icon,
                const SizedBox(width: 12),
                Expanded(child: name),
              ],
            ),
            const SizedBox(height: 4),
            Align(alignment: Alignment.centerRight, child: amount),
            const SizedBox(height: 4),
            timestamp,
          ],
        );
      }
      return Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [name, const SizedBox(height: 4), timestamp],
            ),
          ),
          const SizedBox(width: 12),
          amount,
        ],
      );
    },
  );
}

class _HistoryLocations {
  const _HistoryLocations({this.pairs = const {}, this.locations = const {}});
  final Map<int, ResolvedStationPair> pairs;
  final Map<int, StationResolution> locations;
}

class _ComparisonHistoryPage extends StatefulWidget {
  const _ComparisonHistoryPage({
    required this.card,
    required this.stationDatabase,
    required this.stationNameDisplayMode,
    this.issueReportRepository,
  });
  final ComparedCard card;
  final Future<AssetStationDatabase> stationDatabase;
  final StationNameDisplayMode stationNameDisplayMode;
  final IssueReportRepository? issueReportRepository;
  @override
  State<_ComparisonHistoryPage> createState() => _ComparisonHistoryPageState();
}

class _ComparisonHistoryPageState extends State<_ComparisonHistoryPage> {
  late final _histories = const TransitHistoryParser().parse(
    widget.card.result.blocks,
  );
  late final Future<_HistoryLocations> _resolved = _resolve();

  Future<_HistoryLocations> _resolve() async {
    try {
      final database = await widget.stationDatabase;
      final pairs = <int, ResolvedStationPair>{};
      final locations = <int, StationResolution>{};
      for (final history in _histories) {
        if (history.transactionType == TransitTransactionType.rail) {
          pairs[history.rawBlock.index] = database.resolvePair(
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
        if (history.hasTransactionLocationCode) {
          locations[history.rawBlock.index] = database.resolve(
            StationCode(
              regionCode: history.transactionLocationRegionCode!,
              lineCode: history.transactionLocationLineCode!,
              stationCode: history.transactionLocationStationCode!,
            ),
          );
        }
      }
      return _HistoryLocations(pairs: pairs, locations: locations);
    } catch (_) {
      return const _HistoryLocations();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_cardDisplayName(widget.card, strings(context))),
    ),
    body: SafeArea(
      child: FutureBuilder<_HistoryLocations>(
        future: _resolved,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return HistoryListPage(
            histories: _histories,
            currentBalance: widget.card.balance,
            brandIdentity: widget.card.brandIdentity,
            stationPairs: snapshot.data!.pairs,
            transactionLocations: snapshot.data!.locations,
            stationNameDisplayMode: widget.stationNameDisplayMode,
            issueReportRepository: widget.issueReportRepository,
            onScan: () => Navigator.pop(context, true),
          );
        },
      ),
    ),
  );
}

String _cardDisplayName(ComparedCard card, AppLocalizations l10n) {
  if (card.isNameCustomized || l10n.localeName != 'en') return card.name;
  final brand = card.brandIdentity;
  if (brand == null) {
    return l10n.defaultCardName(card.name.substring('카드 '.length));
  }
  return cardBrandName(brand, l10n) + card.name.substring(brand.label.length);
}
