import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/tools/presentation/tools_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const preview = bool.fromEnvironment('TOOLS_PREVIEW');
  if (preview) {
    setUpAll(() async {
      for (final font in {
        'ToolsPreview': 'C:/Windows/Fonts/malgun.ttf',
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
  for (final dark in [false, true]) {
    for (final spec in [
      (const Size(390, 844), 1.0),
      (const Size(320, 740), 2.0),
      (const Size(844, 390), 1.0),
      (const Size(768, 1024), 1.0),
      (const Size(390, 844), 3.0),
    ]) {
      testWidgets('B tiles dark=$dark size=${spec.$1} text=${spec.$2}', (
        tester,
      ) async {
        tester.view.physicalSize = spec.$1;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        var pass = 0, contactless = 0, locker = 0;
        final theme = dark ? AppTheme.dark : AppTheme.light;
        await tester.pumpWidget(
          MaterialApp(
            theme: preview
                ? theme.copyWith(
                    textTheme: theme.textTheme.apply(
                      fontFamily: 'ToolsPreview',
                    ),
                  )
                : theme,
            home: MediaQuery(
              data: MediaQueryData(
                textScaler: TextScaler.linear(spec.$2),
                disableAnimations: true,
              ),
              child: RepaintBoundary(
                key: const ValueKey('tools-preview'),
                child: Scaffold(
                  body: SafeArea(
                    child: ToolsPage(
                      onOpenPassComparison: () => pass++,
                      onOpenContactless: () => contactless++,
                      onOpenCoinLocker: () => locker++,
                    ),
                  ),
                  bottomNavigationBar: NavigationBar(
                    selectedIndex: 2,
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.home_outlined),
                        label: '홈',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.receipt_long_outlined),
                        label: '이용내역',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.grid_view_rounded),
                        label: '도구',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.settings_outlined),
                        label: '설정',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final first = find.byKey(const ValueKey('tools-pass-comparison'));
        final second = find.byKey(const ValueKey('tools-contactless'));
        final third = find.byKey(const ValueKey('tools-coin-locker'));
        final firstSemantics = tester.getSemantics(first).getSemanticsData();
        semantics.dispose();
        expect(firstSemantics.label, '교통패스 비교');
        expect(firstSemantics.hint, '패스 가격과 예상 교통비 비교');
        expect(firstSemantics.hasAction(ui.SemanticsAction.tap), isTrue);
        expect(find.text('교통패스 비교'), findsOneWidget);
        expect(find.text('컨택리스 노선'), findsOneWidget);
        expect(find.text('코인락커 찾기'), findsOneWidget);
        final oneColumn = spec.$1.width - 40 < 300 || spec.$2 > 1.4;
        if (oneColumn) {
          expect(
            tester.getTopLeft(second).dy,
            greaterThan(tester.getBottomLeft(first).dy),
          );
        } else {
          expect(tester.getTopLeft(first).dy, tester.getTopLeft(second).dy);
          expect(tester.getSize(first).height, tester.getSize(second).height);
        }
        for (final tile in [first, second, third]) {
          await Scrollable.ensureVisible(tester.element(tile), alignment: 0.2);
          await tester.pumpAndSettle();
          expect(tester.getSize(tile).height, greaterThanOrEqualTo(48));
          expect(tester.getSize(tile).width, greaterThanOrEqualTo(48));
          await tester.tap(tile);
          await tester.pump();
        }
        expect(pass, 1);
        expect(contactless, 1);
        expect(locker, 1);
        expect(tester.takeException(), isNull);
        if (preview && spec.$1.width != 768 && spec.$2 != 3) {
          final scroll = tester.state<ScrollableState>(
            find.byType(Scrollable).first,
          );
          scroll.position.jumpTo(0);
          await tester.pumpAndSettle();
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('tools-preview')),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 1.5);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final dir = Directory('.private-backups/tools-tab-B-2026-11-02');
            await dir.create(recursive: true);
            await File(
              '${dir.path}/${spec.$1.width.toInt()}-${spec.$2}-${dark ? 'dark' : 'light'}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      });
    }
  }
}
