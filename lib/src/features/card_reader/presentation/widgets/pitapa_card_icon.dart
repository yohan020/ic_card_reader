import 'package:flutter/material.dart';

import 'card_brand_icon_frame.dart';

/// Basic-card design preview only. PiTaPa normal detection is not enabled.
class PitapaCardIcon extends StatelessWidget {
  const PitapaCardIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return CardBrandIconFrame(
      label: '피타파 카드',
      tileKey: const ValueKey('pitapa-icon-tile'),
      backgroundColor: dark ? const Color(0xFF302F43) : const Color(0xFFEEECF8),
      painter: _PitapaPainter(isDark: dark),
    );
  }
}

class _PitapaPainter extends CardBrandIconPainter {
  const _PitapaPainter({required super.isDark});

  @override
  Color get outlineColor =>
      isDark ? const Color(0xFFACA9CF) : const Color(0xFF7976A2);

  @override
  void paintFace(Canvas canvas) {
    // Basic card: lavender inset, broad pale arc from upper left, inner disk.
    // Only the broad geometric layout remains; no PiTaPa logotype or numbers.
    final panel = RRect.fromRectAndRadius(
      const Rect.fromLTWH(11, 11, 138, 90),
      const Radius.circular(7),
    );
    canvas.save();
    canvas.clipRRect(panel);
    canvas.drawRRect(panel, Paint()..color = const Color(0xFFC4C3E1));
    canvas.drawOval(
      const Rect.fromLTWH(-37, -10, 109, 98),
      Paint()..color = cardColor,
    );
    canvas.drawCircle(
      const Offset(36, 44),
      14,
      Paint()..color = const Color(0xFFC4C3E1),
    );
    canvas.restore();
  }
}
