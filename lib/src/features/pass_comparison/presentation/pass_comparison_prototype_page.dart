import 'package:flutter/material.dart';

import 'pass_strings.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import 'widgets/pass_result_scope_note.dart';
import '../data/pass_transit_data.dart';
import '../domain/pass_comparison.dart';
import 'widgets/pass_segment_remove_button.dart';
import 'widgets/pass_station_picker_field.dart';

class PassComparisonPrototypePage extends StatefulWidget {
  const PassComparisonPrototypePage({
    this.initialData,
    this.initialProduct = PassProduct.tokyoSubway24,
    super.key,
  });

  final PassTransitData? initialData;
  final PassProduct initialProduct;

  @override
  State<PassComparisonPrototypePage> createState() =>
      _PassComparisonPrototypePageState();
}

class _PassComparisonPrototypePageState
    extends State<PassComparisonPrototypePage> {
  late PassProduct _product;
  late DateTime _validFrom;
  final List<_SegmentDraft> _drafts = [];
  PassTransitData? _transitData;
  Object? _dataLoadError;
  int _nextId = 1;

  @override
  void initState() {
    super.initState();
    _product = widget.initialProduct;
    final now = DateTime.now();
    _validFrom = DateTime(now.year, now.month, now.day);
    _transitData = widget.initialData;
    _addDraft(notify: false);
    if (_transitData == null) _loadTransitData();
  }

  Future<void> _loadTransitData() async {
    try {
      final data = await PassTransitDataRepository().load();
      if (!mounted) return;
      setState(() => _transitData = data);
    } catch (error) {
      if (!mounted) return;
      setState(() => _dataLoadError = error);
    }
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _clearAll() {
    setState(() {
      for (final draft in _drafts) {
        draft.dispose();
      }
      _drafts.clear();
      _addDraft(notify: false);
    });
  }

  void _addDraft({bool notify = true}) {
    void action() {
      _drafts.add(_SegmentDraft(id: _nextId++, dayIndex: 0));
    }

    if (notify) {
      setState(action);
    } else {
      action();
    }
  }

  void _removeDraft(_SegmentDraft draft) {
    setState(() {
      _drafts.remove(draft);
      draft.dispose();
    });
  }

  List<PlannedTransitSegment> get _validSegments {
    final segments = <PlannedTransitSegment>[];
    for (final draft in _drafts) {
      final fare = draft.resolvedFare;
      final from = draft.fromStation;
      final to = draft.toStation;
      if (fare == null || from == null || to == null) continue;
      segments.add(
        PlannedTransitSegment(
          id: draft.id,
          departureAt: _segmentDepartureAt(draft),
          fromStation: from.passName(context),
          toStation: to.passName(context),
          coverage: draft.coverage,
          regularFare: fare,
        ),
      );
    }
    return segments;
  }

  DateTime _segmentDepartureAt(_SegmentDraft draft) =>
      _product.isTokyoSubwayTicket
      ? DateTime(
          _validFrom.year,
          _validFrom.month,
          _validFrom.day + draft.dayIndex,
        )
      : DateTime(_validFrom.year, _validFrom.month, _validFrom.day);

  void _changeProduct(PassProduct product) {
    if (_product == product) return;
    setState(() {
      _product = product;
      final dayCount = product.duration.inDays;
      for (final draft in _drafts) {
        if (draft.dayIndex >= dayCount) draft.dayIndex = 0;
        _resolveDraft(draft);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(passText(context, '교통패스 비교'))),
      body: SafeArea(
        top: false,
        child: ListView(
          key: ValueKey('pass-comparison-planner-scroll'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            _PlannerProgress(),
            SizedBox(height: 24),
            Text(
              passText(context, '이동 계획을 입력해 주세요'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            SizedBox(height: 6),
            Text(
              passText(context, '실제로 개찰을 통과할 출발역과 하차역을 입력하면 운임을 자동으로 찾습니다.'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            SizedBox(height: 20),
            _buildPlanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanner() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (_dataLoadError != null)
        NoticeBanner(
          title: passText(context, '운임 데이터를 읽지 못했습니다'),
          text: passText(context, '역과 운임 데이터를 준비한 뒤 다시 시도해 주세요.'),
          tone: NoticeTone.warning,
        ),
      if (_dataLoadError != null) SizedBox(height: 12),
      _SelectedPassSummary(product: _product, onChangeProduct: _changeProduct),
      SizedBox(height: 20),
      SectionLabel(
        passText(context, '이동 구간'),
        trailing: TextButton(
          onPressed: _clearAll,
          child: Text(passText(context, '비우기')),
        ),
      ),
      AppSurface(
        key: ValueKey('journey-plan-card'),
        padding: EdgeInsets.all(14),
        child: Column(
          children: [
            for (var index = 0; index < _drafts.length; index++) ...[
              _SegmentEditor(
                key: ValueKey(_drafts[index].id),
                index: index,
                draft: _drafts[index],
                data: _transitData,
                product: _product,
                canRemove: _drafts.length > 1,
                onChanged: () {
                  _resolveDraft(_drafts[index]);
                  setState(() {});
                },
                onSwap: () {
                  _drafts[index].swapStations();
                  _resolveDraft(_drafts[index]);
                  setState(() {});
                },
                onRemove: () => _removeDraft(_drafts[index]),
              ),
              if (index != _drafts.length - 1) ...[
                SizedBox(height: 14),
                Divider(color: Theme.of(context).colorScheme.outlineVariant),
                SizedBox(height: 14),
              ],
            ],
          ],
        ),
      ),
      SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: _addDraft,
        icon: Icon(Icons.add_rounded),
        label: Text(passText(context, '이동 구간 추가')),
      ),
      SizedBox(height: 18),
      FilledButton(
        onPressed: _openResult,
        child: Text(passText(context, '비교 결과 보기')),
      ),
      SizedBox(height: 12),
      _PlannerFootnote(),
    ],
  );

  void _openResult() {
    final result = PassComparisonEvaluator.evaluate(
      product: _product,
      validFrom: _validFrom,
      segments: _validSegments,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PassComparisonResultPage(result: result),
      ),
    );
  }

  void _resolveDraft(_SegmentDraft draft) {
    final data = _transitData;
    final from = draft.fromStation;
    final to = draft.toStation;
    if (data == null || from == null || to == null) {
      draft.resolvedFare = null;
      return;
    }
    final resolved = data.resolveFare(from, to);
    draft.resolvedFare = resolved?.fare;
    if (resolved != null) draft.coverage = resolved.coverage;
  }
}

class _SelectedPassSummary extends StatelessWidget {
  const _SelectedPassSummary({
    required this.product,
    required this.onChangeProduct,
  });

  final PassProduct product;
  final ValueChanged<PassProduct> onChangeProduct;

  @override
  Widget build(BuildContext context) => AppSurface(
    padding: EdgeInsets.all(14),
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
                product.isTokyoSubwayTicket
                    ? Icons.subway_outlined
                    : Icons.train_outlined,
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
                      product.isTokyoSubwayTicket
                          ? 'Tokyo Subway Ticket'
                          : product.label,
                    ),
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 2),
                  Text(
                    passText(context, '¥${product.price}'),
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
        if (product.isTokyoSubwayTicket) ...[
          SizedBox(height: 10),
          _TicketDurationSelector(value: product, onChanged: onChangeProduct),
        ],
      ],
    ),
  );
}

class _TicketDurationSelector extends StatelessWidget {
  const _TicketDurationSelector({required this.value, required this.onChanged});

  final PassProduct value;
  final ValueChanged<PassProduct> onChanged;

  @override
  Widget build(BuildContext context) {
    const products = [
      PassProduct.tokyoSubway24,
      PassProduct.tokyoSubway48,
      PassProduct.tokyoSubway72,
    ];
    return Row(
      children: [
        for (var index = 0; index < products.length; index++) ...[
          Expanded(
            child: _DurationOption(
              product: products[index],
              selected: products[index] == value,
              onTap: () => onChanged(products[index]),
            ),
          ),
          if (index != products.length - 1) SizedBox(width: 7),
        ],
      ],
    );
  }
}

class _DurationOption extends StatelessWidget {
  const _DurationOption({
    required this.product,
    required this.selected,
    required this.onTap,
  });

  final PassProduct product;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: passText(
      context,
      '${product.duration.inHours}시간권 ${product.price}엔',
    ),
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
              passText(context, '${product.duration.inHours}시간'),
              style: TextStyle(
                color: selected ? Colors.white : AppColors.accent(context),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 2),
            Text(
              passText(context, '¥${product.price}'),
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

class _PlannerFootnote extends StatelessWidget {
  const _PlannerFootnote();

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        Icons.info_outline_rounded,
        size: 16,
        color: AppColors.mutedText(context),
      ),
      SizedBox(width: 6),
      Expanded(
        child: Text(
          passText(
            context,
            '실제로 개찰을 통과해 하차한 역을 입력해 주세요. 확인되지 않은 운임은 계산하지 않습니다.',
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

class _SegmentDraft {
  _SegmentDraft({required this.id, required this.dayIndex})
    : fromController = TextEditingController(),
      toController = TextEditingController();

  final int id;
  final TextEditingController fromController;
  final TextEditingController toController;
  PassStation? fromStation;
  PassStation? toStation;
  int? resolvedFare;
  int dayIndex;
  TransitCoverage coverage = TransitCoverage.tokyoMetro;

  void dispose() {
    fromController.dispose();
    toController.dispose();
  }

  void clearStations() {
    fromStation = null;
    toStation = null;
    resolvedFare = null;
    fromController.clear();
    toController.clear();
  }

  void swapStations() {
    final previousFromStation = fromStation;
    final previousFromText = fromController.text;
    fromStation = toStation;
    fromController.text = toController.text;
    toStation = previousFromStation;
    toController.text = previousFromText;
    resolvedFare = null;
  }
}

class _SegmentEditor extends StatelessWidget {
  const _SegmentEditor({
    required this.index,
    required this.draft,
    required this.data,
    required this.product,
    required this.canRemove,
    required this.onChanged,
    required this.onSwap,
    required this.onRemove,
    super.key,
  });

  final int index;
  final _SegmentDraft draft;
  final PassTransitData? data;
  final PassProduct product;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onSwap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Column(
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
          SizedBox(width: 9),
          Expanded(
            child: Text(
              passText(context, '이동 구간'),
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          if (canRemove) PassSegmentRemoveButton(onPressed: onRemove),
        ],
      ),
      SizedBox(height: 9),
      Row(
        children: [
          Expanded(
            child: _StationPickerField(
              controller: draft.fromController,
              station: draft.fromStation,
              label: '출발역',
              data: data,
              product: product,
              onSelected: (station) {
                draft.fromController.text = station.passName(context);
                draft.fromStation = station;
                onChanged();
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: IconButton(
              key: ValueKey('segment-swap-$index'),
              tooltip: passText(context, '출발역과 도착역 바꾸기'),
              onPressed: onSwap,
              visualDensity: VisualDensity.compact,
              constraints: BoxConstraints(minWidth: 36, minHeight: 36),
              style: IconButton.styleFrom(
                foregroundColor: AppColors.accent(context),
                backgroundColor: AppColors.softSurface(context),
              ),
              icon: Icon(Icons.swap_horiz_rounded, size: 20),
            ),
          ),
          Expanded(
            child: _StationPickerField(
              controller: draft.toController,
              station: draft.toStation,
              label: '도착역',
              data: data,
              product: product,
              onSelected: (station) {
                draft.toController.text = station.passName(context);
                draft.toStation = station;
                onChanged();
              },
            ),
          ),
        ],
      ),
      SizedBox(height: 8),
      _ResolvedFareSummary(draft: draft, product: product),
    ],
  );
}

class _ResolvedFareSummary extends StatelessWidget {
  const _ResolvedFareSummary({required this.draft, required this.product});

  final _SegmentDraft draft;
  final PassProduct product;

  @override
  Widget build(BuildContext context) {
    final fare = draft.resolvedFare;
    if (fare == null) {
      return Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 17,
            color: AppColors.mutedText(context),
          ),
          SizedBox(width: 7),
          Expanded(
            child: Text(
              passText(context, '두 역을 선택하면 운임을 자동으로 확인합니다.'),
              style: TextStyle(
                color: AppColors.mutedText(context),
                fontSize: 11,
              ),
            ),
          ),
        ],
      );
    }
    final covered = draft.coverage.isCoveredBy(product);
    final color = covered ? AppColors.success : AppColors.mutedText(context);
    return Row(
      children: [
        Icon(
          covered
              ? Icons.check_circle_outline_rounded
              : Icons.info_outline_rounded,
          size: 18,
          color: color,
        ),
        SizedBox(width: 7),
        Expanded(
          child: Text(
            passText(context, '성인 일반 운임 ¥$fare'),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StationPickerField extends StatelessWidget {
  const _StationPickerField({
    required this.controller,
    required this.station,
    required this.label,
    required this.data,
    required this.product,
    required this.onSelected,
  });

  final TextEditingController controller;
  final PassStation? station;
  final String label;
  final PassTransitData? data;
  final PassProduct product;
  final ValueChanged<PassStation> onSelected;

  @override
  Widget build(BuildContext context) {
    return PassStationPickerField(
      key: ValueKey('station-picker-$label'),
      label: label.endsWith('역') ? label.substring(0, label.length - 1) : label,
      stationName: station?.passName(context),
      emptyLabel: data == null ? '데이터 준비 중' : '역 선택',
      operatorLabel: station == null ? null : _passOperatorLabel(station!),
      onTap: data == null ? null : () => _openSearch(context),
      semanticLabel: '$label 검색',
    );
  }

  Future<void> _openSearch(BuildContext context) async {
    final transitData = data;
    if (transitData == null) return;
    final station = await Navigator.of(context).push<PassStation>(
      MaterialPageRoute<PassStation>(
        builder: (_) => _StationSearchPage(
          title: '$label 선택',
          data: transitData,
          product: product,
        ),
      ),
    );
    if (station != null) onSelected(station);
  }
}

class _StationSearchPage extends StatefulWidget {
  const _StationSearchPage({
    required this.title,
    required this.data,
    required this.product,
  });

  final String title;
  final PassTransitData data;
  final PassProduct product;

  @override
  State<_StationSearchPage> createState() => _StationSearchPageState();
}

String _passOperatorLabel(PassStation station) => station.operators.isEmpty
    ? '운영사 정보 없음'
    : station.operators.map(_passOperatorDisplayName).join(' · ');

String _passOperatorDisplayName(String operator) => switch (operator) {
  'odpt.Operator:TokyoMetro' => '도쿄메트로',
  'odpt.Operator:Toei' => '도에이 지하철',
  'odpt.Operator:JR-East' => 'JR 동일본',
  _ => operator,
};

class _StationSearchPageState extends State<_StationSearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<PassStation> _results = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String query) {
    setState(() {
      _results = query.trim().isEmpty
          ? []
          : widget.data.searchStations(query, product: widget.product);
    });
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
            key: ValueKey('station-search-field'),
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: _search,
            decoration: InputDecoration(
              hintText: passText(context, '역 이름을 검색해 주세요'),
              prefixIcon: Icon(Icons.search_rounded),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: passText(context, '검색어 지우기'),
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
    body: SafeArea(
      top: false,
      child: _controller.text.trim().isEmpty
          ? _StationSearchEmptyState(
              icon: Icons.search_rounded,
              title: '찾고 싶은 역을 입력해 주세요',
              description: '한국어·초성·일본어·영어로 검색할 수 있습니다.',
            )
          : _results.isEmpty
          ? _StationSearchEmptyState(
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
                    child: Icon(
                      Icons.subway_outlined,
                      color: AppColors.skyDark,
                    ),
                  ),
                  title: Text(
                    passText(context, station.passName(context)),
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: station.passSecondary(context).isEmpty
                      ? null
                      : Text(passText(context, station.passSecondary(context))),
                  trailing: Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).pop(station),
                );
              },
            ),
    ),
  );
}

class _StationSearchEmptyState extends StatelessWidget {
  const _StationSearchEmptyState({
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

class PassComparisonResultPage extends StatelessWidget {
  const PassComparisonResultPage({required this.result, super.key});

  final PassComparisonResult result;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        passText(context, '비교 결과'),
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          _ResultProgress(),
          SizedBox(height: 24),
          _ResultPanel(result: result),
          SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.edit_outlined),
            label: Text(passText(context, '이동 계획 수정')),
          ),
        ],
      ),
    ),
  );
}

class _PlannerProgress extends StatelessWidget {
  const _PlannerProgress();

  @override
  Widget build(BuildContext context) => _ProgressBar(activeStep: 2);
}

class _ResultProgress extends StatelessWidget {
  const _ResultProgress();

  @override
  Widget build(BuildContext context) => _ProgressBar(activeStep: 3);
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.activeStep});

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
                SizedBox(height: 7),
                Text(
                  passText(
                    context,
                    '${index + 1}. ${passText(context, labels[index])}',
                  ),
                  overflow: TextOverflow.ellipsis,
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
          if (index != labels.length - 1) SizedBox(width: 5),
        ],
      ],
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.result});

  final PassComparisonResult result;

  @override
  Widget build(BuildContext context) {
    final (title, description, color, icon) = switch (result.verdict) {
      PassComparisonVerdict.beneficial => (
        '패스가 더 이득이에요',
        '예상 절약액 ¥${result.savings}',
        AppColors.success,
        Icons.savings_outlined,
      ),
      PassComparisonVerdict.breakEven => (
        '일반 운임과 같아요',
        '예상 비용 차이가 없습니다',
        AppColors.skyDark,
        Icons.balance_rounded,
      ),
      PassComparisonVerdict.notBeneficial => (
        '일반 결제가 더 저렴해요',
        '패스를 사면 ¥${-result.savings} 더 들어요',
        AppColors.warning,
        Icons.trending_down_rounded,
      ),
      PassComparisonVerdict.insufficientData => (
        '비교할 구간이 부족해요',
        '패스 적용 구간과 운임을 입력해 주세요',
        AppColors.muted,
        Icons.route_outlined,
      ),
    };
    if (result.verdict == PassComparisonVerdict.insufficientData) {
      return AppSurface(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.skySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.route_outlined, color: AppColors.skyDark),
            ),
            SizedBox(height: 14),
            Text(
              passText(context, '아직 비교할 이동이 없어요'),
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 5),
            Text(
              passText(context, '출발역과 도착역을 선택한 이동 구간을 추가하면 손익을 계산합니다.'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSurface(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .11),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              SizedBox(height: 16),
              Text(
                passText(context, title),
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
              SizedBox(height: 5),
              Text(
                passText(context, description),
                style: TextStyle(color: color, fontSize: 16),
              ),
              PassResultScopeNote(),
              SizedBox(height: 18),
              _MoneyRow(
                label: '패스 적용 구간 일반 운임',
                value: result.coveredRegularFare,
              ),
              _MoneyRow(label: '패스 가격', value: result.product.price),
              _MoneyRow(
                label: '비교 제외 외부 운임',
                value: result.excludedFare,
                muted: true,
              ),
              Divider(height: 26),
              _MoneyRow(
                label: '예상 손익',
                value: result.savings,
                signed: true,
                emphasized: true,
              ),
              SizedBox(height: 14),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.skySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    passText(context, _validitySummary(result)),
                    style: TextStyle(
                      color: AppColors.skyDark,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 18),
        SectionLabel(passText(context, '구간별 판정')),
        AppSurface(
          child: result.segments.isEmpty
              ? Text(passText(context, '유효한 이동 구간을 입력하면 판정 근거가 표시됩니다.'))
              : Column(
                  children: [
                    for (var i = 0; i < result.segments.length; i++) ...[
                      _SegmentResultTile(item: result.segments[i]),
                      if (i != result.segments.length - 1) Divider(height: 22),
                    ],
                  ],
                ),
        ),
        SizedBox(height: 14),
        NoticeBanner(
          title: passText(context, '결과 사용 시 주의'),
          text: passText(
            context,
            'Metro↔도에이 구간은 공식 지정 환승역·60분 이내 환승·70엔 할인을 전제로 계산합니다. 패스 구매 전 공식 운임과 상품 구매 조건을 다시 확인해 주세요.',
          ),
          tone: NoticeTone.warning,
        ),
      ],
    );
  }

  String _validitySummary(PassComparisonResult result) {
    final range = result.product.isTokyoSubwayTicket
        ? '${result.product.duration.inHours}시간권'
        : '1일권';
    return '$range · ${result.coveredSegmentCount}개 구간 적용';
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    this.muted = false,
    this.signed = false,
    this.emphasized = false,
  });

  final String label;
  final int value;
  final bool muted;
  final bool signed;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final prefix = signed && value > 0 ? '+' : '';
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              passText(context, label),
              style: TextStyle(
                color: muted
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : null,
                fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            passText(context, '$prefix¥$value'),
            style: TextStyle(
              fontSize: emphasized ? 22 : 16,
              fontWeight: emphasized ? FontWeight.w900 : FontWeight.w800,
              color: emphasized && value > 0 ? AppColors.success : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentResultTile extends StatelessWidget {
  const _SegmentResultTile({required this.item});

  final SegmentEvaluation item;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = item.isCovered
        ? ('패스 적용', AppColors.success, Icons.check_circle_outline_rounded)
        : !item.isWithinValidity
        ? ('유효시간 밖', AppColors.warning, Icons.schedule_rounded)
        : ('비교 제외', AppColors.muted, Icons.remove_circle_outline_rounded);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 21, color: color),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                passText(
                  context,
                  '${item.segment.fromStation} → ${item.segment.toStation}',
                ),
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 3),
              Text(
                passText(context, item.segment.coverage.label),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                passText(context, '¥${item.segment.regularFare}'),
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 3),
              Text(
                passText(context, label),
                textAlign: TextAlign.right,
                style: TextStyle(color: color, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
