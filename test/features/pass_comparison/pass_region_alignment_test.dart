import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/pass_transit_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/pass_selection_page.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/pass_strings.dart';

void main() {
  final emptyData = PassTransitData(
    generatedAt: DateTime(2026),
    source: 'test',
    stations: [],
    fares: [],
  );
  for (final language in ['ko', 'en']) {
    for (final dark in [false, true]) {
      for (final width in [320.0, 390.0]) {
        for (final scale in [1.0, 2.0]) {
          testWidgets(
            'Regional trailing badge stays right $language dark=$dark width=$width scale=$scale',
            (tester) async {
              tester.view.physicalSize = Size(width, 850);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);
              await tester.pumpWidget(
                MaterialApp(
                  locale: Locale(language),
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  theme: dark ? AppTheme.dark : AppTheme.light,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(scale),
                      disableAnimations: true,
                    ),
                    child: child!,
                  ),
                  home: PassSelectionPage(initialTransitData: emptyData),
                ),
              );
              await tester.pumpAndSettle();
              final context = tester.element(find.byType(PassSelectionPage));
              for (final region in [
                PassRegion.hokkaido,
                PassRegion.kanto,
                PassRegion.kansai,
                PassRegion.chugoku,
                PassRegion.kyushu,
                PassRegion.okinawa,
                PassRegion.tohoku,
                PassRegion.chubu,
                PassRegion.shikoku,
              ]) {
                final label = [
                  '홋카이도',
                  '도호쿠',
                  '도쿄·간토',
                  '주부',
                  '간사이',
                  '주고쿠',
                  '시코쿠',
                  '규슈',
                  '오키나와',
                ][region.index];
                final title = find.text(passText(context, label));
                await tester.scrollUntilVisible(title, 250);
                await tester.pumpAndSettle();
                final row = find
                    .ancestor(of: title, matching: find.byType(Row))
                    .first;
                final rowRect = tester.getRect(row);
                final badgeText = find.descendant(
                  of: row,
                  matching: find.byWidgetPredicate(
                    (widget) =>
                        widget is Text &&
                        widget.data != null &&
                        RegExp(
                                r'^(\d+개|\d+ pass(?:es)?|준비 중|Coming soon)$',
                        ).hasMatch(widget.data!),
                  ),
                );
                expect(badgeText, findsOneWidget);
                final badge = find
                    .ancestor(of: badgeText, matching: find.byType(Container))
                    .first;
                final badgeRect = tester.getRect(badge);
                final arrow = find.descendant(
                  of: row,
                  matching: find.byIcon(Icons.chevron_right_rounded),
                );
                if (arrow.evaluate().isNotEmpty) {
                  final arrowRect = tester.getRect(arrow);
                  expect(
                    arrowRect.right,
                    closeTo(rowRect.right, .5),
                    reason: '${region.name}: arrow',
                  );
                  expect(
                    badgeRect.right,
                    closeTo(arrowRect.left - 8, .5),
                    reason: '${region.name}: badge',
                  );
                } else {
                  expect(
                    badgeRect.right,
                    closeTo(rowRect.right, .5),
                    reason: '${region.name}: unavailable badge',
                  );
                }
                expect(tester.getTopLeft(title).dx, closeTo(rowRect.left, .5));
                expect(badgeRect.left, greaterThanOrEqualTo(rowRect.left));
                expect(tester.takeException(), isNull);
              }
            },
          );
        }
      }
    }
  }
}
