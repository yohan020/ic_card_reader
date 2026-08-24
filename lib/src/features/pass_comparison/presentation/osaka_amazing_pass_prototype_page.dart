import 'package:flutter/material.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../data/osaka_pass_station_data.dart';
import '../domain/osaka_amazing_pass.dart';

class OsakaAmazingPassPrototypePage extends StatefulWidget {
  const OsakaAmazingPassPrototypePage({this.initialData, super.key});

  final OsakaPassStationData? initialData;

  @override
  State<OsakaAmazingPassPrototypePage> createState() =>
      _OsakaAmazingPassPrototypePageState();
}

class _OsakaAmazingPassPrototypePageState
    extends State<OsakaAmazingPassPrototypePage> {
  OsakaAmazingPassProduct _product = OsakaAmazingPassProduct.oneDay;
  late OsakaPassStationData? _data = widget.initialData;
  final List<_OsakaSegmentDraft> _drafts = [_OsakaSegmentDraft()];
  final List<int> _busRidesByDay = [0, 0];
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    if (_data == null) _load();
  }

  Future<void> _load() async {
    try {
      final data = await const OsakaPassStationDataRepository().load();
      if (mounted) setState(() => _data = data);
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('교통패스 비교')),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          const _PrototypeProgress(activeStep: 2),
          const SizedBox(height: 24),
          Text(
            '이동 계획을 입력해 주세요',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '실제로 개찰을 통과할 출발역과 하차역을 입력하면 운임을 자동으로 찾습니다.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          _OsakaSelectedPassSummary(
            value: _product,
            onChanged: (value) => setState(() {
              _product = value;
              if (value.dayCount == 1) {
                for (final draft in _drafts) {
                  draft.dayIndex = 0;
                }
                _busRidesByDay[1] = 0;
              }
            }),
          ),
          if (_loadError != null) ...[
            const SizedBox(height: 12),
            const NoticeBanner(
              title: '운임 데이터를 읽지 못했습니다',
              text: '프로토타입 asset을 다시 생성한 뒤 실행해 주세요.',
              tone: NoticeTone.warning,
            ),
          ],
          const SizedBox(height: 20),
          SectionLabel(
            '이동 구간',
            trailing: TextButton(onPressed: _clear, child: const Text('비우기')),
          ),
          AppSurface(
            key: const ValueKey('osaka-journey-plan-card'),
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                for (var index = 0; index < _drafts.length; index++) ...[
                  _SegmentCard(
                    index: index,
                    draft: _drafts[index],
                    data: _data,
                    dayCount: _product.dayCount,
                    canRemove: _drafts.length > 1,
                    onChanged: () => setState(() {}),
                    onRemove: () => _remove(index),
                  ),
                  if (index != _drafts.length - 1) ...[
                    const SizedBox(height: 14),
                    Divider(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    const SizedBox(height: 14),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _data == null
                ? null
                : () => setState(() => _drafts.add(_OsakaSegmentDraft())),
            icon: const Icon(Icons.add_rounded),
            label: const Text('이동 구간 추가'),
          ),
          const SizedBox(height: 18),
          _BusRideCounter(
            dayCount: _product.dayCount,
            ridesByDay: _busRidesByDay,
            fare: _data?.busAdultFare ?? 210,
            onChanged: (day, value) =>
                setState(() => _busRidesByDay[day] = value),
          ),
          const SizedBox(height: 18),
          NoticeBanner(
            title: '교통비만 비교합니다',
            text: _data == null
                ? '검증된 철도·버스 운임 데이터를 불러오는 중입니다.'
                : '철도 ${_data!.stations.length}역·환승 연결 ${_data!.transfers.length}개와 시티버스 일반 운임을 사용합니다. 관광시설 혜택은 포함하지 않습니다.',
            tone: NoticeTone.info,
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _data == null ? null : _showResult,
            child: const Text('비교 결과 보기'),
          ),
          const SizedBox(height: 12),
          const _OsakaPlannerFootnote(),
          const SizedBox(height: 2),
          TextButton.icon(
            onPressed: _data == null ? null : _showDataSources,
            icon: const Icon(Icons.info_outline_rounded),
            label: const Text('운임 데이터 기준과 출처'),
          ),
        ],
      ),
    ),
  );

  void _clear() => setState(() {
    _drafts
      ..clear()
      ..add(_OsakaSegmentDraft());
    for (var index = 0; index < _busRidesByDay.length; index++) {
      _busRidesByDay[index] = 0;
    }
  });

  void _remove(int index) => setState(() => _drafts.removeAt(index));

  void _showResult() {
    final data = _data!;
    final segments = <OsakaPlannedSegment>[];
    for (var draftIndex = 0; draftIndex < _drafts.length; draftIndex++) {
      final draft = _drafts[draftIndex];
      if (draft.from == null && draft.to == null) continue;
      if (draft.from == null || draft.to == null) {
        _showInputMessage('출발역과 도착역을 모두 선택해 주세요.');
        return;
      }
      final route = data.routeBetween(draft.from!, draft.to!);
      if (route == null) {
        _showInputMessage('지원 데이터에서 해당 역 사이의 경로와 운임을 찾지 못했습니다.');
        return;
      }
      segments.addAll(
        route.legs.map(
          (leg) => OsakaPlannedSegment(
            dayIndex: draft.dayIndex,
            operator: leg.operator,
            fromStation: leg.from.displayName,
            toStation: leg.to.displayName,
            regularFare: leg.fare,
            journeyIndex: draftIndex,
          ),
        ),
      );
    }
    final result = OsakaAmazingPassEvaluator.evaluate(
      product: _product,
      segments: segments,
      busRidesByDay: _busRidesByDay,
      busAdultFare: data.busAdultFare,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _OsakaResultPage(result: result, data: data),
      ),
    );
  }

  void _showInputMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showDataSources() {
    final data = _data!;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Text(
              '운임 데이터 기준과 출처',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text('${data.validFrom} 기준 · ${data.datasetVersion}'),
            const SizedBox(height: 12),
            for (final source in data.sources)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.link_rounded),
                title: Text(source.label),
                subtitle: SelectableText('${source.note}\n${source.url}'),
              ),
            const NoticeBanner(
              title: '참고용 자동 계산',
              text:
                  '일부 데이터는 공개된 영업거리와 운임 규칙으로 독립 계산했습니다. 실제 구매 전 패스와 각 교통기관의 최신 공식 안내를 확인해 주세요.',
              tone: NoticeTone.warning,
            ),
          ],
        ),
      ),
    );
  }
}

