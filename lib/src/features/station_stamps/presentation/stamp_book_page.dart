import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization/app_strings.dart';
import '../../pass_comparison/presentation/pass_name_scope.dart';
import '../../station_resolver/domain/station_name_display.dart';
import '../domain/station_stamp_session.dart';
import '../domain/stamp_book_catalog.dart';
import 'stamp_book_style.dart';
import 'stamp_book_coach.dart';
import 'stamp_book_station_picker.dart';
import 'yamanote_stamp_map.dart';
import 'stamp_book_seal.dart';
export 'stamp_book_seal.dart' show StampBookSeal;
export 'stamp_book_home_card.dart' show StampBookHomeCard;

/// Curated illustrated book, available from Home.
class StampBookPage extends StatefulWidget {
  const StampBookPage({
    required this.session,
    required this.candidates,
    required this.hasScan,
    this.enableTutorial = false,
    this.previewTutorial = false,
    super.key,
  });
  final StationStampSession session;
  final Set<String> candidates;
  final bool hasScan;
  final bool enableTutorial;
  final bool previewTutorial;

  @override
  State<StampBookPage> createState() => _StampBookPageState();
}

class _StampBookPageState extends State<StampBookPage> {
  static const _tutorialSeenKey = 'stamp_book_tutorial_seen_v1';
  final _collectAnchor = GlobalKey();
  final _browseAnchor = GlobalKey();
  StampBookCoachStep? _coachStep;
  bool _collectionExpanded = true;
  final _expandedStampRegions = <String?>{};
  StationStampSession get session => widget.session;
  Set<String> get candidates => widget.candidates;
  // The developer preview exercises the guided flow without importing a scan.
  bool get hasScan => !widget.previewTutorial && widget.hasScan;

