import 'package:flutter/material.dart';

import 'pass_strings.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import 'widgets/pass_result_scope_note.dart';
import '../data/sapporo_subway_pass_data.dart';
import '../domain/sapporo_subway_pass.dart';
import 'widgets/pass_segment_remove_button.dart';
import 'widgets/pass_station_picker_field.dart';

class SapporoSubwayPassPage extends StatefulWidget {
  const SapporoSubwayPassPage({super.key});

  @override
  State<SapporoSubwayPassPage> createState() => _SapporoSubwayPassPageState();
}

class _SapporoSubwayPassPageState extends State<SapporoSubwayPassPage> {
  SapporoSubwayPassData? _data;
  Object? _error;
  final _segments = <_DraftSegment>[_DraftSegment()];
  var _passType = SapporoSubwayPassType.standardDay;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final data = await SapporoSubwayPassDataRepository().load();
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
          ? (_error == null
                ? Center(child: CircularProgressIndicator())
                : _LoadFailure(onRetry: _load))
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
                  passText(context, '삿포로시 지하철 역을 선택하면 성인 일반 운임을 자동으로 찾습니다.'),
                  style: TextStyle(
                    color: AppColors.mutedText(context),
                    height: 1.45,
                  ),
                ),
                SizedBox(height: 20),
                _PassSummary(
                  passType: _passType,
                  onPassTypeSelected: (value) =>
                      setState(() => _passType = value),
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
  });

  void _showResult(SapporoSubwayPassData data) {
    final planned = _segments
        .where((item) => item.from != null && item.to != null)
        .map(
          (item) => SapporoSubwayPlannedSegment(
            from: item.from!,
            to: item.to!,
            fare: data.fareBetween(item.from!, item.to!) ?? 0,
          ),
        )
        .toList(growable: false);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ResultPage(
          result: SapporoSubwayPassEvaluator.evaluate(
            planned,
            passType: _passType,
          ),
        ),
      ),
    );
  }
}

class _DraftSegment {
  SapporoSubwayStation? from;
  SapporoSubwayStation? to;
}

class _Steps extends StatelessWidget {
  const _Steps({required this.active});
  final int active;
  @override
  Widget build(BuildContext context) {
    const labels = ['패스 선택', '이용 계획', '비교 결과'];
    return Row(
      children: [
        for (var index = 0; index < labels.length; index++)
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
          ),
      ],
    );
  }
}

class _PassSummary extends StatelessWidget {
  const _PassSummary({
    required this.passType,
    required this.onPassTypeSelected,
  });

  final SapporoSubwayPassType passType;
  final ValueChanged<SapporoSubwayPassType> onPassTypeSelected;

  @override
  Widget build(BuildContext context) => AppSurface(
    padding: EdgeInsets.all(15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                Icons.subway_outlined,
                color: AppColors.accent(context),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    passText(context, passType.displayName),
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 2),
                  Text(
                    passText(context, '¥${passType.price}'),
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
        SizedBox(height: 13),
        Row(
          children: [
            for (final option in SapporoSubwayPassType.values) ...[
              Expanded(
                child: _PassTypeOption(
                  passType: option,
                  selected: passType == option,
                  onTap: () => onPassTypeSelected(option),
                ),
              ),
              if (option != SapporoSubwayPassType.donichika) SizedBox(width: 7),
            ],
          ],
        ),
        if (passType == SapporoSubwayPassType.donichika) ...[
          SizedBox(height: 10),
          Text(
            passText(context, '토·일·공휴일 및 12/29~1/3에만 이용할 수 있어요.'),
            style: TextStyle(
              color: AppColors.mutedText(context),
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ],
    ),
  );
}

class _PassTypeOption extends StatelessWidget {
  const _PassTypeOption({
    required this.passType,
    required this.selected,
    required this.onTap,
  });

  final SapporoSubwayPassType passType;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected
        ? AppColors.accent(context)
        : AppColors.softSurface(context),
    borderRadius: BorderRadius.circular(11),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              passText(context, passType.optionName),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.accent(context),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 7),
            Text(
              passText(context, '¥${passType.price}'),
              style: TextStyle(
                color: selected ? Colors.white : AppColors.accent(context),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
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
  final SapporoSubwayPassData data;
  final _DraftSegment draft;
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
                  draft.from = draft.to;
                  draft.to = from;
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
                onSelected: (value) {
                  draft.to = value;
                  onChanged();
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        _FareHint(fare: fare, hasBoth: draft.from != null && draft.to != null),
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
  final SapporoSubwayStation? station;
  final SapporoSubwayPassData data;
  final ValueChanged<SapporoSubwayStation> onSelected;
  @override
  Widget build(BuildContext context) => PassStationPickerField(
    label: label,
    stationName: station?.passName(context),
    operatorLabel: station == null ? null : '삿포로시 지하철',
    onTap: () async {
      final value = await Navigator.of(context).push<SapporoSubwayStation>(
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
            '삿포로시 지하철의 성인 일반 운임만 계산합니다. 다른 회사 환승과 할인은 포함하지 않습니다.',
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
  final SapporoSubwayPassData data;
  @override
  State<_StationSearchPage> createState() => _StationSearchPageState();
}

class _StationSearchPageState extends State<_StationSearchPage> {
  final _controller = TextEditingController();
  List<SapporoSubwayStation> _results = [];
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
            key: ValueKey('sapporo-subway-station-search-field'),
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
  final SapporoSubwayPassComparisonResult result;
  @override
  Widget build(BuildContext context) {
    final (title, description, color) = switch (result.verdict) {
      SapporoSubwayPassVerdict.beneficial => (
        '패스가 더 이득이에요',
        '교통비 기준 ¥${result.savings} 절약',
        AppColors.success,
      ),
      SapporoSubwayPassVerdict.breakEven => (
        '일반 운임과 같아요',
        '패스 가격과 일반 결제 예상 합계가 같아요',
        AppColors.accent(context),
      ),
      SapporoSubwayPassVerdict.notBeneficial => (
        '개별 결제가 더 저렴해요',
        '현재 계획에서는 ¥${-result.savings} 차이',
        AppColors.mutedText(context),
      ),
      SapporoSubwayPassVerdict.insufficientData => (
        '비교할 구간이 부족해요',
        '삿포로시 지하철 이동 구간을 입력해 주세요.',
        AppColors.mutedText(context),
      ),
    };
    return Scaffold(
      appBar: AppBar(title: Text(passText(context, '비교 결과'))),
      body: AppPage(
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
                PassResultScopeNote(),
                SizedBox(height: 20),
                _AmountRow('삿포로시 지하철 일반 운임', result.regularFareTotal),
                Divider(height: 26),
                _AmountRow('패스 가격', result.passType.price),
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
              '${result.passType.displayName} 기준으로 삿포로시 지하철의 성인 일반 운임만 합산합니다. 다른 회사 환승·할인과 소아요금은 포함하지 않습니다.',
            ),
          ),
          if (result.segments.isNotEmpty) ...[
            SizedBox(height: 18),
            SectionLabel(passText(context, '이동별 상세')),
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
                      subtitle: Text(passText(context, '삿포로시 지하철')),
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
