import 'package:flutter/material.dart';
import '../../../core/design/app_theme.dart';
import '../../../core/localization/app_strings.dart';
import '../../coin_locker/domain/coin_locker_catalog.dart';
import '../../coin_locker/presentation/coin_locker_page.dart';
import '../../station_resolver/domain/station_name_display.dart';
import '../data/station_map_repository.dart';
import '../domain/station_map_catalog.dart';
import 'station_map_link_title.dart';

/// Uses the same approved region rail, search, cards and typography as lockers.
class StationMapPage extends StatefulWidget {
  const StationMapPage({
    super.key,
    this.load,
    this.openLink,
    this.stationNameDisplayMode = StationNameDisplayMode.japanese,
  });
  final Future<StationMapCatalog> Function()? load;
  final Future<bool> Function(Uri)? openLink;
  final StationNameDisplayMode stationNameDisplayMode;
  @override
  State<StationMapPage> createState() => _StationMapPageState();
}

class _StationMapPageState extends State<StationMapPage> {
  final _repository = StationMapRepository();
  StationMapCatalog? _catalog;
  Future<CoinLockerCatalog> _load() async {
    _catalog = await (widget.load ?? _repository.load)();
    return _catalog!.browserCatalog;
  }

  Future<void> _help() => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (context) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      localized(context, '구내도 이용 안내', 'About station maps'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: localized(context, '닫기', 'Close'),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final item in <(IconData, String, String)>[
              (
                Icons.open_in_new,
                '운영사가 제공하는 공식 구내도를 외부 브라우저에서 열어요.',
                'Official maps from station operators open in your browser.',
              ),
              (
                Icons.translate,
                '구내도는 원문 언어로 열리며, 역명 표기 설정은 적용되지 않아요.',
                'Maps open in their original language. Station name settings do not translate them.',
              ),
              (
                Icons.layers_outlined,
                '지도는 운영사별 범위이며, 환승역 전체를 포함하지 않을 수 있어요.',
                'Each map covers its operator’s area, not necessarily the whole interchange.',
              ),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        item.$1,
                        size: 21,
                        color: AppColors.accent(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        localized(context, item.$2, item.$3),
                        style: const TextStyle(fontSize: 14, height: 1.6),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 2),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localized(context, '확인', 'Got it')),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => CoinLockerPage(
    load: _load,
    stationNameDisplayMode: widget.stationNameDisplayMode,
    guide: StationGuidePresentation(
      titleKo: '역 구내도',
      titleEn: 'Station maps',
      showFooter: false,
      helpButton: SizedBox.square(
        dimension: 48,
        child: IconButton(
          key: const ValueKey('station-map-help'),
          tooltip: localized(context, '구내도 이용 안내', 'About station maps'),
          style: IconButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            _help();
          },
          icon: Icon(
            Icons.info_outline_rounded,
            size: 23,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      footerKo: '확인된 공식 구내도를 연결해요.\n지도는 운영사별 범위이며 전체 환승역을 포함하지 않을 수 있어요.',
      footerEn:
          'Verified official station maps. Each map covers its operator’s area, not necessarily the whole interchange.',
      expandedContent: (context, place) => _MapLinks(
        key: ValueKey('station-maps-${place.id}'),
        place: place,
        links: _catalog!.links[place.id]!,
        mode: widget.stationNameDisplayMode,
        openLink: widget.openLink ?? const StationMapLinkOpener().open,
      ),
    ),
  );
}

class _MapLinks extends StatefulWidget {
  const _MapLinks({
    super.key,
    required this.place,
    required this.links,
    required this.mode,
    required this.openLink,
  });
  final CoinLockerPlace place;
  final List<StationMapLink> links;
  final StationNameDisplayMode mode;
  final Future<bool> Function(Uri) openLink;
  @override
  State<_MapLinks> createState() => _MapLinksState();
}

class _MapLinksState extends State<_MapLinks> {
  String? _opening, _failed;
  Future<void> _open(StationMapLink link) async {
    if (_opening != null || !isAllowedStationMapUri(link.uri)) return;
    setState(() {
      _opening = link.id;
      _failed = null;
    });
    var opened = false;
    try {
      opened = await widget.openLink(link.uri);
    } catch (_) {
      /* Inline retry. */
    }
    if (!mounted) return;
    setState(() {
      _opening = null;
      _failed = opened ? null : link.id;
    });
  }

  String _station(StationMapLink link) {
    final place = widget.place;
    final same = place.nameJa == link.stationJa;
    final ko =
        link.stationKo ??
        (same && RegExp(r'[가-힣]').hasMatch(place.nameKo) ? place.nameKo : null);
    return displayStationName(
      japanese: link.stationJa,
      korean: ko,
      english: link.stationEn ?? (same ? place.nameEn : null),
      mode: widget.mode,
    );
  }

  String _title(StationMapLink link) => stationMapLinkTitle(
    link: link,
    links: widget.links,
    placeStationJa: widget.place.nameJa,
    stationName: _station,
    english: usesEnglish(context),
  );

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<StationMapLink>>{};
    for (final link in widget.links) {
      (groups[link.operatorJa] ??= []).add(link);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final links in groups.values) ...[
            if (links != groups.values.first)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: AppColors.outline(context)),
              ),
            for (final link in links) ...[
              Semantics(
                link: true,
                enabled: _opening == null,
                label: localized(
                  context,
                  '${_title(link)}, 외부 브라우저에서 열기',
                  '${_title(link)}, opens in browser',
                ),
                excludeSemantics: true,
                onTap: _opening == null ? () => _open(link) : null,
                child: InkWell(
                  key: ValueKey('station-map-link-${link.id}'),
                  onTap: _opening == null ? () => _open(link) : null,
                  borderRadius: BorderRadius.circular(11),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _title(link),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.5,
                                  color: AppColors.accent(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_opening == link.id)
                          const SizedBox(
                            width: 18,
                            height: 18,
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
              if (_failed == link.id) ...[
                Semantics(
                  liveRegion: true,
                  child: Text(
                    localized(
                      context,
                      '구내도를 열지 못했어요. 인터넷 연결과 브라우저 설정을 확인해 주세요.',
                      'Couldn’t open the map. Check your connection and browser settings.',
                    ),
                    style: const TextStyle(fontSize: 12, height: 1.6),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _opening == null ? () => _open(link) : null,
                  child: Text(localized(context, '다시 열기', 'Try again')),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}
