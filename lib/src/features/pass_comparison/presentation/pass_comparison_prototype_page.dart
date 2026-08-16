import 'package:flutter/material.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../data/pass_transit_data.dart';
import '../domain/pass_comparison.dart';

class PassComparisonPrototypePage extends StatefulWidget {
  const PassComparisonPrototypePage({this.initialData, super.key});

  final PassTransitData? initialData;

  @override
  State<PassComparisonPrototypePage> createState() =>
      _PassComparisonPrototypePageState();
}

class _PassComparisonPrototypePageState
    extends State<PassComparisonPrototypePage> {
  PassProduct _product = PassProduct.tokyoSubway24;
  late DateTime _validFrom;
  final List<_SegmentDraft> _drafts = [];
  PassTransitData? _transitData;
  Object? _dataLoadError;
  int _nextId = 1;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _validFrom = DateTime(now.year, now.month, now.day, 9);
    _transitData = widget.initialData;
    _addDraft(notify: false);
    if (_transitData == null) _loadTransitData();
  }

  Future<void> _loadTransitData() async {
    try {
      final data = await const PassTransitDataRepository().load();
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
      _drafts.add(
        _SegmentDraft(
          id: _nextId++,
          departureAt: _validFrom.add(Duration(hours: _drafts.length * 2)),
        ),
      );
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
          departureAt: draft.departureAt,
          fromStation: from.displayName,
          toStation: to.displayName,
          coverage: draft.coverage,
          regularFare: fare,
        ),
      );
    }
    return segments;
  }

  @override
  Widget build(BuildContext context) {
    final result = PassComparisonEvaluator.evaluate(
      product: _product,
      validFrom: _validFrom,
      segments: _validSegments,
    );
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 980;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 36 : 18,
                    8,
                    wide ? 36 : 18,
                    40,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1320),
                        child: wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 7, child: _buildPlanner()),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 5,
                                    child: _ResultPanel(result: result),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildPlanner(),
                                  const SizedBox(height: 20),
                                  _ResultPanel(result: result),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1320),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.skyDark,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.confirmation_number_outlined,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '교통패스 비교 실험실',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text('Tokyo Subway Ticket · 계산 엔진 프로토타입'),
                ],
              ),
            ),
            const StatusPill(
              label: '로컬 계산',
              icon: Icons.lock_outline_rounded,
              color: AppColors.success,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildPlanner() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (_transitData != null)
        NoticeBanner(
          title: 'ODPT 실제 역·운임 데이터',
          text:
              '${_transitData!.stations.length}개 역 후보와 ${_transitData!.fares.length}개 성인 IC 운임을 기기 안에서 검색합니다. 데이터 기준: ${_formatDate(_transitData!.generatedAt)}',
          tone: NoticeTone.success,
        )
      else if (_dataLoadError != null)
        const NoticeBanner(
          title: 'ODPT 데이터 가져오기가 필요합니다',
          text: '개발용 가져오기 도구로 정적 데이터를 생성한 뒤 다시 실행해 주세요. 액세스 토큰은 앱에 포함되지 않습니다.',
          tone: NoticeTone.warning,
        )
      else
        const NoticeBanner(
          title: 'ODPT 데이터 읽는 중',
          text: '실제 역과 성인 IC 운임 데이터를 준비하고 있습니다.',
          tone: NoticeTone.info,
        ),
      const SizedBox(height: 20),
      const SectionLabel('패스 설정'),
      AppSurface(
        child: Column(
          children: [
            DropdownButtonFormField<PassProduct>(
              initialValue: _product,
              decoration: const InputDecoration(
                labelText: '비교할 패스',
                prefixIcon: Icon(Icons.local_activity_outlined),
              ),
              items: PassProduct.values
                  .map(
                    (product) => DropdownMenuItem(
                      value: product,
                      child: Text('${product.label} · ¥${product.price}'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _product = value);
              },
            ),
            const SizedBox(height: 14),
            _DateTimeButton(
              label: '사용 시작',
              value: _validFrom,
              onChanged: (value) => setState(() => _validFrom = value),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      SectionLabel(
        '이동 구간',
        trailing: TextButton(onPressed: _clearAll, child: const Text('비우기')),
      ),
      for (var index = 0; index < _drafts.length; index++) ...[
        _SegmentEditor(
          key: ValueKey(_drafts[index].id),
          index: index,
          draft: _drafts[index],
          data: _transitData,
          canRemove: _drafts.length > 1,
          onChanged: () {
            _resolveDraft(_drafts[index]);
            setState(() {});
          },
          onRemove: () => _removeDraft(_drafts[index]),
        ),
        const SizedBox(height: 12),
      ],
      OutlinedButton.icon(
        onPressed: _addDraft,
        icon: const Icon(Icons.add_rounded),
        label: const Text('이동 구간 추가'),
      ),
    ],
  );

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

class _SegmentDraft {
  _SegmentDraft({required this.id, required this.departureAt})
    : fromController = TextEditingController(),
      toController = TextEditingController();

  final int id;
  final TextEditingController fromController;
  final TextEditingController toController;
  final FocusNode fromFocusNode = FocusNode();
  final FocusNode toFocusNode = FocusNode();
  PassStation? fromStation;
  PassStation? toStation;
  int? resolvedFare;
  DateTime departureAt;
  TransitCoverage coverage = TransitCoverage.tokyoMetro;

  void dispose() {
    fromController.dispose();
    toController.dispose();
    fromFocusNode.dispose();
    toFocusNode.dispose();
  }
}

class _SegmentEditor extends StatelessWidget {
  const _SegmentEditor({
    required this.index,
    required this.draft,
    required this.data,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final int index;
  final _SegmentDraft draft;
  final PassTransitData? data;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => AppSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.skySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: AppColors.skyDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
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
                icon: const Icon(Icons.delete_outline_rounded),
              ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final inline = constraints.maxWidth >= 560;
            final fromField = _StationAutocomplete(
              controller: draft.fromController,
              focusNode: draft.fromFocusNode,
              label: '출발역',
              data: data,
              onChanged: () {
                draft.fromStation = null;
                draft.resolvedFare = null;
                onChanged();
              },
              onSelected: (station) {
                draft.fromStation = station;
                onChanged();
              },
            );
            final toField = _StationAutocomplete(
              controller: draft.toController,
              focusNode: draft.toFocusNode,
              label: '도착역',
              data: data,
              onChanged: () {
                draft.toStation = null;
                draft.resolvedFare = null;
                onChanged();
              },
              onSelected: (station) {
                draft.toStation = station;
                onChanged();
              },
            );
            return inline
                ? Row(
                    children: [
                      Expanded(child: fromField),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward_rounded, size: 20),
                      ),
                      Expanded(child: toField),
                    ],
                  )
                : Column(
                    children: [
                      fromField,
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 7),
                        child: Icon(Icons.arrow_downward_rounded, size: 20),
                      ),
                      toField,
                    ],
                  );
          },
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final inline = constraints.maxWidth >= 620;
            final coverageField = InputDecorator(
              decoration: const InputDecoration(labelText: '적용 구분'),
              child: Text(
                draft.resolvedFare == null
                    ? '역 선택 후 자동 판정'
                    : draft.coverage.label,
              ),
            );
            final fareField = InputDecorator(
              decoration: const InputDecoration(labelText: 'ODPT 성인 IC 운임'),
              child: Text(
                draft.resolvedFare == null
                    ? '해당 운임 없음'
                    : '¥${draft.resolvedFare}',
              ),
            );
            final departureField = _DateTimeButton(
              label: '출발 예정',
              value: draft.departureAt,
              onChanged: (value) {
                draft.departureAt = value;
                onChanged();
              },
            );
            return inline
                ? Row(
                    children: [
                      Expanded(child: coverageField),
                      const SizedBox(width: 10),
                      Expanded(child: fareField),
                      const SizedBox(width: 10),
                      Expanded(child: departureField),
                    ],
                  )
                : Column(
                    children: [
                      coverageField,
                      const SizedBox(height: 10),
                      fareField,
                      const SizedBox(height: 10),
                      departureField,
                    ],
                  );
          },
        ),
      ],
    ),
  );
}

