import 'package:flutter/material.dart';

import 'card_brand_icon_frame.dart';

/// Approved user-requested front-facing bus; detection lives in the reader.
class PasmoCardIcon extends StatelessWidget {
  const PasmoCardIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CardBrandIconFrame(
      label: '파스모 카드',
      tileKey: const ValueKey('pasmo-icon-tile'),
      backgroundColor: isDark
          ? const Color(0xFF3C2934)
          : const Color(0xFFF9E6EF),
      painter: _PasmoCardPainter(isDark: isDark),
    );
  }
}

class _PasmoCardPainter extends CardBrandIconPainter
    implements CardBrandBalanceFace {
  const _PasmoCardPainter({required super.isDark});

  static const _pink = Color(0xFFE469A0);

  @override
  Color get outlineColor =>
      isDark ? const Color(0xFFC293AB) : const Color(0xFF93647B);

  @override
  void paintBalanceFace(Canvas canvas, Size size) {
    // Fit the whole bus (including mirrors/wheels) with a uniform scale.
    const scale = .88;
    canvas.save();
    canvas.translate(size.width / 2 - 80 * scale, size.height / 2 - 56 * scale);
    canvas.scale(scale);
    paintFace(canvas);
    canvas.restore();
  }

  @override
  void paintFace(Canvas canvas) {
    // Keep the supplied card's pink/silver palette. The user requested one
    // front-facing bus instead of the original stacked side-facing vehicles.
    // Mirrors, a broad windshield and two headlights remain legible when small.
    final pink = Paint()..color = _pink;
    final cutout = Paint()..color = cardColor;

    for (final x in [50.0, 97.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 85, 13, 14),
          const Radius.circular(3),
        ),
        pink,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(43, 15, 74, 78),
        const Radius.circular(12),
      ),
      pink,
    );
    for (final x in [33.0, 117.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 38, 10, 20),
          const Radius.circular(4),
        ),
        pink,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(51, 29, 58, 32),
        const Radius.circular(5),
      ),
      cutout,
    );
    for (final x in [57.0, 103.0]) {
      canvas.drawCircle(Offset(x, 77), 5, cutout);
    }
  }
}
