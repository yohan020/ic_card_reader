import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/contactless/domain/contactless_catalog.dart';
import 'package:ic_card_reader/src/features/contactless/data/contactless_repository.dart';
import 'package:ic_card_reader/src/features/contactless/presentation/contactless_page.dart';

ContactlessCatalog _catalog() => ContactlessCatalog.fromJson(
  jsonDecode(
        utf8.decode(
          gzip.decode(
            File('assets/data/contactless/catalog.bin').readAsBytesSync(),
          ),
        ),
      )
      as Map<String, dynamic>,
);
const preview = bool.fromEnvironment('CONTACTLESS_PREVIEW');

class _Bundle extends CachingAssetBundle {
  int calls = 0;
  bool fail = false;
  @override
  Future<ByteData> load(String key) async {
    calls++;
    if (fail) throw const FormatException('Fixture unavailable');
    return ByteData.sublistView(
      File('assets/data/contactless/catalog.bin').readAsBytesSync(),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final all = _catalog();
  final small = ContactlessCatalog(
    all.lines
        .where((l) => ['긴자선', '히비야선', '마루노우치선', '시즈오카시미즈선'].contains(l.name))
        .toList(),
    attribution: all.attribution,
    releaseReviewPending: true,
  );
  if (preview) {
    setUpAll(() async {
      for (final font in {
        'ContactlessPreview': 'C:/Windows/Fonts/malgun.ttf',
        'ContactlessJapanese': 'C:/Windows/Fonts/meiryo.ttc',
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
  test(
    'snapshot preserves IDs, archive, five decisions, and 42 condition records',
    () {
      expect(all.lines.length, 596);
      final visible = all.search('', null);
      expect(visible.length, 595);
      for (final entry in {
        'supported': 176,
        'partial': 42,
        'unsupported': 125,
        'inferred': 235,
        'unknown': 17,
      }.entries) {
        expect(visible.where((l) => l.status == entry.key).length, entry.value);
      }
      expect(all.lines.where((l) => l.connectionOnly).length, 22);
      expect(
        all.lines.where((l) => l.records('stations').isNotEmpty).length,
        42,
      );
      expect(all.releaseReviewPending, isTrue);
      expect(all.lines.map((l) => l.id).toSet().length, 596);
    },
  );
  test(
    'operators sort by verified ridership, preserve every group and region',
    () {
      List<ContactlessLine> ordered(List<ContactlessLine> lines) {
        final groups = <String, ContactlessLine>{};
        for (final line in lines) {
          groups.putIfAbsent(line.operatorId, () => line);
        }
        return groups.values.toList()..sort(compareContactlessOperators);
      }

      final nationwide = ordered(all.search('', null));
      expect(nationwide.length, 176);
      expect(nationwide.take(6).map((l) => l.operatorName), [
        'JR 동일본',
        '도쿄메트로',
        'JR 서일본',
        '도큐 전철',
        '도쿄도 교통국',
        '오사카 메트로',
      ]);
      expect(nationwide.first.operatorAnnualPassengersThousand, 5697444);
      expect(
        nationwide
            .where((l) => l.operatorAnnualPassengersThousand == null)
            .map((l) => l.operatorName),
        ['고베 미래도시기구'],
      );
      expect(
        nationwide.indexWhere((l) => l.operatorName == '도쿄메트로'),
        lessThan(nationwide.indexWhere((l) => l.operatorName.contains('이시카와'))),
      );
      expect(
        nationwide.indexWhere((l) => l.operatorName == '오사카 메트로'),
        lessThan(nationwide.indexWhere((l) => l.operatorName.contains('이와테'))),
      );
      final kansai = ordered(all.search('', 'kansai'));
      expect(kansai.take(3).map((l) => l.operatorName), [
        'JR 서일본',
        '오사카 메트로',
        '한큐 전철',
      ]);
      expect(
        ordered(nationwide.reversed.toList()).map((l) => l.operatorId),
        nationwide.map((l) => l.operatorId),
      );
      final unknown = ContactlessLine({
        ...nationwide.first.data,
        'operatorId': 'unknown',
        'operator': '가나다',
        'operatorAnnualPassengersThousand': null,
      });
      final zero = ContactlessLine({
        ...unknown.data,
        'operatorId': 'zero',
        'operatorAnnualPassengersThousand': 0,
      });
      expect(compareContactlessOperators(zero, unknown), lessThan(0));
      final tie = ContactlessLine({...unknown.data, 'operatorId': 'zzz'});
      expect(compareContactlessOperators(unknown, tie), lessThan(0));
      final named = ContactlessLine({...unknown.data, 'operator': '나다라'});
      expect(compareContactlessOperators(unknown, named), lessThan(0));
    },
  );
  test(
    'names, companies, Japanese, initials, regions, and archived search',
    () {
      expect(all.search('히비야', null).single.name, '히비야선');
      expect(all.search('日比谷', null).single.name, '히비야선');
      expect(all.search('도쿄메트로', null).length, greaterThan(3));
      expect(all.search('ㅎㅂㅇ', null).any((l) => l.name == '히비야선'), isTrue);
      expect(all.search('히비야', 'kansai'), isEmpty);
      expect(all.search('히비야가없는이름', null), isEmpty);
      expect(all.search('루모이선', null), isEmpty);
      expect(all.search('스', null).length, lessThan(100));
    },
  );
  test(
    'single connection never claims internal travel, unsupported never has ratio',
    () {
      for (final l in all.lines.where((l) => l.connectionOnly)) {
        expect(l.summaryLabel, '대상 역');
        expect(l.summaryValue, '1곳');
      }
      for (final l in all.lines.where(
        (l) => ['unsupported', 'inferred', 'unknown'].contains(l.status),
      )) {
        expect(l.summaryValue, isNot(contains('/')));
      }
      final l = ContactlessLine({
        ...all.lines.first.data,
        'status': 'future-value',
      });
      expect(l.label, '정보 미확인');
    },
  );
  test(
    'direction and brand unknown fields retained, URL actions absent from payload',
    () {
      final lines = all.lines.where((l) => l.status == 'partial');
      expect(
        lines.any(
          (l) => l
              .records('stations')
              .any(
                (s) => (s['gates'] as List).any(
                  (g) => g['direction'] == 'entry_only',
                ),
              ),
        ),
        isTrue,
      );
      expect(
        lines.any(
          (l) => l
              .records('stations')
              .any(
                (s) => (s['gates'] as List).any(
                  (g) => g['direction'] == 'exit_only',
                ),
              ),
        ),
        isTrue,
      );
      expect(lines.every((l) => l.data['mobileBrands'] == null), isTrue);
      expect(
        all.lines.every(
          (l) => l.records('sources').every((s) => !s.containsKey('url')),
        ),
        isTrue,
      );
      expect(all.attribution, contains('CC BY 4.0'));
    },
  );
  test('repository caches shared read and failed read can retry', () async {
    final b = _Bundle();
    final r = ContactlessRepository(bundle: b);
    final a = r.load();
    expect(identical(a, r.load()), isTrue);
    expect((await a).lines.length, 596);
    expect(b.calls, 1);
    final failed = _Bundle()..fail = true;
    final retry = ContactlessRepository(bundle: failed);
    await expectLater(retry.load(), throwsFormatException);
    failed.fail = false;
    expect((await retry.load()).lines.length, 596);
    expect(failed.calls, 2);
  });
  test(
    'registered root asset loads and cache is shared across repositories',
    () async {
      final a = ContactlessRepository().load();
      final b = ContactlessRepository().load();
      expect(identical(a, b), isTrue);
      expect((await a).search('', null).length, 595);
    },
  );
  testWidgets(
    'companies start collapsed, search auto-opens, clear restores manual state',
    (tester) async {
      await _pump(tester, ContactlessPage(load: () => Future.value(small)));
      expect(find.text('히비야선'), findsNothing);
      expect(find.byType(ContactlessBadge), findsNothing);
      await tester.enterText(find.byType(TextField), '히비야');
      await tester.pumpAndSettle();
      expect(find.text('히비야선'), findsOneWidget);
      await tester.tap(find.byTooltip('검색 지우기'));
      await tester.pumpAndSettle();
      expect(find.text('히비야선'), findsNothing);
      await tester.tap(find.text('도쿄메트로'));
      await tester.pumpAndSettle();
      expect(find.text('히비야선'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '긴자');
      await tester.pumpAndSettle();
      await tester.tap(find.text('도쿄메트로'));
      await tester.pumpAndSettle();
      expect(find.text('긴자선'), findsNothing);
      await tester.tap(find.byTooltip('검색 지우기'));
      await tester.pumpAndSettle();
      expect(find.text('히비야선'), findsOneWidget);
      await tester.tap(find.text('도쿄메트로'));
      await tester.pumpAndSettle();
      expect(find.text('히비야선'), findsNothing);
      await tester.enterText(find.byType(TextField), '시즈오카');
      await tester.pumpAndSettle();
      await tester.tap(find.text('시즈오카시미즈선'));
      await tester.pumpAndSettle();
      expect(find.text('이용 가능한 역'), findsOneWidget);
      expect(find.text('5 / 15'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '시즈오카',
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('real nationwide first company is major and collapsed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, ContactlessPage(load: () => Future.value(all)));
    final cards = tester.widgetList<Card>(find.byType(Card)).toList();
    expect(
      cards.first.key,
      const ValueKey('company-operator-d69d6dd794dbc64b'),
    );
    expect(find.byType(ContactlessBadge), findsNothing);
    if (preview) await _capture(tester, 'nationwide-light');
    await tester.tap(find.text('도쿄메트로'));
    await tester.pumpAndSettle();
    if (preview) await _capture(tester, 'nationwide-expanded-light');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'B layout has left rail, borderless 14dp cards and compact badges',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pump(tester, ContactlessPage(load: () => Future.value(small)));
      final rail = find.byKey(const ValueKey('contactless-region-rail'));
      final companies = find.byKey(const ValueKey('contactless-companies'));
      expect(tester.getSize(rail).width, 76);
      expect(tester.getRect(rail).right, tester.getRect(companies).left);
      expect(find.text('어느 노선을 이용하나요?'), findsNothing);
      final closed = tester.widget<Card>(find.byType(Card).first);
      final shape = closed.shape! as RoundedRectangleBorder;
      expect(shape.side, BorderSide.none);
      expect(shape.borderRadius, BorderRadius.circular(14));
      expect(closed.color, Colors.white);
      await tester.tap(find.text('도쿄메트로'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Card>(find.byType(Card).first).color,
        const Color(0xFFDDEFFB),
      );
      expect(
        tester
            .widget<ContactlessBadge>(find.byType(ContactlessBadge).first)
            .compact,
        isTrue,
      );
      expect(
        tester.getSize(find.byType(ContactlessBadge).first).height,
        lessThan(32),
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'large company remains lazy and detail return restores list offset',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pump(tester, ContactlessPage(load: () => Future.value(all)));
      await tester.tap(find.text('JR 동일본'));
      await tester.pumpAndSettle();
      expect(find.byType(ContactlessBadge).evaluate().length, lessThan(69));
      final jr =
          all.search('', null).where((l) => l.operatorName == 'JR 동일본').toList()
            ..sort((a, b) => a.name.compareTo(b.name));
      final last = find.byKey(ValueKey('line-${jr.last.id}'));
      final scrollable = find.descendant(
        of: find.byKey(const ValueKey('contactless-companies')),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        last,
        400,
        scrollable: scrollable,
        maxScrolls: 30,
      );
      await tester.pumpAndSettle();
      final offset = tester.state<ScrollableState>(scrollable).position.pixels;
      expect(offset, greaterThan(1000));
      await tester.tap(last);
      await tester.pumpAndSettle();
      expect(find.text('노선 상세'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(tester.state<ScrollableState>(scrollable).position.pixels, offset);
      expect(last.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final params in [
    (const Size(320, 740), 2.0),
    (const Size(844, 390), 1.0),
  ]) {
    testWidgets(
      'left rail reaches final region independently size=${params.$1}',
      (tester) async {
        tester.view.physicalSize = params.$1;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        await _pump(
          tester,
          ContactlessPage(load: () => Future.value(small)),
          scale: params.$2,
        );
        final railScrollable = find.descendant(
          of: find.byKey(const ValueKey('contactless-region-rail')),
          matching: find.byType(Scrollable),
        );
        final companies = find.byKey(const ValueKey('contactless-companies'));
        final companyPosition = tester.getTopLeft(find.text('도쿄메트로'));
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('region-okinawa')),
          180,
          scrollable: railScrollable,
        );
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.text('도쿄메트로')), companyPosition);
        final last = find.byKey(const ValueKey('region-okinawa'));
        expect(last.hitTestable(), findsOneWidget);
        expect(tester.getSize(last).height, greaterThanOrEqualTo(48));
        await tester.tap(last);
        await tester.pumpAndSettle();
        expect(
          tester.getSemantics(last).flagsCollection.isSelected,
          ui.Tristate.isTrue,
        );
        expect(
          find.descendant(of: companies, matching: find.text('일치하는 노선이 없어요.')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }
  testWidgets('region change and detail return preserve expanded company', (
    tester,
  ) async {
    await _pump(tester, ContactlessPage(load: () => Future.value(small)));
    await tester.tap(find.text('간토'));
    await tester.pumpAndSettle();
    expect(find.byType(ContactlessBadge), findsNothing);
    await tester.tap(find.text('도쿄메트로'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('긴자선'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('긴자선'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('region-kanto')))
          .flagsCollection
          .isSelected,
      ui.Tristate.isTrue,
    );
    await tester.tap(find.text('전국'));
    await tester.pumpAndSettle();
    expect(find.text('긴자선'), findsOneWidget);
    await _pump(tester, const SizedBox());
    await _pump(tester, ContactlessPage(load: () => Future.value(small)));
    expect(find.byType(ContactlessBadge), findsNothing);
  });
  for (final status in [
    'supported',
    'partial',
    'unsupported',
    'inferred',
    'unknown',
  ]) {
    testWidgets(
      'detail keeps status $status without inventing station totals',
      (tester) async {
        final line = all.lines.firstWhere(
          (l) => !l.archived && l.status == status,
        );
        await _pump(
          tester,
          ContactlessDetailPage(line: line, attribution: all.attribution),
        );
        expect(find.text(line.label), findsWidgets);
        expect(find.text(line.summaryValue), findsWidgets);
        if (['unsupported', 'inferred', 'unknown'].contains(status)) {
          expect(find.text('0 / 0'), findsNothing);
          expect(find.text('역별 지원 여부'), findsNothing);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'single connection displays explicit no-internal-journey caveat',
    (tester) async {
      final line = all.lines.firstWhere((l) => l.connectionOnly);
      await _pump(
        tester,
        ContactlessDetailPage(line: line, attribution: all.attribution),
      );
      expect(find.text('1곳'), findsOneWidget);
      expect(find.textContaining('이 노선 내부 구간의 이용 가능을 뜻하지 않아요'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('read failure retries, search empty distinct from unsupported', (
    tester,
  ) async {
    int attempts = 0;
    await _pump(
      tester,
      ContactlessPage(
        load: () => ++attempts == 1
            ? Future.error(StateError('test'))
            : Future.value(small),
      ),
    );
    expect(find.text('노선 정보를 불러오지 못했어요.'), findsOneWidget);
    await tester.tap(find.text('다시 불러오기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '아무노선없음');
    await tester.pumpAndSettle();
    expect(find.text('일치하는 노선이 없어요.'), findsOneWidget);
    expect(find.text('미지원'), findsNothing);
  });
  testWidgets(
    'evidence is collapsed, inline expands and closes without links',
    (tester) async {
      final l = all.lines.firstWhere((l) => l.name == '시즈오카시미즈선');
      await _pump(
        tester,
        ContactlessDetailPage(line: l, attribution: all.attribution),
      );
      await tester.scrollUntilVisible(
        find.text('판단 근거 및 출처'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(l.data['reason'] as String).hitTestable(), findsNothing);
      await tester.tap(find.text('판단 근거 및 출처'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(l.data['reason'] as String),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text(l.data['reason'] as String).hitTestable(),
        findsOneWidget,
      );
      expect(find.textContaining('자료 확인일'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
  for (final dark in [false, true]) {
    for (final params in [
      (const Size(390, 844), 1.0),
      (const Size(320, 740), 2.0),
      (const Size(844, 390), 1.0),
    ]) {
      testWidgets(
        'responsive list dark=$dark size=${params.$1} scale=${params.$2}',
        (tester) async {
          tester.view.physicalSize = params.$1;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await _pump(
            tester,
            ContactlessPage(load: () => Future.value(small)),
            dark: dark,
            scale: params.$2,
          );
          expect(tester.takeException(), isNull);
          expect(find.byType(ContactlessBadge), findsNothing);
          if (preview && params.$2 == 1 && params.$1.width == 390) {
            await _capture(tester, 'collapsed-${dark ? 'dark' : 'light'}');
          }
          await tester.tap(find.text('도쿄메트로'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (params.$2 == 1 && params.$1.width == 390) {
            final badge = tester.getSize(find.byType(ContactlessBadge).first);
            expect(badge.width, greaterThan(50));
            expect(badge.height, lessThan(50));
          }
          if (preview && params.$1.width != 844) {
            await _capture(
              tester,
              'list-${params.$1.width.toInt()}-${dark ? 'dark' : 'light'}',
            );
          }
        },
      );
      testWidgets(
        'responsive detail dark=$dark size=${params.$1} scale=${params.$2}',
        (tester) async {
          tester.view.physicalSize = params.$1;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final l = all.lines.firstWhere((l) => l.name == '시즈오카시미즈선');
          await _pump(
            tester,
            ContactlessDetailPage(line: l, attribution: all.attribution),
            dark: dark,
            scale: params.$2,
          );
          expect(tester.takeException(), isNull);
          if (preview && params.$2 == 1 && params.$1.width == 390) {
            await _capture(tester, 'detail-${dark ? 'dark' : 'light'}');
          }
        },
      );
    }
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget page, {
  bool dark = false,
  double scale = 1,
}) async {
  final theme = dark ? AppTheme.dark : AppTheme.light;
  await tester.pumpWidget(
    MaterialApp(
      theme: preview
          ? theme.copyWith(
              textTheme: theme.textTheme.apply(
                fontFamily: 'ContactlessPreview',
                fontFamilyFallback: const ['ContactlessJapanese'],
              ),
              primaryTextTheme: theme.primaryTextTheme.apply(
                fontFamily: 'ContactlessPreview',
                fontFamilyFallback: const ['ContactlessJapanese'],
              ),
              appBarTheme: theme.appBarTheme.copyWith(
                titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
                  fontFamily: 'ContactlessPreview',
                  fontFamilyFallback: const ['ContactlessJapanese'],
                ),
              ),
            )
          : theme,
      home: MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: RepaintBoundary(
          key: const ValueKey('contactless-preview'),
          child: page,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('contactless-preview')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory('.private-backups/contactless-soft-layer-2026-11-01');
    await dir.create(recursive: true);
    await File(
      '${dir.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
