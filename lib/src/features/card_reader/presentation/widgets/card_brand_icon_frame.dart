import 'package:flutter/material.dart';

/// A shared default, not a claim that all real cards use identical gray ink.
/// Override the painter's cardColor when a reference is visibly different.
const cardBrandNeutralGray = Color(0xFFE7E7E7);

/// ISO ID-1 proportions, for the opt-in history balance illustration only.
const cardBrandRealAspectRatio = 85.60 / 53.98;
const cardBrandBalanceSize = Size(129, 129 / cardBrandRealAspectRatio);

/// A brand owns the composition of its real-ratio face. Full-bleed fields may
/// reflow, but foreground circles/vehicles must keep their own proportions.
abstract interface class CardBrandBalanceFace {
  void paintBalanceFace(Canvas canvas, Size size);
}

/// Opt-in display treatment for the history balance hero only. Compact icons
/// elsewhere keep their approved tile, dimensions and painter unchanged.
class CardBrandIconBalanceScope extends InheritedWidget {
  const CardBrandIconBalanceScope({required super.child, super.key});

  static bool isActive(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CardBrandIconBalanceScope>() !=
      null;

  @override
  bool updateShouldNotify(CardBrandIconBalanceScope oldWidget) => false;
}

class CardBrandIconFrame extends StatelessWidget {
  const CardBrandIconFrame({
    required this.label,
    required this.tileKey,
    required this.backgroundColor,
    required this.painter,
    super.key,
  });

  final String label;
  final Key tileKey;
  final Color backgroundColor;
  final CardBrandIconPainter painter;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    image: true,
    child: CardBrandIconBalanceScope.isActive(context)
        ? SizedBox.fromSize(
            size: cardBrandBalanceSize,
            child: CustomPaint(painter: CardBrandBalancePainter(painter)),
          )
        : SizedBox(
            width: 42,
            height: 42,
            child: DecoratedBox(
              key: tileKey,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: SizedBox(
                  width: 34,
                  height: 24,
                  child: CustomPaint(painter: painter),
                ),
              ),
            ),
          ),
  );
}

/// Keeps the approved card silhouette, scale and stroke consistent across brands.
abstract class CardBrandIconPainter extends CustomPainter {
  const CardBrandIconPainter({required this.isDark});

  final bool isDark;
  static const outlineWidth = 5.0;
  Color get cardColor => cardBrandNeutralGray;
  Color get outlineColor;
  void paintFace(Canvas canvas);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 160);
    canvas.translate(0, (size.height * 160 / size.width - 112) / 2);
    final card = RRect.fromRectAndRadius(
      const Rect.fromLTWH(2.5, 2.5, 155, 107),
      const Radius.circular(12),
    );
    canvas.drawRRect(card, Paint()..color = cardColor);
    paintFace(canvas);
    canvas.drawRRect(
      card,
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = outlineWidth,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CardBrandIconPainter oldDelegate) =>
      oldDelegate.runtimeType != runtimeType || oldDelegate.isDark != isDark;
}

/// The outline is shared; registered brands provide their own real-ratio face.
/// Clipping is only an edge guard for full-bleed fields, not a layout strategy.
class CardBrandBalancePainter extends CustomPainter {
  const CardBrandBalancePainter(this.delegate);

  final CardBrandIconPainter delegate;
  static const referenceSize = Size(160, 160 / cardBrandRealAspectRatio);
  static const outlineWidth = 4.5;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / referenceSize.width);
    final card = RRect.fromRectAndRadius(
      (Offset.zero & referenceSize).deflate(outlineWidth / 2),
      const Radius.circular(12),
    );
    canvas.drawRRect(card, Paint()..color = delegate.cardColor);
    canvas.save();
    canvas.clipRRect(card);
    if (delegate case final CardBrandBalanceFace face) {
      face.paintBalanceFace(canvas, referenceSize);
    } else {
      // Safe containment for an unregistered painter. Every active brand has
      // an explicit layout and tests require it; never crop legacy artwork.
      final scale = (referenceSize.height - 16) / 112;
      canvas.translate((referenceSize.width - 160 * scale) / 2, 8);
      canvas.scale(scale);
      delegate.paintFace(canvas);
    }
    canvas.restore();
    canvas.drawRRect(
      card,
      Paint()
        ..color = delegate.outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = outlineWidth,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CardBrandBalancePainter oldDelegate) =>
      oldDelegate.delegate.runtimeType != delegate.runtimeType ||
      delegate.shouldRepaint(oldDelegate.delegate);
}
