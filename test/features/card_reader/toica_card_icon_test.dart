import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/card_brand_icon_frame.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/icoca_card_icon.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/pasmo_card_icon.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/suica_card_icon.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/toica_card_icon.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('TOICA icon preview ${dark ? 'dark' : 'light'}', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: Scaffold(
            body: Center(
              child: RepaintBoundary(
                key: const ValueKey('toica-icon-preview'),
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
                        child: const ToicaCardIcon(),
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
        find.byKey(const ValueKey('toica-icon-preview')),
        matchesGoldenFile(
          'goldens/toica_card_icon_${dark ? 'dark' : 'light'}.png',
        ),
      );
    });

    testWidgets('TOICA shares existing icon frame at large text ($dark)', (
      tester,
    ) async {
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
                  children: [
                    SuicaCardIcon(),
                    IcocaCardIcon(),
                    PasmoCardIcon(),
                    ToicaCardIcon(),
                  ],
                ),
              ),
            ),
          ),
        );
        expect(tester.getSize(find.byType(ToicaCardIcon)), const Size(42, 42));
        expect(find.bySemanticsLabel('토이카 카드'), findsOneWidget);
        final frames = tester.widgetList<CardBrandIconFrame>(
          find.byType(CardBrandIconFrame),
        );
        expect(frames.length, 4);
        expect(
          frames.map(
            (frame) => (frame.painter as CardBrandIconPainter).cardColor,
          ),
          everyElement(cardBrandNeutralGray),
        );
        final tile = tester.widget<DecoratedBox>(
          find.byKey(const ValueKey('toica-icon-tile')),
        );
        final decoration = tile.decoration as BoxDecoration;
        expect(decoration.borderRadius, BorderRadius.circular(13));
        expect(
          decoration.color,
          dark ? const Color(0xFF20383E) : const Color(0xFFDDF2F6),
        );
        expect(
          find.descendant(
            of: find.byType(ToicaCardIcon),
            matching: find.byType(Text),
          ),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }
}
