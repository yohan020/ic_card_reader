import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/card_brand_icon_frame.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/icoca_card_icon.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/suica_card_icon.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('ICOCA icon preview ${dark ? 'dark' : 'light'}', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: Scaffold(
            body: Center(
              child: RepaintBoundary(
                key: const ValueKey('icoca-icon-preview'),
                child: ColoredBox(
                  color: dark
                      ? AppTheme.dark.scaffoldBackgroundColor
                      : AppTheme.light.scaffoldBackgroundColor,
                  child: SizedBox(
                    width: 184,
                    height: 184,
                    child: Center(
                      child: Transform.scale(
                        scale: 4,
                        child: const IcocaCardIcon(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await expectLater(
        find.byKey(const ValueKey('icoca-icon-preview')),
        matchesGoldenFile(
          'goldens/icoca_card_icon_${dark ? 'dark' : 'light'}.png',
        ),
      );
    });

    testWidgets('ICOCA shares Suica frame and neutral gray ($dark)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: const Scaffold(
            body: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [SuicaCardIcon(), IcocaCardIcon()],
              ),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(IcocaCardIcon)), const Size(42, 42));
      expect(tester.getSize(find.byType(SuicaCardIcon)), const Size(42, 42));
      final frames = tester
          .widgetList<CardBrandIconFrame>(find.byType(CardBrandIconFrame))
          .toList();
      final painters = frames
          .map((frame) => frame.painter as CardBrandIconPainter)
          .toList();
      expect(
        painters.map((painter) => painter.cardColor),
        everyElement(cardBrandNeutralGray),
      );
      for (final key in ['suica-icon-tile', 'icoca-icon-tile']) {
        final tile = tester.widget<DecoratedBox>(find.byKey(ValueKey(key)));
        expect(
          (tile.decoration as BoxDecoration).borderRadius,
          BorderRadius.circular(13),
        );
      }
      expect(find.text('ICOCA'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
