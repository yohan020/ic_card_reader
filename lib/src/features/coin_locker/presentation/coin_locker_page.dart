import 'package:flutter/material.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/localization/app_strings.dart';
import '../../station_resolver/domain/station_name_display.dart';
import '../data/coin_locker_link_opener.dart';
import '../data/coin_locker_repository.dart';
import '../domain/coin_locker_catalog.dart';

/// Reuses the approved station browser for another curated external guide.
/// Locker parsing and URL policy remain unchanged when this is absent.
class StationGuidePresentation {
  const StationGuidePresentation({
    required this.titleKo,
    required this.titleEn,
    required this.footerKo,
    required this.footerEn,
    required this.expandedContent,
    this.helpButton,
    this.showFooter = true,
  });
  final String titleKo, titleEn, footerKo, footerEn;
  final Widget Function(BuildContext, CoinLockerPlace) expandedContent;
  final Widget? helpButton;
  final bool showFooter;
}

/// Approved A refinement: one card per place with compact source groups.
class CoinLockerPage extends StatefulWidget {
  const CoinLockerPage({
    super.key,
    this.load,
    this.openLink,
    this.stationNameDisplayMode = StationNameDisplayMode.japanese,
    this.guide,
  });
  final Future<CoinLockerCatalog> Function()? load;
  final Future<bool> Function(Uri)? openLink;
  final StationNameDisplayMode stationNameDisplayMode;
  final StationGuidePresentation? guide;

  @override
  State<CoinLockerPage> createState() => _CoinLockerPageState();
}

class _CoinLockerPageState extends State<CoinLockerPage> {
  final _repository = CoinLockerRepository();
  final _query = TextEditingController();
  final _scroll = ScrollController();
  late Future<CoinLockerCatalog> _future;
  String? _region;
  String? _expanded;
  Uri? _opening;
  Uri? _failedLink;

  @override
  void initState() {
    super.initState();
    _future = (widget.load ?? _repository.load)();
  }

