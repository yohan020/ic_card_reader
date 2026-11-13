import 'package:flutter/material.dart';

import 'pass_strings.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../data/hakone_freepass_data.dart';
import 'widgets/pass_segment_remove_button.dart';
import 'widgets/pass_station_picker_field.dart';

class HakoneFreepassPage extends StatefulWidget {
  const HakoneFreepassPage({super.key});

  @override
  State<HakoneFreepassPage> createState() => _HakoneFreepassPageState();
}

class _HakoneFreepassPageState extends State<HakoneFreepassPage> {
  HakoneFreepassData? _data;
  HakoneDeparture? _departure;
  var _days = 2;
  final _segments = <_Draft>[_Draft()];
  final _busCounts = <String, int>{};

  @override
  void initState() {
    super.initState();
    HakoneFreepassDataRepository().load().then((value) {
      if (mounted) setState(() => _data = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null)
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    final price = _departure == null
        ? null
        : data.passPrice(_departure!, _days);
    return Scaffold(
      appBar: AppBar(title: Text(passText(context, '교통패스 비교'))),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            _Steps(),
            SizedBox(height: 24),
            Text(
              passText(context, '이동 계획을 입력해 주세요'),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6),
            Text(
              passText(context, '성인 일반 운임만 기준으로 하코네 프리패스의 손익을 비교합니다.'),
              style: TextStyle(color: AppColors.mutedText(context)),
            ),
            SizedBox(height: 20),
            _HakoneOriginCard(
              departure: _departure,
              price: price,
              days: _days,
              onPick: () => _pickDeparture(data),
              onDaysChanged: (value) => setState(() => _days = value),
            ),
            SizedBox(height: 20),
            SectionLabel(
              passText(context, '이동 구간'),
              trailing: TextButton(
                onPressed: _clear,
                child: Text(passText(context, '비우기')),
              ),
            ),
            AppSurface(
              padding: EdgeInsets.all(14),
              child: Column(
                children: [
                  for (var index = 0; index < _segments.length; index++) ...[
                    _SegmentEditor(
                      index: index,
                      draft: _segments[index],
                      data: data,
                      removable: _segments.length > 1,
                      onChanged: () => setState(() {}),
                      onRemove: () => setState(() => _segments.removeAt(index)),
                    ),
                    if (index != _segments.length - 1)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(),
                      ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => setState(() => _segments.add(_Draft())),
              icon: Icon(Icons.add_rounded),
              label: Text(passText(context, '이동 구간 추가')),
            ),
            SizedBox(height: 18),
            _BusEstimateCard(
              data: data,
              counts: _busCounts,
              onChanged: (id, value) => setState(() => _busCounts[id] = value),
            ),
            SizedBox(height: 16),
            NoticeBanner(
              tone: NoticeTone.info,
              title: passText(context, '버스 운임은 예상값입니다'),
              text: passText(
                context,
                '등산전차·케이블카·로프웨이·해적선은 정확 운임으로, 버스는 평균 운임과 횟수로 계산합니다. 로망스카 특급권은 포함하지 않습니다.',
              ),
            ),
            SizedBox(height: 16),
            FilledButton(
              onPressed: price == null ? null : () => _showResult(data, price),
              child: Text(passText(context, '비교 결과 보기')),
            ),
          ],
        ),
      ),
    );
  }

  void _clear() => setState(() {
    _segments
      ..clear()
      ..add(_Draft());
    _busCounts.clear();
  });

  Future<void> _pickDeparture(HakoneFreepassData data) async {
    final selected = await Navigator.of(context).push<HakoneDeparture>(
      MaterialPageRoute(
        builder: (_) => _HakoneOriginListPage(data: data, days: _days),
      ),
    );
    if (selected != null && mounted) setState(() => _departure = selected);
  }

  void _showResult(HakoneFreepassData data, int price) {
    var exactFare = 0;
    for (final segment in _segments) {
      if (segment.from != null && segment.to != null)
        exactFare +=
            data.fare(segment.from!, segment.to!, mode: segment.mode) ?? 0;
    }
    final busEstimate = data.bus.fold<int>(
      0,
      (sum, item) =>
          sum + ((_busCounts[item['id']] ?? 0) * (item['fare'] as int)),
    );
    final total = exactFare + busEstimate;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          passText(context, total > price ? '패스가 더 이득이에요' : '개별 결제가 더 저렴해요'),
        ),
        content: Text(
          passText(
            context,
            '입력한 교통 이용 기준의 예상 비교입니다.\n버스는 추정 요금이며 실제 요금과 다를 수 있습니다.\n\n패스 가격 ¥$price\n입력 구간 운임 ¥$exactFare\n버스 예상 운임 ¥$busEstimate\n예상 손익 ¥${total - price}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(passText(context, '확인')),
          ),
        ],
      ),
    );
  }
}

