import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/coin_locker/domain/coin_locker_catalog.dart';
import 'package:ic_card_reader/src/features/coin_locker/data/coin_locker_repository.dart';
import 'package:ic_card_reader/src/features/coin_locker/data/coin_locker_link_opener.dart';
import 'package:ic_card_reader/src/features/coin_locker/presentation/coin_locker_page.dart';

Map<String, dynamic> jsonFixture() =>
    jsonDecode(File('assets/data/coin_locker/catalog.json').readAsStringSync())
        as Map<String, dynamic>;
CoinLockerCatalog fixture() => CoinLockerCatalog.fromJson(jsonFixture());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const preview = bool.fromEnvironment('LOCKER_PREVIEW');
  if (preview) {
    setUpAll(() async {
      for (final font in {
        'LockerPreview': 'C:/Windows/Fonts/malgun.ttf',
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
    'expanded catalog preserves seed URLs and includes all verified survey URLs',
    () {
      final catalog = fixture();
      expect(catalog.places.length, 1000);
      expect(catalog.regions.length, 10);
      final links = catalog.places
          .expand((p) => p.sources.expand((s) => s.links))
          .toList();
      expect(links.length, 1950);
      expect(links.map((l) => l.uri).toSet().length, 1934);
      final research =
          jsonDecode(
                File(
                  'docs/research/coin-locker-links-2026-11-03/phase3-review.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      expect(
        links.map((l) => l.uri.toString()).toSet(),
        containsAll((research['links'] as List).map((l) => l['url'])),
      );
      expect(
        links.where((l) => l.caution != null).length,
        greaterThanOrEqualTo(5),
      );
      final arashi = catalog.search('사가아라시야마').single;
      expect(arashi.sources.map((s) => s.id), [
        'miitsuketa',
        'shiori',
        'guide',
      ]);
      expect(arashi.sources[1].links.length, 3);
      expect(
        catalog.search('교토', region: '교토부').map((s) => s.id),
        contains('kyoto'),
      );
      expect(catalog.search('', region: '교토부').length, 62);
      expect(catalog.search('嵐山').single.id, 'arashiyama');
      expect(catalog.search('우메다역').single.id, 'osaka_umeda');
      expect(catalog.search('역'), isEmpty);
      expect(catalog.search('가짜역'), isEmpty);
      expect(catalog.search('벳푸', region: '오이타현').single.region, '오이타현');
      expect(catalog.search('겐초마에', region: '오키나와현').single.region, '오키나와현');
      expect(catalog.search('교바시', region: '오사카부').single.region, '오사카부');
    },
  );

  test('rejects schemes, lookalikes, identifiers, queries and fragments', () {
    for (final address in [
      'http://coin-locker.net/ueno/',
      'https://coin-locker.net.evil.test/ueno/',
      'https://user@coin-locker.net/ueno/',
      'https://coin-locker.net:8443/ueno/',
      'https://coin-locker.net/ueno/?idm=secret',
      'https://coin-locker.net/ueno/#card',
      'file:///tmp/page',
      'intent://coin-locker.net/ueno/',
    ]) {
      expect(
        isAllowedCoinLockerUri(Uri.parse(address)),
        false,
        reason: address,
      );
    }
    expect(
      isAllowedCoinLockerUri(
        Uri.parse('https://coin-locker.net/ueno/'),
        sourceId: 'shiori',
      ),
      false,
    );
    final data = jsonFixture();
    data['places'][0]['sources'][0]['links'][0]['url'] = 'https://example.com/';
    expect(() => CoinLockerCatalog.fromJson(data), throwsFormatException);
    final duplicates = jsonFixture();
    duplicates['places'].add(duplicates['places'][0]);
    expect(() => CoinLockerCatalog.fromJson(duplicates), throwsFormatException);
  });

  test(
    'one reviewed area article may cover distinct places, not duplicate within a place',
    () {
      final data = jsonFixture();
      final copy =
          jsonDecode(jsonEncode(data['places'][0])) as Map<String, dynamic>;
      copy['id'] = 'shared-article-distinct-place';
      data['places'].add(copy);
      expect(() => CoinLockerCatalog.fromJson(data), returnsNormally);
      final duplicate = jsonFixture();
      final links = duplicate['places'][0]['sources'][0]['links'] as List;
      links.add(links.first);
      expect(
        () => CoinLockerCatalog.fromJson(duplicate),
        throwsFormatException,
      );
    },
  );

  test(
    'all app links have accepted source assignments and uncertain links stay excluded',
    () {
      final provenance =
          jsonDecode(
                File(
                  'docs/research/coin-locker-links-2026-11-03/app-link-provenance.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final accepted = (provenance['assignments'] as List)
          .map((a) => '${a['place_id']}|${a['site']}|${a['url']}')
          .toSet();
      final catalog = fixture();
      for (final p in catalog.places) {
        expect(catalog.search(p.nameJa).map((r) => r.id), contains(p.id));
        expect(catalog.search(p.nameKo).map((r) => r.id), contains(p.id));
        for (final source in p.sources) {
          for (final link in source.links) {
            expect(accepted, contains('${p.id}|${source.id}|${link.uri}'));
          }
        }
      }
      expect(
        catalog.places
            .expand((p) => p.sources.expand((s) => s.links))
            .any(
              (l) => l.uri.toString() == 'https://coin-locker.net/toyotashi/',
            ),
        isFalse,
      );
      expect(
        catalog.search('기온시조').map((p) => p.id),
        contains('kyoto_kawaramachi'),
      );
      expect(
        catalog.search('西高島平').map((p) => p.nameKo),
        contains('니시타카시마다이라'),
      );
    },
  );

  test('repository shares in-flight work and retries an asset error', () async {
    final bundle = _Bundle();
    final repo = CoinLockerRepository(bundle: bundle);
    final first = repo.load();
    expect(identical(first, repo.load()), isTrue);
    expect((await first).places.length, 1000);
    expect(bundle.reads, 1);
    final broken = _Bundle()..fail = true;
    final retry = CoinLockerRepository(bundle: broken);
    await expectLater(retry.load(), throwsStateError);
    broken.fail = false;
    expect((await retry.load()).places.length, 1000);
    expect(broken.reads, 2);
  });

  test(
    'launcher sends only the fixed public URL, handles rejection and missing platform',
    () async {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(CoinLockerLinkOpener.channel, (
        call,
      ) async {
        calls.add(call);
        return true;
      });
      const opener = CoinLockerLinkOpener();
      final uri = Uri.parse('https://coin-locker.net/ueno/');
      expect(await opener.open(uri), true);
      expect(calls.single.method, 'open');
      expect(calls.single.arguments, {'url': uri.toString()});
      expect(await opener.open(Uri.parse('https://example.com/')), false);
      expect(calls.length, 1);
      messenger.setMockMethodCallHandler(
        CoinLockerLinkOpener.channel,
        (_) async => throw PlatformException(code: 'UNAVAILABLE'),
      );
      expect(await opener.open(uri), false);
      messenger.setMockMethodCallHandler(CoinLockerLinkOpener.channel, null);
      expect(await opener.open(uri), false);
    },
  );

  for (final dark in [false, true]) {
    for (final spec in [
      (const Size(390, 844), 1.0),
      (const Size(375, 812), 1.0),
      (const Size(320, 740), 2.0),
      (const Size(844, 390), 1.0),
      (const Size(768, 1024), 1.0),
      (const Size(390, 844), 3.0),
    ]) {
      testWidgets(
        'B list and multi-link expanded dark=$dark size=${spec.$1} scale=${spec.$2}',
        (tester) async {
          tester.view.physicalSize = spec.$1;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final theme = dark ? AppTheme.dark : AppTheme.light;
          await tester.pumpWidget(
            MaterialApp(
              theme: preview
                  ? theme.copyWith(
                      textTheme: theme.textTheme.apply(
                        fontFamily: 'LockerPreview',
                      ),
                      appBarTheme: theme.appBarTheme.copyWith(
                        titleTextStyle: theme.appBarTheme.titleTextStyle
                            ?.copyWith(fontFamily: 'LockerPreview'),
                      ),
                    )
                  : theme,
              home: MediaQuery(
                data: MediaQueryData(
                  textScaler: TextScaler.linear(spec.$2),
                  disableAnimations: true,
                ),
                child: RepaintBoundary(
                  key: const ValueKey('locker-preview'),
                  child: CoinLockerPage(
                    load: () async => fixture(),
                    openLink: (_) async => true,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('코인락커 찾기'), findsOneWidget);
          expect(find.text('코인락커 시오리'), findsNothing);
          await tester.enterText(find.byType(TextField), '아라시야마');
          await tester.pumpAndSettle();
          final toggle = find.byKey(const ValueKey('locker-toggle-arashiyama'));
          await tester.ensureVisible(toggle);
          await tester.tap(toggle);
          await tester.pumpAndSettle();
          expect(find.text('코인락커 시오리'), findsOneWidget);
          expect(find.text('란덴 아라시야마'), findsOneWidget);
          expect(find.text('JR 사가아라시야마'), findsOneWidget);
          expect(find.byIcon(Icons.open_in_new), findsNWidgets(5));
          expect(tester.takeException(), isNull);
          if (preview && spec.$1.width == 390 && spec.$2 == 1) {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('locker-preview')),
            );
            await tester.runAsync(() async {
              final image = await boundary.toImage(pixelRatio: 1.5);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(
                'docs/design/coin-locker-2026-11-03/implementation-${dark ? 'dark' : 'light'}.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          await tester.ensureVisible(toggle);
          await tester.tap(toggle);
          await tester.pumpAndSettle();
          expect(find.text('코인락커 시오리'), findsNothing);
          await tester.enterText(find.byType(TextField), '없는역');
          await tester.pumpAndSettle();
          expect(find.textContaining('연결된 안내를 찾지 못했어요.'), findsOneWidget);
          await tester.enterText(find.byType(TextField), '嵐山');
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('locker-toggle-arashiyama')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'region selection stays collapsed and launcher failure can retry',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: CoinLockerPage(
            load: () async => fixture(),
            openLink: (_) async => ++calls > 1,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final kyoto = find.text('교토').first;
      await tester.ensureVisible(kyoto);
      await tester.tap(kyoto);
      await tester.pumpAndSettle();
      expect(find.text('교토의 역·공항'), findsOneWidget);
      expect(find.text('코인락커 시오리'), findsNothing);
      await tester.enterText(find.byType(TextField), '아라시야마');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('locker-toggle-arashiyama')));
      await tester.pumpAndSettle();
      final link = find.byKey(
        const ValueKey('locker-link-https://coin-locker.net/arashiyama/'),
      );
      await tester.ensureVisible(link);
      await tester.tap(link);
      await tester.pumpAndSettle();
      expect(find.text('다시 열기'), findsOneWidget);
      await tester.ensureVisible(find.text('다시 열기'));
      await tester.tap(find.text('다시 열기'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('다시 열기'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('launch is single-flight and handles page disposal', (
    tester,
  ) async {
    var calls = 0;
    final pending = Completer<bool>();
    await tester.pumpWidget(
      MaterialApp(
        home: CoinLockerPage(
          load: () async => fixture(),
          openLink: (_) {
            calls++;
            return pending.future;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '아라시야마');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('locker-toggle-arashiyama')));
    await tester.pumpAndSettle();
    final first = find.byKey(
      const ValueKey('locker-link-https://coin-locker.net/arashiyama/'),
    );
    await tester.ensureVisible(first);
    await tester.tap(first);
    await tester.pump();
    await tester.tap(first);
    await tester.pump();
    expect(calls, 1);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    pending.complete(false);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('load failure retains retry action', (tester) async {
    var count = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: CoinLockerPage(
          load: () async {
            if (++count == 1) throw StateError('test');
            return fixture();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('다시 불러오기'), findsOneWidget);
    await tester.tap(find.text('다시 불러오기'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _Bundle extends CachingAssetBundle {
  int reads = 0;
  bool fail = false;
  @override
  Future<ByteData> load(String key) async => throw UnimplementedError();
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    reads++;
    if (fail) throw StateError('test');
    return File(key).readAsString();
  }
}