class _StationAutocomplete extends StatelessWidget {
  const _StationAutocomplete({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.data,
    required this.onChanged,
    required this.onSelected,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final PassTransitData? data;
  final VoidCallback onChanged;
  final ValueChanged<PassStation> onSelected;

  @override
  Widget build(BuildContext context) => RawAutocomplete<PassStation>(
    textEditingController: controller,
    focusNode: focusNode,
    displayStringForOption: (option) => option.displayName,
    optionsBuilder: (value) => data?.searchStations(value.text) ?? const [],
    onSelected: onSelected,
    fieldViewBuilder: (context, textController, fieldFocusNode, onSubmitted) =>
        TextField(
          controller: textController,
          focusNode: fieldFocusNode,
          onChanged: (_) => onChanged(),
          onSubmitted: (_) => onSubmitted(),
          decoration: InputDecoration(
            labelText: label,
            hintText: data == null ? '데이터 준비 중' : '예: 시부야, ㅅㅂㅇ',
            suffixIcon: const Icon(Icons.search_rounded),
          ),
        ),
    optionsViewBuilder: (context, select, options) {
      final items = options.toList(growable: false);
      return Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 8,
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 320),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 6),
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final station = items[index];
                return ListTile(
                  leading: const Icon(
                    Icons.subway_outlined,
                    color: AppColors.skyDark,
                  ),
                  title: Text(
                    station.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: station.secondaryLabel.isEmpty
                      ? null
                      : Text(station.secondaryLabel),
                  onTap: () => select(station),
                );
              },
            ),
          ),
        ),
      );
    },
  );
}

