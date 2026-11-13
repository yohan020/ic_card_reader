import 'package:flutter/material.dart';

import 'card_brand_icon_frame.dart';

/// User-approved, text/mascot-free card study, drawn at native resolution.
/// Represents the Suica family, not a confirmed physical card design.
class SuicaCardIcon extends StatelessWidget {
  const SuicaCardIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CardBrandIconFrame(
      label: '스이카 카드',
      tileKey: const ValueKey('suica-icon-tile'),
      backgroundColor: isDark
          ? const Color(0xFF26352C)
          : const Color(0xFFEAF3E1),
      painter: _SuicaCardPainter(isDark: isDark),
    );
  }
}

class _SuicaCardPainter extends CardBrandIconPainter
    implements CardBrandBalanceFace {
  const _SuicaCardPainter({required super.isDark});

  @override
  Color get outlineColor =>
      isDark ? const Color(0xFF91AB87) : const Color(0xFF58754C);

  @override
  void paintFace(Canvas canvas) {
    _paintPanel(canvas);
    final green = Paint()..color = const Color(0xFF70B627);
    canvas.drawCircle(const Offset(128, 23), 11, Paint()..color = Colors.black);
    canvas.drawCircle(const Offset(141, 23), 11, green);
  }

  @override
  void paintBalanceFace(Canvas canvas, Size size) {
    // Adapt only the broad panel; keep the overlapping symbols circular and
    // restore their top/right clearance on the shorter physical silhouette.
    canvas.save();
    canvas.scale(1, size.height / 112);
    _paintPanel(canvas);
    canvas.restore();
    final y = size.height * 23 / 112;
    canvas.drawCircle(
      Offset(size.width - 30, y),
      10,
      Paint()..color = Colors.black,
    );
    canvas.drawCircle(
      Offset(size.width - 18, y),
      10,
      Paint()..color = const Color(0xFF70B627),
    );
  }

  void _paintPanel(Canvas canvas) {
    final green = Paint()..color = const Color(0xFF70B627);
    final panel = Path()
      ..moveTo(17, 10)
      ..lineTo(62, 10)
      ..quadraticBezierTo(68, 10, 70, 16)
      ..lineTo(101, 94)
      ..quadraticBezierTo(104, 102, 96, 102)
      ..lineTo(17, 102)
      ..quadraticBezierTo(10, 102, 10, 95)
      ..lineTo(10, 17)
      ..quadraticBezierTo(10, 10, 17, 10)
      ..close();
    canvas.drawPath(panel, green);
  }
}
