import 'package:flutter/material.dart';

import 'card_brand_icon_frame.dart';

/// Approved reference-based icon; detection is handled by the reader.
class ToicaCardIcon extends StatelessWidget {
  const ToicaCardIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CardBrandIconFrame(
      label: '토이카 카드',
      tileKey: const ValueKey('toica-icon-tile'),
      backgroundColor: isDark
          ? const Color(0xFF20383E)
          : const Color(0xFFDDF2F6),
      painter: _ToicaCardPainter(isDark: isDark),
    );
  }
}

class _ToicaCardPainter extends CardBrandIconPainter
    implements CardBrandBalanceFace {
  const _ToicaCardPainter({required super.isDark});

  static const _blue = Color(0xFF009FBD);

  @override
  Color get outlineColor =>
      isDark ? const Color(0xFF87B2BD) : const Color(0xFF467D89);

  @override
  void paintFace(Canvas canvas) {
    _paintWave(canvas);
    final blue = Paint()..color = _blue;
    // Enlarge the three tiny upper-left triangles just enough for icon scale.
    for (final x in [14.0, 24.0, 34.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(x, 23)
          ..lineTo(x + 9, 14)
          ..lineTo(x + 9, 23)
          ..close(),
        blue,
      );
    }
    _paintChick(canvas, const Offset(116, 54), const Size(25, 31));
    _paintChick(canvas, const Offset(144, 44), const Size(16, 20));
  }

  @override
  void paintBalanceFace(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(1, size.height / 112);
    _paintWave(canvas);
    canvas.restore();
    final y = size.height * 23 / 112;
    for (final x in [14.0, 24.0, 34.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(x, y)
          ..lineTo(x + 8, y - 8)
          ..lineTo(x + 8, y)
          ..close(),
        Paint()..color = _blue,
      );
    }
    final scale = size.height / 112;
    _paintChick(
      canvas,
      Offset(116, size.height * 54 / 112),
      Size(25 * scale, 31 * scale),
      beakScale: scale,
    );
    _paintChick(
      canvas,
      Offset(144, size.height * 44 / 112),
      Size(16 * scale, 20 * scale),
      beakScale: scale,
    );
  }

  void _paintWave(Canvas canvas) {
    // Reference: blue wave crests on the left, dips right of center, then rises
    // at the right edge. Keep its broad silhouette without lettering.
    final blue = Paint()..color = _blue;
    final wave = Path()
      ..moveTo(2.5, 69)
      ..cubicTo(45, 36, 55, 52, 76, 73)
      ..cubicTo(94, 94, 125, 77, 157.5, 57)
      ..lineTo(157.5, 97.5)
      ..quadraticBezierTo(157.5, 109.5, 145.5, 109.5)
      ..lineTo(14.5, 109.5)
      ..quadraticBezierTo(2.5, 109.5, 2.5, 97.5)
      ..close();
    canvas.drawPath(wave, blue);
  }

  void _paintChick(
    Canvas canvas,
    Offset center,
    Size size, {
    double beakScale = 1,
  }) {
    final left = center.dx - size.width / 2;
    final beakHalfHeight = size.height * 0.14;
    canvas.drawPath(
      Path()
        ..moveTo(left + 2 * beakScale, center.dy - beakHalfHeight)
        ..lineTo(left - 5 * beakScale, center.dy)
        ..lineTo(left + 2 * beakScale, center.dy + beakHalfHeight)
        ..close(),
      Paint()..color = const Color(0xFFF39A00),
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: size.width, height: size.height),
      Paint()..color = const Color(0xFFFFD600),
    );
  }
}
