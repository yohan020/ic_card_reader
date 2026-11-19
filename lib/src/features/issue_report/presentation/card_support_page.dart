import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import 'report_strings.dart';

import '../../../core/widgets/app_ui.dart';
import '../../card_reader/domain/card_reader.dart';
import '../../card_reader/domain/card_scan_result.dart';
import '../../settings/domain/installed_app_version.dart';
import '../domain/card_support_report.dart';
import '../domain/issue_report_repository.dart';
import 'report_success_dialog.dart';

class CardSupportPage extends StatefulWidget {
  const CardSupportPage({required this.reader, this.repository, super.key});
  final CardReader reader;
  final CardSupportRepository? repository;

  @override
  State<CardSupportPage> createState() => _CardSupportPageState();
}

class _CardSupportPageState extends State<CardSupportPage> {
  final _brand = TextEditingController();
  final _description = TextEditingController();
  CardSupportCategory _category = CardSupportCategory.unreadable;
  CardSupportDiagnostic? _diagnostic;
  CardSupportReport? _preview;
  bool _scanConsent = false;
  bool _sendConsent = false;
  bool _scanning = false;
  bool _sending = false;
  int _generation = 0;
  String? _message;

  @override
  void dispose() {
    _generation++;
    if (_scanning) unawaited(widget.reader.cancel().catchError((Object _) {}));
    _brand.dispose();
    _description.dispose();
    super.dispose();
  }

  void _edited() => setState(() {
    _preview = null;
    _sendConsent = false;
    _message = null;
  });

