import 'package:flutter/material.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/localization/app_strings.dart';

/// Approved B direction: centered introduction with readable grouped guidance.
class ContactlessGuidanceDialog extends StatelessWidget {
  const ContactlessGuidanceDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = AppColors.mutedText(context);
    return Dialog(
      key: const ValueKey('contactless-guidance-dialog'),
      insetPadding: const EdgeInsets.all(24),
      constraints: const BoxConstraints(maxWidth: 342),
      backgroundColor: theme.cardTheme.color,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        key: const ValueKey('contactless-guidance-surface'),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                key: const ValueKey('contactless-guidance-content'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: ExcludeSemantics(
                        child: Container(
                          key: const ValueKey('contactless-guidance-icon'),
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: AppColors.softSurface(context),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: CustomPaint(
                            size: const Size(32, 32),
                            painter: _TapCardPainter(AppColors.accent(context)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Semantics(
                      namesRoute: true,
                      header: true,
                      child: Text(
                        localized(context, '컨택리스 승차 안내', 'Tap-to-ride guide'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      localized(
                        context,
                        '신용·체크카드를 전용 단말에 직접 태그하는 승차 방식이에요. 교통IC·QR 승차권과는 달라요.',
                        'Tap a credit or debit card directly on a designated reader. This is different from using a transit IC card or a QR ticket.',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 21),
                    Divider(height: 1, color: AppColors.outline(context)),
                    const SizedBox(height: 18),
                    _GuidanceSection(
                      title: localized(
                        context,
                        '노선별 이용 조건을 확인해 주세요',
                        'Check each line before travelling',
                      ),
                      body: localized(
                        context,
                        '전역 지원도 모든 개찰구·카드·직통 구간의 이용을 보장하지 않아요.',
                        'Even when all stations are covered, some gates, cards and through services may not be.',
                      ),
                    ),
                    const SizedBox(height: 17),
                    _GuidanceSection(
                      title: localized(
                        context,
                        '‘미확인’은 ‘미지원’이 아니에요',
                        '“Unverified” does not mean “Not supported”',
                      ),
                      body: localized(
                        context,
                        '미지원(추정)은 지불수단 안내를 기준으로 한 추정이며, 정보 미확인은 지원 여부를 확인하지 못한 상태예요.',
                        '“Likely not supported” is based on published payment methods. “Unverified” means we could not confirm either way.',
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      key: const ValueKey('contactless-guidance-note'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.isDark(context)
                            ? AppColors.fieldSurface(context)
                            : AppColors.canvas,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            localized(
                              context,
                              '오프라인 조회 · 실시간 정보 아님',
                              'Available offline · not live',
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                              color: muted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            localized(
                              context,
                              '저장된 조사 자료로 조회하며, 실시간 운행·결제 현황은 제공하지 않아요.',
                              'The app uses saved research, not live service or payment information.',
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const ValueKey('contactless-guidance-confirm'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(localized(context, '확인', 'Got it')),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidanceSection extends StatelessWidget {
  const _GuidanceSection({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        body,
        style: TextStyle(
          fontSize: 14,
          height: 1.55,
          color: AppColors.mutedText(context),
        ),
      ),
    ],
  );
}

class _TapCardPainter extends CustomPainter {
  const _TapCardPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(3, 7, 22, 18),
        const Radius.circular(3),
      ),
      stroke,
    );
    canvas.drawLine(const Offset(3, 13), const Offset(25, 13), stroke);
    canvas.drawLine(const Offset(8, 20), const Offset(13, 20), stroke);
    canvas.drawPath(
      Path()
        ..moveTo(28, 9)
        ..cubicTo(31, 13, 31, 19, 28, 23),
      stroke,
    );
  }

  @override
  bool shouldRepaint(_TapCardPainter oldDelegate) => color != oldDelegate.color;
}
