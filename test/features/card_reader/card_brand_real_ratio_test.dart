import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_brand_identity.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/card_brand_icon.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/card_brand_icon_frame.dart';

void main() {
  test(
    'balance silhouette matches ID-1; stroke is only ten percent thinner',
    () {
      expect(cardBrandBalanceSize.width, 129);
      expect(cardBrandBalanceSize.height, closeTo(81.3484, .0001));
      expect(cardBrandBalanceSize.aspectRatio, closeTo(85.60 / 53.98, .000001));
      expect(
        CardBrandBalancePainter.referenceSize.aspectRatio,
        closeTo(85.60 / 53.98, .000001),
      );
      expect(
        CardBrandBalancePainter.outlineWidth /
            CardBrandIconPainter.outlineWidth,
        closeTo(.9, .000001),
      );
    },
  );

  for (final dark in [false, true]) {
    testWidgets('all ten balance brands use real silhouette dark=$dark', (
      tester,
    ) async {
      for (final brand in CardBrandIdentity.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: Scaffold(
              body: Center(
                child: CardBrandIcon(identity: brand, prominent: true),
              ),
            ),
          ),
        );
        final icon = find.byType(CardBrandIcon);
        expect(tester.getSize(icon), cardBrandBalanceSize);
        final paint = tester.widget<CustomPaint>(
          find.descendant(of: icon, matching: find.byType(CustomPaint)),
        );
        expect(paint.painter, isA<CardBrandBalancePainter>());
        expect(
          (paint.painter! as CardBrandBalancePainter).delegate,
          isA<CardBrandBalanceFace>(),
        );
        expect(
          find.descendant(of: icon, matching: find.byType(DecoratedBox)),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      }
      {
        tester.view.physicalSize = const Size(760, 260);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: RepaintBoundary(
              key: const ValueKey('brand-ratio-sheet'),
              child: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 710,
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        for (final brand in CardBrandIdentity.values)
                          CardBrandIcon(identity: brand, prominent: true),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byKey(const ValueKey('brand-ratio-sheet')),
          matchesGoldenFile(
            'goldens/card_brand_balance_composition_${dark ? 'dark' : 'light'}.png',
          ),
        );
        if (!const bool.fromEnvironment('HISTORY_BALANCE_VISUAL_PREVIEW')) {
          return;
        }
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('brand-ratio-sheet')),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          try {
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            final directory = Directory('.dart_tool/history_balance_preview');
            await directory.create(recursive: true);
            await File(
              '${directory.path}/brands_real_ratio_${dark ? 'dark' : 'light'}.png',
            ).writeAsBytes(data!.buffer.asUint8List());
          } finally {
            image.dispose();
          }
        });
      }
    });
  }

  testWidgets('real silhouette keeps face circles uniformly scaled', (
    tester,
  ) async {
    final probe = _ProbePainter();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox.fromSize(
              size: cardBrandBalanceSize,
              child: CustomPaint(painter: CardBrandBalancePainter(probe)),
            ),
          ),
        ),
      ),
    );
    expect(probe.scaleX, closeTo(129 / 160, .000001));
    expect(probe.scaleY, closeTo(probe.scaleX!, .000001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact card keeps old silhouette and painter unchanged', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Center(
            child: CardBrandIcon(identity: CardBrandIdentity.nimoca),
          ),
        ),
      ),
    );
    final icon = find.byType(CardBrandIcon);
    final paint = tester.widget<CustomPaint>(
      find.descendant(of: icon, matching: find.byType(CustomPaint)),
    );
    expect(tester.getSize(icon), const Size(42, 42));
    expect(
      tester.getSize(
        find.descendant(of: icon, matching: find.byType(CustomPaint)),
      ),
      const Size(34, 24),
    );
    expect(paint.painter, isA<CardBrandIconPainter>());
    expect(paint.painter, isNot(isA<CardBrandBalancePainter>()));
    expect(find.byKey(const ValueKey('nimoca-icon-tile')), findsOneWidget);
  });

  testWidgets(
    'brand-specific margins and circles survive the real-ratio face',
    (tester) async {
      for (final (brand, color) in [
        (CardBrandIdentity.suicaFamily, const Color(0xFF70B627)),
        (CardBrandIdentity.nimoca, const Color(0xFF00ACC8)),
        (CardBrandIdentity.manaca, const Color(0xFFFFDF00)),
        (CardBrandIdentity.ica, Colors.white),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: Center(
                child: CardBrandIcon(identity: brand, prominent: true),
              ),
            ),
          ),
        );
        final icon = find.byType(CardBrandIcon);
        final paint = tester.widget<CustomPaint>(
          find.descendant(of: icon, matching: find.byType(CustomPaint)),
        );
        final bounds = await tester.runAsync(
          () => _colorBounds(paint.painter!, color),
        );
        expect(bounds, isNotNull);
        if (brand == CardBrandIdentity.nimoca ||
            brand == CardBrandIdentity.manaca) {
          expect(bounds!.width, closeTo(bounds.height, 1));
          expect(bounds.top, greaterThanOrEqualTo(11));
          expect(
            bounds.bottom,
            lessThanOrEqualTo(
              CardBrandBalancePainter.referenceSize.height - 10,
            ),
          );
        } else if (brand == CardBrandIdentity.suicaFamily) {
          expect(bounds!.top, greaterThanOrEqualTo(8));
          expect(
            bounds.bottom,
            lessThanOrEqualTo(CardBrandBalancePainter.referenceSize.height - 7),
          );
        } else {
          expect(
            bounds!.bottom,
            lessThanOrEqualTo(CardBrandBalancePainter.referenceSize.height - 7),
          );
        }
      }
    },
  );
}

Future<Rect> _colorBounds(CustomPainter painter, Color color) async {
  const width = 160;
  const height = 101;
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), CardBrandBalancePainter.referenceSize);
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final bytes = data!.buffer.asUint8List();
    final argb = color.toARGB32();
    var left = width;
    var top = height;
    var right = -1;
    var bottom = -1;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final offset = (y * width + x) * 4;
        if (bytes[offset] == ((argb >> 16) & 255) &&
            bytes[offset + 1] == ((argb >> 8) & 255) &&
            bytes[offset + 2] == (argb & 255) &&
            bytes[offset + 3] == 255) {
          if (x < left) left = x;
          if (y < top) top = y;
          if (x > right) right = x;
          if (y > bottom) bottom = y;
        }
      }
    }
    expect(right, greaterThanOrEqualTo(left));
    return Rect.fromLTRB(
      left.toDouble(),
      top.toDouble(),
      right + 1.0,
      bottom + 1.0,
    );
  } finally {
    image.dispose();
    picture.dispose();
  }
}

class _ProbePainter extends CardBrandIconPainter
    implements CardBrandBalanceFace {
  _ProbePainter() : super(isDark: false);

  double? scaleX;
  double? scaleY;

  @override
  Color get outlineColor => Colors.black;

  @override
  void paintBalanceFace(Canvas canvas, Size size) => paintFace(canvas);

  @override
  void paintFace(Canvas canvas) {
    final transform = canvas.getTransform();
    scaleX = transform[0];
    scaleY = transform[5];
    canvas.drawCircle(const Offset(80, 56), 12, Paint()..color = Colors.blue);
  }
}
