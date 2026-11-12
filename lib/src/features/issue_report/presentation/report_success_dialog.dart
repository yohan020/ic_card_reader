import 'package:flutter/material.dart';

import 'report_strings.dart';

import '../../../core/design/app_theme.dart';

Future<void> showReportSuccessDialog(
  BuildContext context, {
  required String reportId,
  String title = '제보가 접수되었습니다',
  String privacyNotice = '카드 IDm과 다른 이용내역은 전송되지 않았습니다.',
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (dialogContext) => ReportSuccessDialog(
    reportId: reportId,
    title: title,
    privacyNotice: privacyNotice,
    onClose: () => Navigator.pop(dialogContext),
  ),
);

/// Both inquiry flows share the existing receipt dialog's visual design.
class ReportSuccessDialog extends StatelessWidget {
  const ReportSuccessDialog({
    required this.reportId,
    required this.onClose,
    this.title = '제보가 접수되었습니다',
    this.privacyNotice = '카드 IDm과 다른 이용내역은 전송되지 않았습니다.',
    super.key,
  });

  final String reportId;
  final VoidCallback onClose;
  final String title;
  final String privacyNotice;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dialog(
      key: const ValueKey('report-success-dialog'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SingleChildScrollView(
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
                reportText(context, title),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                reportText(context, '보내주신 내용은 확인 후\n앱 개선에 활용됩니다.'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    Text(
                      reportText(context, '접수 번호'),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 15,
                    color: AppColors.skyDark,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      reportText(context, privacyNotice),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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
                  child: Text(
                    reportText(context, '확인'),
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
