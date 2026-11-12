import 'package:flutter/material.dart';

import 'card_brand_icon_frame.dart';

/// Approved reference-based icon; detection is handled by the reader.
class HayakakenCardIcon extends StatelessWidget {
  const HayakakenCardIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CardBrandIconFrame(
      label: '하야카켄 카드',
      tileKey: const ValueKey('hayakaken-icon-tile'),
      backgroundColor: isDark
          ? const Color(0xFF273640)
          : const Color(0xFFE4F3FA),
      painter: _HayakakenCardPainter(isDark: isDark),
    );
  }
}

class _HayakakenCardPainter extends CardBrandIconPainter
    implements CardBrandBalanceFace {
  const _HayakakenCardPainter({required super.isDark});

  @override
  Color get outlineColor =>
      isDark ? const Color(0xFF90B5CF) : const Color(0xFF537F9F);

  @override
  void paintBalanceFace(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          10,
          size.height * 31 / 112,
          size.width - 10,
          size.height - 9,
        ),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF9DD9EB),
    );
    final center = Offset(size.width - 28, size.height * 82 / 112);
    canvas.drawCircle(center, 11.5, Paint()..color = cardColor);
    canvas.drawCircle(
      center,
      11.5,
      Paint()
        ..color = const Color(0xFF005DA8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  @override
  void paintFace(Canvas canvas) {
    // The user explicitly requested the same neutral gray as Suica, despite
    // the warm tint in the supplied capture. Keep the gray header visible.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(10, 31, 140, 71),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF9DD9EB),
    );

    // Replace the lower-right character with one plain blue-outlined circle.
    // No lettering, logos, hand, arrow or detailed character reconstruction.
    const center = Offset(132, 82);
    canvas.drawCircle(center, 13, Paint()..color = cardColor);
    canvas.drawCircle(
      center,
      13,
      Paint()
        ..color = const Color(0xFF005DA8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5,
    );
  }
}
