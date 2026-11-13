import 'package:flutter/material.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/localization/app_strings.dart';
import '../../station_resolver/domain/station_name_display.dart';
import '../data/coin_locker_link_opener.dart';
import '../data/coin_locker_repository.dart';
import '../domain/coin_locker_catalog.dart';

/// Approved B: fixed region index, independently scrolling expandable places.
class CoinLockerPage extends StatefulWidget {
  const CoinLockerPage({
    super.key,
    this.load,
    this.openLink,
    this.stationNameDisplayMode = StationNameDisplayMode.japanese,
  });
  final Future<CoinLockerCatalog> Function()? load;
  final Future<bool> Function(Uri)? openLink;
  final StationNameDisplayMode stationNameDisplayMode;

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
    final dark = AppColors.isDark(context);
    final header = dark ? const Color(0xFF162C38) : const Color(0xFFEBF6FC);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: header,
        toolbarHeight:
            56 + (MediaQuery.textScalerOf(context).scale(21) - 21).clamp(0, 70),
        title: Text(
          localized(context, '코인락커 찾기', 'Find coin lockers'),
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
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
                          '코인락커 안내를 불러오지 못했어요.',
                          'Couldn’t load the locker guides.',
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
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
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
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: localized(
                            context,
                            '한국어·일본어 역 이름 검색',
                            'Search station names',
                          ),
                          prefixIcon: const Icon(Icons.search, size: 23),
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
                          fillColor: AppColors.fieldSurface(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
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
                      final railWidth = (88 * scale).clamp(
                        88.0,
                        constraints.maxWidth * .38,
                      );
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: railWidth,
                            child: ColoredBox(
                              color: dark
                                  ? const Color(0xFF14242E)
                                  : const Color(0xFFEEF5F9),
                              child: ListView(
                                key: const PageStorageKey('locker-regions'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 12,
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
                          Expanded(
                            child: ListView.builder(
                              controller: _scroll,
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                16,
                                14,
                                24,
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
                                              '외부 사이트의 위치 안내를 연결해요.\n실시간 빈자리·예약 정보는 아니에요.',
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
    padding: const EdgeInsets.only(bottom: 4),
    child: Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.softSurface(context) : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
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
                fontSize: 13,
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
  });
  final CoinLockerPlace place;
  final StationNameDisplayMode stationNameDisplayMode;
  final bool expanded;
  final Uri? opening;
  final Uri? failedLink;
  final Future<void> Function(Uri) onOpen;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: AppColors.fieldSurface(context),
      borderRadius: BorderRadius.circular(17),
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
                  vertical: 18,
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
                              fontSize: 16,
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
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 15, 13, 15),
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
                    const SizedBox(height: 16),
                  ],
                  for (final source in place.sources) ...[
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
                    const SizedBox(height: 14),
                  ],
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
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 13, height: 1.55),
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
