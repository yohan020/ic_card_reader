import 'package:flutter/material.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import 'widgets/pass_result_scope_note.dart';
import '../data/enokama_pass_data.dart';
import '../domain/enokama_pass.dart';
import 'widgets/pass_segment_remove_button.dart';
import 'widgets/pass_station_picker_field.dart';

class EnokamaPassPage extends StatefulWidget {
  const EnokamaPassPage({super.key});
  @override
  State<EnokamaPassPage> createState() => _EnokamaPassPageState();
}

class _EnokamaPassPageState extends State<EnokamaPassPage> {
  EnokamaPassData? _data;
  Object? _loadError;
  EnokamaOrigin? _origin;
  final _segments = <_Draft>[_Draft()];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final data = await const EnokamaPassDataRepository().load();
      if (mounted) setState(() => _data = data);
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      appBar: AppBar(title: const Text('교통패스 비교')),
      body: data == null
          ? _loadError == null
                ? const Center(child: CircularProgressIndicator())
                : _LoadFailure(onRetry: _load)
          : SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                children: [
                  const _Steps(active: 1),
                  const SizedBox(height: 24),
                  Text(
                    '이동 계획을 입력해 주세요',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '패스 출발역과 에노덴·오다큐 프리구간 이동을 입력하면 성인 IC 기준 운임을 비교합니다.',
                    style: TextStyle(
                      color: AppColors.mutedText(context),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _OriginCard(
                    origin: _origin,
                    data: data,
                    onSelected: (value) => setState(() => _origin = value),
                  ),
                  const SizedBox(height: 20),
                  SectionLabel(
                    '이동 구간',
                    trailing: TextButton(
                      onPressed: _clear,
                      child: const Text('비우기'),
                    ),
                  ),
                  AppSurface(
                    key: const ValueKey('enokama-journey-plan-card'),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        for (
                          var index = 0;
                          index < _segments.length;
                          index++
                        ) ...[
                          _SegmentEditor(
                            index: index,
                            draft: _segments[index],
                            data: data,
                            removable: _segments.length > 1,
                            onChanged: () => setState(() {}),
                            onRemove: () =>
                                setState(() => _segments.removeAt(index)),
                          ),
                          if (index != _segments.length - 1)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(),
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _segments.add(_Draft())),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('이동 구간 추가'),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () => _showResult(data),
                    child: const Text('비교 결과 보기'),
                  ),
                  const SizedBox(height: 12),
                  const _Footnote(),
                ],
              ),
            ),
    );
  }

  void _clear() => setState(() {
    _origin = null;
    _segments
      ..clear()
      ..add(_Draft());
  });
  void _showResult(EnokamaPassData data) {
    final segments = _segments
        .where((item) => item.from != null && item.to != null)
        .map(
          (item) => EnokamaSegment(
            item.from!,
            item.to!,
            data.fareBetween(item.from!, item.to!) ?? 0,
          ),
        )
        .toList();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ResultPage(
          result: EnokamaPassEvaluator.evaluate(
            origin: _origin,
            segments: segments,
          ),
        ),
      ),
    );
  }
}

class _Draft {
  EnokamaStation? from;
  EnokamaStation? to;
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppColors.mutedText(context),
            size: 40,
          ),
          const SizedBox(height: 12),
          const Text(
            '패스 데이터를 불러오지 못했어요',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            '앱을 다시 실행하거나 다시 시도해 주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedText(context)),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    ),
  );
}

