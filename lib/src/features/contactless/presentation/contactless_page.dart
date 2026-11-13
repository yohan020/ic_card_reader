import 'package:flutter/material.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/widgets/app_ui.dart';
import '../data/contactless_repository.dart';
import '../domain/contactless_catalog.dart';
import '../domain/contactless_english_details.dart';
import '../domain/contactless_station_name.dart';
import '../../station_resolver/domain/station_name_display.dart';
import 'contactless_guidance_dialog.dart';

const _regions = <String?, String>{
  null: '전국',
  'kanto': '간토',
  'chubu': '주부',
  'kansai': '간사이',
  'kyushu': '규슈',
  'hokkaido': '홋카이도',
  'tohoku': '도호쿠',
  'chugoku': '주고쿠',
  'shikoku': '시코쿠',
  'okinawa': '오키나와',
};

const _englishRegions = <String?, String>{
  null: 'All Japan',
  'kanto': 'Kanto',
  'chubu': 'Chubu',
  'kansai': 'Kansai',
  'kyushu': 'Kyushu',
  'hokkaido': 'Hokkaido',
  'tohoku': 'Tohoku',
  'chugoku': 'Chugoku',
  'shikoku': 'Shikoku',
  'okinawa': 'Okinawa',
};

class ContactlessPage extends StatefulWidget {
  const ContactlessPage({
    super.key,
    this.load,
    this.stationNameDisplayMode = StationNameDisplayMode.japanese,
  });
  final Future<ContactlessCatalog> Function()? load;
  final StationNameDisplayMode stationNameDisplayMode;
  @override
  State<ContactlessPage> createState() => _ContactlessPageState();
}

class _ContactlessPageState extends State<ContactlessPage> {
  final _repository = ContactlessRepository();
  final _query = TextEditingController();
  final _scroll = ScrollController();
  final _regionScroll = ScrollController();
  final _expanded = <String>{};
  final _searchCollapsed = <String>{};
  String? _region;
  late Future<ContactlessCatalog> _future;
  @override
  void initState() {
    super.initState();
    _future = (widget.load ?? _repository.load)();
  }

  @override
  void dispose() {
    _query.dispose();
    _scroll.dispose();
    _regionScroll.dispose();
    super.dispose();
  }