  @override
  void dispose() {
    _query.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _filter({String? region, bool regionChanged = false}) {
    setState(() {
      if (regionChanged) _region = region;
      _expanded = null;
      _failedLink = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _open(Uri uri) async {
    if (_opening != null) return;
    setState(() {
      _opening = uri;
      _failedLink = null;
    });
    var opened = false;
    try {
      opened = await (widget.openLink ?? const CoinLockerLinkOpener().open)(
        uri,
      );
    } catch (_) {
      // A failed launcher is recoverable; never log URLs or session contents.
    }
    if (!mounted) return;
    setState(() {
      _opening = null;
      _failedLink = opened ? null : uri;
    });
  }

  @override
  Widget build(BuildContext context) {
    final header = AppColors.toolListBackground(context);
    return Scaffold(
      backgroundColor: AppColors.toolListBackground(context),
      appBar: AppBar(
        actions: widget.guide?.helpButton == null
            ? null
            : [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: widget.guide!.helpButton!,
                ),
              ],
        title: Text(
          localized(
            context,
            widget.guide?.titleKo ?? '코인락커 찾기',
            widget.guide?.titleEn ?? 'Find coin lockers',
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<CoinLockerCatalog>(
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
                          widget.guide == null
                              ? '코인락커 안내를 불러오지 못했어요.'
                              : '역 구내도를 불러오지 못했어요.',
                          widget.guide == null
                              ? 'Couldn’t load the locker guides.'
                              : 'Couldn’t load the station maps.',
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => setState(() {
                          _future = (widget.load ?? _repository.load)();
                        }),
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
            final matches = catalog.search(_query.text, region: _region);
            return Column(
              children: [
                ColoredBox(
                  color: header,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Semantics(
                      label: localized(
                        context,
                        '역 이름 검색',
                        'Search for a station',
                      ),
                      child: TextField(
                        controller: _query,
                        onChanged: (_) => _filter(),
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: localized(
                            context,
                            widget.guide == null
                                ? '한국어·일본어 역 이름 검색'
                                : '역 이름 검색',
                            'Search station names',
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.mutedText(context),
                          ),
                          hintStyle: TextStyle(
                            color: AppColors.mutedText(context),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          suffixIcon: _query.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: localized(
                                    context,
                                    '검색어 지우기',
                                    'Clear search',
                                  ),
                                  onPressed: () {
                                    _query.clear();
                                    _filter();
                                  },
                                  icon: const Icon(Icons.close, size: 20),
                                ),
                          filled: true,
                          fillColor: AppColors.toolRegionBackground(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide: BorderSide(
                              color: AppColors.outline(context),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide: BorderSide(
                              color: AppColors.outline(context),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide: BorderSide(
                              color: AppColors.accent(context),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final scale =
                          MediaQuery.textScalerOf(context).scale(13) / 13;
                      // English region names need the incumbent width to avoid
                      // splitting a short name such as Kanagawa mid-word.
                      final railBaseWidth = usesEnglish(context) ? 88.0 : 76.0;
                      final railWidth = (railBaseWidth * scale).clamp(
                        railBaseWidth,
                        constraints.maxWidth * .38,
                      );
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: railWidth,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(17),
                              ),
                              child: ColoredBox(
                                key: const ValueKey(
                                  'station-guide-region-background',
                                ),
                                color: AppColors.toolRegionBackground(context),
                                child: ListView(
                                  key: const PageStorageKey('locker-regions'),
                                  padding: const EdgeInsets.fromLTRB(
                                    6,
                                    12,
                                    6,
                                    16,
                                  ),
                                  children: [
                                    for (final region in <String?>[
                                      null,
                                      ...catalog.regions,
                                    ])
                                      _RegionButton(
                                        region: region,
                                        selected: region == _region,
                                        onTap: () => _filter(
                                          region: region,
                                          regionChanged: true,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              controller: _scroll,
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                12,
                                20,
                                28,
                              ),
                              itemCount: matches.length + 2,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: Wrap(
                                      spacing: 10,
                                      runSpacing: 4,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          localized(
                                            context,
                                            '${_shortRegion(_region)}의 역·공항',
                                            _region == null
                                                ? 'Stations & airports'
                                                : '${_englishRegion(_region)} stations & airports',
                                          ),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          localized(
                                            context,
                                            '${matches.length}곳',
                                            '${matches.length} places',
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.mutedText(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                if (index == matches.length + 1) {
                                  if (matches.isNotEmpty &&
                                      widget.guide?.showFooter == false) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Text(
                                      matches.isEmpty
                                          ? localized(
                                              context,
                                              '연결된 안내를 찾지 못했어요.\n다른 역 이름이나 지역으로 검색해 주세요.',
                                              'No matching guides.\nTry another station or region.',
                                            )
                                          : localized(
                                              context,
                                              widget.guide?.footerKo ??
                                                  '외부 사이트의 위치 안내를 연결해요.\n실시간 빈자리·예약 정보는 아니에요.',
                                              widget.guide?.footerEn ??
                                                  'Links show locker locations, not live availability or reservations.',
                                            ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 1.65,
                                        color: AppColors.mutedText(context),
                                      ),
                                    ),
                                  );
                                }
                                final place = matches[index - 1];
                                return _PlaceCard(
                                  key: ValueKey('locker-place-${place.id}'),
                                  place: place,
                                  customBody: _expanded == place.id
                                      ? widget.guide?.expandedContent(
                                          context,
                                          place,
                                        )
                                      : null,
                                  stationNameDisplayMode:
                                      widget.stationNameDisplayMode,
                                  expanded: _expanded == place.id,
                                  opening: _opening,
                                  failedLink: _failedLink,
                                  onOpen: _open,
                                  onToggle: () => setState(() {
                                    _expanded = _expanded == place.id
                                        ? null
                                        : place.id;
                                    _failedLink = null;
                                  }),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
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

String _shortRegion(String? region) => region == null
    ? '전체'
    : region == '홋카이도'
    ? region
    : region.replaceFirst(RegExp(r'[도부현]$'), '');

String _englishRegion(String? region) => switch (region) {
  null => 'All',
  '도쿄도' => 'Tokyo',
  '오사카부' => 'Osaka',
  '후쿠오카현' => 'Fukuoka',
  '지바현' => 'Chiba',
  '교토부' => 'Kyoto',
  '홋카이도' => 'Hokkaido',
  '오이타현' => 'Oita',
  '오키나와현' => 'Okinawa',
  '아이치현' => 'Aichi',
  '가나가와현' => 'Kanagawa',
  _ => 'Other',
};

class _RegionButton extends StatelessWidget {
  const _RegionButton({
    required this.region,
    required this.selected,
    required this.onTap,
  });
  final String? region;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.softSurface(context) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 49),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 12),
            alignment: Alignment.center,
            child: Text(
              localized(context, _shortRegion(region), _englishRegion(region)),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? AppColors.accent(context)
                    : AppColors.mutedText(context),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    super.key,
    required this.place,
    required this.stationNameDisplayMode,
    required this.expanded,
    required this.opening,
    required this.failedLink,
    required this.onOpen,
    required this.onToggle,
    this.customBody,
  });
  final CoinLockerPlace place;
  final StationNameDisplayMode stationNameDisplayMode;
  final bool expanded;
  final Uri? opening;
  final Uri? failedLink;
  final Future<void> Function(Uri) onOpen;
  final VoidCallback onToggle;
  final Widget? customBody;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: AppColors.toolRegionBackground(context),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: expanded,
            child: InkWell(
              key: ValueKey('locker-toggle-${place.id}'),
              onTap: onToggle,
              child: Ink(
                color: expanded ? AppColors.softSurface(context) : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stationNameDisplayMode ==
                                    StationNameDisplayMode.english
                                ? place.nameEn ?? place.nameJa
                                : stationNameDisplayMode ==
                                          StationNameDisplayMode.japanese ||
                                      stationNameDisplayMode ==
                                          StationNameDisplayMode
                                              .japaneseEnglish ||
                                      !_hasKoreanName(place)
                                ? place.nameJa
                                : place.nameKo,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if ((stationNameDisplayMode ==
                                      StationNameDisplayMode.both &&
                                  _hasKoreanName(place)) ||
                              (stationNameDisplayMode ==
                                      StationNameDisplayMode.japaneseEnglish &&
                                  place.nameEn != null &&
                                  place.nameEn != place.nameJa)) ...[
                            const SizedBox(height: 4),
                            Text(
                              stationNameDisplayMode ==
                                      StationNameDisplayMode.japaneseEnglish
                                  ? place.nameEn!
                                  : place.nameJa,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: AppColors.mutedText(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20,
                      color: AppColors.mutedText(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded && customBody != null)
            customBody!
          else if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (place.kind != 'station') ...[
                    Text(
                      place.kind == 'airport_area'
                          ? localized(
                              context,
                              '공항 터미널 중심의 안내예요.',
                              'These guides focus on airport terminals.',
                            )
                          : localized(
                              context,
                              '서로 다른 역이 포함된 지역이에요.\n이용할 역에 맞는 안내를 선택해 주세요.',
                              'This area includes several stations.\nChoose the guide for the station you’ll use.',
                            ),
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: AppColors.mutedText(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  for (final source in place.sources) ...[
                    if (source != place.sources.first)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Divider(
                          height: 1,
                          color: AppColors.outline(context),
                        ),
                      ),
                    Text(
                      usesEnglish(context) ? source.englishName : source.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                        color: AppColors.mutedText(context),
                      ),
                    ),
                    const SizedBox(height: 5),
                    for (final link in source.links) ...[
                      _ExternalLink(
                        key: ValueKey('locker-link-${link.uri}'),
                        link: link,
                        place: place,
                        busy: opening == link.uri,
                        disabled: opening != null,
                        onTap: () => onOpen(link.uri),
                      ),
                      if (link.caution != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            usesEnglish(context)
                                ? link.englishCaution!
                                : link.caution!,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.6,
                              color: AppColors.mutedText(context),
                            ),
                          ),
                        ),
                      if (failedLink == link.uri)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                localized(
                                  context,
                                  '안내를 열지 못했어요. 브라우저 설정을 확인해 주세요.',
                                  'Couldn’t open the guide. Check your browser settings.',
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: opening == null
                                  ? () => onOpen(link.uri)
                                  : null,
                              child: Text(
                                localized(context, '다시 열기', 'Try again'),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                    ],
                  ],
                  const SizedBox(height: 10),
                  Text(
                    localized(
                      context,
                      '선택한 안내는 외부 브라우저에서 열려요.',
                      'Guides open in your browser.',
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      color: AppColors.mutedText(context),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

// The catalog keeps the Japanese fallback in nameKo when no verified Korean
// mapping exists, sometimes with an operator qualifier. Do not repeat that
// fallback as a second Japanese line in bilingual mode.
bool _hasKoreanName(CoinLockerPlace place) =>
    RegExp(r'[가-힣]').hasMatch(place.nameKo) && place.nameKo != place.nameJa;

class _ExternalLink extends StatelessWidget {
  const _ExternalLink({
    super.key,
    required this.link,
    required this.place,
    required this.busy,
    required this.disabled,
    required this.onTap,
  });
  final CoinLockerLink link;
  final CoinLockerPlace place;
  final bool busy;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = usesEnglish(context) ? link.englishLabel(place) : link.label;
    return Semantics(
      link: true,
      label: localized(
        context,
        '$label, 외부 브라우저에서 열기',
        '$label, opens in browser',
      ),
      onTap: disabled ? null : onTap,
      enabled: !disabled,
      excludeSemantics: true,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(9),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.55,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent(context),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (busy)
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    Icons.open_in_new,
                    size: 18,
                    color: AppColors.accent(context),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