class _OsakaSelectedPassSummary extends StatelessWidget {
  const _OsakaSelectedPassSummary({
    required this.value,
    required this.onChanged,
  });

  final OsakaAmazingPassProduct value;
  final ValueChanged<OsakaAmazingPassProduct> onChanged;

  @override
  Widget build(BuildContext context) => AppSurface(
    padding: const EdgeInsets.all(14),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.softSurface(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.confirmation_number_outlined,
                color: AppColors.accent(context),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value.label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '¥${value.price}',
                    style: TextStyle(
                      color: AppColors.accent(context),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (
              var index = 0;
              index < OsakaAmazingPassProduct.values.length;
              index++
            ) ...[
              Expanded(
                child: _OsakaDurationOption(
                  product: OsakaAmazingPassProduct.values[index],
                  selected: OsakaAmazingPassProduct.values[index] == value,
                  onTap: () => onChanged(OsakaAmazingPassProduct.values[index]),
                ),
              ),
              if (index != OsakaAmazingPassProduct.values.length - 1)
                const SizedBox(width: 7),
            ],
          ],
        ),
      ],
    ),
  );
}

class _OsakaDurationOption extends StatelessWidget {
  const _OsakaDurationOption({
    required this.product,
    required this.selected,
    required this.onTap,
  });

