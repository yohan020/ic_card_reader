import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/station_stamps/domain/station_stamp_session.dart';
import 'package:ic_card_reader/src/features/station_stamps/domain/stamp_book_catalog.dart';
import 'package:ic_card_reader/src/features/station_stamps/presentation/stamp_book_page.dart';
import 'package:ic_card_reader/src/features/station_stamps/presentation/yamanote_stamp_map.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_name_display.dart';
import 'stamp_test_support.dart' show app;

const preview = bool.fromEnvironment('STAMP_PREVIEW');

Future<void> capture(WidgetTester tester, String name) async {
  final images = tester.widgetList<Image>(find.byType(Image)).toList();
  final context = tester.element(find.byType(Scaffold).last);
  await tester.runAsync(
    () =>
        Future.wait(images.map((image) => precacheImage(image.image, context))),
  );
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('stamp-preview')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final output = Directory('docs/design/stamp-book-chuo-sobu-2026-11-17');
    await output.create(recursive: true);
    await File(
      '${output.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    if (!preview) return;
    for (final font in {
      'Preview': 'C:/Windows/Fonts/malgun.ttf',
      'PreviewLatin': 'C:/Windows/Fonts/arial.ttf',
      'PreviewJapanese': 'C:/Windows/Fonts/YuGothM.ttc',
      'MaterialIcons':
          'C:/Users/yohan/Desktop/project/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(font.key)..addFont(
            Future.value(
              ByteData.sublistView(await File(font.value).readAsBytes()),
            ),
          ))
          .load();
    }
  });
  void size(WidgetTester tester, Size value) {
    tester.view.physicalSize = value;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  for (final line in stampBookLines) {
    for (final english in [false, true]) {
      for (final dark in [false, true]) {
        testWidgets(
          '${line.id} station bottom sheet selection/cancel/help en=$english dark=$dark',
          (tester) async {
            size(tester, const Size(375, 812));
            final session = StationStampSession()
              ..collect([line.stations.first.id]);
            addTearDown(session.dispose);
            await tester.pumpWidget(
              app(
                StampBookLinePage(session: session, line: line),
                language: english ? 'en' : 'ko',
                dark: dark,
                mode: english
                    ? StationNameDisplayMode.english
                    : StationNameDisplayMode.korean,
              ),
            );
            await tester.tap(find.byKey(const ValueKey('stamp-book-tab-map')));
            await tester.pumpAndSettle();
            final picker = find.byKey(
              const ValueKey('stamp-book-station-picker'),
            );
            await tester.scrollUntilVisible(
              picker,
              200,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.pumpAndSettle();
            expect(
              find.byIcon(Icons.center_focus_strong_outlined),
              findsOneWidget,
            );
            expect(find.byIcon(Icons.fit_screen_rounded), findsNothing);
            expect(find.byType(DropdownButtonFormField<int>), findsNothing);
            expect(find.textContaining('These original app'), findsNothing);
            expect(find.textContaining('역 좌표를 연결한 도식이며'), findsNothing);
            await tester.tap(picker);
            await tester.pumpAndSettle();
            final sheet = find.byKey(
              const ValueKey('stamp-book-station-sheet'),
            );
            expect(sheet, findsOneWidget);
            for (var i = 0; i < line.stations.length; i++) {
              final option = find.byKey(
                ValueKey('stamp-book-station-option-$i'),
              );
              expect(option, findsOneWidget);
              expect(tester.getSize(option).height, greaterThanOrEqualTo(56));
            }
            expect(
              find.descendant(
                of: sheet,
                matching: find.text(english ? 'Collected' : '수집 완료'),
              ),
              findsOneWidget,
            );
            if (preview && line.id == chuoSobuBookLine.id && english == dark) {
              await capture(tester, 'station-picker-$english-$dark');
            }
            await tester.tap(
              find.byKey(const ValueKey('stamp-book-station-sheet-close')),
            );
            await tester.pumpAndSettle();
            expect(
              tester
                  .widget<YamanoteStampMap>(find.byType(YamanoteStampMap))
                  .selected,
              0,
            );
            await tester.tap(picker);
            await tester.pumpAndSettle();
            final last = find.byKey(
              ValueKey('stamp-book-station-option-${line.stations.length - 1}'),
            );
            await tester.ensureVisible(last);
            await tester.pumpAndSettle();
            await tester.tap(last);
            await tester.pumpAndSettle();
            expect(sheet, findsNothing);
            expect(
              tester
                  .widget<YamanoteStampMap>(find.byType(YamanoteStampMap))
                  .selected,
              line.stations.length - 1,
            );
            await tester.tap(picker);
            await tester.pumpAndSettle();
            expect(last.hitTestable(), findsOneWidget);
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(sheet, findsNothing);
            expect(session.collected, {line.stations.first.id});
            await tester.tap(
              find.byTooltip(english ? 'About collection' : '수집 안내'),
            );
            await tester.pumpAndSettle();
            final help = find.byType(BottomSheet);
            expect(
              find.descendant(
                of: help,
                matching: find.textContaining(
                  english ? 'not actual tracks' : '실제 선로가 아닌',
                ),
              ),
              findsOneWidget,
            );
            expect(
              find.descendant(
                of: help,
                matching: find.textContaining(
                  english ? 'not official station stamps' : '공식 역 도장',
                ),
              ),
              findsOneWidget,
            );
            expect(
              find.descendant(
                of: help,
                matching: find.textContaining(
                  english ? '30 Yamanote' : '야마노테선 30역',
                ),
              ),
              findsNothing,
            );
            if (preview && line.id == chuoSobuBookLine.id && english == dark) {
              await capture(tester, 'stamp-help-short-$english-$dark');
            }
            await tester.ensureVisible(find.text(english ? 'Got it' : '확인'));
            await tester.tap(find.text(english ? 'Got it' : '확인'));
            await tester.pumpAndSettle();
            expect(help, findsNothing);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
  for (final viewport in [
    const Size(320, 700),
    const Size(812, 375),
    const Size(1024, 768),
  ]) {
    testWidgets('station sheet/help large text english dark $viewport', (
      tester,
    ) async {
      size(tester, viewport);
      final session = StationStampSession();
      addTearDown(session.dispose);
      await tester.pumpWidget(
        app(
          StampBookLinePage(session: session, line: chuoSobuBookLine),
          language: 'en',
          dark: true,
          scale: 2,
          mode: StationNameDisplayMode.japaneseEnglish,
        ),
      );
      final tab = find.byKey(const ValueKey('stamp-book-tab-map'));
      await tester.ensureVisible(tab);
      await tester.tap(tab);
      await tester.pumpAndSettle();
      final picker = find.byKey(const ValueKey('stamp-book-station-picker'));
      await tester.scrollUntilVisible(
        picker,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(tester.element(picker), alignment: .5);
      await tester.pumpAndSettle();
      await tester.tap(picker);
      await tester.pumpAndSettle();
      final last = find.byKey(const ValueKey('stamp-book-station-option-38'));
      await tester.ensureVisible(last);
      await tester.pumpAndSettle();
      await tester.tap(last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<YamanoteStampMap>(find.byType(YamanoteStampMap)).selected,
        38,
      );
      await tester.tap(find.byTooltip('About collection'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Got it'));
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
