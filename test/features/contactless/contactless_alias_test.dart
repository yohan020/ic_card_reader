import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/contactless/domain/contactless_alias.dart';
import 'package:ic_card_reader/src/features/contactless/domain/contactless_catalog.dart';
import 'package:ic_card_reader/src/features/contactless/presentation/contactless_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final catalog = ContactlessCatalog.fromJson(
    jsonDecode(
          utf8.decode(
            gzip.decode(
              File('assets/data/contactless/catalog.bin').readAsBytesSync(),
            ),
          ),
        )
        as Map<String, dynamic>,
  );
  const preview = bool.fromEnvironment('ALIAS_PREVIEW');
  if (preview) {
    setUpAll(() async {
      for (final font in {
        'AliasPreview': 'C:/Windows/Fonts/malgun.ttf',
        'AliasJapanese': 'C:/Windows/Fonts/meiryo.ttc',
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
  final skytree = catalog.lines.firstWhere((l) => l.nameJa == '伊勢崎線');

  test(
    'company aliases display and search without renaming stable identities',
    () {
      final toei = catalog.lines.firstWhere((l) => l.operatorName == '도쿄도 교통국');
      expect(toei.operatorDisplayName, '도쿄도 교통국(도에이)');
      expect(toei.matches('도에이'), isTrue);
      expect(toei.matches('都営'), isTrue);
      expect(toei.operatorName, '도쿄도 교통국');
      final metro = catalog.lines.firstWhere((l) => l.operatorName == '도쿄메트로');
      expect(metro.operatorDisplayName, '도쿄메트로');
    },
  );

  test(
    'whole and partial aliases stay distinct and partial search finds only parent',
    () {
      final noda = catalog.lines.firstWhere((l) => l.nameJa == '野田線');
      expect(noda.displayName, contains('도부 아반파크라인'));
      expect(noda.displayName, isNot(contains('일부:')));
      expect(skytree.displayName, contains('일부: 도부 스카이트리라인'));
      expect(skytree.lineAliases.single.section, '아사쿠사·오시아게~도부도부쓰코엔');
      expect(catalog.search('스카이트리', null).map((l) => l.id), [skytree.id]);
      expect(skytree.matches('東武スカイツリーライン'), isTrue);
      expect(skytree.matches('ㄷㅂㅅㅋㅇㅌㄹ'), isTrue);
      expect(skytree.name, isNot(contains('스카이트리')));
    },
  );

  test(
    'multi-route, historical, train and unverified observations are not appended',
    () {
      for (final l in catalog.lines) {
        expect(
          l.lineAliases.any(
            (a) => [
              '上野東京ライン',
              '湘南新宿ライン',
              'JR神戸線',
              '新京成線',
              '汐見橋線',
              '犬吠崖っぷちライン',
              'こあら号',
            ].contains(a.ja),
          ),
          isFalse,
        );
      }
      expect(contactlessLineAliases('missing'), isEmpty);
      expect(contactlessOperatorAliases('missing'), isEmpty);
      final kyoto = catalog.lines.firstWhere(
        (l) => l.nameJa == '東海道線' && l.operatorName == 'JR 서일본',
      );
      expect(
        kyoto.lineAliases.where((a) => a.ja == 'JR京都線').single.section,
        '교토~오사카',
      );
    },
  );

  test(
    'alias overlay never mutates payload, status, source or sorting names',
    () {
      for (final l in catalog.lines) {
        final before = jsonEncode(l.data);
        l.displayName;
        l.operatorDisplayName;
        l.matches('도에이');
        expect(jsonEncode(l.data), before);
        expect(l.status, l.data['status']);
      }
      expect(
        withContactlessAliases('도쿄 메트로', const [
          ContactlessAlias(ko: '도쿄 메트로', ja: '東京メトロ', label: '도쿄 메트로'),
        ]),
        '도쿄 메트로',
      );
    },
  );

  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('partial alias list and detail dark=$dark scale=$scale', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        Future<void> pump(Widget child) async {
          final theme = dark ? AppTheme.dark : AppTheme.light;
          await tester.pumpWidget(
            MaterialApp(
              key: ValueKey(child.runtimeType),
              theme: preview
                  ? theme.copyWith(
                      textTheme: theme.textTheme.apply(
                        fontFamily: 'AliasPreview',
                        fontFamilyFallback: const ['AliasJapanese'],
                      ),
                      primaryTextTheme: theme.primaryTextTheme.apply(
                        fontFamily: 'AliasPreview',
                        fontFamilyFallback: const ['AliasJapanese'],
                      ),
                      appBarTheme: theme.appBarTheme.copyWith(
                        titleTextStyle: theme.appBarTheme.titleTextStyle
                            ?.copyWith(
                              fontFamily: 'AliasPreview',
                              fontFamilyFallback: const ['AliasJapanese'],
                            ),
                      ),
                    )
                  : theme,
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: RepaintBoundary(
                  key: const ValueKey('alias-preview'),
                  child: child,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        Future<void> capture(String name) async {
          if (!preview) return;
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('alias-preview')),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 1);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final dir = Directory(
              '.private-backups/contactless-aliases-2026-11-02',
            );
            await dir.create(recursive: true);
            await File(
              '${dir.path}/$name-$dark-$scale.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }

        await pump(
          ContactlessPage(
            load: () async => ContactlessCatalog(
              [skytree],
              attribution: catalog.attribution,
              releaseReviewPending: true,
            ),
          ),
        );
        await tester.tap(find.byKey(ValueKey('company-${skytree.operatorId}')));
        await tester.pumpAndSettle();
        expect(find.text(skytree.displayName), findsOneWidget);
        expect(tester.takeException(), isNull);
        await capture('list');
        await tester.tap(find.text(skytree.displayName));
        await tester.pumpAndSettle();
        expect(find.textContaining('アサクサ'), findsNothing);
        expect(find.textContaining('아사쿠사·오시아게~도부도부쓰코엔'), findsOneWidget);
        expect(find.text(skytree.label), findsWidgets);
        expect(tester.takeException(), isNull);
        if (preview) {
          // Detail navigation has its own overlay; capture the actual root view.
          await pump(
            ContactlessDetailPage(
              line: skytree,
              attribution: catalog.attribution,
            ),
          );
          await capture('detail');
        }
      });
    }
  }
}
