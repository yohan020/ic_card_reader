import 'package:flutter/material.dart';

import 'pass_strings.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import 'widgets/pass_result_scope_note.dart';
import '../data/kyoto_subway_bus_pass_data.dart';
import '../domain/kyoto_subway_bus_pass.dart';
import 'widgets/pass_segment_remove_button.dart';
import 'widgets/pass_station_picker_field.dart';

class KyotoSubwayBusPassPage extends StatefulWidget {
  const KyotoSubwayBusPassPage({super.key});

  @override
  State<KyotoSubwayBusPassPage> createState() => _KyotoSubwayBusPassPageState();
}

class _KyotoSubwayBusPassPageState extends State<KyotoSubwayBusPassPage> {
  KyotoSubwayBusPassData? _data;
  final _segments = <_KyotoDraft>[_KyotoDraft()];
  var _cityBusRides = 0;
  var _sightseeingRides = 0;

  @override
  void initState() {
    super.initState();
    KyotoSubwayBusPassDataRepository().load().then((data) {
      if (mounted) setState(() => _data = data);
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      appBar: AppBar(title: Text(passText(context, '교통패스 비교'))),
      body: data == null
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
              top: false,
              child: ListView(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 32),
                children: [
                  _Steps(active: 1),
                  SizedBox(height: 24),
                  Text(
                    passText(context, '이동 계획을 입력해 주세요'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    passText(context, '교토시영 지하철은 역을 선택하면 성인 운임을 자동으로 찾습니다.'),
                    style: TextStyle(
                      color: AppColors.mutedText(context),
                      height: 1.45,
                    ),
                  ),
                  SizedBox(height: 20),
                  _PassSummary(price: data.passPrice),
                  SizedBox(height: 20),
                  SectionLabel(
                    passText(context, '이동 구간'),
                    trailing: TextButton(
                      onPressed: _clear,
                      child: Text(passText(context, '비우기')),
                    ),
                  ),
                  AppSurface(
                    key: ValueKey('kyoto-journey-plan-card'),
                    padding: EdgeInsets.all(14),
                    child: Column(
                      children: [
                        for (
                          var index = 0;
                          index < _segments.length;
                          index++
                        ) ...[
                          _JourneySegment(
                            index: index,
                            draft: _segments[index],
                            data: data,
                            removable: _segments.length > 1,
                            onChanged: () => setState(() {}),
                            onRemove: () =>
                                setState(() => _segments.removeAt(index)),
                          ),
                          if (index != _segments.length - 1) ...[
                            SizedBox(height: 14),
                            Divider(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                            SizedBox(height: 14),
                          ],
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => _segments.add(_KyotoDraft())),
                    icon: Icon(Icons.add_rounded),
                    label: Text(passText(context, '이동 구간 추가')),
                  ),
                  SizedBox(height: 18),
                  _BusEstimateCard(
                    data: data,
                    cityRides: _cityBusRides,
                    sightseeingRides: _sightseeingRides,
                    onCityChanged: (value) =>
                        setState(() => _cityBusRides = value),
                    onSightseeingChanged: (value) =>
                        setState(() => _sightseeingRides = value),
                  ),
                  SizedBox(height: 18),
                  NoticeBanner(
                    tone: NoticeTone.info,
                    title: passText(context, '버스는 횟수 기반 예상 운임입니다'),
                    text: passText(
                      context,
                      '일반 시내버스와 관광특급버스 횟수만 합산합니다. 실제 노선·사업자·조정 운임 구간·심야 할증과 패스 제외 노선은 자동 판정하지 않습니다.',
                    ),
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
            ),
    );
  }

  void _clear() => setState(() {
    _segments
      ..clear()
      ..add(_KyotoDraft());
    _cityBusRides = 0;
    _sightseeingRides = 0;
  });

  void _showResult(KyotoSubwayBusPassData data) {
    final segments = _segments
        .where((draft) => draft.from != null && draft.to != null)
        .map(
          (draft) => KyotoPlannedSegment(
            from: draft.from!,
            to: draft.to!,
            fare: data.fareBetween(draft.from!, draft.to!) ?? 0,
          ),
        )
        .toList(growable: false);
    final result = KyotoSubwayBusPassEvaluator.evaluate(
      segments: segments,
      cityBusRides: _cityBusRides,
      sightseeingExpressRides: _sightseeingRides,
      data: data,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _KyotoResultPage(result: result, data: data),
      ),
    );
  }
}

class _KyotoDraft {
  KyotoSubwayStation? from;
  KyotoSubwayStation? to;
}

class _Steps extends StatelessWidget {
  const _Steps({required this.active});
  final int active;
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
                    '${index + 1}. ${passText(context, ['패스 선택', '이용 계획', '비교 결과'][index])}',
                  ),
                  style: TextStyle(
                    color: index == active
                        ? AppColors.accent(context)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: index == active
                        ? FontWeight.w800
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

class _PassSummary extends StatelessWidget {
  const _PassSummary({required this.price});
  final int price;
  @override
  Widget build(BuildContext context) => AppSurface(
    padding: EdgeInsets.all(14),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.softSurface(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.directions_bus_filled_outlined,
            color: AppColors.accent(context),
            size: 22,
          ),
        ),
        SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                passText(context, '교토 지하철·버스 1일권'),
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 2),
              Text(
                passText(context, '¥$price'),
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
  );
}

class _JourneySegment extends StatelessWidget {
  const _JourneySegment({
    required this.index,
    required this.draft,
    required this.data,
    required this.removable,
    required this.onChanged,
    required this.onRemove,
  });
  final int index;
  final _KyotoDraft draft;
  final KyotoSubwayBusPassData data;
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
                  onChanged();
                },
                tooltip: passText(context, '출발·도착 바꾸기'),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.softSurface(context),
                  foregroundColor: AppColors.accent(context),
                ),
                constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                visualDensity: VisualDensity.compact,
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

class _StationButton extends StatelessWidget {
  const _StationButton({
    required this.label,
    required this.station,
    required this.data,
    required this.onSelected,
  });
  final String label;
  final KyotoSubwayStation? station;
  final KyotoSubwayBusPassData data;
  final ValueChanged<KyotoSubwayStation> onSelected;
  @override
  Widget build(BuildContext context) => PassStationPickerField(
    label: label,
    stationName: station?.passName(context),
    operatorLabel: station == null ? null : '교토시영 지하철',
    onTap: () async {
      final selected = await Navigator.of(context).push<KyotoSubwayStation>(
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
    final message = !hasBoth
        ? '두 역을 선택하면 운임을 자동으로 확인합니다.'
        : fare == null
        ? '이 구간의 운임을 확인할 수 없습니다.'
        : '성인 일반 운임 ¥$fare';
    final success = fare != null;
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

class _BusEstimateCard extends StatelessWidget {
  const _BusEstimateCard({
    required this.data,
    required this.cityRides,
    required this.sightseeingRides,
    required this.onCityChanged,
    required this.onSightseeingChanged,
  });
  final KyotoSubwayBusPassData data;
  final int cityRides;
  final int sightseeingRides;
  final ValueChanged<int> onCityChanged;
  final ValueChanged<int> onSightseeingChanged;
  @override
  Widget build(BuildContext context) => AppSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          passText(context, '교토 버스 예상 이용'),
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 4),
        Text(
          passText(context, '교토 지하철·버스 1일권 기준 탑승 횟수를 직접 입력해 주세요.'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        SizedBox(height: 10),
        _RideCounter(
          label: '일반 시내버스',
          note: '1회 ¥${data.cityBusFare}',
          value: cityRides,
          onChanged: onCityChanged,
        ),
        Divider(height: 18),
        _RideCounter(
          label: '관광특급버스',
          note: '1회 ¥${data.sightseeingExpressFare}',
          value: sightseeingRides,
          onChanged: onSightseeingChanged,
        ),
      ],
    ),
  );
}

class _RideCounter extends StatelessWidget {
  const _RideCounter({
    required this.label,
    required this.note,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final String note;
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
            Text(
              passText(context, note),
              style: TextStyle(
                color: AppColors.mutedText(context),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      IconButton(
        onPressed: value == 0 ? null : () => onChanged(value - 1),
        tooltip: passText(context, '1회 줄이기'),
        icon: Icon(Icons.remove_circle_outline_rounded),
      ),
      SizedBox(
        width: 34,
        child: Text(
          passText(context, '$value회'),
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      IconButton(
        onPressed: value >= 20 ? null : () => onChanged(value + 1),
        tooltip: passText(context, '1회 늘리기'),
        icon: Icon(Icons.add_circle_outline_rounded),
      ),
    ],
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
          passText(
            context,
            '지하철은 실제 개찰을 통과해 하차한 역을 입력해 주세요. 버스 운임 기준은 설정의 데이터 출처 및 운임 기준에서 확인할 수 있습니다.',
          ),
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
  final KyotoSubwayBusPassData data;
  @override
  State<_StationSearchPage> createState() => _StationSearchPageState();
}

class _StationSearchPageState extends State<_StationSearchPage> {
  final _controller = TextEditingController();
  List<KyotoSubwayStation> _results = [];
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
            key: ValueKey('kyoto-station-search-field'),
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
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 15),
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
                borderSide: BorderSide(color: AppColors.skyDark, width: 1.4),
              ),
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
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.symmetric(vertical: 6),
            itemCount: _results.length,
            separatorBuilder: (_, _) => Divider(height: 1),
            itemBuilder: (context, index) {
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
                  child: Icon(Icons.subway_outlined, color: AppColors.skyDark),
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
  void _search(String query) => setState(
    () => _results = query.trim().isEmpty ? [] : widget.data.search(query),
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 6),
          Text(
            passText(context, description),
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

class _KyotoResultPage extends StatelessWidget {
  const _KyotoResultPage({required this.result, required this.data});
  final KyotoPassComparisonResult result;
  final KyotoSubwayBusPassData data;
  @override
  Widget build(BuildContext context) {
    final (title, description, color) = switch (result.verdict) {
      KyotoPassVerdict.beneficial => (
        '패스가 더 이득이에요',
        '교통비 기준 ¥${result.savings} 절약',
        AppColors.success,
      ),
      KyotoPassVerdict.breakEven => (
        '일반 운임과 같아요',
        '패스 가격과 일반 결제 예상 합계가 같아요',
        AppColors.accent(context),
      ),
      KyotoPassVerdict.notBeneficial => (
        '개별 결제가 더 저렴해요',
        '현재 계획에서는 ¥${-result.savings} 차이',
        AppColors.mutedText(context),
      ),
      KyotoPassVerdict.insufficientData => (
        '비교할 구간이 부족해요',
        '지하철 구간 또는 버스 이용 횟수를 입력해 주세요.',
        AppColors.mutedText(context),
      ),
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(
          passText(context, '비교 결과'),
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 28),
          children: [
            _Steps(active: 2),
            SizedBox(height: 28),
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
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    passText(context, description),
                    style: TextStyle(color: AppColors.mutedText(context)),
                  ),
                  PassResultScopeNote(
                    detail: '버스 대표 요금은 실제 이용 구간의 요금과 다를 수 있습니다.',
                  ),
                  SizedBox(height: 20),
                  _AmountRow('지하철 일반 운임', result.railFareTotal),
                  _AmountRow('버스 예상 운임', result.busFareTotal),
                  Divider(height: 26),
                  _AmountRow(
                    '일반 결제 예상 합계',
                    result.regularFareTotal,
                    bold: true,
                  ),
                  _AmountRow('패스 가격', data.passPrice),
                  Divider(height: 26),
                  _AmountRow('예상 손익', result.savings, bold: true, signed: true),
                ],
              ),
            ),
            SizedBox(height: 18),
            NoticeBanner(
              tone: NoticeTone.info,
              title: passText(context, '계산 기준'),
              text: passText(
                context,
                '교토시영 지하철은 역 선택 기반 성인 일반 운임, 버스는 입력한 횟수 기반 예상 운임입니다.',
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
                        leading: Icon(Icons.subway_outlined),
                        title: Text(
                          passText(
                            context,
                            '${segment.from.passName(context)} → ${segment.to.passName(context)}',
                          ),
                        ),
                        subtitle: Text(passText(context, '교토시영 지하철')),
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
    padding: EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            passText(context, label),
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          passText(context, '${signed && amount > 0 ? '+' : ''}¥$amount'),
          style: TextStyle(
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
            fontSize: bold ? 19 : 16,
          ),
        ),
      ],
    ),
  );
}
