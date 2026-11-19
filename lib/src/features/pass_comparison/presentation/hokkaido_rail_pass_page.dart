import 'package:flutter/material.dart';

import 'pass_strings.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import 'widgets/pass_result_scope_note.dart';
import '../data/hokkaido_rail_pass_data.dart';
import '../domain/hokkaido_rail_pass.dart';
import 'widgets/pass_segment_remove_button.dart';
import 'widgets/pass_station_picker_field.dart';

class HokkaidoRailPassPage extends StatefulWidget {
  const HokkaidoRailPassPage({super.key});

  @override
  State<HokkaidoRailPassPage> createState() => _HokkaidoRailPassPageState();
}

class _HokkaidoRailPassPageState extends State<HokkaidoRailPassPage> {
  HokkaidoRailPassData? _data;
  Object? _error;
  final _segments = <_DraftSegment>[_DraftSegment()];
  var _days = 5;
  var _estimatedBusRides = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final data = await HokkaidoRailPassDataRepository().load();
      if (mounted) setState(() => _data = data);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      appBar: AppBar(title: Text(passText(context, '교통패스 비교'))),
      body: data == null
          ? _error == null
                ? Center(child: CircularProgressIndicator())
                : _LoadFailure(onRetry: _load)
          : AppPage(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 32),
              children: [
                _Steps(active: 1),
                SizedBox(height: 24),
                Text(
                  passText(context, '이동 계획을 입력해 주세요'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  passText(context, 'JR 홋카이도 역을 선택하면 성인 일반 운임을 자동으로 찾습니다.'),
                  style: TextStyle(
                    color: AppColors.mutedText(context),
                    height: 1.45,
                  ),
                ),
                SizedBox(height: 20),
                _PassSummary(
                  days: _days,
                  onDaysSelected: (value) => setState(() => _days = value),
                ),
                SizedBox(height: 24),
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
                      for (
                        var index = 0;
                        index < _segments.length;
                        index++
                      ) ...[
                        _SegmentEditor(
                          index: index,
                          data: data,
                          draft: _segments[index],
                          removable: _segments.length > 1,
                          onChanged: () => setState(() {}),
                          onRemove: () =>
                              setState(() => _segments.removeAt(index)),
                        ),
                        if (index + 1 < _segments.length)
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
                  onPressed: () =>
                      setState(() => _segments.add(_DraftSegment())),
                  icon: Icon(Icons.add_rounded),
                  label: Text(passText(context, '이동 구간 추가')),
                ),
                SizedBox(height: 18),
                _BusEstimate(
                  rides: _estimatedBusRides,
                  onChanged: (value) =>
                      setState(() => _estimatedBusRides = value),
                ),
                SizedBox(height: 18),
                FilledButton(
                  onPressed: () => _showResult(data),
                  child: Text(passText(context, '비교 결과 보기')),
                ),
                SizedBox(height: 12),
                _Footnote(),
              ],
            ),
    );
  }

  void _clear() => setState(() {
    _segments
      ..clear()
      ..add(_DraftSegment());
    _estimatedBusRides = 0;
  });

  void _showResult(HokkaidoRailPassData data) {
    final planned = _segments
        .where((draft) => draft.from != null && draft.to != null)
        .map((draft) {
          final limitedExpressFare = data.limitedExpressFareBetween(
            draft.from!,
            draft.to!,
          );
          final fare =
              draft.mode == HokkaidoRailTravelMode.limitedExpress &&
                  limitedExpressFare != null
              ? limitedExpressFare.normalTotalYen
              : data.basicFareBetween(draft.from!, draft.to!) ?? 0;
          return HokkaidoRailPassPlannedSegment(
            from: draft.from!,
            to: draft.to!,
            fare: fare,
            mode: draft.mode,
          );
        })
        .toList(growable: false);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ResultPage(
          result: HokkaidoRailPassEvaluator.evaluate(
            segments: planned,
            estimatedBusRides: _estimatedBusRides,
            passPrice: HokkaidoRailPassData.stationPurchasePrices[_days]!,
          ),
        ),
      ),
    );
  }
}

class _DraftSegment {
  HokkaidoRailPassStation? from;
  HokkaidoRailPassStation? to;
  HokkaidoRailTravelMode mode = HokkaidoRailTravelMode.localRapid;
}

class _Steps extends StatelessWidget {
  const _Steps({required this.active});
  final int active;

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
                    color: index <= active
                        ? AppColors.accent(context)
                        : AppColors.softSurface(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  passText(
                    context,
                    '${index + 1}. ${passText(context, labels[index])}',
                  ),
                  style: TextStyle(
                    color: index == active
                        ? AppColors.accent(context)
                        : AppColors.mutedText(context),
                    fontSize: 11,
                    fontWeight: index == active
                        ? FontWeight.w800
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (index != labels.length - 1) SizedBox(width: 5),
        ],
      ],
    );
  }
}

