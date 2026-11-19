import 'package:flutter/material.dart';

import 'card_brand_icon_frame.dart';

/// Approved reference-based icon; detection is handled by the reader.
class NimocaCardIcon extends StatelessWidget {
  const NimocaCardIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CardBrandIconFrame(
      label: '니모카 카드',
      tileKey: const ValueKey('nimoca-icon-tile'),
      backgroundColor: isDark
          ? const Color(0xFF21383D)
          : const Color(0xFFDFF3F5),
      painter: _NimocaCardPainter(isDark: isDark),
    );
  }
}

class _NimocaCardPainter extends CardBrandIconPainter
    implements CardBrandBalanceFace {
  const _NimocaCardPainter({required super.isDark});

  @override
  Color get outlineColor =>
      isDark ? const Color(0xFF8AB1B9) : const Color(0xFF497F89);

  @override
  void paintFace(Canvas canvas) {
    // Reference: a large cyan circle to the left and a small yellow form right.
    // No lettering, star, arrow, face, ears or detailed mascot reconstruction.
    canvas.drawCircle(
      const Offset(64, 56),
      42,
      Paint()..color = const Color(0xFF00ACC8),
    );

    _paintAccent(canvas);
  }

  @override
  void paintBalanceFace(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width * .4, size.height / 2),
      size.height * .375,
      Paint()..color = const Color(0xFF00ACC8),
    );
    const scale = .88;
    canvas.save();
    canvas.translate(
      size.width - 30 - 129 * scale,
      size.height * .59 - 64 * scale,
    );
    canvas.scale(scale);
    _paintAccent(canvas);
    canvas.restore();
  }

  void _paintAccent(Canvas canvas) {
    final yellow = Paint()..color = const Color(0xFFF2D550);
    canvas.drawPath(
      Path()
        ..moveTo(129, 81)
        ..quadraticBezierTo(142, 86, 146, 73)
        ..quadraticBezierTo(153, 94, 130, 93)
        ..close(),
      yellow,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(122, 49, 14, 42),
        const Radius.circular(7),
      ),
      yellow,
    );
    final arm = Paint()
      ..color = yellow.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(125, 60), const Offset(117, 55), arm);
    canvas.drawLine(const Offset(134, 61), const Offset(141, 69), arm);
    canvas.drawCircle(const Offset(129, 43), 8, yellow);
  }
}
