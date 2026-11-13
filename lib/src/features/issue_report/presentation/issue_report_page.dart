import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import 'report_strings.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../card_reader/domain/raw_history_block.dart';
import '../../settings/domain/installed_app_version.dart';
import '../../station_resolver/data/asset_station_database.dart';
import '../../station_resolver/domain/station_resolution.dart';
import '../../transaction_history/data/ica_history_parser.dart';
import '../../transaction_history/data/transit_history_parser.dart';
import '../../transaction_history/domain/amount_calculation.dart';
import '../../transaction_history/domain/parsed_transit_history.dart';
import '../../transaction_history/domain/transit_transaction_type.dart';
import '../../transaction_history/presentation/transaction_history_labels.dart';
import '../data/supabase_issue_report_repository.dart';
import '../domain/issue_report.dart';
import '../domain/issue_report_repository.dart';
import 'report_success_dialog.dart';

class IssueReportPage extends StatefulWidget {
  const IssueReportPage({
    required this.history,
    super.key,
    this.stations,
    this.transactionLocation,
    this.repository,
  });

  final ParsedTransitHistory history;
  final ResolvedStationPair? stations;
  final StationResolution? transactionLocation;
  final IssueReportRepository? repository;

  @override
  State<IssueReportPage> createState() => _IssueReportPageState();
}

class _IssueReportPageState extends State<IssueReportPage> {
  int _step = 0;
  String? _issue;
  bool _consented = false;
  bool _isSubmitting = false;
  String? _submissionError;
  String? _detailError;
  StationIssueScope? _stationIssueScope;
  String? _suggestedTransactionType;
  final _detailFormKey = GlobalKey<FormState>();
  final _boardingStationController = TextEditingController();
  final _boardingCityController = TextEditingController();
  final _boardingLineController = TextEditingController();
  final _alightingStationController = TextEditingController();
  final _alightingCityController = TextEditingController();
  final _alightingLineController = TextEditingController();
  final _busCompanyNameController = TextEditingController();
  final _busCompanyCityController = TextEditingController();
  final _nameBoardingStationController = TextEditingController();
  final _nameAlightingStationController = TextEditingController();
  final _customTransactionTypeController = TextEditingController();
  final _descriptionController = TextEditingController();

  IssueReportRepository get _repository =>
      widget.repository ?? const UnavailableIssueReportRepository();

