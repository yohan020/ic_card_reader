import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/core/widgets/main_page_header.dart';

void main() {
  const preview = bool.fromEnvironment('HEADER_PREVIEW');
  if (preview) {
    setUpAll(() async {
      for (final font in {
        'HeaderPreview': 'C:/Windows/Fonts/malgun.ttf',
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
  }
  const titles = ['IC 카드 리더', '이용내역', '도구', '설정'];
  for (final dark in [false, true]) {
    for (final spec in [
      (const Size(390, 844), 1.0),
      (const Size(320, 740), 2.0),
      (const Size(844, 390), 1.0),
      (const Size(375, 812), 3.0),
    ]) {
      testWidgets(
        'A minimal headers dark=$dark size=${spec.$1} scale=${spec.$2}',
        (tester) async {
          tester.view.physicalSize = spec.$1;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var scans = 0;
          final theme = dark ? AppTheme.dark : AppTheme.light;
          await tester.pumpWidget(
            MaterialApp(
              theme: preview
                  ? theme.copyWith(
                      textTheme: theme.textTheme.apply(
                        fontFamily: 'HeaderPreview',
                      ),
                    )
                  : theme,
              home: MediaQuery(
                data: MediaQueryData(
                  textScaler: TextScaler.linear(spec.$2),
                  disableAnimations: true,
                ),
                child: RepaintBoundary(
                  key: const ValueKey('header-preview'),
                  child: Scaffold(
                    body: SafeArea(
                      child: ListView(
                        padding: MainPageHeader.pagePadding,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < 4; i++)
                                MainPageHeader(
                                  title: titles[i],
                                  onScan: i == 1 ? () => scans++ : null,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          expect(find.byType(Text), findsNWidgets(4));
          expect(find.byType(Icon), findsOneWidget);
          final semantics = tester.ensureSemantics();
          final node = tester.getSemantics(find.text(titles[0]));
          final isHeading = node.flagsCollection.isHeader;
          semantics.dispose();
          expect(isHeading, isTrue);
          for (final title in titles) {
            await tester.ensureVisible(find.text(title));
            final text = tester.widget<Text>(find.text(title));
            expect(text.style!.fontSize, 21);
            expect(text.style!.fontWeight, FontWeight.w700);
            expect(text.maxLines, isNull);
            expect(tester.takeException(), isNull);
          }
          await tester.ensureVisible(find.byTooltip('IC 카드 스캔'));
          expect(
            tester.getSize(find.byTooltip('IC 카드 스캔')),
            const Size(48, 48),
          );
          await tester.tap(find.byTooltip('IC 카드 스캔'));
          expect(scans, 1);
          expect(tester.takeException(), isNull);
          if (preview && spec.$2 == 1 && spec.$1.width == 390) {
            await tester.drag(find.byType(ListView), const Offset(0, 2000));
            await tester.pumpAndSettle();
            await tester.runAsync(() async {
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(const ValueKey('header-preview')),
              );
              final image = await boundary.toImage(pixelRatio: 2);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final dir = Directory(
                '.private-backups/main-headers-A-flutter-2026-11-02',
              );
              await dir.create(recursive: true);
              await File(
                '${dir.path}/${dark ? 'dark' : 'light'}.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
        },
      );
    }
  }
}
