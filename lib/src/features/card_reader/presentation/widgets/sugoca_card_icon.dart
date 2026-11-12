import 'package:flutter/material.dart';

import 'card_brand_icon_frame.dart';

/// Regular SUGOCA color layout, not the special pink illustrated edition.
class SugocaCardIcon extends StatelessWidget {
  const SugocaCardIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return CardBrandIconFrame(
      label: '스고카 카드',
      tileKey: const ValueKey('sugoca-icon-tile'),
      backgroundColor: dark ? const Color(0xFF3B3035) : const Color(0xFFF8E8EE),
      painter: _SugocaPainter(isDark: dark),
    );
  }
}

class _SugocaPainter extends CardBrandIconPainter
    implements CardBrandBalanceFace {
  const _SugocaPainter({required super.isDark});

  @override
  Color get cardColor => const Color(0xFFFFFFE9);

  @override
  Color get outlineColor =>
      isDark ? const Color(0xFFBDBDA4) : const Color(0xFF898C70);

  @override
  void paintFace(Canvas canvas) {
    _paintCurve(canvas);
    // The small lower-right pink mark is a plain lozenge, not a copied logo.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(116, 85, 30, 14),
        const Radius.circular(7),
      ),
      Paint()..color = const Color(0xFFF36B9B),
    );
  }

  @override
  void paintBalanceFace(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(1, size.height / 112);
    _paintCurve(canvas);
    canvas.restore();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 44, size.height - 26, 28, 12),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFFF36B9B),
    );
  }

  void _paintCurve(Canvas canvas) {
    // Retain the large right-hand olive curve, omit frog/clock and lettering.
    canvas.drawPath(
      Path()
        ..moveTo(117, 2.5)
        ..lineTo(145.5, 2.5)
        ..quadraticBezierTo(157.5, 2.5, 157.5, 14.5)
        ..lineTo(157.5, 97.5)
        ..quadraticBezierTo(157.5, 109.5, 145.5, 109.5)
        ..lineTo(117, 109.5)
        ..cubicTo(78, 88, 78, 25, 117, 2.5)
        ..close(),
      Paint()..color = const Color(0xFFC6C7AF),
    );
  }
}