  bool? _previousEnglish;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final english = usesEnglish(context);
    if (_previousEnglish != null &&
        _previousEnglish != english &&
        _isStationNameRequest &&
        !_isSubmitting) {
      // A suggested label must not silently become a different language's
      // suggestion when the app/system language changes during a draft.
      _nameBoardingStationController.clear();
      _nameAlightingStationController.clear();
      _stationIssueScope = null;
      _consented = false;
      _detailError = null;
      _submissionError = null;
      _step = 0;
    }
    _previousEnglish = english;
  }

  @override
  void dispose() {
    _boardingStationController.dispose();
    _boardingCityController.dispose();
    _boardingLineController.dispose();
    _alightingStationController.dispose();
    _alightingCityController.dispose();
    _alightingLineController.dispose();
    _busCompanyNameController.dispose();
    _busCompanyCityController.dispose();
    _nameBoardingStationController.dispose();
    _nameAlightingStationController.dispose();
    _customTransactionTypeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: 62,
      titleSpacing: 2,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reportText(context, '오류 제보'),
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 1),
          Text(
            strings(context).reportStep(_step + 1),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    ),
    body: SafeArea(
      top: false,
      child: AppPage(
        children: [
          _StepIndicator(current: _step),
          const SizedBox(height: 18),
          _SelectedHistoryCard(
            history: widget.history,
            stations: widget.stations,
            transactionLocation: widget.transactionLocation,
          ),
          const SizedBox(height: 22),
          if (_step == 0) _issueStep(context),
          if (_step == 1) _detailStep(context),
          if (_step == 2) _reviewStep(context),
        ],
      ),
    ),
  );

  Widget _issueStep(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        reportText(context, '어떤 정보가 잘못되었나요?'),
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 6),
      Text(
        reportText(context, '가장 가까운 항목 하나를 선택해 주세요.'),
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 18),
      AppSurface(
        padding: EdgeInsets.zero,
        child: RadioGroup<String>(
          groupValue: _issue,
          onChanged: _selectIssue,
          child: Column(
            children: [
              for (final issue in [
                '역 정보가 없거나 잘못됨',
                '역명 한글 표기 추가 요청',
                if (_isBusHistory) '버스 회사 정보가 없거나 잘못됨',
                '거래 유형이 잘못됨',
                '금액 또는 잔액이 잘못됨',
                '기타',
              ]) ...[
                RadioListTile<String>(
                  value: issue,
                  title: Text(
                    reportText(context, issue),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                if (issue != '기타') const Divider(),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: _issue == null ? null : () => setState(() => _step = 1),
        child: Text(
          reportText(context, '다음'),
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );

  Widget _detailStep(BuildContext context) => Form(
    key: _detailFormKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          reportText(context, _detailTitle),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          reportText(context, _detailGuide),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 18),
        if (_usesStationScope) ...[
          Text(
            reportText(
              context,
              _isStationNameRequest ? '어느 역의 한글 표기인가요?' : '어느 역 정보인가요?',
            ),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _showStationScopeSheet,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              alignment: Alignment.centerLeft,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.train_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    reportText(
                      context,
                      _stationIssueScope == null
                          ? '승차역·하차역을 선택해 주세요'
                          : _stationIssueScopeLabel(_stationIssueScope!),
                    ),
                    style: TextStyle(
                      color: _stationIssueScope == null
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_up_rounded),
              ],
            ),
          ),
          if (_detailError != null) ...[
            const SizedBox(height: 4),
            Text(
              reportText(context, _detailError!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 10),
        ],
        if (_needsStationCorrection && _needsBoardingStationScope) ...[
          _stationCorrectionFields(
            context,
            title: '올바른 승차역',
            stationController: _boardingStationController,
            cityController: _boardingCityController,
            lineController: _boardingLineController,
          ),
          if (_needsAlightingStationScope) const SizedBox(height: 18),
        ],
        if (_needsStationCorrection && _needsAlightingStationScope)
          _stationCorrectionFields(
            context,
            title: '올바른 하차역',
            stationController: _alightingStationController,
            cityController: _alightingCityController,
            lineController: _alightingLineController,
          ),
        if (_issue == '거래 유형이 잘못됨') ...[
          Text(
            reportText(context, '올바른 거래 유형'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _showTransactionTypeSheet,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              alignment: Alignment.centerLeft,
            ),
            child: Row(
              children: [
                Icon(
                  _suggestedTransactionType == null
                      ? Icons.category_outlined
                      : _suggestedTransactionTypeIcon(
                          _suggestedTransactionType!,
                        ),
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    reportText(
                      context,
                      _suggestedTransactionType == null
                          ? '유형을 선택해 주세요'
                          : _suggestedTransactionTypeLabel(
                              _suggestedTransactionType!,
                            ),
                    ),
                    style: TextStyle(
                      color: _suggestedTransactionType == null
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_up_rounded),
              ],
            ),
          ),
          if (_detailError != null) ...[
            const SizedBox(height: 4),
            Text(
              reportText(context, _detailError!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (_suggestedTransactionType == 'OTHER') ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _customTransactionTypeController,
              maxLength: 80,
              decoration: InputDecoration(
                labelText: reportText(context, '직접 입력한 거래 유형'),
                hintText: reportText(context, '예: 승차권 구매'),
              ),
              validator: (value) => _requiredTextError(context, value, '거래 유형'),
            ),
          ],
        ],
        if (_isBusCompanyIssue) ...[_busCompanyFields(context)],
        if (_isStationNameRequest && _needsBoardingStationScope) ...[
          _stationNameField(
            context,
            title: '승차역 한글 표기',
            controller: _nameBoardingStationController,
          ),
          if (_needsAlightingStationScope) const SizedBox(height: 18),
        ],
        if (_isStationNameRequest && _needsAlightingStationScope)
          _stationNameField(
            context,
            title: '하차역 한글 표기',
            controller: _nameAlightingStationController,
          ),
        if (_needsStationCorrection ||
            _issue == '거래 유형이 잘못됨' ||
            _isBusCompanyIssue ||
            _isStationNameRequest)
          const SizedBox(height: 20),
        if (!_isStationNameRequest) ...[
          Text(
            reportText(context, '추가 설명 (선택)'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            maxLength: 300,
            decoration: InputDecoration(
              hintText: reportText(context, '개인정보를 제외하고 추가로 알려줄 내용을 적어주세요.'),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step = 0),
                child: Text(
                  reportText(context, '이전'),
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _validateAndReview,
                child: Text(
                  reportText(context, '검토하기'),
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _reviewStep(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        reportText(context, '전송 전 확인'),
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 18),
      AppSurface(
        child: Column(
          children: [
            DetailLine(
              label: reportText(context, '제보 유형'),
              value: reportText(context, _issue ?? '-'),
            ),
            const Divider(),
            if (_needsStationCorrection && _needsBoardingStationScope) ...[
              DetailLine(
                label: reportText(context, '올바른 승차역'),
                value: _boardingCorrectionSummary,
              ),
              const Divider(),
            ],
            if (_needsStationCorrection && _needsAlightingStationScope) ...[
              DetailLine(
                label: reportText(context, '올바른 하차역'),
                value: _alightingCorrectionSummary,
              ),
              const Divider(),
            ],
            if (_usesStationScope) ...[
              DetailLine(
                label: reportText(context, '문제가 있는 역 정보'),
                value: reportText(
                  context,
                  _stationIssueScope == null
                      ? '선택되지 않음'
                      : _stationIssueScopeLabel(_stationIssueScope!),
                ),
              ),
              const Divider(),
            ],
            if (_issue == '거래 유형이 잘못됨') ...[
              DetailLine(
                label: reportText(context, '제안 거래 유형'),
                value: _suggestedTransactionSummary,
              ),
              const Divider(),
            ],
            if (_isBusCompanyIssue) ...[
              DetailLine(
                label: reportText(context, '실제 버스 회사명'),
                value: _busCompanyName,
              ),
              const Divider(),
              DetailLine(
                label: reportText(context, '운행 도시·지역'),
                value: _busCompanyCity,
              ),
              const Divider(),
            ],
            if (_isStationNameRequest) ...[
              if (_needsBoardingStationScope) ...[
                DetailLine(
                  label: reportText(context, '제안 승차역 한글 표기'),
                  value:
                      _optionalText(_nameBoardingStationController) ??
                      reportText(context, '입력 없음'),
                ),
                const Divider(),
                DetailLine(
                  label: reportText(context, '파서 확인 승차역 노선'),
                  value: widget.stations?.boarding.station?.lineName ?? 'null',
                ),
                const Divider(),
              ],
              if (_needsAlightingStationScope) ...[
                DetailLine(
                  label: reportText(context, '제안 하차역 한글 표기'),
                  value:
                      _optionalText(_nameAlightingStationController) ??
                      reportText(context, '입력 없음'),
                ),
                const Divider(),
                DetailLine(
                  label: reportText(context, '파서 확인 하차역 노선'),
                  value: widget.stations?.alighting.station?.lineName ?? 'null',
                ),
                const Divider(),
              ],
            ],
            DetailLine(
              label: reportText(context, '선택한 내역'),
              value: reportText(
                context,
                _reportHistorySummary(
                  widget.history,
                  widget.stations,
                  widget.transactionLocation,
                  strings(context),
                ),
              ),
            ),
            const Divider(),
            DetailLine(
              label: reportText(context, '거래 유형 / 금액'),
              value: reportText(
                context,
                '${transactionTypeLabel(widget.history, strings(context))} · ${reportText(context, _reportAmount(widget.history.amountCalculation))}',
              ),
            ),
            const Divider(),
            DetailLine(
              label: reportText(context, '이용 날짜'),
              value: reportText(context, formatDate(widget.history.usageDate)),
            ),
            const Divider(),
            DetailLine(
              label: reportText(context, '익명 원본 기록'),
              value: reportText(context, widget.history.rawBlock.hexadecimal),
              monospace: true,
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      NoticeBanner(
        title: reportText(context, '개인정보 보호'),
        text: reportText(
          context,
          '카드 IDm은 포함하지 않습니다. 선택한 이용내역 1건과 입력한 역·도시·노선, 버스 회사·도시 또는 거래 유형, 제보 내용만 전송 대상으로 준비합니다.',
        ),
        tone: NoticeTone.privacy,
      ),
      const SizedBox(height: 12),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: _consented,
        onChanged: (value) => setState(() => _consented = value ?? false),
        title: Text(
          reportText(context, '위 정보의 전송에 동의합니다.'),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
      if (_submissionError case final error?) ...[
        const SizedBox(height: 4),
        NoticeBanner(
          title: reportText(context, '제보를 전송하지 못했습니다'),
          text: reportText(context, error),
          tone: NoticeTone.danger,
        ),
      ],
      const SizedBox(height: 12),
      FilledButton(
        onPressed: !_consented || _isSubmitting ? null : _submit,
        child: _isSubmitting
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : Text(
                reportText(context, '익명으로 제보하기'),
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
      ),
      const SizedBox(height: 10),
      OutlinedButton(
        onPressed: () => setState(() => _step = 1),
        child: Text(
          reportText(context, '이전'),
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );

  Future<void> _submit() async {
    final englishRequest = usesEnglish(context);
    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });
    try {
      final installedVersion = await InstalledAppVersion.current;
      if (!mounted) return;
      final receipt = await _repository.submit(
        _createReport(
          appVersion: installedVersion ?? 'unknown',
          englishRequest: englishRequest,
        ),
      );
      if (!mounted) return;
      await showReportSuccessDialog(context, reportId: receipt.reportId);
      if (mounted) Navigator.pop(context);
    } on IssueReportSubmissionException catch (error) {
      if (!mounted) return;
      setState(() => _submissionError = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submissionError = '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  IssueReport _createReport({
    required String appVersion,
    required bool englishRequest,
  }) {
    final description = _descriptionController.text.trim();
    return IssueReport(
      anonymousReportId: _uuidV4(),
      anonymousRawRecord: widget.history.rawBlock.hexadecimal,
      issueType: _issueType(_issue!, english: englishRequest),
      regionCode: widget.history.regionCode,
      boardingLineCode: widget.history.boardingLineCode,
      boardingStationCode: widget.history.boardingStationCode,
      alightingLineCode: widget.history.alightingLineCode,
      alightingStationCode: widget.history.alightingStationCode,
      currentBoardingStation: widget.stations?.boarding.station?.stationName,
      currentAlightingStation: widget.stations?.alighting.station?.stationName,
      stationIssueScope: _stationIssueScope,
      correctedBoardingStation:
          _needsStationCorrection && _needsBoardingStationScope
          ? _stationCorrection(
              _boardingStationController,
              _boardingCityController,
              _boardingLineController,
            )
          : null,
      correctedAlightingStation:
          _needsStationCorrection && _needsAlightingStationScope
          ? _stationCorrection(
              _alightingStationController,
              _alightingCityController,
              _alightingLineController,
            )
          : null,
      suggestedBusCompanyName: _isBusCompanyIssue ? _busCompanyName : null,
      suggestedBusCompanyCity: _isBusCompanyIssue ? _busCompanyCity : null,
      suggestedKoreanBoardingStationName:
          _isStationNameRequest && !englishRequest && _needsBoardingStationScope
          ? _optionalText(_nameBoardingStationController)
          : null,
      suggestedKoreanAlightingStationName:
          _isStationNameRequest &&
              !englishRequest &&
              _needsAlightingStationScope
          ? _optionalText(_nameAlightingStationController)
          : null,
      suggestedEnglishBoardingStationName:
          _isStationNameRequest && englishRequest && _needsBoardingStationScope
          ? _optionalText(_nameBoardingStationController)
          : null,
      suggestedEnglishAlightingStationName:
          _isStationNameRequest && englishRequest && _needsAlightingStationScope
          ? _optionalText(_nameAlightingStationController)
          : null,
      currentBoardingLineName:
          _isStationNameRequest && _needsBoardingStationScope
          ? widget.stations?.boarding.station?.lineName
          : null,
      currentAlightingLineName:
          _isStationNameRequest && _needsAlightingStationScope
          ? widget.stations?.alighting.station?.lineName
          : null,
      currentTransactionType: widget.history.transactionType.wireName,
      suggestedTransactionType: _issue == '거래 유형이 잘못됨'
          ? _suggestedTransactionType
          : null,
      customSuggestedTransactionType: _suggestedTransactionType == 'OTHER'
          ? _optionalText(_customTransactionTypeController)
          : null,
      usageDate: widget.history.usageDate,
      balance: widget.history.balance,
      calculatedAmount: widget.history.amountCalculation.isResolved
          ? widget.history.amountCalculation.amount
          : null,
      additionalDescription: _isStationNameRequest || description.isEmpty
          ? null
          : description,
      parserVersion: widget.history.rawBlock.format == HistoryRecordFormat.ica
          ? IcaHistoryParser.version
          : TransitHistoryParser.version,
      stationDatabaseVersion: AssetStationDatabase.version,
      appVersion: appVersion,
      platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
      osVersion: kIsWeb ? 'web' : Platform.operatingSystemVersion,
    );
  }

  void _selectIssue(String? value) {
    setState(() {
      _issue = value;
      _detailError = null;
      _stationIssueScope = null;
      _suggestedTransactionType = null;
      _busCompanyNameController.clear();
      _busCompanyCityController.clear();
      _nameBoardingStationController.clear();
      _nameAlightingStationController.clear();
      _customTransactionTypeController.clear();
    });
  }

  Future<void> _showStationScopeSheet() async {
    final selected = await showModalBottomSheet<StationIssueScope>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _StationScopeSheet(
        selected: _stationIssueScope,
        isStationNameRequest: _isStationNameRequest,
      ),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _stationIssueScope = selected;
      _detailError = null;
    });
  }

  Future<void> _showTransactionTypeSheet() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) =>
          _TransactionTypeSheet(selected: _suggestedTransactionType),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _suggestedTransactionType = selected;
      _detailError = null;
      if (selected != 'OTHER') _customTransactionTypeController.clear();
    });
  }

  void _validateAndReview() {
    if (_usesStationScope && _stationIssueScope == null) {
      setState(() => _detailError = '역 범위를 선택해 주세요.');
      return;
    }
    if (_issue == '거래 유형이 잘못됨' && _suggestedTransactionType == null) {
      setState(() => _detailError = '올바른 거래 유형을 선택해 주세요.');
      return;
    }
    if (!(_detailFormKey.currentState?.validate() ?? false)) return;
    setState(() {
      _detailError = null;
      _step = 2;
    });
  }

  bool get _needsStationCorrection => _issue == '역 정보가 없거나 잘못됨';

  bool get _usesStationScope =>
      _issue == '역 정보가 없거나 잘못됨' || _isStationNameRequest;

  bool get _isBusHistory =>
      widget.history.transactionType == TransitTransactionType.bus;

  bool get _isBusCompanyIssue => _issue == '버스 회사 정보가 없거나 잘못됨';

  bool get _isStationNameRequest => _issue == '역명 한글 표기 추가 요청';

  bool get _needsBoardingStationScope =>
      _stationIssueScope == StationIssueScope.boarding ||
      _stationIssueScope == StationIssueScope.both;

  bool get _needsAlightingStationScope =>
      _stationIssueScope == StationIssueScope.alighting ||
      _stationIssueScope == StationIssueScope.both;

  String get _detailTitle => _needsStationCorrection
      ? '올바른 역 정보'
      : _issue == '거래 유형이 잘못됨'
      ? '올바른 거래 유형'
      : _isBusCompanyIssue
      ? '버스 회사 정보'
      : _isStationNameRequest
      ? '한글 역명 제안'
      : '추가 설명';

  String get _detailGuide => _needsStationCorrection
      ? '역 이름과 도시·지역을 입력해 주세요. 노선명은 알고 있는 경우에만 적어주세요.'
      : _issue == '거래 유형이 잘못됨'
      ? '목록에서 선택하고, 없는 유형은 직접 입력해 주세요.'
      : _isBusCompanyIssue
      ? '실제 버스 회사명과 운행 도시·지역을 입력해 주세요.'
      : _isStationNameRequest
      ? '승차역·하차역 중 해당 범위를 선택해 주세요. 한글 발음을 아는 경우에만 표기를 입력하면 됩니다.'
      : '알고 있는 내용을 적어주시면 해석 정확도를 높이는 데 도움이 됩니다.';

  String get _boardingCorrectionSummary => _stationCorrectionSummary(
    _boardingStationController,
    _boardingCityController,
    _boardingLineController,
  );

  String get _alightingCorrectionSummary => _stationCorrectionSummary(
    _alightingStationController,
    _alightingCityController,
    _alightingLineController,
  );

  String get _suggestedTransactionSummary =>
      _suggestedTransactionType == 'OTHER'
      ? _optionalText(_customTransactionTypeController) ??
            reportText(context, '직접 입력 없음')
      : reportText(
          context,
          _suggestedTransactionTypeLabel(_suggestedTransactionType),
        );

  String get _busCompanyName => _busCompanyNameController.text.trim();

  String get _busCompanyCity => _busCompanyCityController.text.trim();

  Widget _stationCorrectionFields(
    BuildContext context, {
    required String title,
    required TextEditingController stationController,
    required TextEditingController cityController,
    required TextEditingController lineController,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        reportText(context, title),
        style: Theme.of(context).textTheme.titleSmall,
      ),
      const SizedBox(height: 10),
      TextFormField(
        controller: stationController,
        maxLength: 80,
        decoration: InputDecoration(labelText: reportText(context, '역 이름')),
        validator: (value) => _requiredTextError(context, value, '역 이름'),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: cityController,
        maxLength: 80,
        decoration: InputDecoration(labelText: reportText(context, '도시·지역')),
        validator: (value) => _requiredTextError(context, value, '도시·지역'),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: lineController,
        maxLength: 100,
        decoration: InputDecoration(labelText: reportText(context, '노선명 (선택)')),
      ),
    ],
  );

  Widget _stationNameField(
    BuildContext context, {
    required String title,
    required TextEditingController controller,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        reportText(context, title),
        style: Theme.of(context).textTheme.titleSmall,
      ),
      const SizedBox(height: 10),
      TextFormField(
        controller: controller,
        maxLength: 80,
        decoration: InputDecoration(
          labelText: reportText(context, '한글 표기'),
          hintText: reportText(context, '예: 시부야 (모르면 비워 두세요)'),
        ),
      ),
    ],
  );

  Widget _busCompanyFields(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        reportText(context, '버스 회사 정보'),
        style: Theme.of(context).textTheme.titleSmall,
      ),
      const SizedBox(height: 10),
      TextFormField(
        controller: _busCompanyNameController,
        maxLength: 80,
        decoration: InputDecoration(
          labelText: reportText(context, '실제 버스 회사명'),
        ),
        validator: (value) => _requiredTextError(context, value, '버스 회사명'),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: _busCompanyCityController,
        maxLength: 80,
        decoration: InputDecoration(labelText: reportText(context, '운행 도시·지역')),
        validator: (value) => _requiredTextError(context, value, '운행 도시·지역'),
      ),
    ],
  );

  StationCorrection _stationCorrection(
    TextEditingController stationController,
    TextEditingController cityController,
    TextEditingController lineController,
  ) => StationCorrection(
    name: stationController.text.trim(),
    city: cityController.text.trim(),
    line: _optionalText(lineController),
  );
}

class _StationScopeSheet extends StatelessWidget {
  const _StationScopeSheet({this.selected, required this.isStationNameRequest});

  final StationIssueScope? selected;
  final bool isStationNameRequest;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              reportText(
                context,
                isStationNameRequest ? '어느 역의 한글 표기인가요?' : '어느 역 정보인가요?',
              ),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(
              reportText(
                context,
                isStationNameRequest
                    ? '한글 표기를 추가할 역을 선택해 주세요.'
                    : '표시되지 않거나 잘못된 역 정보를 선택해 주세요.',
              ),
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            for (final scope in StationIssueScope.values) ...[
              _StationScopeOption(
                scope: scope,
                selected: selected == scope,
                onTap: () => Navigator.pop(context, scope),
              ),
              if (scope != StationIssueScope.both) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _StationScopeOption extends StatelessWidget {
  const _StationScopeOption({
    required this.scope,
    required this.selected,
    required this.onTap,
  });

  final StationIssueScope scope;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? AppColors.skySoft : colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Icon(
                scope == StationIssueScope.both
                    ? Icons.compare_arrows_rounded
                    : Icons.train_outlined,
                color: selected
                    ? AppColors.skyDark
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  reportText(context, _stationIssueScopeLabel(scope)),
                  style: TextStyle(
                    color: selected ? AppColors.skyDark : colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: AppColors.skyDark),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionTypeSheet extends StatelessWidget {
  const _TransactionTypeSheet({this.selected});

  final String? selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              reportText(context, '올바른 거래 유형을 선택해 주세요'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(
              reportText(context, '목록에 없는 유형은 직접 입력할 수 있습니다.'),
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _suggestedTransactionTypes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final type = _suggestedTransactionTypes[index];
                  return _TransactionTypeOption(
                    type: type,
                    selected: selected == type,
                    onTap: () => Navigator.pop(context, type),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTypeOption extends StatelessWidget {
  const _TransactionTypeOption({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final String type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? AppColors.skySoft : colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Icon(
                _suggestedTransactionTypeIcon(type),
                color: selected
                    ? AppColors.skyDark
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  reportText(context, _suggestedTransactionTypeLabel(type)),
                  style: TextStyle(
                    color: selected ? AppColors.skyDark : colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: AppColors.skyDark),
            ],
          ),
        ),
      ),
    );
  }
}

IssueType _issueType(String issue, {bool english = false}) => switch (issue) {
  '역 정보가 없거나 잘못됨' => IssueType.wrongStationName,
  '역명 한글 표기 추가 요청' =>
    english
        ? IssueType.englishStationNameRequest
        : IssueType.koreanStationNameRequest,
  '버스 회사 정보가 없거나 잘못됨' => IssueType.busCompanyNotResolved,
  '거래 유형이 잘못됨' => IssueType.wrongTransactionType,
  '금액 또는 잔액이 잘못됨' => IssueType.wrongAmountOrBalance,
  _ => IssueType.other,
};

String? _requiredTextError(BuildContext context, String? value, String label) =>
    value == null || value.trim().isEmpty
    ? strings(context).reportRequiredField(reportText(context, label))
    : null;

String? _optionalText(TextEditingController controller) {
  final value = controller.text.trim();
  return value.isEmpty ? null : value;
}

String _stationIssueScopeLabel(StationIssueScope scope) => switch (scope) {
  StationIssueScope.boarding => '승차역',
  StationIssueScope.alighting => '하차역',
  StationIssueScope.both => '승차역과 하차역 모두',
};

String _stationCorrectionSummary(
  TextEditingController stationController,
  TextEditingController cityController,
  TextEditingController lineController,
) {
  final values = [
    stationController.text.trim(),
    cityController.text.trim(),
    _optionalText(lineController),
  ].whereType<String>().where((value) => value.isNotEmpty);
  return values.join(' · ');
}

String _suggestedTransactionTypeLabel(String? type) => switch (type) {
  'RAIL' => '철도 이용',
  'BUS' => '버스 이용',
  'PURCHASE' => '물품 구매',
  'CHARGE' => '충전',
  'GATE_WINDOW_PROCESSING' => '개찰 창구 처리',
  'REFUND' => '환불',
  'ADJUSTMENT' => '정산',
  'OTHER' => '목록에 없음 / 직접 입력',
  _ => '선택되지 않음',
};

const _suggestedTransactionTypes = [
  'RAIL',
  'BUS',
  'PURCHASE',
  'CHARGE',
  'GATE_WINDOW_PROCESSING',
  'REFUND',
  'ADJUSTMENT',
  'OTHER',
];

IconData _suggestedTransactionTypeIcon(String type) => switch (type) {
  'RAIL' => Icons.train_rounded,
  'BUS' => Icons.directions_bus_rounded,
  'PURCHASE' => Icons.shopping_bag_outlined,
  'CHARGE' => Icons.add_card_rounded,
  'GATE_WINDOW_PROCESSING' => Icons.meeting_room_outlined,
  'REFUND' => Icons.undo_rounded,
  'ADJUSTMENT' => Icons.receipt_long_outlined,
  _ => Icons.edit_note_rounded,
};

String _uuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0F) | 0x40;
  bytes[8] = (bytes[8] & 0x3F) | 0x80;
  final hexadecimal = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hexadecimal.substring(0, 8)}-'
      '${hexadecimal.substring(8, 12)}-'
      '${hexadecimal.substring(12, 16)}-'
      '${hexadecimal.substring(16, 20)}-'
      '${hexadecimal.substring(20)}';
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var index = 0; index < 3; index++) ...[
        Expanded(
          child: AnimatedContainer(
            key: ValueKey('report-progress-segment-$index'),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            height: 5,
            decoration: BoxDecoration(
              color: index <= current
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        if (index < 2) const SizedBox(width: 7),
      ],
    ],
  );
}

class _SelectedHistoryCard extends StatelessWidget {
  const _SelectedHistoryCard({
    required this.history,
    this.stations,
    this.transactionLocation,
  });

  final ParsedTransitHistory history;
  final ResolvedStationPair? stations;
  final StationResolution? transactionLocation;

  @override
  Widget build(BuildContext context) => AppSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          reportText(context, '선택한 이용내역'),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                reportText(
                  context,
                  _reportHistorySummary(
                    history,
                    stations,
                    transactionLocation,
                    strings(context),
                  ),
                ),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              reportText(context, _reportAmount(history.amountCalculation)),
              style: TextStyle(
                color: history.transactionType == TransitTransactionType.charge
                    ? AppColors.success
                    : null,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          reportText(
            context,
            '${transactionTypeLabel(history, strings(context))} · ${formatDate(history.usageDate)}',
          ),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

String _reportHistorySummary(
  ParsedTransitHistory history,
  ResolvedStationPair? stations,
  StationResolution? transactionLocation,
  AppLocalizations l10n,
) => switch (history.transactionType) {
  TransitTransactionType.rail =>
    '${stations?.boarding.station?.stationName ?? _reportBoardingCode(history)}'
        ' → '
        '${stations?.alighting.station?.stationName ?? _reportAlightingCode(history)}',
  TransitTransactionType.bus => history.busOperatorName ?? '버스 회사 미확인',
  TransitTransactionType.purchase => purchaseSummary(history, l10n),
  TransitTransactionType.charge => chargeSummary(
    history,
    transactionLocation: transactionLocation,
    l10n: l10n,
  ),
  TransitTransactionType.gateWindowProcessing => gateWindowSummary(
    history,
    transactionLocation: transactionLocation,
    l10n: l10n,
  ),
  TransitTransactionType.refund => '환불',
  TransitTransactionType.adjustment => '정산',
  TransitTransactionType.unknown => '거래 유형 미확인',
};

String _reportAmount(AmountCalculation calculation) =>
    switch (calculation.status) {
      AmountCalculationStatus.calculated => '-${yen(calculation.amount!)}',
      AmountCalculationStatus.balanceIncrease => '+${yen(calculation.amount!)}',
      AmountCalculationStatus.unavailable => '계산 불가',
      AmountCalculationStatus.suspicious => '확인 필요',
    };

String _reportBoardingCode(ParsedTransitHistory history) =>
    '${hexByte(history.regionCode)}-${hexByte(history.boardingLineCode)}-${hexByte(history.boardingStationCode)}';

String _reportAlightingCode(ParsedTransitHistory history) =>
    '${hexByte(history.regionCode)}-${hexByte(history.alightingLineCode)}-${hexByte(history.alightingStationCode)}';
