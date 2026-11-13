import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/card_brand_icon_frame.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/kitaca_card_icon.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/manaca_card_icon.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/sugoca_card_icon.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/pitapa_card_icon.dart';

const _brands = [
  (id: 'kitaca', label: '키타카', icon: KitacaCardIcon()),
  (id: 'manaca', label: '마나카', icon: ManacaCardIcon()),
  (id: 'sugoca', label: '스고카', icon: SugocaCardIcon()),
  (id: 'pitapa', label: '피타파', icon: PitapaCardIcon()),
];

void main() {
  for (final dark in [false, true]) {
    for (final brand in _brands) {
      testWidgets('${brand.id} common frame and visual dark=$dark', (
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
              home: Scaffold(
                body: Center(
                  child: RepaintBoundary(
                    key: const ValueKey('preview'),
                    child: ColoredBox(
                      color: dark
                          ? AppTheme.dark.scaffoldBackgroundColor
                          : AppTheme.light.scaffoldBackgroundColor,
                      child: SizedBox(
                        width: 184,
                        height: 184,
                        child: Center(
                          child: Transform.scale(scale: 4, child: brand.icon),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          expect(tester.getSize(find.byWidget(brand.icon)), const Size(42, 42));
          expect(find.bySemanticsLabel('${brand.label} 카드'), findsOneWidget);
          expect(find.byType(Text), findsNothing);
          final frame = tester.widget<CardBrandIconFrame>(
            find.byType(CardBrandIconFrame),
          );
          final painter = frame.painter as CardBrandIconPainter;
          expect(
            painter.cardColor,
            brand.id == 'sugoca'
                ? const Color(0xFFFFFFE9)
                : cardBrandNeutralGray,
          );
          expect(painter.isDark, dark);
          final tile = tester.widget<DecoratedBox>(
            find.byKey(ValueKey('${brand.id}-icon-tile')),
          );
          expect(
            (tile.decoration as BoxDecoration).borderRadius,
            BorderRadius.circular(13),
          );
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('preview')),
            matchesGoldenFile(
              'goldens/${brand.id}_card_icon_${dark ? 'dark' : 'light'}.png',
            ),
          );
        } finally {
          semantics.dispose();
        }
      });
    }
  }

  // Optional local contact sheet from the actual Flutter painters, not shipped.
  const preview = bool.fromEnvironment('CARD_ICONS_VISUAL_PREVIEW');
  if (preview) {
    testWidgets('render remaining icon contact sheet', (tester) async {
      await tester.runAsync(() async {
        final loader = FontLoader('CardPreview')
          ..addFont(
            Future.value(
              ByteData.sublistView(
                await File('C:/Windows/Fonts/malgun.ttf').readAsBytes(),
              ),
            ),
          );
        await loader.load();
      });
      tester.view.physicalSize = const Size(736, 460);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: const ValueKey('sheet'),
              child: Column(
                children: [
                  for (final dark in [false, true])
                    Theme(
                      data: dark ? AppTheme.dark : AppTheme.light,
                      child: ColoredBox(
                        color: dark
                            ? AppTheme.dark.scaffoldBackgroundColor
                            : AppTheme.light.scaffoldBackgroundColor,
                        child: SizedBox(
                          height: 230,
                          child: Row(
                            children: [
                              for (final brand in _brands)
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        height: 132,
                                        child: Center(
                                          child: Transform.scale(
                                            scale: 3,
                                            child: brand.icon,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        brand.label,
                                        style: TextStyle(
                                          fontFamily: 'CardPreview',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: dark
                                              ? const Color(0xFFE2E8EF)
                                              : const Color(0xFF1C2830),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      brand.icon,
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('sheet')),
      );
      await tester.runAsync(() async {
        final rendered = await boundary.toImage(pixelRatio: 1.5);
        try {
          final bytes = await rendered.toByteData(
            format: ui.ImageByteFormat.png,
          );
          final dir = Directory('.dart_tool/card_icon_preview');
          await dir.create(recursive: true);
          await File(
            '${dir.path}/remaining_card_icons.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
        } finally {
          rendered.dispose();
        }
      });
    });
  }
}