class _Draft {
  HakonePlace? from;
  HakonePlace? to;
  String mode = 'rail';
}

class _HakoneOriginCard extends StatelessWidget {
  const _HakoneOriginCard({
    required this.departure,
    required this.price,
    required this.days,
    required this.onPick,
    required this.onDaysChanged,
  });
  final HakoneDeparture? departure;
  final int? price;
  final int days;
  final VoidCallback onPick;
  final ValueChanged<int> onDaysChanged;

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
            SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    passText(
                      context,
                      departure == null ? '하코네 프리패스' : '하코네 프리패스 ${days}일권',
                    ),
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (price != null) ...[
                    SizedBox(height: 2),
                    Text(
                      passText(context, '¥$price'),
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
        SizedBox(height: 12),
        OutlinedButton(
          onPressed: onPick,
          style: OutlinedButton.styleFrom(
            minimumSize: Size.fromHeight(52),
            alignment: Alignment.centerLeft,
            backgroundColor: AppColors.fieldSurface(context),
          ),
          child: Row(
            children: [
              Icon(Icons.train_outlined),
              SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passText(
                        context,
                        departure?.passName(context) ?? '패스 출발역 선택',
                      ),
                      style: TextStyle(
                        color: AppColors.accent(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (departure != null)
                      Text(
                        passText(context, '${departure!.ja} · 오다와라 왕복 1회 포함'),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
        if (departure != null) ...[
          SizedBox(height: 10),
          Row(
            children: [
              for (final value in [2, 3]) ...[
                Expanded(
                  child: _HakoneDurationOption(
                    days: value,
                    price: value == 2 ? departure!.adult2 : departure!.adult3,
                    selected: days == value,
                    onTap: () => onDaysChanged(value),
                  ),
                ),
                if (value == 2) SizedBox(width: 7),
              ],
            ],
          ),
        ],
      ],
    ),
  );
}

class _HakoneDurationOption extends StatelessWidget {
  const _HakoneDurationOption({
    required this.days,
    required this.price,
    required this.selected,
    required this.onTap,
  });
  final int days;
  final int price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: passText(context, '$days일권 $price엔'),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.skyDark : AppColors.softSurface(context),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          children: [
            Text(
              passText(context, '$days일권'),
              style: TextStyle(
                color: selected ? Colors.white : AppColors.accent(context),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 2),
            Text(
              passText(context, '¥$price'),
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

class _Steps extends StatelessWidget {
  const _Steps();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var index = 0; index < 3; index++)
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 2 ? 0 : 5),
            child: Column(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: index <= 1
                        ? AppColors.accent(context)
                        : AppColors.softSurface(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  passText(
                    context,
                    '${index + 1}. ${passText(context, ['패스 선택', '이용 계획', '비교 결과'][index])}',
                  ),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: index == 1 ? FontWeight.w800 : FontWeight.w500,
                    color: index == 1
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
  final HakoneFreepassData data;
  final bool removable;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final fare = draft.from == null || draft.to == null
        ? null
        : data.fare(draft.from!, draft.to!);
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
                passText(context, '${index + 1}'),
                style: TextStyle(
                  color: AppColors.accent(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                passText(context, '이동 구간'),
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            if (removable) PassSegmentRemoveButton(onPressed: onRemove),
          ],
        ),
        SizedBox(height: 16),
        _ModePicker(
          mode: draft.mode,
          onChanged: (value) {
            draft
              ..mode = value
              ..from = null
              ..to = null;
            onChanged();
          },
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _PlaceButton(
                label: '출발',
                place: draft.from,
                data: data,
                mode: draft.mode,
                onSelected: (value) {
                  draft.from = value;
                  onChanged();
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 5),
              child: IconButton(
                onPressed: () {
                  final from = draft.from;
                  draft
                    ..from = draft.to
                    ..to = from;
                  onChanged();
                },
                tooltip: passText(context, '출발·도착 바꾸기'),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.softSurface(context),
                  foregroundColor: AppColors.accent(context),
                ),
                icon: Icon(Icons.swap_horiz_rounded),
              ),
            ),
            Expanded(
              child: _PlaceButton(
                label: '도착',
                place: draft.to,
                data: data,
                mode: draft.mode,
                onSelected: (value) {
                  draft.to = value;
                  onChanged();
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        _FareHint(hasBoth: draft.from != null && draft.to != null, fare: fare),
      ],
    );
  }
}

class _PlaceButton extends StatelessWidget {
  const _PlaceButton({
    required this.label,
    required this.place,
    required this.data,
    required this.mode,
    required this.onSelected,
  });
  final String label;
  final HakonePlace? place;
  final HakoneFreepassData data;
  final String mode;
  final ValueChanged<HakonePlace> onSelected;
  @override
  Widget build(BuildContext context) => PassStationPickerField(
    label: label,
    stationName: place?.passName(context),
    operatorLabel: place == null ? null : place!.detail.split(' · ').last,
    onTap: () async {
      final selected = await Navigator.of(context).push<HakonePlace>(
        MaterialPageRoute(
          builder: (_) => _Search<HakonePlace>(
            title: '$label역 선택',
            items: data.placesForMode(mode),
            search: (query) => data.searchPlace(query, mode),
            label: (item) => item.passName(context),
            detail: (item) => item.detailForMode(mode),
          ),
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
        ? '두 지점을 선택하면 성인 일반 운임을 확인합니다.'
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
        SizedBox(width: 7),
        Expanded(
          child: Text(
            passText(context, message),
            style: TextStyle(
              fontSize: hasBoth ? null : 11,
              color: success ? AppColors.success : AppColors.mutedText(context),
              fontWeight: success ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _ModePicker extends StatelessWidget {
  const _ModePicker({required this.mode, required this.onChanged});
  final String mode;
  final ValueChanged<String> onChanged;
  static const _modes = {
    'rail': ('등산전차', Icons.train_outlined),
    'cable': ('케이블카', Icons.tram_outlined),
    'ropeway': ('로프웨이', Icons.cable_rounded),
    'cruise': ('해적선', Icons.directions_boat_outlined),
  };
  @override
  Widget build(BuildContext context) {
    final current = _modes[mode]!;
    return OutlinedButton(
      onPressed: () => _showPicker(context),
      style: OutlinedButton.styleFrom(
        minimumSize: Size.fromHeight(52),
        alignment: Alignment.centerLeft,
        foregroundColor: AppColors.accent(context),
        backgroundColor: AppColors.fieldSurface(context),
      ),
      child: Row(
        children: [
          Icon(current.$2, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              passText(context, current.$1),
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded),
        ],
      ),
    );
  }

  void _showPicker(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 2, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              passText(context, '교통수단 선택'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 12),
            for (final entry in _modes.entries) ...[
              _ModeOption(
                label: entry.value.$1,
                icon: entry.value.$2,
                selected: entry.key == mode,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onChanged(entry.key);
                },
              ),
              if (entry.key != _modes.keys.last) SizedBox(height: 8),
            ],
          ],
        ),
      ),
    ),
  );
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.softSurface(context) : Colors.transparent,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent(context)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                passText(context, label),
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded, color: AppColors.accent(context)),
          ],
        ),
      ),
    ),
  );
}

class _BusEstimateCard extends StatelessWidget {
  const _BusEstimateCard({
    required this.data,
    required this.counts,
    required this.onChanged,
  });
  final HakoneFreepassData data;
  final Map<String, int> counts;
  final void Function(String id, int value) onChanged;
  @override
  Widget build(BuildContext context) => AppSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          passText(context, '버스 이용 추정'),
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 4),
        Text(
          passText(context, '정류장별 운임이 아닌 사업자별 평균 성인 운임입니다.'),
          style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
        ),
        for (final item in data.bus)
          _Counter(
            label: item['en'] as String,
            note: '약 ¥${item['fare']}/회',
            value: counts[item['id']] ?? 0,
            onChanged: (value) => onChanged(item['id'] as String, value),
          ),
      ],
    ),
  );
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.label,
    required this.note,
    required this.value,
    required this.onChanged,
  });
  final String label, note;
  final int value;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              passText(context, label),
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(passText(context, note)),
          ],
        ),
      ),
      IconButton(
        onPressed: value == 0 ? null : () => onChanged(value - 1),
        icon: Icon(Icons.remove_circle_outline),
      ),
      Text(passText(context, '$value회')),
      IconButton(
        onPressed: () => onChanged(value + 1),
        icon: Icon(Icons.add_circle_outline),
      ),
    ],
  );
}

