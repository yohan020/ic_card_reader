import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/core/localization/app_strings.dart';
import 'package:ic_card_reader/src/features/contactless/domain/contactless_catalog.dart';
import 'package:ic_card_reader/src/features/contactless/domain/contactless_english_details.dart';
import 'package:ic_card_reader/src/features/contactless/domain/contactless_english_names.dart';
import 'package:ic_card_reader/src/features/contactless/domain/contactless_station_name.dart';
import 'package:ic_card_reader/src/features/contactless/presentation/contactless_page.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_name_display.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const preview = bool.fromEnvironment('STATION_NAME_PREVIEW');
  if (preview) {
    setUpAll(() async {
      for (final font in {
        'StationPreview': 'C:/Windows/Fonts/malgun.ttf',
        'StationJapanese': 'C:/Windows/Fonts/meiryo.ttc',
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
  final audit =
      jsonDecode(
            File(
              'docs/release/contactless-station-name-mapping-2026-11-02.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
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
  final line = catalog.lines.firstWhere((l) => l.nameJa == '犬山線');
  final station = line.records('stations').firstWhere((s) => s['name'] == '犬山');

  test(
    'every bundled contactless line and operator has an English display name and notes',
    () {
      final untranslated = RegExp(r'[가-힣ぁ-んァ-ヶ一-龯]');
      for (final item in catalog.lines) {
        expect(contactlessEnglishLines[item.id], isNotNull, reason: item.id);
        expect(
          contactlessEnglishOperators[item.operatorId],
          isNotNull,
          reason: item.operatorId,
        );
        expect(item.nameFor(english: true), isNot(contains(untranslated)));
        expect(
          item.operatorNameFor(english: true),
          isNot(contains(untranslated)),
        );
        for (final note in item.strings('conditions')) {
          expect(
            contactlessEnglishCondition(note),
            isNot('Check the operator’s guide for this condition.'),
          );
        }
      }
      expect(
        catalog
            .search('Ginza Line', 'kanto')
            .any((line) => line.nameJa == '銀座線'),
        isTrue,
      );
      expect(
        catalog
            .search('Meitetsu', 'chubu')
            .any((line) => line.id == 'N02-0714c9f60c17'),
        isTrue,
      );
    },
  );

  testWidgets('English contactless guide, region, operator, line and details', (
    tester,
  ) async {
    final one = ContactlessLine({
      ...line.data,
      'stations': [station],
    });
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: ContactlessPage(
          load: () async => ContactlessCatalog(
            [one],
            attribution: catalog.attribution,
            releaseReviewPending: true,
          ),
          stationNameDisplayMode: StationNameDisplayMode.japaneseEnglish,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chubu'), findsOneWidget);
    expect(find.text('Routes by operator'), findsOneWidget);
    await tester.tap(find.byTooltip('Tap-to-ride guide'));
    await tester.pumpAndSettle();
    expect(find.text('Got it'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nagoya Railroad (Meitetsu)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inuyama Line'));
    await tester.pumpAndSettle();
    expect(find.text('Route details'), findsOneWidget);
    expect(find.text('Inuyama Line'), findsOneWidget);
    final scroll = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.byKey(ValueKey('contactless-station-${station['id']}')),
      170,
      scrollable: scroll,
    );
    expect(find.text('犬山 (Inuyama)'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Evidence and sources'),
      170,
      scrollable: scroll,
    );
    await tester.ensureVisible(find.text('Evidence and sources'));
    await tester.tap(find.text('Evidence and sources'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('The official list of eligible stations'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  String display(Map<String, dynamic> row, StationNameDisplayMode mode) =>
      displayContactlessStationName(
        lineId: row['lineId'] as String,
        stationId: row['stationId'] as String,
        japanese: row['ja'] as String,
        mode: mode,
      );

  test('all891 mapped rows follow Japanese, Korean and both modes', () {
    for (final row
        in (audit['mappings'] as List).cast<Map<String, dynamic>>()) {
      expect(display(row, StationNameDisplayMode.japanese), row['ja']);
      expect(display(row, StationNameDisplayMode.korean), row['ko']);
      expect(
        display(row, StationNameDisplayMode.both),
        '${row['ko']} (${row['ja']})',
      );
    }
  });
  test('all28 unresolved rows and changed identity safely retain Japanese', () {
    for (final row
        in (audit['unresolved'] as List).cast<Map<String, dynamic>>()) {
      for (final mode in [
        StationNameDisplayMode.japanese,
        StationNameDisplayMode.korean,
        StationNameDisplayMode.both,
      ]) {
        expect(display(row, mode), row['ja']);
      }
    }
    expect(
      displayContactlessStationName(
        lineId: line.id,
        stationId: station['id'] as String,
        japanese: '改名駅',
        mode: StationNameDisplayMode.korean,
      ),
      '改名駅',
    );
    expect(
      displayContactlessStationName(
        lineId: 'other',
        stationId: station['id'] as String,
        japanese: '犬山',
        mode: StationNameDisplayMode.korean,
      ),
      '犬山',
    );
  });

  for (final mode in StationNameDisplayMode.values) {
    testWidgets('page forwards $mode to detail and gate station labels', (
      tester,
    ) async {
      final one = ContactlessLine({
        ...line.data,
        'stations': [station],
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ContactlessPage(
            stationNameDisplayMode: mode,
            load: () async => ContactlessCatalog(
              [one],
              attribution: catalog.attribution,
              releaseReviewPending: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('company-${one.operatorId}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('line-${one.id}')));
      await tester.pumpAndSettle();
      final detail = tester.widget<ContactlessDetailPage>(
        find.byType(ContactlessDetailPage),
      );
      expect(detail.stationNameDisplayMode, mode);
      final expected = switch (mode) {
        StationNameDisplayMode.japanese => '犬山',
        StationNameDisplayMode.english => 'Inuyama',
        StationNameDisplayMode.korean => '이누야마',
        StationNameDisplayMode.both => '이누야마 (犬山)',
        StationNameDisplayMode.japaneseEnglish => '犬山 (Inuyama)',
      };
      final list = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text(expected).first,
        180,
        scrollable: list,
      );
      expect(find.text(expected), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('北改札口 · 입·퇴장'),
        160,
        scrollable: list,
      );
      expect(find.text(expected), findsWidgets);
      expect(find.text('北改札口 · 입·퇴장'), findsOneWidget);
      expect(find.text('南改札口 · 입·퇴장'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final dark in [false, true]) {
    testWidgets('both mode wraps long station names at2x dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final airportLine = catalog.lines.firstWhere(
        (l) => l.nameJa == '空港線' && l.operatorName == '메이테쓰',
      );
      final airport = airportLine
          .records('stations')
          .firstWhere((s) => s['name'] == '中部国際空港');
      final limited = ContactlessLine({
        ...airportLine.data,
        'stations': [airport],
      });
      final theme = dark ? AppTheme.dark : AppTheme.light;
      await tester.pumpWidget(
        MaterialApp(
          theme: preview
              ? theme.copyWith(
                  textTheme: theme.textTheme.apply(
                    fontFamily: 'StationPreview',
                    fontFamilyFallback: const ['StationJapanese'],
                  ),
                  appBarTheme: theme.appBarTheme.copyWith(
                    titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
                      fontFamily: 'StationPreview',
                      fontFamilyFallback: const ['StationJapanese'],
                    ),
                  ),
                )
              : theme,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: RepaintBoundary(
              key: const ValueKey('station-name-preview'),
              child: ContactlessDetailPage(
                line: limited,
                attribution: catalog.attribution,
                stationNameDisplayMode: StationNameDisplayMode.both,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('contactless-station-${airport['id']}')),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(
        tester.element(
          find.byKey(ValueKey('contactless-station-${airport['id']}')),
        ),
        alignment: 0.2,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byKey(ValueKey('contactless-station-${airport['id']}')),
          matching: find.text('주부코쿠사이쿠코 (中部国際空港)'),
        ),
        findsOneWidget,
      );
      final rect = tester.getRect(
        find.byKey(ValueKey('contactless-station-${airport['id']}')),
      );
      expect(rect.top, greaterThanOrEqualTo(56));
      expect(rect.bottom, lessThanOrEqualTo(740));
      if (preview) {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('station-name-preview')),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final dir = Directory(
            '.private-backups/contactless-station-names-2026-11-02',
          );
          await dir.create(recursive: true);
          await File(
            '${dir.path}/both-2x-$dark.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
}
