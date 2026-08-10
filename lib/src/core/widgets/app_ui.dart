import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/app_theme.dart';

class AppPage extends StatelessWidget {
  const AppPage({
    required this.children,
    super.key,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 28),
  });

  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ListView(padding: padding, children: children);
  }
}

class AppSurface extends StatelessWidget {
  const AppSurface({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: padding, child: child),
  );
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

enum NoticeTone { info, success, warning, danger, privacy }

class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    required this.text,
    super.key,
    this.title,
    this.tone = NoticeTone.info,
  });

  final String? title;
  final String text;
  final NoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (color, icon) = switch (tone) {
      NoticeTone.info => (const Color(0xFF247EAA), Icons.info_outline_rounded),
      NoticeTone.success => (
        AppColors.success,
        Icons.check_circle_outline_rounded,
      ),
      NoticeTone.warning => (AppColors.warning, Icons.warning_amber_rounded),
      NoticeTone.danger => (
        Theme.of(context).colorScheme.error,
        Icons.error_outline_rounded,
      ),
      NoticeTone.privacy => (AppColors.skyDark, Icons.shield_outlined),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: isDark ? .17 : .09),
          Theme.of(context).scaffoldBackgroundColor,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(
                      title!,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    super.key,
    this.icon,
    this.color = AppColors.skyDark,
  });

  final String label;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

class IcCardArt extends StatefulWidget {
  const IcCardArt({super.key, this.animated = false, this.size = 220});

  final bool animated;
  final double size;

  @override
  State<IcCardArt> createState() => _IcCardArtState();
}

class _IcCardArtState extends State<IcCardArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animated) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant IcCardArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animated && !_controller.isAnimating) _controller.repeat();
    if (!widget.animated && _controller.isAnimating) _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: widget.size,
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: _CardArtPainter(
          progress: widget.animated ? _controller.value : .45,
          dark: Theme.of(context).brightness == Brightness.dark,
        ),
      ),
    ),
  );
}

class _CardArtPainter extends CustomPainter {
  const _CardArtPainter({required this.progress, required this.dark});

  final double progress;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final base = size.shortestSide;
    for (var i = 0; i < 3; i++) {
      final phase = (progress + i / 3) % 1;
      canvas.drawCircle(
        center,
        base * (.20 + phase * .28),
        Paint()
          ..color = AppColors.sky.withValues(alpha: (1 - phase) * .16)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 18);
    final card = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: base * .62,
        height: base * .40,
      ),
      Radius.circular(base * .06),
    );
    final gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF4FC4F2), Color(0xFF1688C2)],
    );
    canvas.drawShadow(
      Path()..addRRect(card),
      Colors.black.withValues(alpha: dark ? .42 : .24),
      base * .035,
      true,
    );
    canvas.drawRRect(
      card,
      Paint()..shader = gradient.createShader(card.outerRect),
    );
    canvas.drawCircle(
      Offset(-base * .19, -base * .08),
      base * .045,
      Paint()..color = Colors.white.withValues(alpha: .86),
    );
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: .72)
      ..strokeWidth = base * .018
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(-base * .22, base * .08),
      Offset(base * .02, base * .08),
      linePaint,
    );
    canvas.drawLine(
      Offset(-base * .22, base * .14),
      Offset(base * .10, base * .14),
      linePaint,
    );
    final icLabel = TextPainter(
      text: TextSpan(
        text: 'IC',
        style: TextStyle(
          color: Colors.white.withValues(alpha: .9),
          fontSize: base * .060,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    icLabel.paint(canvas, Offset(base * .19, -base * .17));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CardArtPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.dark != dark;
}

class DetailLine extends StatelessWidget {
  const DetailLine({
    required this.label,
    required this.value,
    super.key,
    this.monospace = false,
  });

  final String label;
  final String value;
  final bool monospace;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontFamily: monospace ? 'monospace' : null,
            ),
          ),
        ),
      ],
    ),
  );
}

String formatDate(DateTime? date) {
  if (date == null) return '날짜 확인 불가';
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}.$month.$day';
}

String formatDateTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${formatDate(date)} $hour:$minute';
}

String yen(int value) => '¥${value.toString()}';

String hexByte(int value) =>
    value.toRadixString(16).padLeft(2, '0').toUpperCase();