class _HakoneOriginListPage extends StatefulWidget {
  const _HakoneOriginListPage({required this.data, required this.days});
  final HakoneFreepassData data;
  final int days;
  @override
  State<_HakoneOriginListPage> createState() => _HakoneOriginListPageState();
}

class _HakoneOriginListPageState extends State<_HakoneOriginListPage> {
  final _controller = TextEditingController();
  List<HakoneDeparture> _results = [];
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const lines = ['Odawara Line', 'Enoshima Line', 'Tama Line'];
    return Scaffold(
      appBar: AppBar(title: Text(passText(context, '패스 출발역 선택'))),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Text(
            passText(context, '오다큐 출발역을 선택해 주세요'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 5),
          Text(
            passText(context, '출발역에 따라 ${widget.days}일권 가격이 달라집니다.'),
            style: TextStyle(color: AppColors.mutedText(context)),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _controller,
            onChanged: (query) => setState(
              () => _results = query.trim().isEmpty
                  ? []
                  : widget.data.searchDeparture(query),
            ),
            decoration: InputDecoration(
              hintText: passText(context, '출발역 검색'),
              prefixIcon: Icon(Icons.search_rounded),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _controller.clear();
                        setState(() => _results = []);
                      },
                      icon: Icon(Icons.close_rounded),
                    ),
              filled: true,
              isDense: true,
            ),
          ),
          SizedBox(height: 18),
          if (_controller.text.isNotEmpty) ...[
            SectionLabel(passText(context, '검색 결과 ${_results.length}개')),
            if (_results.isEmpty)
              _OriginEmptyState()
            else
              _HakoneOriginRows(origins: _results),
          ] else ...[
            SectionLabel(passText(context, '노선 선택')),
            for (final line in lines) ...[
              _HakoneOriginLineCard(
                label: _lineLabel(line),
                count: widget.data.departures
                    .where((item) => item.line == line)
                    .length,
                onTap: () => Navigator.of(context)
                    .push<HakoneDeparture>(
                      MaterialPageRoute(
                        builder: (_) => _HakoneOriginLinePage(
                          label: _lineLabel(line),
                          origins: widget.data.departures
                              .where((item) => item.line == line)
                              .toList(),
                          days: widget.days,
                        ),
                      ),
                    )
                    .then((origin) {
                      if (origin != null && context.mounted)
                        Navigator.of(context).pop(origin);
                    }),
              ),
              SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}

class _HakoneOriginLineCard extends StatelessWidget {
  const _HakoneOriginLineCard({
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
      title: Text(
        passText(context, label),
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(passText(context, '$count개 출발역')),
      trailing: Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    ),
  );
}

class _HakoneOriginLinePage extends StatelessWidget {
  const _HakoneOriginLinePage({
    required this.label,
    required this.origins,
    required this.days,
  });
  final String label;
  final List<HakoneDeparture> origins;
  final int days;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(passText(context, label))),
    body: ListView(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Text(
          passText(context, '$label 출발역'),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 5),
        Text(
          passText(context, '출발역을 선택하면 $days일권 가격을 적용합니다.'),
          style: TextStyle(color: AppColors.mutedText(context)),
        ),
        SizedBox(height: 18),
        _HakoneOriginRows(origins: origins),
      ],
    ),
  );
}

