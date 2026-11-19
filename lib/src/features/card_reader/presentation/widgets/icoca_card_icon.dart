import 'package:flutter/material.dart';

import 'card_brand_icon_frame.dart';

/// Approved reference-matched icon; detection is handled by the reader.
class IcocaCardIcon extends StatelessWidget {
  const IcocaCardIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CardBrandIconFrame(
      label: '이코카 카드',
      tileKey: const ValueKey('icoca-icon-tile'),
      backgroundColor: isDark
          ? const Color(0xFF23373D)
          : const Color(0xFFE0F3F7),
      painter: _IcocaCardPainter(isDark: isDark),
    );
  }
}

class _IcocaCardPainter extends CardBrandIconPainter
    implements CardBrandBalanceFace {
  const _IcocaCardPainter({required super.isDark});

  @override
  Color get outlineColor =>
      isDark ? const Color(0xFF86ABB5) : const Color(0xFF437B89);

  @override
  void paintBalanceFace(Canvas canvas, Size size) {
    // This face consists only of a field: preserve both gray corner cutouts
    // and the original inset proportions instead of cropping the top/bottom.
    canvas.save();
    canvas.scale(1, size.height / 112);
    paintFace(canvas);
    canvas.restore();
  }

  @override
  void paintFace(Canvas canvas) {
    // Supplied reference: cyan field, gray top-left and bottom-right corners.
    // Lettering, mascot, arrow and physical notch are intentionally omitted.
    final panel = Path()
      ..moveTo(49, 10)
      ..lineTo(143, 10)
      ..quadraticBezierTo(150, 10, 150, 17)
      ..lineTo(150, 75)
      ..quadraticBezierTo(150, 78, 147, 81)
      ..lineTo(128, 99)
      ..quadraticBezierTo(125, 102, 121, 102)
      ..lineTo(17, 102)
      ..quadraticBezierTo(10, 102, 10, 95)
      ..lineTo(10, 51)
      ..quadraticBezierTo(10, 48, 13, 45)
      ..lineTo(42, 14)
      ..quadraticBezierTo(46, 10, 49, 10)
      ..close();
    canvas.drawPath(panel, Paint()..color = const Color(0xFF3FBDD7));
  }
}