class _PassSummary extends StatelessWidget {
  const _PassSummary({required this.days, required this.onDaysSelected});

  final int days;
  final ValueChanged<int> onDaysSelected;

  @override
  Widget build(BuildContext context) => AppSurface(
    padding: EdgeInsets.all(15),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.softSurface(context),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.confirmation_number_outlined,
                color: AppColors.accent(context),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    passText(context, '홋카이도 레일패스 $days일권'),
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 2),
                  Text(
                    passText(
                      context,
                      '¥${HokkaidoRailPassData.stationPurchasePrices[days]}',
                    ),
                    style: TextStyle(
                      color: AppColors.accent(context),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        Row(
          children: [
            for (final option in [5, 7, 10]) ...[
              Expanded(
                child: _PeriodOption(
                  days: option,
                  price: HokkaidoRailPassData.stationPurchasePrices[option]!,
                  selected: days == option,
                  onTap: () => onDaysSelected(option),
                ),
              ),
              if (option != 10) SizedBox(width: 7),
            ],
          ],
        ),
        SizedBox(height: 9),
        Text(
          passText(context, '역 구매 가격 · 사전 구매 시 ¥1,000 저렴'),
          style: TextStyle(color: AppColors.mutedText(context), fontSize: 11),
        ),
      ],
    ),
  );
}

class _PeriodOption extends StatelessWidget {
  const _PeriodOption({
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
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AppColors.accent(context);
    return Semantics(
      button: true,
      selected: selected,
      label: passText(context, '$days일권 ¥$price'),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.skyDark
                  : AppColors.softSurface(context),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  passText(context, '$days일권'),
                  style: TextStyle(
                    color: foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  passText(context, '¥$price'),
                  style: TextStyle(
                    color: foreground,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentEditor extends StatelessWidget {
  const _SegmentEditor({
    required this.index,
    required this.data,
    required this.draft,
    required this.removable,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final HokkaidoRailPassData data;
  final _DraftSegment draft;
  final bool removable;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final basicFare = draft.from == null || draft.to == null
        ? null
        : data.basicFareBetween(draft.from!, draft.to!);
    final limitedExpressFare = draft.from == null || draft.to == null
        ? null
        : data.limitedExpressFareBetween(draft.from!, draft.to!);
    final fare = draft.mode == HokkaidoRailTravelMode.limitedExpress
        ? limitedExpressFare?.normalTotalYen
        : basicFare;
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
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StationButton(
                label: '출발',
                station: draft.from,
                data: data,
                onSelected: (station) {
                  draft.from = station;
                  _resetUnsupportedMode();
                  onChanged();
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 5),
              child: IconButton(
                onPressed: () {
                  final from = draft.from;
                  draft.from = draft.to;
                  draft.to = from;
                  _resetUnsupportedMode();
                  onChanged();
                },
                tooltip: passText(context, '출발·도착 바꾸기'),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.softSurface(context),
                  foregroundColor: AppColors.accent(context),
                ),
                icon: Icon(Icons.swap_horiz_rounded, size: 20),
              ),
            ),
            Expanded(
              child: _StationButton(
                label: '도착',
                station: draft.to,
                data: data,
                onSelected: (station) {
                  draft.to = station;
                  _resetUnsupportedMode();
                  onChanged();
                },
              ),
            ),
          ],
        ),
        if (limitedExpressFare != null) ...[
          SizedBox(height: 12),
          _TravelModeSelector(
            selected: draft.mode,
            onSelected: (mode) {
              draft.mode = mode;
              onChanged();
            },
          ),
        ],
        SizedBox(height: 8),
        _FareHint(fare: fare, hasBoth: draft.from != null && draft.to != null),
      ],
    );
  }

  void _resetUnsupportedMode() {
    final from = draft.from;
    final to = draft.to;
    if (from == null ||
        to == null ||
        data.limitedExpressFareBetween(from, to) == null) {
      draft.mode = HokkaidoRailTravelMode.localRapid;
    }
  }
}

class _TravelModeSelector extends StatelessWidget {
  const _TravelModeSelector({required this.selected, required this.onSelected});

  final HokkaidoRailTravelMode selected;
  final ValueChanged<HokkaidoRailTravelMode> onSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        passText(context, '이용 열차'),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      SizedBox(height: 7),
      Row(
        children: [
          Expanded(
            child: _TravelModeOption(
              label: '보통·쾌속',
              selected: selected == HokkaidoRailTravelMode.localRapid,
              onTap: () => onSelected(HokkaidoRailTravelMode.localRapid),
            ),
          ),
          SizedBox(width: 7),
          Expanded(
            child: _TravelModeOption(
              label: '특급',
              selected: selected == HokkaidoRailTravelMode.limitedExpress,
              onTap: () => onSelected(HokkaidoRailTravelMode.limitedExpress),
            ),
          ),
        ],
      ),
    ],
  );
}