class _Steps extends StatelessWidget {
  const _Steps({required this.active});
  final int active;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < 3; i++)
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == 2 ? 0 : 5),
            child: Column(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= active
                        ? AppColors.accent(context)
                        : AppColors.softSurface(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${i + 1}. ${['패스 선택', '이용 계획', '비교 결과'][i]}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: i == active ? FontWeight.w800 : FontWeight.w500,
                    color: i == active
                        ? AppColors.accent(context)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

class _OriginCard extends StatelessWidget {
  const _OriginCard({
    required this.origin,
    required this.data,
    required this.onSelected,
  });
  final EnokamaOrigin? origin;
  final EnokamaPassData data;
  final ValueChanged<EnokamaOrigin> onSelected;
  @override
  Widget build(BuildContext context) => AppSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  const Text(
                    '에노시마·가마쿠라 프리패스 1일권',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (origin != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '¥${origin!.passPrice}',
                      style: TextStyle(
                        color: AppColors.accent(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () async {
            final selected = await Navigator.of(context).push<EnokamaOrigin>(
              MaterialPageRoute(builder: (_) => _OriginListPage(data: data)),
            );
            if (selected != null) onSelected(selected);
          },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            alignment: Alignment.centerLeft,
            backgroundColor: AppColors.fieldSurface(context),
          ),
          child: Row(
            children: [
              const Icon(Icons.train_outlined),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      origin?.displayName ?? '패스 출발역 선택',
                      style: TextStyle(
                        color: AppColors.accent(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (origin != null)
                      Text(
                        '${origin!.nameJa} · ${origin!.roundTripApplicable ? '후지사와 왕복 포함' : '프리구간 내부 출발역'}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SegmentEditor extends StatelessWidget {
  const _SegmentEditor({
    required this.index,
    required this.draft,
    required this.data,
    required this.removable,
    required this.onChanged,
    required this.onRemove,
  });
  final int index;
  final _Draft draft;
  final EnokamaPassData data;
  final bool removable;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) {
    final fare = draft.from == null || draft.to == null
        ? null
        : data.fareBetween(draft.from!, draft.to!);
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
            if (removable) PassSegmentRemoveButton(onPressed: onRemove),
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
                onSelected: (value) {
                  draft.from = value;
                  onChanged();
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: IconButton(
                onPressed: () {
                  final from = draft.from;
                  draft.from = draft.to;
                  draft.to = from;
                  onChanged();
                },
                tooltip: '출발·도착 바꾸기',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.softSurface(context),
                  foregroundColor: AppColors.accent(context),
                ),
                icon: const Icon(Icons.swap_horiz_rounded),
              ),
            ),
            Expanded(
              child: _StationButton(
                label: '도착',
                station: draft.to,
                data: data,
                onSelected: (value) {
                  draft.to = value;
                  onChanged();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _FareHint(hasBoth: draft.from != null && draft.to != null, fare: fare),
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
  final EnokamaStation? station;
  final EnokamaPassData data;
  final ValueChanged<EnokamaStation> onSelected;
  @override
  Widget build(BuildContext context) => PassStationPickerField(
    label: label,
    stationName: station?.displayName,
    operatorLabel: station == null
        ? null
        : station!.secondaryLabel.split(' · ').last,
    onTap: () async {
      final selected = await Navigator.of(context).push<EnokamaStation>(
        MaterialPageRoute(
          builder: (_) => _StationSearchPage(title: '$label역 선택', data: data),
        ),
      );
      if (selected != null) onSelected(selected);
    },
  );
}

class _FareHint extends StatelessWidget {
  const _FareHint({required this.hasBoth, required this.fare});
  final bool hasBoth;
  final int? fare;
  @override
  Widget build(BuildContext context) {
    final success = fare != null;
    final message = !hasBoth
        ? '두 역을 선택하면 운임을 자동으로 확인합니다.'
        : fare == null
        ? '이 구간의 운임을 확인할 수 없습니다.'
        : '성인 일반 운임 ¥$fare';
    return Row(
      children: [
        Icon(
          success
              ? Icons.check_circle_outline_rounded
              : Icons.info_outline_rounded,
          size: 18,
          color: success ? AppColors.success : AppColors.mutedText(context),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: success ? AppColors.success : AppColors.mutedText(context),
              fontWeight: success ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _Footnote extends StatelessWidget {
  const _Footnote();
  @override
  Widget build(BuildContext context) => Text(
    '패스 출발역과 후지사와 사이의 왕복 1회, 에노덴 전선과 오다큐 후지사와–가타세에노시마 구간만 계산합니다. 프리구간 밖 추가 이동, 특급·좌석요금과 할인은 포함하지 않습니다.',
    style: TextStyle(
      color: AppColors.mutedText(context),
      fontSize: 12,
      height: 1.35,
    ),
  );
}

class _StationSearchPage extends StatefulWidget {
  const _StationSearchPage({required this.title, required this.data});
  final String title;
  final EnokamaPassData data;
  @override
  State<_StationSearchPage> createState() => _StationSearchPageState();
}

class _StationSearchPageState extends State<_StationSearchPage> {
  final _controller = TextEditingController();
  List<EnokamaStation> _results = const [];
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SearchScaffold<EnokamaStation>(
    title: widget.title,
    controller: _controller,
    results: _results,
    emptyText: '에노덴·오다큐 프리구간 역을 검색할 수 있습니다.',
    onChanged: (value) =>
        setState(() => _results = widget.data.searchStations(value)),
    item: (station) => _StationTile(station: station),
    onTap: (station) => Navigator.of(context).pop(station),
  );
}

class _OriginListPage extends StatefulWidget {
  const _OriginListPage({required this.data});
  final EnokamaPassData data;

  @override
  State<_OriginListPage> createState() => _OriginListPageState();
}

class _OriginListPageState extends State<_OriginListPage> {
  final _controller = TextEditingController();
  List<EnokamaOrigin> _results = const [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const lines = ['Odawara Line', 'Enoshima Line', 'Tama Line'];
    const labels = {
      'Odawara Line': '오다와라선',
      'Enoshima Line': '에노시마선',
      'Tama Line': '다마선',
    };
    return Scaffold(
      appBar: AppBar(title: const Text('패스 출발역 선택')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Text(
            '오다큐 출발역을 선택해 주세요',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            '출발역에 따라 패스 가격이 달라집니다.',
            style: TextStyle(color: AppColors.mutedText(context)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            onChanged: (query) => setState(
              () => _results = query.trim().isEmpty
                  ? const []
                  : widget.data.searchOrigins(query),
            ),
            decoration: InputDecoration(
              hintText: '출발역 검색',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _controller.clear();
                        setState(() => _results = const []);
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              isDense: true,
            ),
          ),
          const SizedBox(height: 18),
          if (_controller.text.isNotEmpty) ...[
            SectionLabel('검색 결과 ${_results.length}개'),
            if (_results.isEmpty)
              const _OriginEmptyState()
            else
              _OriginRows(origins: _results),
          ] else ...[
            const SectionLabel('노선 선택'),
            for (final line in lines) ...[
              _OriginLineCard(
                label: labels[line]!,
                count: widget.data.origins
                    .where((item) => item.line == line)
                    .length,
                onTap: () => Navigator.of(context)
                    .push<EnokamaOrigin>(
                      MaterialPageRoute(
                        builder: (_) => _OriginLinePage(
                          line: line,
                          label: labels[line]!,
                          origins: widget.data.origins
                              .where((item) => item.line == line)
                              .toList(),
                        ),
                      ),
                    )
                    .then((origin) {
                      if (origin != null && context.mounted)
                        Navigator.of(context).pop(origin);
                    }),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}

class _OriginLineCard extends StatelessWidget {
  const _OriginLineCard({
    required this.label,
    required this.count,
    required this.onTap,
  });
  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppSurface(
    padding: EdgeInsets.zero,
    child: ListTile(
      leading: Icon(Icons.train_outlined, color: AppColors.accent(context)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text('$count개 출발역'),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    ),
  );
}

class _OriginLinePage extends StatelessWidget {
  const _OriginLinePage({
    required this.line,
    required this.label,
    required this.origins,
  });
  final String line;
  final String label;
  final List<EnokamaOrigin> origins;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(label)),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Text(
          '$label 출발역',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        Text(
          '출발역을 선택하면 해당 패스 가격을 적용합니다.',
          style: TextStyle(color: AppColors.mutedText(context)),
        ),
        const SizedBox(height: 18),
        _OriginRows(origins: origins),
      ],
    ),
  );
}

class _OriginRows extends StatelessWidget {
  const _OriginRows({required this.origins});
  final List<EnokamaOrigin> origins;

  @override
  Widget build(BuildContext context) => AppSurface(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (final origin in origins)
          ListTile(
            leading: const Icon(Icons.train_outlined),
            title: Text(
              origin.displayName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(origin.secondaryLabel),
            trailing: Text(
              '¥${origin.passPrice}',
              style: TextStyle(
                color: AppColors.accent(context),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            onTap: () => Navigator.of(context).pop(origin),
          ),
      ],
    ),
  );
}

class _OriginEmptyState extends StatelessWidget {
  const _OriginEmptyState();
  @override
  Widget build(BuildContext context) => AppSurface(
    child: Text(
      '일치하는 출발역을 찾지 못했어요. 한글·초성·일본어로 다시 검색해 주세요.',
      style: TextStyle(color: AppColors.mutedText(context)),
    ),
  );
}

class _SearchScaffold<T> extends StatelessWidget {
  const _SearchScaffold({
    required this.title,
    required this.controller,
    required this.results,
    required this.emptyText,
    required this.onChanged,
    required this.item,
    required this.onTap,
  });
  final String title;
  final TextEditingController controller;
  final List<T> results;
  final String emptyText;
  final ValueChanged<String> onChanged;
  final Widget Function(T) item;
  final ValueChanged<T> onTap;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
          child: TextField(
            controller: controller,
            autofocus: true,
            onChanged: onChanged,
            decoration: const InputDecoration(
              hintText: '역 이름을 검색해 주세요',
              prefixIcon: Icon(Icons.search_rounded),
              filled: true,
              isDense: true,
            ),
          ),
        ),
      ),
    ),
    body: controller.text.trim().isEmpty
        ? Center(
            child: Text(
              emptyText,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedText(context)),
            ),
          )
        : results.isEmpty
        ? const Center(child: Text('일치하는 역을 찾지 못했어요'))
        : ListView.separated(
            itemCount: results.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, index) => item(results[index]),
          ),
  );
}

class _StationTile extends StatelessWidget {
  const _StationTile({required this.station});
  final EnokamaStation station;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.train_outlined),
    title: Text(
      station.displayName,
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    subtitle: Text(station.secondaryLabel),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: () => Navigator.of(context).pop(station),
  );
}

class _ResultPage extends StatelessWidget {
  const _ResultPage({required this.result});
  final EnokamaResult result;

  @override
  Widget build(BuildContext context) {
    final beneficial = !result.insufficient && result.savings > 0;
    final title = result.insufficient
        ? '비교할 구간이 부족해요'
        : beneficial
        ? '패스가 더 이득이에요'
        : result.savings == 0
        ? '일반 운임과 같아요'
        : '개별 결제가 더 저렴해요';
    final price = result.origin?.passPrice ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('비교 결과')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        children: [
          const _Steps(active: 2),
          const SizedBox(height: 28),
          Text(
            '비교 결과',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          AppSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.confirmation_number_outlined,
                  color: beneficial
                      ? AppColors.success
                      : AppColors.accent(context),
                  size: 34,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: beneficial
                        ? AppColors.success
                        : AppColors.mutedText(context),
                  ),
                ),
                const SizedBox(height: 20),
                const PassResultScopeNote(),
                _AmountRow('일반 운임 합계', result.total),
                if (result.origin?.roundTripApplicable == true)
                  _AmountRow('출발역 ↔ 후지사와 왕복 포함', result.origin!.roundTripFare),
                const Divider(height: 26),
                _AmountRow('패스 가격', price),
                const Divider(height: 26),
                _AmountRow('예상 손익', result.savings, bold: true, signed: true),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const NoticeBanner(
            title: '계산 기준',
            text:
                '선택한 오다큐 출발역의 패스 가격과 후지사와 왕복 성인 IC 운임, 프리구간의 실제 입력 이동만 비교합니다.',
            tone: NoticeTone.info,
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow(
    this.label,
    this.amount, {
    this.bold = false,
    this.signed = false,
  });
  final String label;
  final int amount;
  final bool bold;
  final bool signed;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          '${signed && amount > 0 ? '+' : ''}¥$amount',
          style: TextStyle(
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
            fontSize: bold ? 19 : 16,
          ),
        ),
      ],
    ),
  );
}
