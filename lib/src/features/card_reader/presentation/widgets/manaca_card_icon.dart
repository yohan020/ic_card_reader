import 'package:flutter/material.dart';

import 'card_brand_icon_frame.dart';

/// Approved manaca icon; no lettering or mascot facial details.
class ManacaCardIcon extends StatelessWidget {
  const ManacaCardIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return CardBrandIconFrame(
      label: '마나카 카드',
      tileKey: const ValueKey('manaca-icon-tile'),
      backgroundColor: dark ? const Color(0xFF3C3725) : const Color(0xFFFFF5D3),
      painter: _ManacaPainter(isDark: dark),
    );
  }
}

class _ManacaPainter extends CardBrandIconPainter
    implements CardBrandBalanceFace {
  const _ManacaPainter({required super.isDark});

  @override
  Color get outlineColor =>
      isDark ? const Color(0xFFC5B479) : const Color(0xFF9A8443);

  @override
  void paintBalanceFace(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.height * .375,
      Paint()..color = const Color(0xFFFFDF00),
    );
  }

  @override
  void paintFace(Canvas canvas) {
    // Official regular card: centered yellow disk on neutral gray.
    canvas.drawCircle(
      const Offset(80, 56),
      42,
      Paint()..color = const Color(0xFFFFDF00),
    );
  }
}
