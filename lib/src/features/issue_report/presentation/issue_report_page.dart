import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../station_resolver/data/asset_station_database.dart';
import '../../station_resolver/domain/station_resolution.dart';
import '../../transaction_history/data/transit_history_parser.dart';
import '../../transaction_history/domain/amount_calculation.dart';
import '../../transaction_history/domain/parsed_transit_history.dart';
import '../../transaction_history/domain/transit_transaction_type.dart';
import '../data/supabase_issue_report_repository.dart';
import '../domain/issue_report.dart';
import '../domain/issue_report_repository.dart';

class IssueReportPage extends StatefulWidget {
  const IssueReportPage({
    required this.history,
    super.key,
    this.stations,
    this.repository,
  });

  final ParsedTransitHistory history;
  final ResolvedStationPair? stations;
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
  final _descriptionController = TextEditingController();

  IssueReportRepository get _repository =>
      widget.repository ?? const UnavailableIssueReportRepository();

  @override
  void dispose() {
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
          const Text('오류 제보', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 1),
          Text(
            '${_step + 1}/3 단계',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    ),
    body: AppPage(
      children: [
        _StepIndicator(current: _step),
        const SizedBox(height: 18),
        _SelectedHistoryCard(
          history: widget.history,
          stations: widget.stations,
        ),
        const SizedBox(height: 22),
        if (_step == 0) _issueStep(context),
        if (_step == 1) _detailStep(context),
        if (_step == 2) _reviewStep(context),
      ],
    ),
  );