  Future<void> _scan() async {
    if (!_scanConsent || _scanning || _sending) return;
    final reader = widget.reader;
    if (reader is! SupportCardReader) {
      setState(() => _message = '이 읽기 방식에서는 카드 진단을 지원하지 않아요.');
      return;
    }
    final generation = ++_generation;
    setState(() {
      _scanning = true;
      _diagnostic = null;
      _preview = null;
      _sendConsent = false;
      _message = '카드 한 장을 기기 뒷면 NFC 위치에 대 주세요.';
    });
    try {
      final report = await (reader as SupportCardReader)
          .scanSupportDiagnostics();
      if (!mounted || generation != _generation) return;
      setState(() {
        _diagnostic = CardSupportDiagnostic.fromReport(report);
        _message = '진단 정보를 확인했어요. 아직 서버로 전송하지 않았어요.';
      });
    } on CardScanException catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        if (error.kind != CardScanFailureKind.cancelled &&
            error.kind != CardScanFailureKind.nfcUnavailable &&
            error.kind != CardScanFailureKind.timedOut) {
          _diagnostic = CardSupportDiagnostic.fromFailure(error.kind);
        }
        _message = switch (error.kind) {
          CardScanFailureKind.cancelled => '진단을 취소했어요.',
          CardScanFailureKind.nfcUnavailable => 'NFC를 켠 뒤 다시 시도해 주세요.',
          CardScanFailureKind.timedOut => '시간이 초과됐어요. 다시 진단해 주세요.',
          _ => '메타데이터를 읽지 못했어요. 최소 오류 코드와 설명만 문의할 수 있어요.',
        };
      });
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() => _message = '진단을 완료하지 못했어요. 다시 시도해 주세요.');
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _scanning = false);
      }
    }
  }

  Future<void> _cancel() async {
    _generation++;
    await widget.reader.cancel();
    if (mounted) {
      setState(() {
        _scanning = false;
        _message = '진단을 취소했어요.';
      });
    }
  }

  Future<void> _prepare() async {
    final diagnostic = _diagnostic;
    if (diagnostic == null || _scanning || _sending) return;
    final generation = ++_generation;
    final version = await InstalledAppVersion.read();
    if (!mounted || generation != _generation) return;
    setState(() {
      _preview = CardSupportReport(
        reportId: _uuid(),
        category: _category,
        expectedBrand: _brand.text,
        description: _description.text,
        diagnostic: diagnostic,
        appVersion: version ?? 'unknown',
        platform: Platform.operatingSystem,
        osVersion: Platform.operatingSystemVersion.substring(
          0,
          min(160, Platform.operatingSystemVersion.length),
        ),
      );
      _sendConsent = false;
      _message = null;
    });
  }

  Future<void> _chooseCategory() async {
    if (_scanning || _sending) return;
    FocusScope.of(context).unfocus();
    final selected = await showModalBottomSheet<CardSupportCategory>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => _CategorySheet(selected: _category),
    );
    if (!mounted || selected == null || selected == _category) return;
    _category = selected;
    _edited();
  }

  Future<void> _showPayload(CardSupportReport preview) async {
    FocusScope.of(context).unfocus();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .78,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  reportText(context, '전송 항목 전체 보기'),
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                _SupportNotice(
                  reportText(context, '아래 내용만 전송해요. 이 화면을 여는 것만으로는 전송되지 않아요.'),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      JsonEncoder.withIndent('  ').convert(preview.toJson()),
                      key: const ValueKey('support-payload-json'),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: Text(reportText(context, '닫기')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final preview = _preview;
    final repository = widget.repository;
    if (preview == null || !_sendConsent || _sending || repository == null) {
      return;
    }
    setState(() {
      _sending = true;
      _message = null;
    });
    try {
      final receipt = await repository.submitCardSupport(preview);
      if (!mounted) return;
      setState(() {
        _preview = null;
        _diagnostic = null;
        _sendConsent = false;
        _scanConsent = false;
        _brand.clear();
        _description.clear();
      });
      await showReportSuccessDialog(
        context,
        reportId: receipt,
        title: '문의가 접수되었습니다',
        privacyNotice: '카드 IDm·잔액·이용내역은 전송되지 않았습니다.',
      );
      if (mounted) Navigator.pop(context);
    } on IssueReportSubmissionException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) setState(() => _message = '전송하지 못했어요. 연결을 확인하고 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(reportText(context, '카드 인식 문의'))),
    body: SafeArea(
      top: false,
      child: AppPage(
        children: [
          Text(
            reportText(context, '읽히지 않는 카드가 있나요?'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _SupportNotice(
            reportText(
              context,
              '카드 읽기·브랜드 구분 문제를 알려 주세요.\n일반 스캔의 이용내역은 바뀌지 않아요.',
            ),
          ),
          const SizedBox(height: 18),
          AppSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  reportText(context, '문의 내용'),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  key: const ValueKey('support-category-picker'),
                  onPressed: _scanning || _sending ? null : _chooseCategory,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    alignment: Alignment.centerLeft,
                  ),
                  child: Row(
                    children: [
                      Icon(_categoryIcon(_category), size: 21),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          reportText(context, _categoryTitle(_category)),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 22),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  key: const ValueKey('support-expected-brand'),
                  controller: _brand,
                  enabled: !_scanning && !_sending,
                  maxLength: 60,
                  onChanged: (_) => _edited(),
                  decoration: InputDecoration(
                    labelText: reportText(context, '카드 브랜드 (선택)'),
                    hintText: reportText(context, '예: Kitaca · 모르면 비워 두세요'),
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey('support-description'),
                  controller: _description,
                  enabled: !_scanning && !_sending,
                  maxLength: 300,
                  minLines: 1,
                  maxLines: 3,
                  onChanged: (_) => _edited(),
                  decoration: InputDecoration(
                    labelText: reportText(context, '문제 설명 (선택)'),
                    hintText: reportText(context, '어떤 문제가 있었나요?'),
                    helperText: reportText(context, '이름·카드번호·연락처는 적지 마세요.'),
                    helperMaxLines: 2,
                    helperStyle: TextStyle(fontSize: 11),
                    counterStyle: TextStyle(fontSize: 11),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  reportText(context, '최소 진단 확인'),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                _SupportNotice(
                  reportText(
                    context,
                    '시스템 코드·제조 정보(PMm)·일부 서비스의 존재 여부·통신 오류 코드만 확인해요.\n카드 전체·서비스 본문·IDm·카드번호·잔액·이용내역은 수집하지 않아요.',
                  ),
                ),
                const SizedBox(height: 6),
                _SupportConsent(
                  label: reportText(context, '최소 진단 확인에 동의해요'),
                  value: _scanConsent,
                  onChanged: _scanning || _sending
                      ? null
                      : (value) =>
                            setState(() => _scanConsent = value ?? false),
                ),
                FilledButton(
                  onPressed: !_scanConsent || _scanning || _sending
                      ? null
                      : _scan,
                  child: Text(
                    reportText(context, _scanning ? '카드 확인 중…' : '진단용 카드 스캔'),
                  ),
                ),
                if (_scanning) ...[
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(),
                  TextButton(
                    onPressed: _cancel,
                    child: Text(reportText(context, '진단 취소')),
                  ),
                ],
              ],
            ),
          ),
          if (_diagnostic != null && _preview == null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _scanning || _sending ? null : _prepare,
              child: Text(reportText(context, '전송할 내용 확인')),
            ),
          ],
          if (_preview case final preview?) ...[
            const SizedBox(height: 16),
            AppSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    reportText(context, '문의 전송'),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  _SupportNotice(
                    reportText(
                      context,
                      '문의·최소 진단·앱/OS 버전·접수 번호·동의 버전을 Supabase로 보내 카드 인식 개선에 사용해요.\n처리 완료 후 1년 뒤 삭제하며, 검토 중인 문의는 유지해요. 익명 인증 ID는 접수 제한에 사용해요.',
                    ),
                  ),
                  const SizedBox(height: 6),
                  _SupportConsent(
                    label: reportText(context, '문의 전송에 동의해요'),
                    value: _sendConsent,
                    onChanged: _sending
                        ? null
                        : (value) =>
                              setState(() => _sendConsent = value ?? false),
                  ),
                  if (widget.repository == null)
                    Text(
                      reportText(
                        context,
                        '문의 서버가 준비되지 않았어요. 설정의 이메일로 연락해 주세요.',
                      ),
                    ),
                  FilledButton(
                    onPressed:
                        !_sendConsent || _sending || widget.repository == null
                        ? null
                        : _submit,
                    child: Text(
                      reportText(context, _sending ? '전송 중…' : '동의하고 문의 보내기'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: _sending ? null : () => _showPayload(preview),
              icon: const Icon(Icons.list_alt_rounded, size: 18),
              label: Text(
                reportText(context, '전송 항목 전체 보기'),
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                reportText(context, _message!),
                key: const ValueKey('card-support-message'),
              ),
            ),
          const SizedBox(height: 16),
          _SupportNotice(
            reportText(context, '개별 답변 문의: iccardreader10@gmail.com'),
          ),
        ],
      ),
    ),
  );
}

String _categoryTitle(CardSupportCategory category) => switch (category) {
  CardSupportCategory.unreadable => '카드 읽기 오류',
  CardSupportCategory.brandUnknown => '카드 브랜드 구분',
};
IconData _categoryIcon(CardSupportCategory category) => switch (category) {
  CardSupportCategory.unreadable => Icons.contactless_outlined,
  CardSupportCategory.brandUnknown => Icons.credit_card_outlined,
};

class _SupportNotice extends StatelessWidget {
  const _SupportNotice(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    reportText(context, text),
    style: TextStyle(
      fontSize: 12,
      height: 1.5,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

class _SupportConsent extends StatelessWidget {
  const _SupportConsent({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool?>? onChanged;
  @override
  Widget build(BuildContext context) => CheckboxListTile(
    contentPadding: EdgeInsets.zero,
    controlAffinity: ListTileControlAffinity.leading,
    dense: true,
    value: value,
    onChanged: onChanged,
    title: Text(
      reportText(context, label),
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    ),
  );
}

class _CategorySheet extends StatelessWidget {
  const _CategorySheet({required this.selected});
  final CardSupportCategory selected;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              reportText(context, '문의 유형 선택'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            _SupportNotice(reportText(context, '가장 가까운 항목 하나를 선택해 주세요.')),
            const SizedBox(height: 18),
            for (final category in CardSupportCategory.values) ...[
              Semantics(
                selected: selected == category,
                child: Material(
                  color: selected == category
                      ? Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: .35)
                      : Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: selected == category
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.pop(context, category),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(
                            _categoryIcon(category),
                            color: Theme.of(context).colorScheme.primary,
                            size: 23,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reportText(context, _categoryTitle(category)),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _SupportNotice(
                                  reportText(context, category.label),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            selected == category
                                ? Icons.check_circle_rounded
                                : Icons.chevron_right_rounded,
                            size: 21,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    ),
  );
}

String _uuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final text = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${text.substring(0, 8)}-${text.substring(8, 12)}-${text.substring(12, 16)}-${text.substring(16, 20)}-${text.substring(20)}';
}