class _HakoneOriginRows extends StatelessWidget {
  const _HakoneOriginRows({required this.origins});
  final List<HakoneDeparture> origins;
  @override
  Widget build(BuildContext context) => AppSurface(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (final origin in origins)
          ListTile(
            leading: Icon(Icons.train_outlined),
            title: Text(
              passText(context, origin.passName(context)),
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              passText(context, '${origin.ja} · ${_lineLabel(origin.line)}'),
            ),
            trailing: _OriginPrices(origin: origin),
            onTap: () => Navigator.of(context).pop(origin),
          ),
      ],
    ),
  );
}

class _OriginPrices extends StatelessWidget {
  const _OriginPrices({required this.origin});
  final HakoneDeparture origin;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      _PriceLine(label: '2일', price: origin.adult2),
      SizedBox(height: 2),
      _PriceLine(label: '3일', price: origin.adult3),
    ],
  );
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({required this.label, required this.price});
  final String label;
  final int price;

  @override
  Widget build(BuildContext context) => Text(
    passText(context, '$label ¥$price'),
    style: TextStyle(
      color: AppColors.accent(context),
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _OriginEmptyState extends StatelessWidget {
  const _OriginEmptyState();
  @override
  Widget build(BuildContext context) => AppSurface(
    child: Text(
      passText(context, '일치하는 출발역을 찾지 못했어요. 한글·초성·일본어로 다시 검색해 주세요.'),
      style: TextStyle(color: AppColors.mutedText(context)),
    ),
  );
}

class _Search<T> extends StatefulWidget {
  const _Search({
    required this.title,
    required this.items,
    required this.search,
    required this.label,
    required this.detail,
  });
  final String title;
  final List<T> items;
  final List<T> Function(String) search;
  final String Function(T) label, detail;
  @override
  State<_Search<T>> createState() => _SearchState<T>();
}

class _SearchState<T> extends State<_Search<T>> {
  var _query = '';
  @override
  Widget build(BuildContext context) {
    final items = _query.isEmpty ? widget.items : widget.search(_query);
    return Scaffold(
      appBar: AppBar(title: Text(passText(context, widget.title))),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              autofocus: true,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: passText(context, '역 이름을 검색해 주세요'),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, index) => ListTile(
                title: Text(passText(context, widget.label(items[index]))),
                subtitle: Text(passText(context, widget.detail(items[index]))),
                onTap: () => Navigator.of(context).pop(items[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _lineLabel(String line) => switch (line) {
  'Odawara Line' => '오다와라선',
  'Enoshima Line' => '에노시마선',
  'Tama Line' => '다마선',
  _ => line,
};
