import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/station_stamps/domain/stamp_book_catalog.dart';
import 'package:ic_card_reader/src/features/station_stamps/domain/station_stamp_session.dart';
import 'package:ic_card_reader/src/features/station_stamps/presentation/stamp_book_page.dart';
import 'stamp_test_support.dart' show app;

const _preview = bool.fromEnvironment('STAMP_PREVIEW');
const _toggle = ValueKey('stamp-book-collection-toggle');
const _company = ValueKey('stamp-book-company-toggle');
const _browse = ValueKey('stamp-book-browse');
const _line = ValueKey('stamp-book-yamanote');
const _search = ValueKey('stamp-book-search');
const _kantoCollection = ValueKey('stamp-book-region-kanto');
const _regionPreviewDir = String.fromEnvironment('STAMP_REGION_REVIEW_DIR');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (!_preview) return;
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
  void size(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> tap(WidgetTester tester, Key key) async {
    if (find.byKey(key).evaluate().isEmpty) {
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      if (find.byKey(key).evaluate().isEmpty) {
        await tester.scrollUntilVisible(find.byKey(key), 150);
      }
    }
    await tester.ensureVisible(find.byKey(key));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  for (final language in ['ko', 'en']) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('book hub disclosures $language dark=$dark scale=$scale', (
          tester,
        ) async {
          size(tester, Size(scale == 1 ? 360 : 320, 800));
          final session = StationStampSession()
            ..collect(yamanoteStampStations.take(4).map((s) => s.id));
          addTearDown(session.dispose);
          final semantics = tester.ensureSemantics();
          try {
            await tester.pumpWidget(
              app(
                StampBookPage(
                  session: session,
                  candidates: const {'jr-east:ueno'},
                  hasScan: true,
                ),
                language: language,
                dark: dark,
                scale: scale,
              ),
            );
            await tester.pumpAndSettle();
            expect(find.byKey(_line), findsOneWidget);
            expect(
              tester.getSize(find.byKey(_toggle)).height,
              greaterThanOrEqualTo(48),
            );
            final node = tester.getSemantics(find.byKey(_toggle));
            expect(
              node.getSemanticsData().flagsCollection.isExpanded,
              ui.Tristate.isTrue,
            );
            if (_preview && scale == 1) {
              await capture(tester, 'native-home-$language-$dark');
            }
            await tap(tester, _toggle);
            expect(find.byKey(_line), findsNothing);
            expect(find.byKey(_browse), findsOneWidget);
            expect(
              tester
                  .getSemantics(find.byKey(_toggle))
                  .getSemanticsData()
                  .flagsCollection
                  .isExpanded,
              ui.Tristate.isFalse,
            );
            if (_preview && scale == 1) {
              await capture(tester, 'native-folded-$language-$dark');
            }
            await tap(tester, _browse);
            expect(find.byType(StampBookBrowsePage), findsOneWidget);
            expect(
              find.byKey(_line),
              findsNothing,
              reason: 'company starts folded',
            );
            expect(
              find.text(language == 'ko' ? 'JR 동일본' : 'JR East'),
              findsOneWidget,
            );
            expect(
              tester.getSize(find.byKey(_company)).height,
              greaterThanOrEqualTo(48),
            );
            if (_preview && scale == 1) {
              await capture(tester, 'native-browse-folded-$language-$dark');
            }
            await tap(tester, _company);
            expect(find.byKey(_line), findsOneWidget);
            expect(find.text('4 / 30'), findsOneWidget);
            expect(
              find.byKey(const ValueKey('stamp-book-chuo-sobu')),
              findsOneWidget,
            );
            if (_preview && scale == 1) {
              await capture(tester, 'native-browse-open-$language-$dark');
            }
            await tap(tester, _line);
            expect(find.byType(YamanoteStampBookLinePage), findsOneWidget);
            expect(find.byType(StampBookSeal), findsNWidgets(30));
            Navigator.of(
              tester.element(find.byType(YamanoteStampBookLinePage)),
            ).pop();
            await tester.pumpAndSettle();
            Navigator.of(
              tester.element(find.byType(StampBookBrowsePage)),
            ).pop();
            await tester.pumpAndSettle();
            expect(
              find.byKey(_line),
              findsNothing,
              reason: 'home disclosure survives browsing',
            );
            await tap(tester, _toggle);
            expect(find.byKey(_line), findsOneWidget);
            expect(session.countFor(yamanoteStampLine), 4);
            expect(tester.takeException(), isNull);
          } finally {
            semantics.dispose();
          }
        });
      }
    }
  }

  testWidgets('pilot search Korean Japanese English plus empty and folding', (
    tester,
  ) async {
    size(tester, const Size(375, 812));
    final session = StationStampSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(app(StampBookBrowsePage(session: session)));
    await tester.pumpAndSettle();
    for (final query in [
      '야마노테',
      '山手',
      'YAMANOTE',
      'JR East',
      'JR 동일본',
      '新宿',
      '시부야',
      'Tokyo',
    ]) {
      await tester.enterText(find.byKey(_search), query);
      await tester.pumpAndSettle();
      expect(find.byKey(_line), findsOneWidget, reason: query);
    }
    await tap(tester, _company);
    expect(find.byKey(_line), findsNothing);
    expect(
      tester.widget<TextField>(find.byKey(_search)).controller!.text,
      'Tokyo',
    );
    await tap(tester, _company);
    session.collect(['jr-east:tokyo']);
    await tester.pumpAndSettle();
    expect(find.text('1 / 30'), findsOneWidget);
    await tester.enterText(find.byKey(_search), 'not a line');
    await tester.pumpAndSettle();
    expect(find.byKey(_company), findsNothing);
    expect(find.text('검색 결과가 없어요.'), findsOneWidget);
    await tester.tap(find.byTooltip('검색어 지우기'));
    await tester.pumpAndSettle();
    expect(find.byKey(_company), findsOneWidget);
    await tap(tester, const ValueKey('stamp-book-region-kanto'));
    expect(find.byKey(_line), findsOneWidget);
    await tap(tester, const ValueKey('stamp-book-region-all'));
    expect(find.byKey(_line), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final dimensions in [const Size(812, 375), const Size(768, 1024)]) {
    testWidgets('book hub responsive $dimensions', (tester) async {
      size(tester, dimensions);
      final session = StationStampSession();
      addTearDown(session.dispose);
      await tester.pumpWidget(
        app(
          StampBookPage(session: session, candidates: const {}, hasScan: false),
          language: 'en',
          scale: 2,
        ),
      );
      await tester.pumpAndSettle();
      final empty = find.text('No lines collected yet.');
      await tester.scrollUntilVisible(empty, 150);
      expect(empty, findsOneWidget);
      await tap(tester, _toggle);
      await tap(tester, _browse);
      await tap(tester, _company);
      expect(find.byKey(_line), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('book home shows only lines with collected stamps', (
    tester,
  ) async {
    size(tester, const Size(375, 812));
    final session = StationStampSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(
      app(
        StampBookPage(
          session: session,
          candidates: const {'jr-east:tokyo'},
          hasScan: true,
        ),
      ),
    );
    const chuo = ValueKey('stamp-book-chuo-sobu');
    final empty = find.text('아직 수집한 노선이 없어요.');
    expect(empty, findsOneWidget);
    expect(find.byKey(_line), findsNothing);
    expect(find.byKey(chuo), findsNothing);
    await tap(tester, _browse);
    await tap(tester, _company);
    expect(find.byKey(_line), findsOneWidget);
    expect(find.byKey(chuo), findsOneWidget);
    Navigator.of(tester.element(find.byType(StampBookBrowsePage))).pop();
    await tester.pumpAndSettle();
    await tap(tester, const ValueKey('stamp-book-collect'));
    expect(empty, findsNothing);
    expect(find.byKey(_line), findsOneWidget);
    expect(find.byKey(chuo), findsNothing);
    session.collect(['jr-east:shinjuku']);
    await tester.pumpAndSettle();
    expect(find.byKey(chuo), findsOneWidget);
    session.clear();
    await tester.pumpAndSettle();
    expect(empty, findsOneWidget);
    expect(find.byKey(_line), findsNothing);
    expect(find.byKey(chuo), findsNothing);
  });

  testWidgets('book home scrolls through every distinct collected seal', (
    tester,
  ) async {
    size(tester, const Size(375, 812));
    final uncollected = stampBookStations[2].id;
    final kantos = stampBookStations
        .where((s) => stampBookRegionByStationId[s.id] == 'kanto')
        .toList();
    final collected = kantos.map((s) => s.id).toSet().difference({uncollected});
    final session = StationStampSession()..collect(collected);
    addTearDown(session.dispose);
    await tester.pumpWidget(
      app(
        StampBookPage(session: session, candidates: const {}, hasScan: false),
      ),
    );
    await tester.pumpAndSettle();
    final kanto = find.byKey(_kantoCollection);
    expect(kanto, findsOneWidget);
    expect(find.text('간토'), findsOneWidget);
    expect(find.text('${collected.length}개'), findsOneWidget);
    expect(find.byType(StampBookSeal), findsNothing);
    final semantics = tester.ensureSemantics();
    try {
      expect(
        tester
            .getSemantics(kanto)
            .getSemanticsData()
            .flagsCollection
            .isExpanded,
        ui.Tristate.isFalse,
      );
      await tap(tester, _kantoCollection);
      expect(
        tester
            .getSemantics(kanto)
            .getSemanticsData()
            .flagsCollection
            .isExpanded,
        ui.Tristate.isTrue,
      );
    } finally {
      semantics.dispose();
    }
    final scroll = find.byType(Scrollable);
    final position = tester.state<ScrollableState>(scroll).position;
    final seen = <Key>{};
    for (var attempt = 0; attempt < 70; attempt++) {
      final mounted = tester
          .widgetList<StampBookSeal>(find.byType(StampBookSeal))
          .map((seal) => seal.key!)
          .toList();
      expect(mounted.toSet(), hasLength(mounted.length));
      seen.addAll(mounted);
      if (position.extentAfter < 1) break;
      await tester.drag(scroll, const Offset(0, -240));
      await tester.pumpAndSettle();
    }
    expect(
      seen,
      collected.map((id) => ValueKey('stamp-book-collected-$id')).toSet(),
    );
    expect(
      find
          .byKey(ValueKey('stamp-book-collected-${kantos.last.id}'))
          .hitTestable(),
      findsOneWidget,
    );
    await tap(tester, _kantoCollection);
    expect(find.byType(StampBookSeal), findsNothing);
    expect(find.text('${collected.length}개'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large text can scroll beyond the first four seals', (
    tester,
  ) async {
    size(tester, const Size(320, 700));
    final stamps = stampBookStations.take(8).toList();
    final session = StationStampSession()..collect(stamps.map((s) => s.id));
    addTearDown(session.dispose);
    await tester.pumpWidget(
      app(
        StampBookPage(session: session, candidates: const {}, hasScan: false),
        language: 'en',
        dark: true,
        scale: 2,
      ),
    );
    final eighth = find.byKey(
      ValueKey('stamp-book-collected-${stamps.last.id}'),
    );
    await tester.pumpAndSettle();
    expect(find.byType(StampBookSeal), findsNothing);
    await tap(tester, _kantoCollection);
    expect(find.text('Kanto'), findsOneWidget);
    expect(find.text('8 stamps'), findsOneWidget);
    await tester.scrollUntilVisible(eighth, 220);
    await tester.pumpAndSettle();
    expect(eighth.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets(
      'region tab keeps contrast and changes its surface dark=$dark',
      (tester) async {
        size(tester, const Size(390, 870));
        final session = StationStampSession()
          ..collect(yamanoteStampStations.take(8).map((station) => station.id));
        addTearDown(session.dispose);
        await tester.pumpWidget(
          app(
            StampBookPage(
              session: session,
              candidates: const {},
              hasScan: false,
            ),
            dark: dark,
          ),
        );
        await tester.pumpAndSettle();

        final tab = find.byKey(_kantoCollection);
        final button = find.descendant(
          of: tab,
          matching: find.byType(TextButton),
        );
        final count = find.descendant(of: tab, matching: find.text('8개'));
        Color surface() => tester
            .widget<TextButton>(button)
            .style!
            .backgroundColor!
            .resolve({})!;
        void expectReadableBadge() {
          final badge = find
              .ancestor(of: count, matching: find.byType(DecoratedBox))
              .first;
          final fill =
              (tester.widget<DecoratedBox>(badge).decoration as BoxDecoration)
                  .color!;
          final ink = tester.widget<Text>(count).style!.color!;
          final values = [ink.computeLuminance(), fill.computeLuminance()]
            ..sort();
          expect(
            (values.last + .05) / (values.first + .05),
            greaterThanOrEqualTo(4.5),
          );
        }

        final closedSurface = surface();
        expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
        expect(
          find.descendant(
            of: tab,
            matching: find.byIcon(Icons.expand_more_rounded),
          ),
          findsOneWidget,
        );
        expectReadableBadge();
        if (_preview && _regionPreviewDir.isNotEmpty) {
          await capture(
            tester,
            'region-tab-closed-$dark',
            directory: _regionPreviewDir,
          );
        }
        await tap(tester, _kantoCollection);
        expect(surface(), isNot(closedSurface));
        expect(
          find.descendant(
            of: tab,
            matching: find.byIcon(Icons.expand_less_rounded),
          ),
          findsOneWidget,
        );
        expectReadableBadge();
        if (_preview && _regionPreviewDir.isNotEmpty) {
          await capture(
            tester,
            'region-tab-open-$dark',
            directory: _regionPreviewDir,
          );
        }
      },
    );
  }
}

Future<void> capture(
  WidgetTester tester,
  String name, {
  String directory = 'docs/design/stamp-book-hub-2026-11-17',
}) async {
  final images = tester.widgetList<Image>(find.byType(Image)).toList();
  final context = tester.element(find.byType(Scaffold).last);
  await tester.runAsync(
    () => Future.wait(images.map((i) => precacheImage(i.image, context))),
  );
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('stamp-preview')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    await File(
      '$directory/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
  });
}
