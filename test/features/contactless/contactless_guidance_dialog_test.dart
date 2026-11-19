import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/contactless/domain/contactless_catalog.dart';
import 'package:ic_card_reader/src/features/contactless/presentation/contactless_guidance_dialog.dart';
import 'package:ic_card_reader/src/features/contactless/presentation/contactless_page.dart';

const _preview = bool.fromEnvironment('CONTACTLESS_MODAL_PREVIEW');
const _surfaceKey = ValueKey('contactless-guidance-surface');
const _confirmKey = ValueKey('contactless-guidance-confirm');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  if (_preview) {
    setUpAll(() async {
      for (final font in {
        'ModalPreview': 'C:/Windows/Fonts/malgun.ttf',
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
    for (final params in [
      (const Size(390, 844), 1.0),
      (const Size(320, 640), 2.0),
      (const Size(844, 390), 1.0),
    ]) {
      testWidgets(
        'B guidance dark=$dark size=${params.$1} scale=${params.$2}',
        (tester) async {
          await _pump(tester, dark: dark, size: params.$1, scale: params.$2);
          await tester.tap(find.byTooltip('컨택리스 안내'));
          await tester.pumpAndSettle();
          expect(find.byType(ContactlessGuidanceDialog), findsOneWidget);
          expect(find.byType(AlertDialog), findsNothing);
          expect(find.text('컨택리스 승차 안내'), findsOneWidget);
          expect(find.text('노선별 이용 조건을 확인해 주세요'), findsOneWidget);
          expect(find.text('‘미확인’은 ‘미지원’이 아니에요'), findsOneWidget);
          expect(find.textContaining('교통IC·QR'), findsOneWidget);
          expect(find.textContaining('실시간 운행·결제 현황은 제공하지 않아요'), findsOneWidget);
          final bounds = tester.getRect(find.byKey(_surfaceKey));
          final button = tester.getRect(find.byKey(_confirmKey));
          expect(bounds.width, lessThanOrEqualTo(342));
          expect(button.height, greaterThanOrEqualTo(48));
          expect(button.left, greaterThan(bounds.left));
          expect(button.right, lessThan(bounds.right));
          expect(find.byKey(_confirmKey).hitTestable(), findsOneWidget);
          if (params.$1.width == 390) {
            final icon = tester.getRect(
              find.byKey(const ValueKey('contactless-guidance-icon')),
            );
            final title = tester.getRect(find.text('컨택리스 승차 안내'));
            expect(icon.center.dx, closeTo(bounds.center.dx, 1));
            expect(title.center.dx, closeTo(bounds.center.dx, 1));
            expect(icon.width, 54);
            if (_preview) await _capture(tester, dark ? 'dark' : 'light');
          }
          await tester.drag(
            find.byKey(const ValueKey('contactless-guidance-content')),
            const Offset(0, -500),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.byKey(_confirmKey).hitTestable(), findsOneWidget);
          await tester.tap(find.byKey(_confirmKey));
          await tester.pumpAndSettle();
          expect(find.byType(ContactlessGuidanceDialog), findsNothing);
          expect(find.byType(ContactlessPage), findsOneWidget);
        },
      );
    }
  }

  testWidgets(
    'confirm, system back, outside dismissal and reopening preserve page state',
    (tester) async {
      await _pump(tester);
      await tester.tap(find.text('도쿄메트로'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '긴자');
      await tester.pumpAndSettle();
      for (final dismiss in ['confirm', 'back', 'outside']) {
        await tester.tap(find.byTooltip('컨택리스 안내'));
        await tester.pumpAndSettle();
        expect(find.byType(ContactlessGuidanceDialog), findsOneWidget);
        if (dismiss == 'confirm') {
          await tester.tap(find.byKey(_confirmKey));
        } else if (dismiss == 'back') {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tapAt(const Offset(5, 5));
        }
        await tester.pumpAndSettle();
        expect(find.byType(ContactlessGuidanceDialog), findsNothing);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          '긴자',
        );
        expect(find.text('긴자선'), findsOneWidget);
      }
      await tester.tap(find.byTooltip('검색 지우기'));
      await tester.pumpAndSettle();
      expect(find.text('긴자선'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pump(
  WidgetTester tester, {
  bool dark = false,
  Size size = const Size(390, 844),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final theme = dark ? AppTheme.dark : AppTheme.light;
  final fixture = ContactlessCatalog(
    [
      ContactlessLine({
        'id': 'test-line',
        'operatorId': 'test-operator',
        'name': '긴자선',
        'nameJa': '銀座線',
        'operator': '도쿄메트로',
        'regions': ['kanto'],
        'status': 'supported',
      }),
    ],
    attribution: 'Test fixture',
    releaseReviewPending: true,
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: _preview
          ? theme.copyWith(
              textTheme: theme.textTheme.apply(fontFamily: 'ModalPreview'),
              primaryTextTheme: theme.primaryTextTheme.apply(
                fontFamily: 'ModalPreview',
              ),
              appBarTheme: theme.appBarTheme.copyWith(
                titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
                  fontFamily: 'ModalPreview',
                ),
              ),
            )
          : theme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: RepaintBoundary(
          key: const ValueKey('modal-preview'),
          child: child!,
        ),
      ),
      home: ContactlessPage(load: () => Future.value(fixture)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('modal-preview')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final folder = Directory('.private-backups/contactless-modal-B-2026-10-31');
    await folder.create(recursive: true);
    await File(
      '${folder.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
