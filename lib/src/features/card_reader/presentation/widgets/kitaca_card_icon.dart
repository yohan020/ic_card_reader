import 'package:flutter/material.dart';

import 'card_brand_icon_frame.dart';

/// Approved Kitaca icon; a display hint, not proof of a card product variant.
class KitacaCardIcon extends StatelessWidget {
  const KitacaCardIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return CardBrandIconFrame(
      label: '키타카 카드',
      tileKey: const ValueKey('kitaca-icon-tile'),
      backgroundColor: dark ? const Color(0xFF32372B) : const Color(0xFFF0F4DD),
      painter: _KitacaPainter(isDark: dark),
    );
  }
}

class _KitacaPainter extends CardBrandIconPainter
    implements CardBrandBalanceFace {
  const _KitacaPainter({required super.isDark});

  @override
  Color get outlineColor =>
      isDark ? const Color(0xFFB4BD84) : const Color(0xFF7D8956);

  @override
  void paintFace(Canvas canvas) {
    _paintBand(canvas);
    // A single lime accent replaces the tiny lower-right certification mark.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(126, 82, 17, 17),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFA6CE39),
    );
  }

  @override
  void paintBalanceFace(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(1, size.height / 112);
    _paintBand(canvas);
    canvas.restore();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 34, size.height - 28, 16, 16),
        const Radius.circular(3.5),
      ),
      Paint()..color = const Color(0xFFA6CE39),
    );
  }

  void _paintBand(Canvas canvas) {
    // Official regular card: gray upper area, pale lime irregular lower band.
    // Smooth the fine forest texture; omit lettering and the flying squirrel.
    final band = Path()
      ..moveTo(2.5, 73)
      ..quadraticBezierTo(25, 61, 44, 72)
      ..quadraticBezierTo(66, 80, 85, 68)
      ..quadraticBezierTo(109, 57, 130, 69)
      ..quadraticBezierTo(145, 77, 157.5, 66)
      ..lineTo(157.5, 97.5)
      ..quadraticBezierTo(157.5, 109.5, 145.5, 109.5)
      ..lineTo(14.5, 109.5)
      ..quadraticBezierTo(2.5, 109.5, 2.5, 97.5)
      ..close();
    canvas.drawPath(band, Paint()..color = const Color(0xFFEAF0BC));
  }
}