  void _changed() => setState(() => _searchCollapsed.clear());
  @override
  Widget build(BuildContext context) {
    final colors = _ListColors.of(context);
    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.header,
        title: Text(localized(context, '컨택리스 노선', 'Contactless routes')),
        actions: [
          IconButton(
            tooltip: localized(context, '컨택리스 안내', 'Tap-to-ride guide'),
            icon: const Icon(Icons.info_outline),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => const ContactlessGuidanceDialog(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<ContactlessCatalog>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        localized(
                          context,
                          '노선 정보를 불러오지 못했어요.',
                          'Couldn’t load the routes.',
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () {
                          final next = (widget.load ?? _repository.load)();
                          setState(() {
                            _future = next;
                          });
                        },
                        child: Text(localized(context, '다시 불러오기', 'Try again')),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final catalog = snapshot.requireData;
            final matches = catalog.search(_query.text, _region);
            final groups = <String, List<ContactlessLine>>{};
            for (final line in matches) {
              groups.putIfAbsent(line.operatorId, () => []).add(line);
            }
            final ordered = groups.values.toList()
              ..sort((a, b) => compareContactlessOperators(a.first, b.first));
            final entries = <Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  localized(context, '회사별 노선', 'Routes by operator'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.muted,
                  ),
                ),
              ),
            ];
            for (final group in ordered) {
              group.sort((a, b) => a.name.compareTo(b.name));
              final id = group.first.operatorId;
              final hidden = _query.text.trim().isEmpty
                  ? !_expanded.contains(id)
                  : _searchCollapsed.contains(id);
              entries.add(
                Padding(
                  key: ValueKey('group-$id'),
                  padding: EdgeInsets.only(bottom: hidden ? 10 : 0),
                  child: Card(
                    color: hidden ? colors.card : colors.expanded,
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: const Radius.circular(14),
                        bottom: Radius.circular(hidden ? 14 : 0),
                      ),
                    ),
                    key: ValueKey('company-$id'),
                    clipBehavior: Clip.antiAlias,
                    child: Semantics(
                      expanded: !hidden,
                      child: InkWell(
                        onTap: () => setState(() {
                          final set = _query.text.trim().isEmpty
                              ? _expanded
                              : _searchCollapsed;
                          if (!set.add(id)) set.remove(id);
                        }),
                        child: _CompanyHeading(
                          name: group.first.operatorNameFor(
                            english: usesEnglish(context),
                          ),
                          count: group.length,
                          expanded: !hidden,
                          colors: colors,
                        ),
                      ),
                    ),
                  ),
                ),
              );
              // Separate lazily-created rows preserve predictable memory use with a large operator.
              if (!hidden) {
                for (final line in group) {
                  entries.add(
                    Padding(
                      key: ValueKey('row-${line.id}'),
                      padding: EdgeInsets.only(
                        bottom: identical(line, group.last) ? 10 : 0,
                      ),
                      child: Card(
                        color: colors.card,
                        elevation: 0,
                        margin: EdgeInsets.zero,
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(
                              identical(line, group.last) ? 14 : 0,
                            ),
                          ),
                        ),
                        key: ValueKey('line-${line.id}'),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => ContactlessDetailPage(
                                line: line,
                                attribution: catalog.attribution,
                                stationNameDisplayMode:
                                    widget.stationNameDisplayMode,
                              ),
                            ),
                          ),
                          child: _RouteRow(
                            line: line,
                            colors: colors,
                            separator: !identical(line, group.first),
                          ),
                        ),
                      ),
                    ),
                  );
                }
              }
            }
            if (matches.isEmpty) {
              entries.add(
                AppSurface(
                  child: Column(
                    children: [
                      Text(
                        catalog.lines.isEmpty
                            ? localized(
                                context,
                                '등록된 노선 정보가 없어요.',
                                'No routes are listed.',
                              )
                            : localized(
                                context,
                                '일치하는 노선이 없어요.',
                                'No matching routes.',
                              ),
                      ),
                      if (_query.text.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            _query.clear();
                            _changed();
                          },
                          child: Text(
                            localized(context, '검색 지우기', 'Clear search'),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }
            entries.add(
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  localized(
                    context,
                    '자료 기준: 2026.10.29~30 · 실시간 정보가 아니에요.\n${catalog.attribution}',
                    'Research snapshot: Oct 29–30, 2026 · Not live.\n$contactlessEnglishAttribution',
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.muted,
                    height: 1.6,
                  ),
                ),
              ),
            );
            return Column(
              children: [
                ColoredBox(
                  color: colors.header,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
                    child: TextField(
                      controller: _query,
                      onChanged: (_) => _changed(),
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: localized(
                          context,
                          '노선명·회사명·역명 검색',
                          'Search lines, operators or stations',
                        ),
                        hintStyle: TextStyle(color: colors.muted),
                        filled: true,
                        fillColor: colors.card,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(13)),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(13)),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide(
                            color: AppColors.accent(context),
                            width: 2,
                          ),
                        ),
                        prefixIcon: Icon(Icons.search, color: colors.muted),
                        suffixIcon: _query.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: localized(
                                  context,
                                  '검색 지우기',
                                  'Clear search',
                                ),
                                onPressed: () {
                                  _query.clear();
                                  _changed();
                                },
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 76,
                        child: Material(
                          key: const ValueKey('contactless-region-rail'),
                          color: colors.card,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(17),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ListView(
                            controller: _regionScroll,
                            padding: const EdgeInsets.fromLTRB(6, 12, 6, 16),
                            children: [
                              for (final region in _regions.entries)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Semantics(
                                    key: ValueKey(
                                      'region-${region.key ?? 'all'}',
                                    ),
                                    selected: _region == region.key,
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                        backgroundColor: _region == region.key
                                            ? AppColors.softSurface(context)
                                            : Colors.transparent,
                                        foregroundColor: _region == region.key
                                            ? AppColors.accent(context)
                                            : colors.muted,
                                        minimumSize: const Size(48, 49),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 3,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        textStyle: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              fontSize: 14,
                                              fontWeight: _region == region.key
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                      ),
                                      onPressed: () => setState(() {
                                        _region = region.key;
                                        _searchCollapsed.clear();
                                      }),
                                      child: Text(
                                        localized(
                                          context,
                                          region.value,
                                          _englishRegions[region.key]!,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          key: const ValueKey('contactless-companies'),
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(12, 16, 12, 28),
                          itemCount: entries.length,
                          itemBuilder: (_, i) => entries[i],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Scoped to the approved B list. Other app surfaces keep the shared theme.
class _ListColors {
  const _ListColors(
    this.canvas,
    this.header,
    this.card,
    this.expanded,
    this.muted,
    this.separator,
  );
  factory _ListColors.of(BuildContext context) => AppColors.isDark(context)
      ? const _ListColors(
          Color(0xFF10171C),
          Color(0xFF142630),
          Color(0xFF182229),
          Color(0xFF1A3D4E),
          Color(0xFFB5C6CF),
          Color(0xFF2D3B43),
        )
      : const _ListColors(
          Color(0xFFF1F6FA),
          Color(0xFFECF6FC),
          Colors.white,
          Color(0xFFDDEFFB),
          Color(0xFF526570),
          Color(0xFFEDF2F5),
        );
  final Color canvas, header, card, expanded, muted, separator;
}

class _CompanyHeading extends StatelessWidget {
  const _CompanyHeading({
    required this.name,
    required this.count,
    required this.expanded,
    required this.colors,
  });
  final String name;
  final int count;
  final bool expanded;
  final _ListColors colors;
  @override
  Widget build(BuildContext context) {
    final foreground = expanded
        ? (AppColors.isDark(context)
              ? AppColors.accent(context)
              : const Color(0xFF075F88))
        : null;
    final nameWidget = Text(
      name,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: foreground,
      ),
    );
    final countWidget = Semantics(
      label: localized(context, '$count개 노선', '$count routes'),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: expanded ? colors.card.withValues(alpha: .65) : colors.canvas,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Text(
            localized(context, '$count개', '$count'),
            style: TextStyle(
              fontSize: 12,
              color: expanded ? foreground : colors.muted,
            ),
          ),
        ),
      ),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 65),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked =
                constraints.maxWidth < 180 ||
                MediaQuery.textScalerOf(context).scale(15) > 21;
            return Row(
              children: [
                Expanded(
                  child: stacked
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            nameWidget,
                            const SizedBox(height: 6),
                            countWidget,
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: nameWidget),
                            const SizedBox(width: 6),
                            countWidget,
                          ],
                        ),
                ),
                const SizedBox(width: 6),
                ExcludeSemantics(
                  child: Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: colors.muted,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.line,
    required this.colors,
    required this.separator,
  });
  final ContactlessLine line;
  final _ListColors colors;
  final bool separator;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 55),
    decoration: BoxDecoration(
      border: separator
          ? Border(top: BorderSide(color: colors.separator))
          : null,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            constraints.maxWidth < 225 ||
            MediaQuery.textScalerOf(context).scale(14) > 19;
        final name = Text(
          line.nameFor(english: usesEnglish(context)),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.55,
          ),
        );
        final badge = ContactlessBadge(line: line, compact: true);
        return Row(
          children: [
            Expanded(
              child: stacked
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [name, const SizedBox(height: 6), badge],
                    )
                  : Row(
                      children: [
                        Expanded(child: name),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 110),
                          child: badge,
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: 6),
            ExcludeSemantics(
              child: Icon(Icons.chevron_right, size: 18, color: colors.muted),
            ),
          ],
        );
      },
    ),
  );
}

class ContactlessBadge extends StatelessWidget {
  const ContactlessBadge({super.key, required this.line, this.compact = false});
  final ContactlessLine line;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final color = switch (line.status) {
      'supported' => isDark ? const Color(0xFF91D9B0) : const Color(0xFF17623F),
      'partial' => isDark ? const Color(0xFFFFD09A) : const Color(0xFF8A4D05),
      _ =>
        compact && !isDark
            ? const Color(0xFF526570)
            : AppColors.mutedText(context),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 3 : 6,
        ),
        child: Text(
          line.labelFor(english: usesEnglish(context)),
          textWidthBasis: TextWidthBasis.longestLine,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: compact ? FontWeight.w600 : FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class ContactlessDetailPage extends StatelessWidget {
  const ContactlessDetailPage({
    super.key,
    required this.line,
    required this.attribution,
    this.stationNameDisplayMode = StationNameDisplayMode.japanese,
  });
  final ContactlessLine line;
  final String attribution;
  final StationNameDisplayMode stationNameDisplayMode;
  String _stationName(Map<String, dynamic> station) =>
      displayContactlessStationName(
        lineId: line.id,
        stationId: station['id'] as String,
        japanese: station['name'] as String,
        mode: stationNameDisplayMode,
      );
  @override
  Widget build(BuildContext context) {
    final stations = [...line.records('stations')]
      ..sort((a, b) {
        final byName = _stationName(a).compareTo(_stationName(b));
        return byName != 0
            ? byName
            : (a['id'] as String).compareTo(b['id'] as String);
      });
    final knownGates = stations
        .where((s) => (s['gates'] as List).isNotEmpty)
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(localized(context, '노선 상세', 'Route details'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: ContactlessBadge(line: line),
            ),
            const SizedBox(height: 16),
            Text(
              line.nameFor(english: usesEnglish(context)),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              usesEnglish(context)
                  ? line.operatorNameFor(english: true)
                  : '${line.operatorDisplayName} · ${line.nameJa}',
              style: TextStyle(color: AppColors.mutedText(context)),
            ),
            if (line.lineAliases.any((alias) => alias.section != null)) ...[
              const SizedBox(height: 12),
              for (final alias in line.lineAliases.where(
                (alias) => alias.section != null,
              ))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    localized(
                      context,
                      '${alias.ko}: ${alias.section} 구간의 안내명이에요.',
                      contactlessEnglishSection(alias.ko),
                    ),
                    style: TextStyle(color: AppColors.mutedText(context)),
                  ),
                ),
            ],
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: AppColors.softSurface(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      line.summaryLabelFor(english: usesEnglish(context)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        line.summaryValueFor(english: usesEnglish(context)),
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (line.connectionOnly)
              NoticeBanner(
                text: localized(
                  context,
                  '접속역 한 곳만 대상이에요. 이 노선 내부 구간의 이용 가능을 뜻하지 않아요.',
                  'Only one connecting station is covered. This does not mean rides within this line are covered.',
                ),
                tone: NoticeTone.warning,
              )
            else if (line.status == 'partial')
              NoticeBanner(
                text: localized(
                  context,
                  '대상역과 전용 단말을 확인해 주세요. 직통·환승 경로 전체의 이용을 보장하지 않아요.',
                  'Check the eligible stations and readers. Through services and transfers may not be covered.',
                ),
              )
            else if (line.status == 'supported')
              NoticeBanner(
                text: localized(
                  context,
                  '모든 개찰구·카드가 대상이라는 뜻은 아니에요. 이용 조건을 확인해 주세요.',
                  'Not all gates or cards are covered. Check the travel conditions.',
                ),
              )
            else if (line.status == 'unknown')
              NoticeBanner(
                text: localized(
                  context,
                  '공식 안내만으로 지원 여부를 확인하지 못했어요.',
                  'The official information does not confirm whether tap-to-ride is supported.',
                ),
              ),
            if (line.strings('conditions').isNotEmpty) ...[
              const SizedBox(height: 20),
              SectionLabel(localized(context, '이용 전 확인', 'Before you travel')),
              AppSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: line
                      .strings('conditions')
                      .map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            usesEnglish(context)
                                ? contactlessEnglishCondition(s)
                                : s,
                            style: const TextStyle(height: 1.6),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            if (stations.isNotEmpty) ...[
              const SizedBox(height: 24),
              SectionLabel(localized(context, '역별 지원 여부', 'Station coverage')),
              Text(
                localized(
                  context,
                  '해당 운영사 전용 단말 기준 · 역 이름순',
                  'Designated readers only · sorted by station name',
                ),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedText(context),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: stations
                        .map(
                          (s) => Padding(
                            key: ValueKey('contactless-station-${s['id']}'),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: Text(_stationName(s))),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    s['eligible'] == true
                                        ? localized(
                                            context,
                                            '대상 단말 이용',
                                            'Use a designated reader',
                                          )
                                        : localized(
                                            context,
                                            '대상 아님',
                                            'Not covered',
                                          ),
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: s['eligible'] == true
                                          ? AppColors.accent(context)
                                          : AppColors.mutedText(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                localized(
                  context,
                  '대상역에서도 지정된 단말을 사용해 주세요. 확인되지 않은 개찰구 위치는 안내하지 않아요.',
                  'Use a designated reader at eligible stations. Gate locations are shown only when verified.',
                ),
                style: TextStyle(
                  fontSize: 12,
                  height: 1.6,
                  color: AppColors.mutedText(context),
                ),
              ),
            ],
            if (knownGates.isNotEmpty) ...[
              const SizedBox(height: 20),
              SectionLabel(localized(context, '개찰구 안내', 'Ticket gates')),
              AppSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: knownGates
                      .map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _stationName(s),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              ...(s['gates'] as List).map(
                                (g) => Text(
                                  '${usesEnglish(context) ? contactlessEnglishGate(g['name'] as String) : g['name']} · ${switch (g['direction']) {
                                    'entry_only' => localized(context, '입장 전용', 'Entry only'),
                                    'exit_only' => localized(context, '퇴장 전용', 'Exit only'),
                                    'entry_and_exit' => localized(context, '입·퇴장', 'Entry and exit'),
                                    _ => localized(context, '방향 미확인', 'Direction unverified'),
                                  }}',
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 20),
            _DetailExpansion(
              title: localized(
                context,
                '결제수단·세부 이용 조건',
                'Payment and travel conditions',
              ),
              children: [
                Text(
                  line.strings('brands').isEmpty
                      ? localized(
                          context,
                          '브랜드별 지원 정보 미확인',
                          'Accepted card brands have not been confirmed',
                        )
                      : localized(
                          context,
                          '실물 카드: ${line.strings('brands').join(', ')}',
                          'Physical cards: ${line.strings('brands').join(', ')}',
                        ),
                  style: const TextStyle(height: 1.6),
                ),
                const SizedBox(height: 8),
                Text(
                  line.data['mobileSupported'] == true
                      ? localized(
                          context,
                          '모바일 일반 지원 · 지갑·발급사별 호환은 별도 확인이 필요해요.',
                          'Mobile payments are supported. Check compatibility with your wallet and card issuer.',
                        )
                      : localized(
                          context,
                          '모바일 세부 지원 정보 미확인',
                          'Mobile payment details have not been confirmed',
                        ),
                  style: const TextStyle(height: 1.6),
                ),
                if (line.data['mobileBrands'] != null)
                  Text(
                    localized(
                      context,
                      '확인된 모바일 브랜드: ${line.strings('mobileBrands').join(', ')}',
                      'Confirmed mobile brands: ${line.strings('mobileBrands').join(', ')}',
                    ),
                    style: const TextStyle(height: 1.6),
                  ),
                for (final item in line.strings('unresolved'))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      localized(
                        context,
                        '미확인: $item',
                        'Unverified: ${contactlessEnglishUnresolved(item)}',
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _DetailExpansion(
              title: localized(context, '판단 근거 및 출처', 'Evidence and sources'),
              children: [
                Text(
                  usesEnglish(context)
                      ? contactlessEnglishReason(line.status)
                      : line.data['reason'] as String,
                  style: const TextStyle(height: 1.7),
                ),
                const SizedBox(height: 16),
                if (line.records('sources').isEmpty)
                  Text(
                    localized(
                      context,
                      '확보한 근거 정보가 부족해요.',
                      'No supporting sources were confirmed.',
                    ),
                  )
                else
                  ...line
                      .records('sources')
                      .map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            localized(
                              context,
                              '${s['title']}\n자료 확인일 ${s['date']}',
                              contactlessEnglishSource(s),
                            ),
                            style: const TextStyle(height: 1.6),
                          ),
                        ),
                      ),
                Text(
                  localized(
                    context,
                    '지원 여부 확인일 ${line.data['checkedOn']}',
                    'Support checked on ${line.data['checkedOn']}',
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedText(context),
                  ),
                ),
                if (line.data['effectiveOn'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      localized(
                        context,
                        '관련 안내 날짜: ${line.data['effectiveOn']}\n일부 도입·범위 변경 기준일일 수 있으며 역별 최초 시행일을 뜻하지 않아요.',
                        'Related announcement date: ${line.data['effectiveOn']}\nThis may refer to a partial rollout or coverage change, not each station’s launch date.',
                      ),
                      style: const TextStyle(fontSize: 12, height: 1.6),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              localized(context, attribution, contactlessEnglishAttribution),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.mutedText(context),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailExpansion extends StatelessWidget {
  const _DetailExpansion({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      shape: const Border(),
      collapsedShape: const Border(),
      maintainState: true,
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    ),
  );
}
