import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/card_brand_icon_frame.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/ica_card_icon.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/suica_card_icon.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('iCa icon preview ${dark ? 'dark' : 'light'}', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: Scaffold(
            body: Center(
              child: RepaintBoundary(
                key: const ValueKey('ica-icon-preview'),
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
                        child: const IcaCardIcon(),
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
        find.byKey(const ValueKey('ica-icon-preview')),
        matchesGoldenFile(
          'goldens/ica_card_icon_${dark ? 'dark' : 'light'}.png',
        ),
      );
    });

    testWidgets(
      'iCa keeps the frame but its reference pink at large text ($dark)',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.7)),
                child: child!,
              ),
              home: const Scaffold(
                body: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [SuicaCardIcon(), IcaCardIcon()],
                  ),
                ),
              ),
            ),
          );
          expect(tester.getSize(find.byType(IcaCardIcon)), const Size(42, 42));
          expect(find.bySemanticsLabel('아이카 카드'), findsOneWidget);
          final frames = tester
              .widgetList<CardBrandIconFrame>(find.byType(CardBrandIconFrame))
              .toList();
          expect(frames.length, 2);
          expect(
            (frames.first.painter as CardBrandIconPainter).cardColor,
            cardBrandNeutralGray,
          );
          expect(
            (frames.last.painter as CardBrandIconPainter).cardColor,
            const Color(0xFFF7E7EE),
          );
          final tile = tester.widget<DecoratedBox>(
            find.byKey(const ValueKey('ica-icon-tile')),
          );
          final decoration = tile.decoration as BoxDecoration;
          expect(decoration.borderRadius, BorderRadius.circular(13));
          expect(
            decoration.color,
            dark ? const Color(0xFF3C2A35) : const Color(0xFFFBEAF2),
          );
          expect(
            find.descendant(
              of: find.byType(IcaCardIcon),
              matching: find.byType(Text),
            ),
            findsNothing,
          );
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );
  }
}
