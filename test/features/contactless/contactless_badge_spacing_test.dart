import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/core/localization/app_strings.dart';
import 'package:ic_card_reader/src/features/contactless/domain/contactless_catalog.dart';
import 'package:ic_card_reader/src/features/contactless/presentation/contactless_page.dart';

void main() {
  testWidgets('English inferred badge fits its longest wrapped line', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: ContactlessBadge(
                line: ContactlessLine({'status': 'inferred'}),
                compact: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final label = find.text('Likely not supported');
    expect(label, findsOneWidget);
    final badgeWidth = tester.getSize(find.byType(ContactlessBadge)).width;
    final textWidth = tester.getSize(label).width;
    expect(badgeWidth, lessThanOrEqualTo(110));
    expect(badgeWidth - textWidth, closeTo(12, .01));
    final widget = tester.widget<Text>(label);
    expect(widget.textWidthBasis, TextWidthBasis.longestLine);
    final painter = TextPainter(
      text: TextSpan(
        text: widget.data,
        style: DefaultTextStyle.of(
          tester.element(label),
        ).style.merge(widget.style),
      ),
      textDirection: TextDirection.ltr,
      textWidthBasis: TextWidthBasis.longestLine,
    )..layout(maxWidth: 98);
    expect(painter.computeLineMetrics().length, greaterThan(1));
    expect(painter.computeLineMetrics().last.width, lessThan(98));
    expect(textWidth, closeTo(painter.width, .01));
    painter.dispose();
    expect(
      find.descendant(
        of: find.byType(ContactlessBadge),
        matching: find.byType(Icon),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
  for (final language in ['ko', 'en']) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        for (final compact in [false, true]) {
          testWidgets(
            'badge content fit $language dark=$dark scale=$scale compact=$compact',
            (tester) async {
              await tester.pumpWidget(
                MaterialApp(
                  theme: dark ? AppTheme.dark : AppTheme.light,
                  locale: Locale(language),
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: Scaffold(
                    body: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 113),
                        child: ContactlessBadge(
                          line: ContactlessLine({'status': 'inferred'}),
                          compact: compact,
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              final label = find.text(
                language == 'en' ? 'Likely not supported' : '미지원(추정)',
              );
              final text = tester.widget<Text>(label);
              final padding = compact ? 12.0 : 16.0;
              final painter = TextPainter(
                text: TextSpan(
                  text: text.data,
                  style: DefaultTextStyle.of(
                    tester.element(label),
                  ).style.merge(text.style),
                ),
                textDirection: TextDirection.ltr,
                textScaler: TextScaler.linear(scale),
                textWidthBasis: TextWidthBasis.longestLine,
              )..layout(maxWidth: 113 - padding);
              expect(
                tester.getSize(find.byType(ContactlessBadge)).width,
                closeTo(painter.width + padding, .01),
              );
              expect(text.textWidthBasis, TextWidthBasis.longestLine);
              if (language == 'en' && compact && scale == 1) {
                expect(
                  tester.getSize(find.byType(ContactlessBadge)).width,
                  lessThan(113),
                );
              }
              painter.dispose();
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }
}