  final OsakaAmazingPassProduct product;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '${product.dayCount}일권 ${product.price}엔',
    child: InkWell(
      key: ValueKey('osaka-duration-${product.dayCount}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.skyDark : AppColors.softSurface(context),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          children: [
            Text(
              '${product.dayCount}일권',
              style: TextStyle(
                color: selected ? Colors.white : AppColors.accent(context),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '¥${product.price}',
              style: TextStyle(
                color: selected
                    ? Colors.white.withValues(alpha: .86)
                    : AppColors.accent(context),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SegmentCard extends StatelessWidget {
  const _SegmentCard({
    required this.index,
    required this.draft,
    required this.data,
    required this.dayCount,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final _OsakaSegmentDraft draft;
  final OsakaPassStationData? data;
  final int dayCount;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final route = draft.from == null || draft.to == null
        ? null
        : data?.routeBetween(draft.from!, draft.to!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.softSurface(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: AppColors.accent(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                '이동 구간',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            if (canRemove)
              IconButton(
                tooltip: '구간 삭제',
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StationButton(
                label: '출발',
                station: draft.from,
                data: data,
                onSelected: (station) {
                  draft.from = station;
                  onChanged();
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: IconButton(
                tooltip: '출발·도착 바꾸기',
                onPressed: () {
                  final from = draft.from;
                  draft.from = draft.to;
                  draft.to = from;
                  onChanged();
                },
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.accent(context),
                  backgroundColor: AppColors.softSurface(context),
                ),
                icon: const Icon(Icons.swap_horiz_rounded, size: 20),
              ),
            ),
            Expanded(
              child: _StationButton(
                label: '도착',
                station: draft.to,
                data: data,
                onSelected: (station) {
                  draft.to = station;
                  onChanged();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _OsakaResolvedFareSummary(
          index: index,
          hasBothStations: draft.from != null && draft.to != null,
          route: route,
        ),
        if (dayCount > 1) ...[
          const SizedBox(height: 9),
          _OsakaDaySelector(
            value: draft.dayIndex,
            dayCount: dayCount,
            onChanged: (value) {
              draft.dayIndex = value;
              onChanged();
            },
          ),
        ],
        if (route != null && route.transferCount > 0) ...[
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              route.legs
                  .map(
                    (leg) =>
                        '${operatorDisplayName(leg.operator)} '
                        '${leg.from.displayName}→${leg.to.displayName} '
                        '¥${leg.fare}',
                  )
                  .join('  ·  '),
              key: ValueKey('osaka-segment-route-$index'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StationButton extends StatelessWidget {
  const _StationButton({
    required this.label,
    required this.station,
    required this.data,
    required this.onSelected,
  });

  final String label;
  final OsakaPassStation? station;
  final OsakaPassStationData? data;
  final ValueChanged<OsakaPassStation> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: station == null ? 60 : 76,
    child: OutlinedButton(
      onPressed: data == null
          ? null
          : () async {
              final selected = await Navigator.of(context)
                  .push<OsakaPassStation>(
                    MaterialPageRoute<OsakaPassStation>(
                      builder: (_) => _OsakaStationSearchPage(
                        title: '$label역 선택',
                        data: data!,
                      ),
                    ),
                  );
              if (selected != null) onSelected(selected);
            },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        backgroundColor: AppColors.fieldSurface(context),
        side: BorderSide(color: AppColors.outline(context)),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(
            station?.displayName ?? '역 선택',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.accent(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (station != null) ...[
            const SizedBox(height: 2),
            Text(
              operatorDisplayName(station!.operator),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ],
      ),
    ),
  );
}

class _OsakaResolvedFareSummary extends StatelessWidget {
  const _OsakaResolvedFareSummary({
    required this.index,
    required this.hasBothStations,
    required this.route,
  });

  final int index;
  final bool hasBothStations;
  final OsakaPassRoute? route;

  @override
  Widget build(BuildContext context) {
    if (!hasBothStations) {
      return Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 17,
            color: AppColors.mutedText(context),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              '두 역을 선택하면 운임을 자동으로 확인합니다.',
              style: TextStyle(
                color: AppColors.mutedText(context),
                fontSize: 12,
              ),
            ),
          ),
        ],
      );
    }
    final resolvedRoute = route;
    if (resolvedRoute == null) {
      return Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 17,
            color: AppColors.mutedText(context),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              '지원 데이터에서 경로를 확인할 수 없습니다.',
              key: ValueKey('osaka-segment-fare-$index'),
              style: TextStyle(
                color: AppColors.mutedText(context),
                fontSize: 12,
              ),
            ),
          ),
        ],
      );
    }
    final fareLabel = resolvedRoute.transferCount == 0
        ? '성인 일반 운임 · ¥${resolvedRoute.fare}'
        : '환승 ${resolvedRoute.transferCount}회 · 성인 일반 운임 ¥${resolvedRoute.fare}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 18,
            color: AppColors.success,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              fareLabel,
              key: ValueKey('osaka-segment-fare-$index'),
              style: const TextStyle(
                color: AppColors.success,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OsakaDaySelector extends StatelessWidget {
  const _OsakaDaySelector({
    required this.value,
    required this.dayCount,
    required this.onChanged,
  });

  final int value;
  final int dayCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        '이용일',
        style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
      ),
      const SizedBox(width: 10),
      for (var day = 0; day < dayCount; day++) ...[
        ChoiceChip(
          label: Text('${day + 1}일차'),
          selected: day == value,
          onSelected: (_) => onChanged(day),
          labelStyle: TextStyle(
            color: day == value ? Colors.white : AppColors.accent(context),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          selectedColor: AppColors.skyDark,
          backgroundColor: AppColors.softSurface(context),
          side: BorderSide.none,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        if (day != dayCount - 1) const SizedBox(width: 6),
      ],
    ],
  );
}

class _OsakaPlannerFootnote extends StatelessWidget {
  const _OsakaPlannerFootnote();

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        Icons.info_outline_rounded,
        size: 16,
        color: AppColors.mutedText(context),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          '실제로 개찰을 통과해 하차한 역을 입력해 주세요. 추천 경로는 시간표 기반 최속 경로가 아닙니다.',
          style: TextStyle(
            color: AppColors.mutedText(context),
            fontSize: 12,
            height: 1.35,
          ),
        ),
      ),
    ],
  );
}

class _OsakaStationSearchPage extends StatefulWidget {
  const _OsakaStationSearchPage({required this.title, required this.data});

  final String title;
  final OsakaPassStationData data;

  @override
  State<_OsakaStationSearchPage> createState() =>
      _OsakaStationSearchPageState();
}

class _OsakaStationSearchPageState extends State<_OsakaStationSearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<OsakaPassStation> _results = const [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(78),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
          child: TextField(
            key: const ValueKey('osaka-station-search-field'),
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: _search,
            decoration: InputDecoration(
              hintText: '역 이름을 검색해 주세요',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: '검색어 지우기',
                      onPressed: () {
                        _controller.clear();
                        _search('');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.skyDark,
                  width: 1.4,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    body: SafeArea(
      top: false,
      child: _controller.text.trim().isEmpty
          ? const _OsakaStationSearchEmptyState(
              icon: Icons.search_rounded,
              title: '찾고 싶은 역을 입력해 주세요',
              description: '한국어·초성·일본어로 검색할 수 있습니다.',
            )
          : _results.isEmpty
          ? const _OsakaStationSearchEmptyState(
              icon: Icons.location_off_outlined,
              title: '일치하는 역을 찾지 못했어요',
              description: '다른 표기나 초성으로 다시 검색해 주세요.',
            )
          : ListView.separated(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: _results.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final station = _results[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.skySoft,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.subway_outlined,
                      color: AppColors.skyDark,
                    ),
                  ),
                  title: Text(
                    station.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: station.secondaryLabel.isEmpty
                      ? null
                      : Text(station.secondaryLabel),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).pop(station),
                );
              },
            ),
    ),
  );

  void _search(String query) {
    setState(() {
      _results = query.trim().isEmpty ? const [] : widget.data.search(query);
    });
  }
}

class _OsakaStationSearchEmptyState extends StatelessWidget {
  const _OsakaStationSearchEmptyState({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: AppColors.skySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.skyDark, size: 29),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    ),
  );
}

class _BusRideCounter extends StatelessWidget {
  const _BusRideCounter({
    required this.dayCount,
    required this.ridesByDay,
    required this.fare,
    required this.onChanged,
  });

  final int dayCount;
  final List<int> ridesByDay;
  final int fare;
  final void Function(int day, int value) onChanged;

  @override
  Widget build(BuildContext context) => AppSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('오사카 시티버스', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
          '주유패스 대상 일반 노선 탑승 횟수 · 1회 ¥$fare',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        for (var day = 0; day < dayCount; day++)
          Row(
            children: [
              Expanded(child: Text(dayCount == 1 ? '탑승 횟수' : '${day + 1}일차')),
              IconButton(
                tooltip: '1회 줄이기',
                onPressed: ridesByDay[day] == 0
                    ? null
                    : () => onChanged(day, ridesByDay[day] - 1),
                icon: const Icon(Icons.remove_circle_outline_rounded),
              ),
              SizedBox(
                width: 34,
                child: Text(
                  '${ridesByDay[day]}회',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: '1회 늘리기',
                onPressed: ridesByDay[day] >= 20
                    ? null
                    : () => onChanged(day, ridesByDay[day] + 1),
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ],
          ),
        Text(
          '일부 특정 노선과 온디맨드 버스는 패스 대상이 아닙니다.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

class _OsakaResultPage extends StatelessWidget {
  const _OsakaResultPage({required this.result, required this.data});

  final OsakaPassComparisonResult result;
  final OsakaPassStationData data;

  @override
  Widget build(BuildContext context) {
    final (title, description, color) = switch (result.verdict) {
      OsakaPassVerdict.beneficial => (
        '패스가 더 이득이에요',
        '교통비만으로 ¥${result.savings} 절약',
        AppColors.success,
      ),
      OsakaPassVerdict.breakEven => (
        '일반 운임과 같아요',
        '관광시설을 이용하면 추가 이득이 생길 수 있습니다.',
        AppColors.skyDark,
      ),
      OsakaPassVerdict.notBeneficial => (
        '교통비만 보면 일반 결제가 저렴해요',
        '패스 가격보다 ¥${-result.savings} 적습니다.',
        AppColors.warning,
      ),
      OsakaPassVerdict.insufficientData => (
        '비교할 이동이 부족해요',
        '철도 구간을 선택하거나 버스 탑승 횟수를 입력해 주세요.',
        AppColors.muted,
      ),
    };
    return Scaffold(
      appBar: AppBar(title: const Text('비교 결과')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            const _PrototypeProgress(activeStep: 3),
            const SizedBox(height: 22),
            AppSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(description),
                  const Divider(height: 28),
                  _ResultMoneyRow(
                    label: '철도 일반 운임',
                    value: result.railFareTotal,
                  ),
                  _ResultMoneyRow(
                    label: '시티버스 일반 운임',
                    value: result.busFareTotal,
                  ),
                  _ResultMoneyRow(
                    label: result.product.label,
                    value: result.product.price,
                  ),
                  const Divider(height: 22),
                  _ResultMoneyRow(
                    label: '예상 손익',
                    value: result.savings,
                    signed: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            for (final segment in result.segments)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: const Icon(Icons.train_outlined),
                title: Text(
                  '${segment.fromStation} → ${segment.toStation}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${segment.dayIndex + 1}일차 · ${segment.journeyIndex + 1}번 이동 · ${operatorDisplayName(segment.operator)}',
                ),
                trailing: Text(
                  '¥${segment.regularFare}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            for (var day = 0; day < result.busRidesByDay.length; day++)
              if (result.busRidesByDay[day] > 0)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: const Icon(Icons.directions_bus_outlined),
                  title: Text(
                    '오사카 시티버스 ${result.busRidesByDay[day]}회',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text('${day + 1}일차 · 주유패스 대상 일반 노선'),
                  trailing: Text(
                    '¥${result.busRidesByDay[day] * data.busAdultFare}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
            const SizedBox(height: 12),
            const NoticeBanner(
              title: '참고용 자동 계산 결과',
              text:
                  '관광시설 혜택, 패스 제외 버스, 특급권·좌석요금은 포함하지 않습니다. 사업자가 바뀌는 이동은 지원 역 그래프의 거리 기반 추천 경로로 계산하므로, 실제 이용 경로와 구매 전 최신 공식 조건을 확인해 주세요.',
              tone: NoticeTone.warning,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultMoneyRow extends StatelessWidget {
  const _ResultMoneyRow({
    required this.label,
    required this.value,
    this.signed = false,
  });

  final String label;
  final int value;
  final bool signed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          '${signed && value > 0 ? '+' : ''}¥$value',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class _PrototypeProgress extends StatelessWidget {
  const _PrototypeProgress({required this.activeStep});

  final int activeStep;

  @override
  Widget build(BuildContext context) {
    const labels = ['패스 선택', '이용 계획', '비교 결과'];
    return Row(
      children: [
        for (var index = 0; index < labels.length; index++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: index + 1 <= activeStep
                        ? AppColors.skyDark
                        : AppColors.softSurface(context),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${index + 1}. ${labels[index]}',
                  style: TextStyle(
                    color: index + 1 == activeStep
                        ? AppColors.accent(context)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: index + 1 == activeStep
                        ? FontWeight.w800
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (index != labels.length - 1) const SizedBox(width: 5),
        ],
      ],
    );
  }
}

class _OsakaSegmentDraft {
  int dayIndex = 0;
  OsakaPassStation? from;
  OsakaPassStation? to;
}
