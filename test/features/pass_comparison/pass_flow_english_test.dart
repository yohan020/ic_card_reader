import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/pass_comparison/presentation/pass_strings.dart';

void main() {
  final entries =
      (jsonDecode(
                File(
                  'docs/release/pass-english-2026-11-11/flow-copy.json',
                ).readAsStringSync(),
              )
              as List)
          .cast<Map<String, dynamic>>();
  String example(String value) =>
      value.replaceAllMapped(RegExp(r'\{arg(\d+)\}'), (m) => 'Example${m[1]}');
  for (final language in ['ko', 'en']) {
    testWidgets('Reviewed pass flow catalog preserves meaning in $language', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              for (final entry in entries) {
                final source = example(entry['source'] as String);
                expect(
                  passText(context, source),
                  example(
                    entry[language == 'ko' ? 'source' : 'english'] as String,
                  ),
                  reason: '${entry['key']}: $source',
                );
              }
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
    });
  }
  testWidgets('Nested pass labels translate without changing unknown values', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            expect(passText(context, '24시간권'), '24-hour pass');
            expect(passText(context, '2일권'), '2 days');
            expect(passText(context, '未確認の駅'), '未確認の駅');
            expect(passText(context, '¥1,500'), '¥1,500');
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  });
}
