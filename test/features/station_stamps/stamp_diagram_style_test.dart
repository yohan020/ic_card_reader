import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/station_stamps/domain/stamp_book_catalog.dart';
import 'package:ic_card_reader/src/features/station_stamps/presentation/stamp_book_style.dart';
import 'package:ic_card_reader/src/features/station_stamps/presentation/yamanote_stamp_map.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_name_display.dart';
import 'stamp_test_support.dart' show app;

const preview = bool.fromEnvironment('STAMP_PREVIEW');
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (!preview) {
      return;
    }
    for (final font in {
      'Preview': 'C:/Windows/Fonts/malgun.ttf',
      'PreviewLatin': 'C:/Windows/Fonts/arial.ttf',
      'PreviewJapanese': 'C:/Windows/Fonts/YuGothM.ttc',
    }.entries) {
      await (FontLoader(font.key)..addFont(
            Future.value(
              ByteData.sublistView(await File(font.value).readAsBytes()),
            ),
          ))
          .load();
    }
  });
  test(
    '39 names stay close without label or station-dot overlap in every language mode',
    () {
      for (final mode in StationNameDisplayMode.values) {
        for (final scale in [1.0, 2.0]) {
          final canvas = Size(2800 * scale, 1000 * scale);
          final points = projectChuoSobu(canvas);
          final labels = chuoSobuBookLine.stations
              .map(
                (s) =>
                    TextPainter(
                      text: TextSpan(
                        text: stampStationName(s, mode),
                        style: TextStyle(
                          fontFamily: preview ? 'Preview' : 'Ahem',
                          fontFamilyFallback: const [
                            'PreviewJapanese',
                            'PreviewLatin',
                          ],
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      textDirection: TextDirection.ltr,
                      textScaler: TextScaler.linear(scale),
                    )..layout(
                      maxWidth: mode == StationNameDisplayMode.japaneseEnglish
                          ? 180
                          : 120,
                    ),
              )
              .toList();
          final rects = layoutChuoSobuLabels(
            points,
            labels.map((t) => t.size).toList(),
            canvas,
          );
          expect(rects.length, 39);
          for (var i = 0; i < rects.length; i++) {
            final r = rects[i], p = points[i];
            final dx = math.max(math.max(r.left - p.dx, p.dx - r.right), 0.0),
                dy = math.max(math.max(r.top - p.dy, p.dy - r.bottom), 0.0);
            expect(
              math.sqrt(dx * dx + dy * dy),
              lessThanOrEqualTo(50.01),
              reason: '$mode/$scale/${chuoSobuBookLine.stations[i].japanese}',
            );
            expect(
              r.left >= 0 &&
                  r.right <= canvas.width &&
                  r.top >= 0 &&
                  r.bottom <= canvas.height,
              true,
            );
            for (var j = 0; j < rects.length; j++) {
              if (i != j) {
                expect(
                  r.overlaps(rects[j]),
                  false,
                  reason: '$mode/$scale labels $i/$j',
                );
              }
              expect(
                r.overlaps(Rect.fromCircle(center: points[j], radius: 7)),
                false,
                reason: '$mode/$scale label $i / station $j',
              );
            }
          }
          for (final label in labels) {
            label.dispose();
          }
        }
      }
    },
  );

  for (final dark in [false, true]) {
    testWidgets('route hues render without path casing dark=$dark', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(const Scaffold(body: SizedBox()), dark: dark),
      );
      final colors = StampBookColors(tester.element(find.byType(Scaffold)));
      final l1 = colors.ink.computeLuminance(),
          l2 = colors.paper.computeLuminance();
      expect(
        (math.max(l1, l2) + .05) / (math.min(l1, l2) + .05),
        greaterThanOrEqualTo(4.5),
      );
      for (final chuo in [false, true]) {
        final painter = YamanoteStampMapPainter(
          collected: const {},
          mode: StationNameDisplayMode.english,
          selected: 0,
          colors: colors,
          textScaler: TextScaler.noScaling,
          textStyle: const TextStyle(),
          chuoSobu: chuo,
        );
        expect(
          painter.routeColor,
          chuo ? StampBookRouteColors.chuoSobu : StampBookRouteColors.yamanote,
        );
        await tester.runAsync(() async {
          final recorder = ui.PictureRecorder(), canvas = Canvas(recorder);
          final size = chuo ? const Size(2800, 1000) : const Size(640, 910);
          expect(
            (Canvas c) => painter.paint(c, size),
            paintsExactlyCountTimes(#drawPath, 1),
            reason: 'one route stroke, without a second outline stroke',
          );
          canvas.drawRect(Offset.zero & size, Paint()..color = colors.paper);
          painter.paint(canvas, size);
          final picture = recorder.endRecording();
          final image = await picture.toImage(
            size.width.toInt(),
            size.height.toInt(),
          );
          final bytes = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          final color = painter.routeColor;
          var pixels = 0;
          for (var i = 0; i < bytes!.lengthInBytes; i += 4) {
            if (bytes.getUint8(i) == (color.r * 255).round() &&
                bytes.getUint8(i + 1) == (color.g * 255).round() &&
                bytes.getUint8(i + 2) == (color.b * 255).round()) {
              pixels++;
            }
          }
          expect(
            pixels,
            greaterThan(100),
            reason: 'rendered route hue, not only a constant',
          );
          image.dispose();
          picture.dispose();
        });
      }
      expect(tester.takeException(), isNull);
    });
  }
}
