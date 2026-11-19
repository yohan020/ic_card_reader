import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import 'stamp_book_style.dart';

enum StampBookCoachStep {
  collect(1),
  browse(2),
  operator(2),
  exampleLine(2),
  diagram(3);

  const StampBookCoachStep(this.number);
  final int number;
}

/// Highlights an existing control without replacing it or hiding its ink.
class StampBookCoach extends StatefulWidget {
  const StampBookCoach({
    required this.step,
    required this.anchor,
    required this.onSkip,
    required this.onAction,
    required this.hasScan,
    required this.child,
    super.key,
  });

  final StampBookCoachStep? step;
  final GlobalKey anchor;
  final VoidCallback onSkip;
  final VoidCallback onAction;
  final bool hasScan;
  final Widget child;

  @override
  State<StampBookCoach> createState() => _StampBookCoachState();
}

class _StampBookCoachState extends State<StampBookCoach> {
  final _surface = GlobalKey();
  Rect? _rect;
  bool _queued = false;
  bool _reveal = true;

  @override
  void didUpdateWidget(StampBookCoach oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step != widget.step) {
      _rect = null;
      _reveal = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    MediaQuery.sizeOf(context);
    MediaQuery.textScalerOf(context);
    _reveal = true;
  }

  void _measure() {
    if (_queued || widget.step == null) return;
    _queued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _queued = false;
      if (!mounted || widget.step == null) return;
      final anchor = widget.anchor.currentContext;
      final target = anchor?.findRenderObject();
      final surface = _surface.currentContext?.findRenderObject();
      if (anchor == null ||
          target is! RenderBox ||
          !target.hasSize ||
          surface is! RenderBox ||
          !surface.hasSize) {
        return;
      }
      if (_reveal) {
        _reveal = false;
        Scrollable.ensureVisible(anchor, alignment: .45);
      }
      final rect =
          (target.localToGlobal(Offset.zero, ancestor: surface) & target.size)
              .inflate(3)
              .intersect(Offset.zero & surface.size);
      if (_rect != rect) setState(() => _rect = rect);
    });
  }

  @override
  Widget build(BuildContext context) {
    _measure();
    final step = widget.step;
    final rect = _rect;
    final showing = step != null && rect != null && !rect.isEmpty;
    return PopScope(
      canPop: !showing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && showing) widget.onSkip();
      },
      child: Stack(
        key: _surface,
        fit: StackFit.expand,
        children: [
          ExcludeFocus(
            excluding: showing,
            child: NotificationListener<ScrollNotification>(
              onNotification: (_) {
                _measure();
                return false;
              },
              child: widget.child,
            ),
          ),
          if (showing)
            Positioned.fill(
              child: BlockSemantics(
                child: _CoachLayer(
                  step: step,
                  target: rect,
                  hasScan: widget.hasScan,
                  onSkip: widget.onSkip,
                  onAction: widget.onAction,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CoachLayer extends StatelessWidget {
  const _CoachLayer({
    required this.step,
    required this.target,
    required this.hasScan,
    required this.onSkip,
    required this.onAction,
  });

  final StampBookCoachStep step;
  final Rect target;
  final bool hasScan;
  final VoidCallback onSkip;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colors = StampBookColors(context);
    final padding = MediaQuery.paddingOf(context);
    final (title, detail, action) = switch (step) {
      StampBookCoachStep.collect => (
        localized(context, '첫 도장을 모아봐요', 'Collect your first stamp'),
        hasScan
            ? localized(
                context,
                '이 버튼으로 현재 스캔에서 확인된 역을 수첩에 담을 수 있어요.',
                'Use this button to add stations from the current scan to your book.',
              )
            : localized(
                context,
                '홈에서 IC 카드를 스캔한 뒤, 이 버튼으로 확인된 역을 모을 수 있어요.',
                'Scan an IC card on Home, then use this button to collect confirmed stations.',
              ),
        localized(context, '다음', 'Next'),
      ),
      StampBookCoachStep.browse => (
        localized(context, '둘러볼 노선을 골라요', 'Choose a line to explore'),
        localized(
          context,
          '전체 노선을 열어 수집할 수 있는 노선을 찾아보세요.',
          'Browse all lines to find routes you can collect.',
        ),
        localized(context, '노선 둘러보기', 'Browse lines'),
      ),
      StampBookCoachStep.operator => (
        localized(context, '회사를 펼쳐봐요', 'Expand the operator'),
        localized(
          context,
          'JR 동일본을 누르면 이 회사의 노선이 나와요.',
          'Tap JR East to reveal its lines.',
        ),
        localized(context, '회사 펼치기', 'Show lines'),
      ),
      StampBookCoachStep.exampleLine => (
        localized(context, '노선을 열어봐요', 'Explore a line'),
        localized(
          context,
          '예시로 야마노테선을 눌러보세요.',
          'Try opening the Yamanote Line.',
        ),
        localized(context, '야마노테선 열기', 'Open Yamanote Line'),
      ),
      StampBookCoachStep.diagram => (
        localized(context, '노선도로 모은 역을 봐요', 'See your stations on the line'),
        localized(
          context,
          '‘노선도’를 누르면 역의 위치와 수집 여부를 한눈에 볼 수 있어요.',
          'Open the line diagram to see station locations and which ones you’ve collected.',
        ),
        localized(context, '노선도 열기', 'Open line diagram'),
      ),
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final top = padding.top + 12;
        final bottom = size.height - padding.bottom - 12;
        final below = bottom - target.bottom;
        final above = target.top - top;
        final lower = below >= above;
        final width = math.min(340.0, size.width - 32);
        final left = (target.center.dx - width / 2).clamp(
          16.0,
          size.width - 16 - width,
        );
        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _SpotlightPainter(target, colors.teal, colors.dark),
                ),
              ),
            ),
            // Intercept only the scrim; the real highlighted control receives
            // taps through the cutout. The bubble also offers a semantic CTA.
            for (final box in [
              Rect.fromLTRB(0, 0, size.width, target.top),
              Rect.fromLTRB(0, target.bottom, size.width, size.height),
              Rect.fromLTRB(0, target.top, target.left, target.bottom),
              Rect.fromLTRB(
                target.right,
                target.top,
                size.width,
                target.bottom,
              ),
            ])
              Positioned.fromRect(
                rect: box,
                child: const Listener(behavior: HitTestBehavior.opaque),
              ),
            Positioned(
              left: left,
              top: lower ? target.bottom + 12 : null,
              bottom: lower ? null : size.height - target.top + 12,
              width: width,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: math.max(0, (lower ? below : above) - 12),
                ),
                child: Material(
                  key: const ValueKey('stamp-book-coach'),
                  color: colors.paper,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: colors.teal),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                localized(context, '수첩 둘러보기', 'BOOK TOUR'),
                                style: TextStyle(
                                  color: colors.teal,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text('${step.number} / 3'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Semantics(
                          header: true,
                          liveRegion: true,
                          child: Text(
                            title,
                            style: TextStyle(
                              color: colors.ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          detail,
                          style: TextStyle(color: colors.ink, height: 1.45),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 8,
                            children: [
                              TextButton(
                                key: const ValueKey('stamp-book-coach-skip'),
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(48, 48),
                                ),
                                onPressed: onSkip,
                                child: Text(localized(context, '건너뛰기', 'Skip')),
                              ),
                              FilledButton(
                                key: const ValueKey('stamp-book-coach-action'),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(48, 38),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  visualDensity: VisualDensity.standard,
                                  tapTargetSize: MaterialTapTargetSize.padded,
                                ),
                                onPressed: onAction,
                                child: Text(action),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: target.center.dx - 6,
              top: lower ? target.bottom + 5 : target.top - 12,
              child: IgnorePointer(
                child: CustomPaint(
                  size: const Size(12, 8),
                  painter: _PointerPainter(colors.paper, colors.teal, lower),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter(this.target, this.outline, this.dark);
  final Rect target;
  final Color outline;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final hole = RRect.fromRectAndRadius(target, const Radius.circular(13));
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(hole);
    canvas.drawPath(
      path,
      Paint()..color = Colors.black.withValues(alpha: dark ? .54 : .36),
    );
    canvas.drawRRect(
      hole,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.target != target || old.outline != outline || old.dark != dark;
}

class _PointerPainter extends CustomPainter {
  const _PointerPainter(this.paper, this.outline, this.pointsUp);
  final Color paper;
  final Color outline;
  final bool pointsUp;

  @override
  void paint(Canvas canvas, Size size) {
    final edge = pointsUp ? size.height : 0.0;
    final path = Path()
      ..moveTo(0, edge)
      ..lineTo(size.width / 2, size.height - edge)
      ..lineTo(size.width, edge);
    canvas.drawPath(path, Paint()..color = paper);
    canvas.drawPath(
      path,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_PointerPainter old) =>
      old.paper != paper || old.outline != outline || old.pointsUp != pointsUp;
}