  Widget _issueStep(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '어떤 정보가 잘못되었나요?',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 6),
      Text(
        '가장 가까운 항목 하나를 선택해 주세요.',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 18),
      AppSurface(
        padding: EdgeInsets.zero,
        child: RadioGroup<String>(
          groupValue: _issue,
          onChanged: (value) => setState(() => _issue = value),
          child: Column(
            children: [
              for (final issue in const [
                '승차역이 잘못됨',
                '하차역이 잘못됨',
                '역을 찾지 못함',
                '거래 유형이 잘못됨',
                '금액 또는 잔액이 잘못됨',
                '기타',
              ]) ...[
                RadioListTile<String>(
                  value: issue,
                  title: Text(
                    issue,
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
        child: const Text('다음', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    ],
  );

  Widget _detailStep(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '추가 설명',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 6),
      Text(
        '알고 있는 내용을 적어주시면 해석 정확도를 높이는 데 도움이 됩니다.',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 18),
      TextField(
        controller: _descriptionController,
        maxLines: 6,
        maxLength: 300,
        decoration: const InputDecoration(
          hintText: '예: 실제 이용한 역이나 거래 유형을 알려주세요.',
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _step = 0),
              child: const Text(
                '이전',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: () => setState(() => _step = 2),
              child: const Text(
                '검토하기',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    ],
  );

  Widget _reviewStep(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '전송 전 확인',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 18),
      AppSurface(
        child: Column(
          children: [
            DetailLine(label: '제보 유형', value: _issue ?? '-'),
            const Divider(),
            DetailLine(
              label: '선택한 내역',
              value: _reportHistorySummary(widget.history, widget.stations),
            ),
            const Divider(),
            DetailLine(
              label: '거래 유형 / 금액',
              value:
                  '${_reportTypeLabel(widget.history.transactionType)} · ${_reportAmount(widget.history.amountCalculation)}',
            ),
            const Divider(),
            DetailLine(
              label: '이용 날짜',
              value: formatDate(widget.history.usageDate),
            ),
            const Divider(),
            DetailLine(
              label: '익명 원본 기록',
              value: widget.history.rawBlock.hexadecimal,
              monospace: true,
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      const NoticeBanner(
        title: '개인정보 보호',
        text: '카드 IDm은 포함하지 않습니다. 선택한 이용내역 1건의 16바이트 원본과 제보 내용만 전송 대상으로 준비합니다.',
        tone: NoticeTone.privacy,
      ),
      const SizedBox(height: 12),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: _consented,
        onChanged: (value) => setState(() => _consented = value ?? false),
        title: const Text(
          '위 정보의 전송에 동의합니다.',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
      if (_submissionError case final error?) ...[
        const SizedBox(height: 4),
        NoticeBanner(
          title: '제보를 전송하지 못했습니다',
          text: error,
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
            : const Text(
                '익명으로 제보하기',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
      ),
      const SizedBox(height: 10),
      OutlinedButton(
        onPressed: () => setState(() => _step = 1),
        child: const Text('이전', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    ],
  );

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });
    try {
      final receipt = await _repository.submit(_createReport());
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => _ReportSuccessDialog(
          reportId: receipt.reportId,
          onClose: () => Navigator.pop(dialogContext),
        ),
      );
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

  IssueReport _createReport() {
    final description = _descriptionController.text.trim();
    return IssueReport(
      anonymousReportId: _uuidV4(),
      anonymousRawRecord: widget.history.rawBlock.hexadecimal,
      issueType: _issueType(_issue!),
      regionCode: widget.history.regionCode,
      boardingLineCode: widget.history.boardingLineCode,
      boardingStationCode: widget.history.boardingStationCode,
      alightingLineCode: widget.history.alightingLineCode,
      alightingStationCode: widget.history.alightingStationCode,
      currentBoardingStation: widget.stations?.boarding.station?.stationName,
      currentAlightingStation: widget.stations?.alighting.station?.stationName,
      currentTransactionType: widget.history.transactionType.name.toUpperCase(),
      usageDate: widget.history.usageDate,
      balance: widget.history.balance,
      calculatedAmount: widget.history.amountCalculation.isResolved
          ? widget.history.amountCalculation.amount
          : null,
      additionalDescription: description.isEmpty ? null : description,
      parserVersion: TransitHistoryParser.version,
      stationDatabaseVersion: AssetStationDatabase.version,
      appVersion: '1.0.0+1',
      platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
      osVersion: kIsWeb ? 'web' : Platform.operatingSystemVersion,
    );
  }
}

class _ReportSuccessDialog extends StatelessWidget {
  const _ReportSuccessDialog({required this.reportId, required this.onClose});

  final String reportId;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: AppColors.skySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 38,
                color: AppColors.skyDark,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '제보가 접수되었습니다',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '보내주신 내용은 확인 후\n앱 개선에 활용됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                children: [
                  Text(
                    '접수 번호',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  SelectableText(
                    reportId,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 15,
                  color: AppColors.skyDark,
                ),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '카드 IDm과 다른 이용내역은 전송되지 않았습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.skyDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onClose,
                child: const Text(
                  '확인',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IssueType _issueType(String issue) => switch (issue) {
  '승차역이 잘못됨' => IssueType.wrongBoardingStation,
  '하차역이 잘못됨' => IssueType.wrongAlightingStation,
  '역을 찾지 못함' => IssueType.stationNotResolved,
  '거래 유형이 잘못됨' => IssueType.wrongTransactionType,
  '금액 또는 잔액이 잘못됨' => IssueType.wrongAmountOrBalance,
  _ => IssueType.other,
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
  const _SelectedHistoryCard({required this.history, this.stations});

  final ParsedTransitHistory history;
  final ResolvedStationPair? stations;

  @override
  Widget build(BuildContext context) => AppSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '선택한 이용내역',
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
                _reportHistorySummary(history, stations),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _reportAmount(history.amountCalculation),
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
          '${_reportTypeLabel(history.transactionType)} · ${formatDate(history.usageDate)}',
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
) => switch (history.transactionType) {
  TransitTransactionType.rail =>
    '${stations?.boarding.station?.stationName ?? _reportBoardingCode(history)}'
        ' → '
        '${stations?.alighting.station?.stationName ?? _reportAlightingCode(history)}',
  TransitTransactionType.bus => '버스 회사 미확인',
  TransitTransactionType.purchase => '물품 구매',
  TransitTransactionType.charge => '카드 충전',
  TransitTransactionType.refund => '환불',
  TransitTransactionType.adjustment => '정산',
  TransitTransactionType.unknown => '거래 유형 미확인',
};

String _reportTypeLabel(TransitTransactionType type) => switch (type) {
  TransitTransactionType.rail => '철도 이용',
  TransitTransactionType.bus => '버스 이용',
  TransitTransactionType.purchase => '물품 구매',
  TransitTransactionType.charge => '충전',
  TransitTransactionType.refund => '환불',
  TransitTransactionType.adjustment => '정산',
  TransitTransactionType.unknown => '유형 미확인',
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
