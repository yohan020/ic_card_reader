import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/l10n/app_localizations.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/coin_locker/domain/coin_locker_catalog.dart';
import 'package:ic_card_reader/src/features/coin_locker/presentation/coin_locker_page.dart';
import 'package:ic_card_reader/src/features/contactless/domain/contactless_catalog.dart';
import 'package:ic_card_reader/src/features/contactless/presentation/contactless_page.dart';
import 'package:ic_card_reader/src/features/station_maps/domain/station_map_catalog.dart';
import 'package:ic_card_reader/src/features/station_maps/presentation/station_map_page.dart';

void main() {
  final lockers = CoinLockerCatalog.fromJson(
    jsonDecode(File('assets/data/coin_locker/catalog.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  final maps = StationMapCatalog.fromJson(
    jsonDecode(File('assets/data/station_maps/catalog.json').readAsStringSync())
        as Map<String, dynamic>,
    lockers,
  );
  final contactless = ContactlessCatalog.fromJson(
    jsonDecode(
          utf8.decode(
            gzip.decode(
              File('assets/data/contactless/catalog.bin').readAsBytesSync(),
            ),
          ),
        )
        as Map<String, dynamic>,
  );
  for (final dark in [false, true]) {
    for (final kind in ['contactless', 'lockers', 'maps']) {
      testWidgets('$kind surfaces match approved tool contract dark=$dark', (
        tester,
      ) async {
        final page = switch (kind) {
          'contactless' => ContactlessPage(load: () async => contactless),
          'lockers' => CoinLockerPage(load: () async => lockers),
          _ => StationMapPage(load: () async => maps),
        };
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: page,
          ),
        );
        await tester.pumpAndSettle();
        final canvas = dark ? const Color(0xFF10171C) : const Color(0xFFF1F6FA);
        final rail = dark ? const Color(0xFF182229) : Colors.white;
        expect(
          tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
          canvas,
        );
        if (kind == 'contactless') {
          expect(
            tester
                .widget<Material>(
                  find.byKey(const ValueKey('contactless-region-rail')),
                )
                .color,
            rail,
          );
        } else {
          final key = const ValueKey('station-guide-region-background');
          await tester.ensureVisible(find.byKey(key));
          expect(tester.widget<ColoredBox>(find.byKey(key)).color, rail);
        }
        expect(tester.takeException(), isNull);
        // A shared color alone is insufficient: the rail must reach the
        // viewport edge/bottom rather than form an inset white rectangle.
        final regionFinder = find.byKey(
          ValueKey(
            kind == 'contactless'
                ? 'contactless-region-rail'
                : 'station-guide-region-background',
          ),
        );
        final railRect = tester.getRect(regionFinder);
        {
          final appBar = tester.widget<AppBar>(find.byType(AppBar));
          expect(
            appBar.backgroundColor ??
                Theme.of(
                  tester.element(find.byType(AppBar)),
                ).appBarTheme.backgroundColor,
            dark ? const Color(0xFF10171C) : AppColors.canvas,
          );
        }
        final pageRect = tester.getRect(find.byType(Scaffold));
        expect(railRect.left, pageRect.left);
        expect(railRect.width, 76);
        expect(railRect.bottom, pageRect.bottom);
        final clip = find.ancestor(
          of: regionFinder,
          matching: find.byType(ClipRRect),
        );
        if (kind != 'contactless') {
          expect(
            tester.widget<ClipRRect>(clip.first).borderRadius,
            const BorderRadius.only(topRight: Radius.circular(17)),
          );
        }
      });
    }
  }
}
