import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_reader.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_scan_result.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/scan_guidance.dart';
import 'package:ic_card_reader/src/features/card_reader/presentation/widgets/card_comparison_exit_dialog.dart';

const _visualPreview = bool.fromEnvironment('COMPACT_MODAL_VISUAL_PREVIEW');

void main() {
  if (_visualPreview) {
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
    for (final compact in [false, true]) {
      testWidgets(
        'B exit dialog layout and results dark=$dark compact=$compact',
        (tester) async {
          final results = <bool?>[];
          await _pump(
            tester,
            dark: dark,
            compact: compact,
            onOpen: (context) async {
              results.add(
                await showDialog<bool>(
                  context: context,
                  builder: (_) => const CardComparisonExitDialog(),
                ),
              );
            },
          );
          Future<void> open() async {
            await tester.tap(find.text('열기'));
            await tester.pumpAndSettle();
          }

          await open();
          final content = find.byKey(const ValueKey('comparison-exit-content'));
          final icon = find.byKey(const ValueKey('comparison-exit-icon'));
          final title = find.text('잔액 비교를 종료할까요?');
          expect(tester.getSize(content).width, lessThanOrEqualTo(320));
          expect(tester.getSize(icon), const Size(40, 40));
          expect(
            tester.getRect(icon).right,
            lessThan(tester.getRect(title).left),
          );
          expect(tester.widget<Text>(title).style!.fontWeight, FontWeight.w700);
          expect(find.text('전체 삭제'), findsNothing);
          if (!compact) {
            expect(tester.getSize(content).height, lessThan(270));
          }
          final cancel = find.byKey(const ValueKey('comparison-exit-cancel'));
          final confirm = find.byKey(const ValueKey('comparison-exit-confirm'));
          await tester.ensureVisible(confirm);
          await tester.pumpAndSettle();
          _expectButtonPair(tester, cancel, confirm);
          expect(tester.takeException(), isNull);
          await _preview(tester, 'exit_${dark ? 'dark' : 'light'}_$compact');
          await tester.tap(cancel);
          await tester.pumpAndSettle();
          expect(results, [false]);

          await open();
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(results, [false, null]);

          await open();
          await tester.tapAt(const Offset(5, 5));
          await tester.pumpAndSettle();
          expect(results, [false, null, null]);

          await open();
          await tester.ensureVisible(confirm);
          await tester.pumpAndSettle();
          await tester.tap(confirm);
          await tester.pumpAndSettle();
          expect(results, [false, null, null, true]);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'B scan sheet layout and actions dark=$dark compact=$compact',
        (tester) async {
          final results = <ScanFailureAction?>[];
          await _pump(
            tester,
            dark: dark,
            compact: compact,
            onOpen: (context) async {
              results.add(
                await showScanFailure(
                  context,
                  kind: CardScanFailureKind.tagLost,
                  availability: CardReaderAvailability.enabled,
                ),
              );
            },
          );
          Future<void> open() async {
            await tester.tap(find.text('열기'));
            await tester.pumpAndSettle();
          }

          await open();
          final icon = find.byKey(const ValueKey('scan-failure-icon'));
          final title = find.text('카드와 통신을 완료하지 못했어요');
          expect(tester.getSize(icon), const Size(40, 40));
          expect(
            tester.getRect(icon).right,
            lessThan(tester.getRect(title).left),
          );
          final help = find.byKey(const ValueKey('scan-failure-help'));
          final retry = find.byKey(const ValueKey('scan-failure-primary'));
          await tester.ensureVisible(retry);
          await tester.pumpAndSettle();
          _expectButtonPair(tester, help, retry);
          final style = tester.widget<OutlinedButton>(help).style!;
          expect(
            style.side!.resolve({})!.color,
            AppColors.accent(tester.element(help)),
          );
          expect(tester.takeException(), isNull);
          await _preview(tester, 'scan_${dark ? 'dark' : 'light'}_$compact');
          await tester.tap(retry);
          await tester.pumpAndSettle();
          expect(results, [ScanFailureAction.retry]);
          await open();
          await tester.ensureVisible(help);
          await tester.pumpAndSettle();
          await tester.tap(help);
          await tester.pumpAndSettle();
          expect(results.last, ScanFailureAction.help);
          await open();
          await tester.ensureVisible(find.byTooltip('안내 닫기'));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('안내 닫기'));
          await tester.pumpAndSettle();
          expect(results, [
            ScanFailureAction.retry,
            ScanFailureAction.help,
            null,
          ]);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('unsupported NFC keeps help but never offers retry or settings', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ScanFailureView(
            kind: CardScanFailureKind.nfcUnavailable,
            availability: CardReaderAvailability.unsupported,
            onRetry: () => fail('unsupported retry'),
            onHelp: () {},
            onOpenSettings: () => fail('unsupported settings'),
          ),
        ),
      ),
    );
    expect(find.text('스캔 도움말'), findsOneWidget);
    expect(find.text('다시 스캔'), findsNothing);
    expect(find.text('NFC 설정 열기'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

void _expectButtonPair(WidgetTester tester, Finder left, Finder right) {
  final leftRect = tester.getRect(left);
  final rightRect = tester.getRect(right);
  expect(leftRect.top, closeTo(rightRect.top, .1));
  expect(leftRect.width, closeTo(rightRect.width, .1));
  expect(leftRect.height, greaterThanOrEqualTo(48));
  expect(rightRect.height, closeTo(leftRect.height, .1));
  expect(rightRect.left - leftRect.right, closeTo(10, .1));
}

Future<void> _pump(
  WidgetTester tester, {
  required bool dark,
  required bool compact,
  required void Function(BuildContext) onOpen,
}) async {
  tester.view.physicalSize = compact
      ? const Size(320, 400)
      : const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final theme = dark ? AppTheme.dark : AppTheme.light;
  await tester.pumpWidget(
    MaterialApp(
      theme: _visualPreview
          ? theme.copyWith(
              textTheme: theme.textTheme.apply(fontFamily: 'ModalPreview'),
              primaryTextTheme: theme.primaryTextTheme.apply(
                fontFamily: 'ModalPreview',
              ),
            )
          : theme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(compact ? 1.7 : 1)),
        child: RepaintBoundary(
          key: const ValueKey('modal-preview'),
          child: child,
        ),
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => onOpen(context),
            child: const Text('열기'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _preview(WidgetTester tester, String name) async {
  if (!_visualPreview) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('modal-preview')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('.dart_tool/compact_modal_preview');
      await directory.create(recursive: true);
      await File(
        '${directory.path}/$name.png',
      ).writeAsBytes(data!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}