class _TravelModeOption extends StatelessWidget {
  const _TravelModeOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: passText(context, label),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Ink(
          height: 42,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.skyDark
                : AppColors.softSurface(context),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Center(
            child: Text(
              passText(context, label),
              style: TextStyle(
                color: selected ? Colors.white : AppColors.accent(context),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _StationButton extends StatelessWidget {
  const _StationButton({
    required this.label,
    required this.station,
    required this.data,
    required this.onSelected,
  });

  final String label;
  final HokkaidoRailPassStation? station;
  final HokkaidoRailPassData data;
  final ValueChanged<HokkaidoRailPassStation> onSelected;

  @override
  Widget build(BuildContext context) => PassStationPickerField(
    label: label,
    stationName: station?.passName(context),
    operatorLabel: station?.passSecondary(context).split(' · ').last,
    onTap: () async {
      final value = await Navigator.of(context).push<HokkaidoRailPassStation>(
        MaterialPageRoute(
          builder: (_) => _StationSearchPage(title: '$label역 선택', data: data),
        ),
      );
      if (value != null) onSelected(value);
    },
  );
}

class _FareHint extends StatelessWidget {
  const _FareHint({required this.fare, required this.hasBoth});

  final int? fare;
  final bool hasBoth;

  @override
  Widget build(BuildContext context) {
    final valid = fare != null;
    final text = !hasBoth
        ? '두 역을 선택하면 운임을 자동으로 확인합니다.'
        : valid
        ? '성인 일반 운임 ¥$fare'
        : '이 구간의 운임을 확인할 수 없습니다.';
    return Row(
      children: [
        Icon(
          valid
              ? Icons.check_circle_outline_rounded
              : Icons.info_outline_rounded,
          size: 18,
          color: valid ? AppColors.success : AppColors.mutedText(context),
        ),
        SizedBox(width: 7),
        Expanded(
          child: Text(
            passText(context, text),
            style: TextStyle(
              fontSize: hasBoth ? null : 11,
              color: valid ? AppColors.success : AppColors.mutedText(context),
              fontWeight: valid ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _BusEstimate extends StatelessWidget {
  const _BusEstimate({required this.rides, required this.onChanged});

  final int rides;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => AppSurface(
    padding: EdgeInsets.all(15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          passText(context, 'JR 홋카이도 버스'),
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 3),
        Text(
          passText(context, '1회 예상 ¥300'),
          style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                passText(context, '이용 횟수'),
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              onPressed: rides == 0 ? null : () => onChanged(rides - 1),
              tooltip: passText(context, '버스 이용 횟수 줄이기'),
              icon: Icon(Icons.remove_circle_outline_rounded),
            ),
            SizedBox(
              width: 38,
              child: Text(
                passText(context, '$rides회'),
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              onPressed: () => onChanged(rides + 1),
              tooltip: passText(context, '버스 이용 횟수 늘리기'),
              icon: Icon(Icons.add_circle_outline_rounded),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Footnote extends StatelessWidget {
  const _Footnote();

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        Icons.info_outline_rounded,
        size: 17,
        color: AppColors.mutedText(context),
      ),
      SizedBox(width: 7),
      Expanded(
        child: Text(
          passText(context, '특급은 보통차 지정석 기준으로 계산합니다. 버스는 1회 ¥300의 예상값입니다.'),
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

class _StationSearchPage extends StatefulWidget {
  const _StationSearchPage({required this.title, required this.data});

  final String title;
  final HokkaidoRailPassData data;

  @override
  State<_StationSearchPage> createState() => _StationSearchPageState();
}

class _StationSearchPageState extends State<_StationSearchPage> {
  final _controller = TextEditingController();
  List<HokkaidoRailPassStation> _results = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(passText(context, widget.title)),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(78),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 14),
          child: TextField(
            key: ValueKey('hokkaido-rail-pass-station-search-field'),
            controller: _controller,
            autofocus: true,
            onChanged: _search,
            decoration: InputDecoration(
              hintText: passText(context, '역 이름을 검색해 주세요'),
              prefixIcon: Icon(Icons.search_rounded),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _controller.clear();
                        _search('');
                      },
                      icon: Icon(Icons.close_rounded),
                    ),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ),
    ),
    body: _controller.text.trim().isEmpty
        ? _SearchState(
            icon: Icons.search_rounded,
            title: '찾고 싶은 역을 입력해 주세요',
            description: '한국어·초성·일본어·영어로 검색할 수 있습니다.',
          )
        : _results.isEmpty
        ? _SearchState(
            icon: Icons.location_off_outlined,
            title: '일치하는 역을 찾지 못했어요',
            description: '다른 표기나 초성으로 다시 검색해 주세요.',
          )
        : ListView.separated(
            padding: EdgeInsets.symmetric(vertical: 6),
            itemCount: _results.length,
            separatorBuilder: (_, _) => Divider(height: 1),
            itemBuilder: (_, index) {
              final station = _results[index];
              return ListTile(
                contentPadding: EdgeInsets.symmetric(
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
                  child: Icon(Icons.train_outlined, color: AppColors.skyDark),
                ),
                title: Text(
                  passText(context, station.passName(context)),
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  passText(context, station.passSecondary(context)),
                ),
                trailing: Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).pop(station),
              );
            },
          ),
  );

  void _search(String value) => setState(
    () => _results = value.trim().isEmpty ? [] : widget.data.search(value),
  );
}

class _SearchState extends StatelessWidget {
  const _SearchState({
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
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.skySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.skyDark, size: 29),
          ),
          SizedBox(height: 16),
          Text(
            passText(context, title),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            passText(context, description),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedText(context), height: 1.4),
          ),
        ],
      ),
    ),
  );
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 38),
          SizedBox(height: 12),
          Text(
            passText(context, '패스 데이터를 불러오지 못했어요'),
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 10),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(passText(context, '다시 시도')),
          ),
        ],
      ),
    ),
  );
}

class _ResultPage extends StatelessWidget {
  const _ResultPage({required this.result});
  final HokkaidoRailPassComparisonResult result;

  @override
  Widget build(BuildContext context) {
    final (title, description, color) = switch (result.verdict) {
      HokkaidoRailPassVerdict.beneficial => (
        '패스가 더 이득이에요',
        '교통비 기준 ¥${result.savings} 절약',
        AppColors.success,
      ),
      HokkaidoRailPassVerdict.breakEven => (
        '일반 운임과 같아요',
        '패스 가격과 일반 결제 예상 합계가 같아요',
        AppColors.accent(context),
      ),
      HokkaidoRailPassVerdict.notBeneficial => (
        '개별 결제가 더 저렴해요',
        '현재 계획에서는 ¥${-result.savings} 차이',
        AppColors.mutedText(context),
      ),
      HokkaidoRailPassVerdict.insufficientData => (
        '비교할 구간이 부족해요',
        '출발역과 도착역을 선택해 주세요',
        AppColors.mutedText(context),
      ),
    };
    return Scaffold(
      appBar: AppBar(title: Text(passText(context, '비교 결과'))),
      body: AppPage(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          _Steps(active: 2),
          SizedBox(height: 26),
          Text(
            passText(context, '비교 결과'),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 14),
          AppSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.confirmation_number_outlined,
                  color: color,
                  size: 34,
                ),
                SizedBox(height: 12),
                Text(
                  passText(context, title),
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  passText(context, description),
                  style: TextStyle(color: AppColors.mutedText(context)),
                ),
                PassResultScopeNote(
                  detail: '버스는 추정 요금이며, 실제 경로·환승 운임에 따라 차이가 날 수 있습니다.',
                ),
                SizedBox(height: 20),
                _AmountRow('철도 일반 운임', result.railFareTotal),
                if (result.estimatedBusValue > 0) ...[
                  Divider(height: 26),
                  _AmountRow('버스 예상 운임', result.estimatedBusValue),
                ],
                Divider(height: 26),
                _AmountRow('패스 가격', result.passPrice),
                Divider(height: 26),
                _AmountRow('예상 손익', result.savings, bold: true, signed: true),
              ],
            ),
          ),
          SizedBox(height: 18),
          NoticeBanner(
            title: passText(context, '계산 기준'),
            text: passText(
              context,
              'JR 홋카이도선의 성인 운임을 계산합니다. 특급은 보통차 지정석만, 버스는 1회 ¥300 예상값만 반영합니다.',
            ),
          ),
          if (result.segments.isNotEmpty) ...[
            SizedBox(height: 18),
            SectionLabel(passText(context, '이동별 상세')),
            SizedBox(height: 8),
            AppSurface(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final segment in result.segments)
                    ListTile(
                      leading: Icon(Icons.train_outlined),
                      title: Text(
                        passText(
                          context,
                          '${segment.from.passName(context)} → ${segment.to.passName(context)}',
                        ),
                      ),
                      subtitle: Text(
                        passText(
                          context,
                          segment.mode == HokkaidoRailTravelMode.limitedExpress
                              ? 'JR 홋카이도 · 특급'
                              : 'JR 홋카이도 · 보통·쾌속',
                        ),
                      ),
                      trailing: Text(
                        passText(context, '¥${segment.fare}'),
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                ],
              ),
            ),
          ],
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
  Widget build(BuildContext context) {
    final prefix = signed && amount > 0 ? '+' : '';
    return Row(
      children: [
        Expanded(child: Text(passText(context, label))),
        Text(
          passText(context, '$prefix¥$amount'),
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