  @override
  void initState() {
    super.initState();
    if (!session.ready && !session.loadFailed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) session.restore();
      });
    }
    if (widget.previewTutorial) {
      _coachStep = StampBookCoachStep.collect;
    } else if (widget.enableTutorial) {
      _maybeStartTutorial();
    }
  }

  Future<void> _maybeStartTutorial() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!mounted || preferences.getBool(_tutorialSeenKey) == true) return;
      setState(() => _coachStep = StampBookCoachStep.collect);
      await preferences.setBool(_tutorialSeenKey, true);
    } on Exception {
      // A preferences failure must not prevent using the book.
    }
  }

  void _nextCoachStep() =>
      setState(() => _coachStep = StampBookCoachStep.browse);

  void _openBrowse(BuildContext context) {
    final inTutorial = _coachStep == StampBookCoachStep.browse;
    if (inTutorial) setState(() => _coachStep = null);
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            StampBookBrowsePage(session: session, continueTutorial: inTutorial),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: stampBookTheme(context),
    child: Builder(
      builder: (context) => ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          final c = StampBookColors(context);
          final collected = session.collected;
          final count = stampBookCollectedCount(session);
          final collectedLines = stampBookLines
              .where((line) => session.countFor(line) > 0)
              .toList();
          final fresh = candidates
              .intersection(stampBookStationIds)
              .difference(collected);
          final stampsByRegion = <String?, List<StampStation>>{};
          for (final station in stampBookStations) {
            if (!collected.contains(station.id)) continue;
            final region = stampBookRegionByStationId[station.id];
            final bucket = _bookStampRegions.containsKey(region)
                ? region
                : null;
            (stampsByRegion[bucket] ??= []).add(station);
          }
          final header = <Widget>[
            _Paper(
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Align(
                        key: const ValueKey('stamp-summary-collected'),
                        alignment: Alignment.centerLeft,
                        child: _metric(
                          context,
                          localized(context, '모은 역', 'Collected stations'),
                          session.ready ? '$count' : '—',
                        ),
                      ),
                    ),
                    VerticalDivider(
                      key: const ValueKey('stamp-summary-divider'),
                      width: 32,
                      thickness: 1,
                      indent: 4,
                      endIndent: 4,
                      color: c.line,
                    ),
                    Expanded(
                      child: Align(
                        key: const ValueKey('stamp-summary-completed'),
                        alignment: Alignment.centerLeft,
                        child: _metric(
                          context,
                          localized(context, '완료 노선', 'Completed lines'),
                          session.ready
                              ? '${stampBookCompletedCount(session)}'
                              : '—',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            KeyedSubtree(
              key: _collectAnchor,
              child: FilledButton.icon(
                key: const ValueKey('stamp-book-collect'),
                onPressed: !hasScan || !session.ready || fresh.isEmpty
                    ? null
                    : () {
                        final added = session.collect(fresh);
                        if (_coachStep == StampBookCoachStep.collect) {
                          _nextCoachStep();
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              localized(
                                context,
                                '$added개 역을 새롭게 수집했어요.',
                                '$added new stations collected.',
                              ),
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.add_task_rounded, size: 20),
                label: Text(
                  localized(context, '현재 스캔에서 수집', 'Collect from current scan'),
                ),
              ),
            ),
            if (!hasScan || (session.ready && fresh.isEmpty))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  localized(
                    context,
                    !hasScan ? '홈에서 IC카드를 먼저 스캔해 주세요.' : '새롭게 수집할 수첩의 역이 없어요.',
                    !hasScan
                        ? 'Scan your IC card on Home first.'
                        : 'No new stations for this book in this scan.',
                  ),
                  style: TextStyle(fontSize: 12, color: c.muted, height: 1.5),
                ),
              ),
            _CollectionStatus(session: session),
            const SizedBox(height: 16),
            _BookDisclosureHeading(
              key: const ValueKey('stamp-book-collection-toggle'),
              title: localized(context, '수집 중인 노선', 'Your line collection'),
              expanded: _collectionExpanded,
              onTap: () =>
                  setState(() => _collectionExpanded = !_collectionExpanded),
            ),
            if (_collectionExpanded)
              for (final line in collectedLines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _BookLineCard(session: session, line: line),
                ),
            if (_collectionExpanded && session.ready && collectedLines.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  localized(
                    context,
                    '아직 수집한 노선이 없어요.',
                    'No lines collected yet.',
                  ),
                  style: TextStyle(color: c.muted, fontSize: 14),
                ),
              ),
            const SizedBox(height: 12),
            _Paper(
              key: _browseAnchor,
              padding: EdgeInsets.zero,
              color: c.ticketStub,
              child: InkWell(
                key: const ValueKey('stamp-book-browse'),
                borderRadius: BorderRadius.circular(14),
                onTap: () => _openBrowse(context),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localized(
                                context,
                                '전체 노선 둘러보기',
                                'Browse all lines',
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              localized(
                                context,
                                '지역·회사별로 노선을 찾아보세요.',
                                'Find lines by region and operator.',
                              ),
                              style: TextStyle(fontSize: 12, color: c.muted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right_rounded, color: c.teal),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                localized(
                  context,
                  '수첩에 등록된 노선의 역을 수집할 수 있어요.',
                  'Collect stations on the lines included in this book.',
                ),
                style: TextStyle(fontSize: 12, color: c.muted),
              ),
            ),
            _heading(
              context,
              localized(context, '수집한 스탬프', 'Collected stamps'),
            ),
            if (stampsByRegion.isEmpty)
              _Paper(
                child: Text(
                  localized(
                    context,
                    '첫 역 스탬프를 모아 여행 수첩을 채워보세요.',
                    'Collect your first station to start your travel book.',
                  ),
                  style: TextStyle(color: c.muted, height: 1.6),
                ),
              ),
          ];
          final page = Scaffold(
            key: const ValueKey('stamp-book-page'),
            appBar: AppBar(
              title: Text(localized(context, '역 스탬프', 'Station stamps')),
              actions: [
                _help(
                  context,
                  onReplay: widget.enableTutorial
                      ? () => setState(
                          () => _coachStep = StampBookCoachStep.collect,
                        )
                      : null,
                ),
              ],
            ),
            body: SafeArea(
              top: false,
              child: CustomScrollView(
                scrollCacheExtent: _coachStep == null
                    ? null
                    : const ScrollCacheExtent.pixels(800),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    sliver: SliverMainAxisGroup(
                      slivers: [
                        SliverList.list(children: header),
                        for (final MapEntry(key: region, value: names)
                            in _bookStampRegions.entries)
                          if (stampsByRegion[region] case final stamps?)
                            SliverMainAxisGroup(
                              key: ValueKey(region),
                              slivers: [
                                SliverPadding(
                                  padding: EdgeInsets.only(
                                    bottom:
                                        _expandedStampRegions.contains(region)
                                        ? 0
                                        : 8,
                                  ),
                                  sliver: SliverToBoxAdapter(
                                    child: _BookStampRegionHeading(
                                      key: ValueKey(
                                        'stamp-book-region-${region ?? 'other'}',
                                      ),
                                      title: localized(
                                        context,
                                        names.$1,
                                        names.$2,
                                      ),
                                      count: localized(
                                        context,
                                        '${stamps.length}개',
                                        stamps.length == 1
                                            ? '1 stamp'
                                            : '${stamps.length} stamps',
                                      ),
                                      expanded: _expandedStampRegions.contains(
                                        region,
                                      ),
                                      onTap: () => setState(() {
                                        if (!_expandedStampRegions.remove(
                                          region,
                                        )) {
                                          _expandedStampRegions.add(region);
                                        }
                                      }),
                                    ),
                                  ),
                                ),
                                if (_expandedStampRegions.contains(region))
                                  SliverPadding(
                                    padding: const EdgeInsets.only(
                                      top: 14,
                                      bottom: 16,
                                    ),
                                    sliver: _CollectedStampRows(
                                      stations: stamps,
                                    ),
                                  ),
                              ],
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
          return StampBookCoach(
            step: _coachStep,
            anchor: _coachStep == StampBookCoachStep.browse
                ? _browseAnchor
                : _collectAnchor,
            onSkip: () => setState(() => _coachStep = null),
            onAction: _coachStep == StampBookCoachStep.browse
                ? () => _openBrowse(context)
                : _nextCoachStep,
            hasScan: hasScan,
            child: page,
          );
        },
      ),
    ),
  );
}

const _bookStampRegions = <String?, (String, String)>{
  'hokkaido': ('홋카이도', 'Hokkaido'),
  'tohoku': ('도호쿠', 'Tohoku'),
  'kanto': ('간토', 'Kanto'),
  'chubu': ('주부', 'Chubu'),
  'kansai': ('간사이', 'Kansai'),
  'chugoku': ('주고쿠', 'Chugoku'),
  'shikoku': ('시코쿠', 'Shikoku'),
  'kyushu': ('규슈', 'Kyushu'),
  'okinawa': ('오키나와', 'Okinawa'),
  null: ('지역 미분류', 'Unassigned region'),
};

/// Lay out only nearby rows so a large collection doesn't build every seal
/// when the user first opens the book.
class _CollectedStampRows extends StatelessWidget {
  const _CollectedStampRows({required this.stations});
  final List<StampStation> stations;

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, constraints) {
      const columnGap = 8.0;
      const rowGap = 16.0;
      final width = constraints.crossAxisExtent;
      final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;
      final sealWidth = largeText
          ? math.min(180.0, width)
          : math.max(0.0, (width - columnGap * 3) / 4);
      final columns = largeText
          ? math.max(1, ((width + columnGap) / (sealWidth + columnGap)).floor())
          : 4;
      return SliverList.builder(
        itemCount: (stations.length + columns - 1) ~/ columns,
        itemBuilder: (context, row) {
          final start = row * columns;
          final end = math.min(start + columns, stations.length);
          return Padding(
            padding: EdgeInsets.only(
              bottom: end == stations.length ? 0 : rowGap,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: columnGap,
              children: [
                for (var index = start; index < end; index++)
                  SizedBox(
                    width: sealWidth,
                    child: StampBookSeal.station(
                      key: ValueKey(
                        'stamp-book-collected-${stations[index].id}',
                      ),
                      station: stations[index],
                      collected: true,
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}

/// Browse only the released illustrated book lines.
class StampBookBrowsePage extends StatefulWidget {
  const StampBookBrowsePage({
    required this.session,
    this.continueTutorial = false,
    super.key,
  });
  final StationStampSession session;
  final bool continueTutorial;

  @override
  State<StampBookBrowsePage> createState() => _StampBookBrowsePageState();
}

class _StampBookBrowsePageState extends State<StampBookBrowsePage> {
  final _search = TextEditingController();
  final _companyAnchor = GlobalKey();
  final _exampleAnchor = GlobalKey();
  final _expandedOperators = <String>{};
  String? _selectedRegion;
  late bool _continueTutorial = widget.continueTutorial;

  void _skipTutorial() => setState(() => _continueTutorial = false);

  void _toggleCompany(String operator) => setState(() {
    if (!_expandedOperators.remove(operator)) _expandedOperators.add(operator);
  });

  bool _takeTutorial() {
    if (!_continueTutorial) return false;
    _skipTutorial();
    return true;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(StampLine line) {
    final query = _search.text.trim().toLowerCase().replaceAll(
      RegExp(r'[\s·・\-()]'),
      '',
    );
    if (query.isEmpty) return true;
    return [
      line.japanese,
      line.korean,
      line.english,
      stampBookLineKorean(line),
      stampBookLineEnglish(line),
      line.operator,
      line.operatorKorean,
      line.operatorEnglish,
      for (final s in line.stations) ...[
        s.japanese,
        s.korean,
        stampBookStationKorean(s),
        s.english,
        ?midosujiBookStationAliases[s.id],
      ],
    ].any(
      (name) => name
          .toLowerCase()
          .replaceAll(RegExp(r'[\s·・\-()]'), '')
          .contains(query),
    );
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: stampBookTheme(context),
    child: Builder(
      builder: (context) {
        final c = StampBookColors(context);
        final region = _selectedRegion;
        final availableRegions = stampBookLines
            .expand((line) => line.regions)
            .toSet();
        final matches = stampBookLines
            .where(
              (line) =>
                  (region == null || line.regions.contains(region)) &&
                  _matches(line),
            )
            .toList();
        final companies = <String, List<StampLine>>{};
        for (final line in matches) {
          (companies[line.operator] ??= []).add(line);
        }
        final jrEast = yamanoteStampLine.operator;
        final expanded = _expandedOperators.contains(jrEast);
        final coachCompany =
            _continueTutorial && !expanded && companies.containsKey(jrEast);
        final coachExample =
            _continueTutorial &&
            expanded &&
            matches.any((line) => line.id == yamanoteStampLine.id);
        final page = Scaffold(
          key: const ValueKey('stamp-book-browse-page'),
          appBar: AppBar(
            title: Text(localized(context, '노선 둘러보기', 'Browse lines')),
            actions: [_help(context)],
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              scrollCacheExtent: coachCompany || coachExample
                  ? const ScrollCacheExtent.pixels(500)
                  : null,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                TextField(
                  key: const ValueKey('stamp-book-search'),
                  controller: _search,
                  style: const TextStyle(fontSize: 14),
                  onChanged: (query) => setState(() {
                    if (query.trim().isNotEmpty) {
                      _expandedOperators.addAll(
                        stampBookLines
                            .where(_matches)
                            .map((line) => line.operator),
                      );
                    }
                  }),
                  decoration: InputDecoration(
                    labelText: localized(
                      context,
                      '노선·회사·역 이름 검색',
                      'Search lines, operators, stations',
                    ),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: localized(
                              context,
                              '검색어 지우기',
                              'Clear search',
                            ),
                            onPressed: () => setState(_search.clear),
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: c.paper,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: c.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: c.line),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final choice in [null, ...availableRegions])
                      ChoiceChip(
                        key: ValueKey('stamp-book-region-${choice ?? 'all'}'),
                        label: Text(
                          localized(
                            context,
                            choice == null
                                ? '전체'
                                : (_bookStampRegions[choice]?.$1 ?? choice),
                            choice == null
                                ? 'All'
                                : (_bookStampRegions[choice]?.$2 ?? choice),
                          ),
                        ),
                        selected: region == choice,
                        onSelected: (_) =>
                            setState(() => _selectedRegion = choice),
                        selectedColor: c.teal,
                        backgroundColor: c.background,
                        checkmarkColor: c.onTeal,
                        labelStyle: TextStyle(
                          color: region == choice ? c.onTeal : c.ink,
                        ),
                        side: BorderSide(color: c.ticketOutline),
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                  ],
                ),
                _heading(
                  context,
                  localized(context, '회사별 노선', 'Lines by operator'),
                ),
                for (final MapEntry(key: operator, value: lines)
                    in companies.entries) ...[
                  KeyedSubtree(
                    key: operator == jrEast
                        ? _companyAnchor
                        : ValueKey('stamp-book-operator-$operator'),
                    child: _BookDisclosureHeading(
                      key: ValueKey(
                        operator == jrEast
                            ? 'stamp-book-company-toggle'
                            : 'stamp-book-company-$operator',
                      ),
                      title: localized(
                        context,
                        stampBookOperatorKorean(lines.first),
                        lines.first.operatorEnglish,
                      ),
                      expanded: _expandedOperators.contains(operator),
                      onTap: () => _toggleCompany(operator),
                    ),
                  ),
                  if (_expandedOperators.contains(operator))
                    ListenableBuilder(
                      listenable: widget.session,
                      builder: (context, _) => Column(
                        children: [
                          for (final line in lines)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _BookLineCard(
                                key: line.id == yamanoteStampLine.id
                                    ? _exampleAnchor
                                    : null,
                                session: widget.session,
                                line: line,
                                showOperator: false,
                                takeTutorial: line.id == yamanoteStampLine.id
                                    ? _takeTutorial
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
                if (companies.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      localized(context, '검색 결과가 없어요.', 'No matching lines.'),
                      style: TextStyle(color: c.muted, fontSize: 14),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  localized(
                    context,
                    '같은 운영사의 공통역은 도장과 수집 기록을 공유해요.',
                    'Lines from the same operator share stamps and collection records for common stations.',
                  ),
                  style: TextStyle(color: c.muted, fontSize: 12, height: 1.6),
                ),
              ],
            ),
          ),
        );
        return StampBookCoach(
          step: coachCompany
              ? StampBookCoachStep.operator
              : coachExample
              ? StampBookCoachStep.exampleLine
              : null,
          anchor: coachExample ? _exampleAnchor : _companyAnchor,
          onSkip: _skipTutorial,
          onAction: coachExample
              ? () => _openBookLine(
                  context,
                  widget.session,
                  yamanoteStampLine,
                  showTutorial: _takeTutorial(),
                )
              : () => _toggleCompany(yamanoteStampLine.operator),
          hasScan: false,
          child: page,
        );
      },
    ),
  );
}

class _BookStampRegionHeading extends StatelessWidget {
  const _BookStampRegionHeading({
    required this.title,
    required this.count,
    required this.expanded,
    required this.onTap,
    super.key,
  });

  final String title;
  final String count;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = StampBookColors(context);
    final tint = c.stamp;
    final surface = expanded
        ? Color.alphaBlend(tint.withValues(alpha: .10), c.paper)
        : c.paper;
    // A slightly deeper ink preserves contrast over the expanded badge.
    final countInk = c.dark ? tint : Color.lerp(tint, c.ink, .16)!;
    return Semantics(
      expanded: expanded,
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: c.ink,
          backgroundColor: surface,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          minimumSize: const Size(48, 48),
          visualDensity: VisualDensity.standard,
          side: BorderSide(
            color: expanded
                ? Color.alphaBlend(tint.withValues(alpha: .30), c.line)
                : c.line,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Color.alphaBlend(tint.withValues(alpha: .075), surface),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                child: Text(
                  count,
                  style: TextStyle(
                    color: countInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ExcludeSemantics(
              child: Icon(
                expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A text-only disclosure, without the large company card surface.
class _BookDisclosureHeading extends StatelessWidget {
  const _BookDisclosureHeading({
    required this.title,
    required this.expanded,
    required this.onTap,
    super.key,
  });
  final String title;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    expanded: expanded,
    child: TextButton(
      style: TextButton.styleFrom(
        foregroundColor: StampBookColors(context).ink,
        padding: const EdgeInsets.symmetric(vertical: 12),
        minimumSize: const Size(48, 48),
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onTap,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          ExcludeSemantics(
            child: Icon(
              expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              size: 22,
            ),
          ),
        ],
      ),
    ),
  );
}

class _BookLineCard extends StatelessWidget {
  const _BookLineCard({
    required this.session,
    required this.line,
    this.showOperator = true,
    this.takeTutorial,
    super.key,
  });
  final StationStampSession session;
  final StampLine line;
  final bool showOperator;
  final bool Function()? takeTutorial;

  @override
  Widget build(BuildContext context) {
    final c = StampBookColors(context);
    final count = session.countFor(line), total = line.stations.length;
    return _Paper(
      padding: EdgeInsets.zero,
      child: InkWell(
        key: ValueKey(switch (line.id) {
          'yamanote' => 'stamp-book-yamanote',
          'service:jr-east:chuo-sobu-local' => 'stamp-book-chuo-sobu',
          _ => 'stamp-book-line-${line.id}',
        }),
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openBookLine(
          context,
          session,
          line,
          showTutorial: takeTutorial?.call() ?? false,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      localized(
                        context,
                        stampBookLineKorean(line),
                        stampBookLineEnglish(line),
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded, color: c.teal),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (showOperator)
                    Text(
                      localized(
                        context,
                        stampBookOperatorKorean(line),
                        line.operatorEnglish,
                      ),
                      style: TextStyle(color: c.muted, fontSize: 12),
                    ),
                  Text(
                    '$count / $total',
                    style: TextStyle(color: c.muted, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              _bar(context, count / total),
            ],
          ),
        ),
      ),
    );
  }
}

void _openBookLine(
  BuildContext context,
  StationStampSession session,
  StampLine line, {
  required bool showTutorial,
}) {
  Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => line.id == yamanoteStampLine.id
          ? YamanoteStampBookLinePage(
              session: session,
              showTutorial: showTutorial,
            )
          : StampBookLinePage(
              session: session,
              line: line,
              showTutorial: showTutorial,
            ),
    ),
  );
}

class YamanoteStampBookLinePage extends StampBookLinePage {
  const YamanoteStampBookLinePage({
    required super.session,
    super.showTutorial,
    super.key,
  }) : super(line: yamanoteStampLine);
}

class StampBookLinePage extends StatefulWidget {
  const StampBookLinePage({
    required this.session,
    required this.line,
    this.showTutorial = false,
    super.key,
  });
  final StationStampSession session;
  final StampLine line;
  final bool showTutorial;
  @override
  State<StampBookLinePage> createState() => _StampBookLinePageState();
}

class _StampBookLinePageState extends State<StampBookLinePage> {
  final _mapAnchor = GlobalKey();
  late bool _showTutorial = widget.showTutorial;
  bool _map = false;
  bool _stationList = false;
  int _selected = 0;
  int _mapRevision = 0;
  bool _fitWholeRoute = false;
  final _transform = TransformationController();

  void _selectView(bool map) => setState(() {
    _map = map;
    if (map) _showTutorial = false;
  });
  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _zoom(double factor) {
    final old = _transform.value.entry(0, 0).abs();
    final next = (old * factor).clamp(
      StampBookDiagramKind.forLine(widget.line).minimumScale,
      3.0,
    );
    _transform.value = _transform.value.clone()
      ..scaleByDouble(next / old, next / old, 1, 1);
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: stampBookTheme(context),
    child: Builder(
      builder: (context) => ListenableBuilder(
        listenable: widget.session,
        builder: (context, _) {
          final c = StampBookColors(context), session = widget.session;
          final line = widget.line, stations = widget.line.stations;
          final diagram = StampBookDiagramKind.forLine(line);
          final total = stations.length;
          final count = session.countFor(line),
              mode = PassNameScope.of(context);
          final names = stations.map((s) => stampStationName(s, mode)).toList();
          final page = Scaffold(
            appBar: AppBar(
              title: Text(
                localized(
                  context,
                  stampBookLineKorean(line),
                  stampBookLineEnglish(line),
                ),
              ),
              actions: [_help(context)],
            ),
            body: SafeArea(
              top: false,
              child: ListView(
                scrollCacheExtent: _showTutorial
                    ? const ScrollCacheExtent.pixels(500)
                    : null,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  Text(
                    localized(
                      context,
                      stampBookOperatorKorean(line),
                      line.operatorEnglish,
                    ),
                    style: TextStyle(color: c.muted, fontSize: 12),
                  ),
                  if (diagram == StampBookDiagramKind.chuoSobu ||
                      diagram == StampBookDiagramKind.midosuji) ...[
                    const SizedBox(height: 6),
                    Text(
                      localized(
                        context,
                        diagram == StampBookDiagramKind.chuoSobu
                            ? '각역정차 · 미타카–치바'
                            : '에사카–나카모즈',
                        diagram == StampBookDiagramKind.chuoSobu
                            ? 'Local service · Mitaka–Chiba'
                            : 'Esaka–Nakamozu',
                      ),
                      style: TextStyle(color: c.muted, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$count / $total',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${(count / total * 100).round()}%',
                        style: TextStyle(
                          color: c.teal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _bar(context, count / total),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: c.line,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      children: [
                        for (final map in [false, true])
                          Expanded(
                            child: Semantics(
                              key: map ? _mapAnchor : null,
                              selected: _map == map,
                              child: TextButton(
                                key: ValueKey(
                                  map
                                      ? 'stamp-book-tab-map'
                                      : 'stamp-book-tab-stamps',
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor: _map == map
                                      ? c.teal
                                      : Colors.transparent,
                                  foregroundColor: _map == map
                                      ? c.onTeal
                                      : c.muted,
                                  minimumSize: const Size(48, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                ),
                                onPressed: () => _selectView(map),
                                child: Text(
                                  localized(
                                    context,
                                    map ? '노선도' : '스탬프',
                                    map ? 'Line diagram' : 'Stamps',
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!_map)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final scale = MediaQuery.textScalerOf(context).scale(1);
                        final bilingual =
                            mode == StationNameDisplayMode.both ||
                            mode == StationNameDisplayMode.japaneseEnglish;
                        final columns =
                            scale > 1.6 || constraints.maxWidth < 290
                            ? 1
                            : scale > 1.3
                            ? 2
                            : bilingual || scale > 1.1
                            ? 3
                            : 4;
                        final width =
                            (constraints.maxWidth - (columns - 1) * 8) /
                            columns;
                        return Wrap(
                          spacing: 8,
                          runSpacing: 16,
                          children: [
                            for (var i = 0; i < total; i++)
                              SizedBox(
                                width: width,
                                child: StampBookSeal.station(
                                  station: stations[i],
                                  collected: session.collected.contains(
                                    stations[i].id,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    )
                  else ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Visibility(
                                visible: !_stationList,
                                maintainSize: true,
                                maintainAnimation: true,
                                maintainState: true,
                                child: Text(
                                  key: const ValueKey('stamp-book-map-caption'),
                                  localized(
                                    context,
                                    '실제 역 위치 기반 · 북쪽이 위',
                                    'Station locations · north is up',
                                  ),
                                  style: TextStyle(
                                    color: c.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              key: const ValueKey(
                                'stamp-book-toggle-station-list',
                              ),
                              style: IconButton.styleFrom(
                                foregroundColor: c.teal,
                                minimumSize: const Size(48, 48),
                              ),
                              onPressed: () =>
                                  setState(() => _stationList = !_stationList),
                              icon: Icon(
                                _stationList
                                    ? Icons.route_outlined
                                    : Icons.format_list_bulleted_rounded,
                                size: 20,
                              ),
                              tooltip: localized(
                                context,
                                _stationList ? '노선도로 보기' : '역 목록으로 보기',
                                _stationList
                                    ? 'Show line diagram'
                                    : 'Show station list',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_stationList)
                          _BookStationList(
                            stations: stations,
                            names: names,
                            collected: session.collected,
                            routeColor: diagram.color,
                          ),
                        Visibility(
                          visible: !_stationList,
                          maintainState: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              YamanoteStampMap(
                                key: ValueKey('stamp-book-map-$_mapRevision'),
                                collected: session.collected,
                                mode: mode,
                                selected: _selected,
                                controller: _transform,
                                kind: diagram,
                                fitWhole: _fitWholeRoute,
                              ),
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: [
                                      for (final acquired in [true, false])
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Icon(
                                              acquired
                                                  ? Icons
                                                        .check_circle_outline_rounded
                                                  : Icons.circle_outlined,
                                              size: 14,
                                              color: acquired
                                                  ? c.teal
                                                  : c.muted,
                                            ),
                                            Text(
                                              localized(
                                                context,
                                                acquired ? '수집 완료' : '미수집',
                                                acquired
                                                    ? 'Collected'
                                                    : 'Not collected',
                                              ),
                                              style: TextStyle(
                                                color: c.muted,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () => _zoom(1 / 1.25),
                                        tooltip: localized(
                                          context,
                                          '축소',
                                          'Zoom out',
                                        ),
                                        icon: const Icon(Icons.remove_rounded),
                                      ),
                                      IconButton(
                                        onPressed: () => setState(() {
                                          if (diagram.focusesStation) {
                                            _fitWholeRoute = !_fitWholeRoute;
                                          }
                                          _mapRevision++;
                                        }),
                                        tooltip: !diagram.focusesStation
                                            ? localized(
                                                context,
                                                '원래 크기',
                                                'Reset view',
                                              )
                                            : localized(
                                                context,
                                                _fitWholeRoute
                                                    ? '역명 확대 보기'
                                                    : '전체 노선 보기',
                                                _fitWholeRoute
                                                    ? 'Readable station view'
                                                    : 'Fit entire line',
                                              ),
                                        icon: const Icon(
                                          Icons.center_focus_strong_outlined,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => _zoom(1.25),
                                        tooltip: localized(
                                          context,
                                          '확대',
                                          'Zoom in',
                                        ),
                                        icon: const Icon(Icons.add_rounded),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              StampBookStationPicker(
                                key: ValueKey('stamp-book-station-$mode'),
                                names: names,
                                line: line,
                                session: session,
                                selected: _selected,
                                onSelected: (i) {
                                  setState(() {
                                    _selected = i;
                                    if (diagram.focusesStation) {
                                      _fitWholeRoute = false;
                                      _mapRevision++;
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
          return StampBookCoach(
            step: _showTutorial ? StampBookCoachStep.diagram : null,
            anchor: _mapAnchor,
            onSkip: () => setState(() => _showTutorial = false),
            onAction: () => _selectView(true),
            hasScan: false,
            child: page,
          );
        },
      ),
    ),
  );
}

class _BookStationList extends StatelessWidget {
  const _BookStationList({
    required this.stations,
    required this.names,
    required this.collected,
    required this.routeColor,
  });
  final List<StampStation> stations;
  final List<String> names;
  final Set<String> collected;
  final Color routeColor;

  @override
  Widget build(BuildContext context) {
    final c = StampBookColors(context);
    return Container(
      key: const ValueKey('stamp-book-station-list'),
      decoration: BoxDecoration(
        color: c.paper,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (var i = 0; i < stations.length; i++)
            IntrinsicHeight(
              key: ValueKey('stamp-book-list-${stations[i].id}'),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 28,
                    child: ExcludeSemantics(
                      child: Column(
                        children: [
                          Expanded(
                            child: Center(
                              child: Container(
                                key: ValueKey('stamp-book-list-top-$i'),
                                width: 3,
                                color: i == 0 ? Colors.transparent : routeColor,
                              ),
                            ),
                          ),
                          Container(
                            key: ValueKey('stamp-book-list-dot-$i'),
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: collected.contains(stations[i].id)
                                  ? c.teal
                                  : c.paper,
                              border: Border.all(
                                color: collected.contains(stations[i].id)
                                    ? c.teal
                                    : c.ink,
                                width: 1.3,
                              ),
                            ),
                            child: collected.contains(stations[i].id)
                                ? Icon(
                                    Icons.check_rounded,
                                    size: 12,
                                    color: c.onTeal,
                                  )
                                : null,
                          ),
                          Expanded(
                            child: Center(
                              child: Container(
                                key: ValueKey('stamp-book-list-bottom-$i'),
                                width: 3,
                                color: i == stations.length - 1
                                    ? Colors.transparent
                                    : routeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        border: i == stations.length - 1
                            ? null
                            : Border(bottom: BorderSide(color: c.line)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            names[i],
                            style: TextStyle(
                              color: c.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            localized(
                              context,
                              collected.contains(stations[i].id)
                                  ? '수집 완료'
                                  : '미수집',
                              collected.contains(stations[i].id)
                                  ? 'Collected'
                                  : 'Not collected',
                            ),
                            style: TextStyle(color: c.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Paper extends StatelessWidget {
  const _Paper({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    super.key,
  });
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final c = StampBookColors(context);
    return Material(
      color: color ?? c.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.line),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

Widget _metric(BuildContext context, String label, String value) => Wrap(
  spacing: 12,
  runSpacing: 4,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: [
    Text(
      label,
      style: TextStyle(fontSize: 12, color: StampBookColors(context).muted),
    ),
    Text(
      value,
      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
    ),
  ],
);
Widget _heading(BuildContext context, String title) => Padding(
  padding: const EdgeInsets.only(top: 24, bottom: 12),
  child: Text(
    title,
    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
  ),
);
Widget _bar(BuildContext context, double value) => LinearProgressIndicator(
  value: value,
  minHeight: 5,
  borderRadius: BorderRadius.circular(8),
  color: StampBookColors(context).stamp,
  backgroundColor: StampBookColors(context).line,
);

class _CollectionStatus extends StatelessWidget {
  const _CollectionStatus({required this.session});
  final StationStampSession session;
  @override
  Widget build(BuildContext context) {
    final loading = !session.ready && !session.loadFailed;
    if (!loading && !session.loadFailed && !session.saveFailed) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localized(
              context,
              loading
                  ? '수집 기록을 불러오는 중이에요.'
                  : session.loadFailed
                  ? '기존 수집 기록을 불러오지 못했어요. 덮어쓰지 않고 기다릴게요.'
                  : '변경 내용을 저장하지 못했어요. 앱을 닫기 전에 다시 시도해 주세요.',
              loading
                  ? 'Loading your collection.'
                  : session.loadFailed
                  ? 'Could not load the existing collection. Nothing will be overwritten.'
                  : 'Could not save changes. Retry before closing the app.',
            ),
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: StampBookColors(context).muted,
            ),
          ),
          if (!loading)
            TextButton(
              onPressed: () =>
                  session.loadFailed ? session.restore() : session.retrySave(),
              child: Text(localized(context, '다시 시도', 'Retry')),
            ),
        ],
      ),
    );
  }
}

Widget _help(BuildContext context, {VoidCallback? onReplay}) => IconButton(
  tooltip: localized(context, '수집 안내', 'About collection'),
  icon: const Icon(Icons.info_outline_rounded),
  onPressed: () async {
    final replay = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: StampBookColors(context).paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                localized(context, '여행 스탬프 수첩', 'Travel stamp book'),
                style: TextStyle(
                  color: StampBookColors(context).ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                localized(
                  context,
                  '이용내역에서 확인된 승차·하차역을 수집해요. 같은 운영사의 역은 노선 간 공유되며, 방문 인증은 아니에요.\n\n노선도는 실제 선로가 아닌 역 위치 도식이에요. 두 손가락으로 확대·이동, 한 손가락으로 스크롤해요.\n\n도장은 앱의 창작물로 공식 역 도장·철도 로고가 아니에요.\n\n수집한 역 식별자만 기기에 저장해요. 원본 이용내역·카드 정보는 저장·전송하지 않아요. 전체 삭제는 설정에서 할 수 있어요.',
                  'Collect confirmed boarding and alighting stations from card history. Stations are shared across lines of the same operator; this is not proof of a visit.\n\nThe diagram shows station locations, not actual tracks. Use two fingers to zoom or pan, and one finger to scroll.\n\nStamps are app creations, not official station stamps or railway logos.\n\nOnly collected station IDs are saved on this device. Raw history and card details are not stored or uploaded. Delete all stamps in Settings.',
                ),
                style: TextStyle(
                  color: StampBookColors(context).ink,
                  height: 1.7,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              if (onReplay != null)
                TextButton.icon(
                  key: const ValueKey('stamp-book-coach-replay'),
                  onPressed: () => Navigator.pop(sheetContext, true),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    localized(context, '튜토리얼 다시 보기', 'Replay tutorial'),
                  ),
                ),
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: Text(localized(context, '확인', 'Got it')),
              ),
            ],
          ),
        ),
      ),
    );
    if (replay == true && context.mounted) onReplay?.call();
  },
);
