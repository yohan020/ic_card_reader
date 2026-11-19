import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/l10n/app_localizations.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/contactless/domain/contactless_catalog.dart';
import 'package:ic_card_reader/src/features/contactless/presentation/contactless_page.dart';
import '../station_stamps/stamp_test_support.dart' show previewTextTheme;

const preview = bool.fromEnvironment('CONTACTLESS_PREVIEW');
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final all = ContactlessCatalog.fromJson(
    jsonDecode(
          utf8.decode(
            gzip.decode(
              File('assets/data/contactless/catalog.bin').readAsBytesSync(),
            ),
          ),
        )
        as Map<String, dynamic>,
  );
  final metro = all.lines.firstWhere((l) => l.operatorName == '도쿄메트로');
  final source = ContactlessCatalog(
    all.lines.where((l) => l.operatorId == metro.operatorId).take(2).toList(),
    attribution: all.attribution,
    releaseReviewPending: true,
  );
  if (preview) {
    setUpAll(() async {
      for (final font in {
        'Preview': 'C:/Windows/Fonts/malgun.ttf',
        'PreviewLatin': 'C:/Windows/Fonts/arial.ttf',
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
  for (final language in ['ko', 'en']) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('plain company heading $language dark=$dark scale=$scale', (
          tester,
        ) async {
          tester.view.physicalSize = Size(scale == 1 ? 390 : 320, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final base = dark ? AppTheme.dark : AppTheme.light;
          final theme = preview
              ? base.copyWith(
                  textTheme: previewTextTheme(base.textTheme),
                  primaryTextTheme: previewTextTheme(base.primaryTextTheme),
                  appBarTheme: base.appBarTheme.copyWith(
                    titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(
                      fontFamily: 'Preview',
                    ),
                  ),
                )
              : base;
          await tester.pumpWidget(
            RepaintBoundary(
              key: const ValueKey('unified-preview'),
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: theme,
                locale: Locale(language),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: ContactlessPage(load: () async => source),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final heading = find.byKey(ValueKey('company-${metro.operatorId}'));
          expect(find.byType(Card), findsNothing);
          expect(find.byType(LinearProgressIndicator), findsNothing);
          expect(tester.getRect(heading).height, greaterThanOrEqualTo(48));
          final title = metro.operatorNameFor(english: language == 'en');
          final text = tester.widget<Text>(find.text(title));
          expect(text.style!.fontSize, 13);
          expect(text.style!.fontWeight, FontWeight.w700);
          expect(find.byType(Divider), findsWidgets);
          if (preview && scale == 1) {
            await capture(tester, 'closed-$language-$dark');
          }
          await tester.tap(heading);
          await tester.pumpAndSettle();
          expect(find.byType(ContactlessBadge), findsWidgets);
          expect(find.byType(Card), findsNWidgets(2));
          expect(tester.takeException(), isNull);
          if (preview) await capture(tester, 'open-$language-$dark-$scale');
        });
      }
    }
  }
}

Future<void> capture(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('unified-preview')),
    );
    final picture = await boundary.toImage(pixelRatio: 2);
    final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
    final folder = Directory('.dart_tool/company-unified-preview')
      ..createSync(recursive: true);
    await File(
      '${folder.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    picture.dispose();
  });
}