class _DateTimeButton extends StatelessWidget {
  const _DateTimeButton({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: () => _pick(context),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.schedule_rounded),
      ),
      child: Text(_formatDateTime(value)),
    ),
  );

  Future<void> _pick(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
    );
    if (time == null) return;
    onChanged(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('비교 결과'),
        AppSurface(
          padding: const EdgeInsets.all(22),
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
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 5),
              Text(description, style: TextStyle(color: color, fontSize: 16)),
              const SizedBox(height: 22),
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
              const Divider(height: 26),
              _MoneyRow(
                label: '예상 손익',
                value: result.savings,
                signed: true,
                emphasized: true,
              ),
              const SizedBox(height: 18),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.skySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    '${_formatDateTime(result.validFrom)}부터 '
                    '${_formatDateTime(result.validUntil)} 전까지 · '
                    '${result.coveredSegmentCount}개 구간 적용',
                    style: const TextStyle(
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
        const SizedBox(height: 18),
        const SectionLabel('구간별 판정'),
        AppSurface(
          child: result.segments.isEmpty
              ? const Text('유효한 이동 구간을 입력하면 판정 근거가 표시됩니다.')
              : Column(
                  children: [
                    for (var i = 0; i < result.segments.length; i++) ...[
                      _SegmentResultTile(item: result.segments[i]),
                      if (i != result.segments.length - 1)
                        const Divider(height: 22),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 14),
        const NoticeBanner(
          title: '결과 사용 시 주의',
          text:
              '현재는 사용자가 입력한 운임을 기준으로 계산합니다. 패스 구매 전 공식 운임과 상품 구매 조건을 다시 확인해 주세요.',
          tone: NoticeTone.warning,
        ),
      ],
    );
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: muted
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : null,
                fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            '$prefix¥$value',
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
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.segment.fromStation} → ${item.segment.toStation}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                '${item.segment.coverage.label} · '
                '${_formatDateTime(item.segment.departureAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '¥${item.segment.regularFare}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

String _formatDateTime(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${value.month}/${value.day} ${two(value.hour)}:${two(value.minute)}';
}

String _formatDate(DateTime value) =>
    '${value.year}.${value.month.toString().padLeft(2, '0')}.'
    '${value.day.toString().padLeft(2, '0')}';
