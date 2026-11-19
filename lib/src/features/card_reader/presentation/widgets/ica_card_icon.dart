import 'package:flutter/material.dart';

import 'card_brand_icon_frame.dart';

/// Approved ICa icon for successfully read ICa cards.
class IcaCardIcon extends StatelessWidget {
  const IcaCardIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CardBrandIconFrame(
      label: '아이카 카드',
      tileKey: const ValueKey('ica-icon-tile'),
      backgroundColor: isDark
          ? const Color(0xFF3C2A35)
          : const Color(0xFFFBEAF2),
      painter: _IcaCardPainter(isDark: isDark),
    );
  }
}

class _IcaCardPainter extends CardBrandIconPainter
    implements CardBrandBalanceFace {
  const _IcaCardPainter({required super.isDark});

  // The supplied iCa background is pink, not one of the neutral-gray cards.
  @override
  Color get cardColor => const Color(0xFFF7E7EE);

  @override
  Color get outlineColor =>
      isDark ? const Color(0xFFC99CB4) : const Color(0xFFA77B93);

  @override
  void paintBalanceFace(Canvas canvas, Size size) {
    // Rebuild the diagonal/rounded field inside the available height. Keep all
    // four white stripes and the outlined lower edge clear of the card rim.
    final panel = Path()
      ..moveTo(12, size.height - 10)
      ..lineTo(79, 23)
      ..cubicTo(102, 1, 135, 8, 146, 35)
      ..cubicTo(158, 66, 138, size.height - 14, 119, size.height - 10)
      ..close();
    canvas.drawPath(panel, Paint()..color = const Color(0xFFF1CDDE));
    final white = Paint()
      ..color = Colors.white
      ..strokeWidth = 4;
    canvas.save();
    canvas.clipPath(panel);
    for (final offset in [43.0, 34.0, 25.0, 16.0]) {
      final y = size.height - offset;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), white);
    }
    canvas.restore();
    canvas.drawPath(
      panel,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  void paintFace(Canvas canvas) {
    // Reference: a diagonal field rising from lower-left into a rounded upper-
    // right end, with horizontal white stripes below. Omit both ICa wordmarks.
    final panel = Path()
      ..moveTo(8, 104)
      ..lineTo(79, 25)
      ..cubicTo(103, -2, 138, 11, 149, 39)
      ..cubicTo(162, 74, 139, 100, 120, 104)
      ..close();
    canvas.drawPath(panel, Paint()..color = const Color(0xFFF1CDDE));

    // Four broad stripes replace the many thin lines at the 34dp icon scale.
    final white = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.5;
    canvas.save();
    canvas.clipPath(panel);
    for (final y in [66.0, 77.0, 88.0, 99.0]) {
      canvas.drawLine(Offset(0, y), Offset(160, y), white);
    }
    canvas.restore();
    canvas.drawPath(
      panel,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeJoin = StrokeJoin.round,
    );
  }
}
