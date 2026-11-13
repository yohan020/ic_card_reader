import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/l10n/app_localizations.dart';
import 'package:ic_card_reader/src/features/settings/presentation/privacy_policy_page.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'English privacy policy is complete and switches language dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        Widget app(String locale) => MaterialApp(
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: dark ? AppTheme.dark : AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const PrivacyPolicyPage(),
        );
        await tester.pumpWidget(app('en'));
        await tester.pumpAndSettle();
        expect(find.text('Privacy policy'), findsOneWidget);
        final en =
            jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map;
        for (final part in [
          'Overview',
          'Nfc',
          'OnDevice',
          'Reports',
          'NotSent',
          'Services',
          'Maps',
          'StationData',
          'Retention',
          'Contact',
        ]) {
          final title = en['privacy${part}Title'] as String;
          final body = en['privacy${part}Body'] as String;
          await tester.scrollUntilVisible(find.text(title), 250);
          expect(find.text(body), findsOneWidget);
          expect(RegExp('[가-힣]').hasMatch(body), isFalse);
          expect(tester.takeException(), isNull);
        }
        await tester.scrollUntilVisible(
          find.text('Effective date: October 27, 2026'),
          250,
        );
        await tester.pumpWidget(app('ko'));
        await tester.pumpAndSettle();
        expect(find.text('개인정보처리방침'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('시행일: 2026년 10월 27일'), 250);
        expect(find.textContaining('개인정보 확인·삭제 요청'), findsOneWidget);
        await tester.pumpWidget(app('en'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Effective date: October 27, 2026'),
          250,
        );
        expect(find.text('Effective date: October 27, 2026'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  test(
    'public English policy preserves disclosures and has reciprocal language links',
    () {
      final markdown = File('docs/PRIVACY_POLICY_EN.md').readAsStringSync();
      final html = File('docs/privacy-en.html').readAsStringSync();
      final korean = File('docs/index.html').readAsStringSync();
      expect(html, contains('<html lang="en">'));
      expect(html, contains('href="index.html" lang="ko"'));
      expect(korean, contains('href="privacy-en.html" lang="en"'));
      expect(RegExp(r'<h2>').allMatches(html).length, 10);
      expect(RegExp(r'^## ', multiLine: true).allMatches(markdown).length, 10);
      for (final source in [markdown, html]) {
        for (final disclosure in [
          'October 27, 2026',
          '16-byte',
          'up to 10 cards',
          'PMm',
          'five per 10 minutes',
          'Google Maps SDK map is displayed automatically',
          'does not request current-location permission',
          'does not cancel or delete requests already made',
          'one year',
          'Supabase',
          'Yoiko',
          'Wikidata CC0',
          'iccardreader10@gmail.com',
        ]) {
          expect(source, contains(disclosure));
        }
        expect(source, isNot(contains('개인정보처리방침')));
      }
    },
  );

  testWidgets('explains NFC use and optional issue report transmission', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const PrivacyPolicyPage()),
    );

    expect(find.text('개인정보처리방침'), findsOneWidget);
    expect(find.text('1. NFC 사용 목적'), findsOneWidget);
    expect(find.textContaining('카드에 정보를 기록하거나 변경하지 않습니다'), findsOneWidget);
    expect(find.textContaining('최대 10장의 이름·잔액·확인 시각'), findsOneWidget);
    expect(find.textContaining('세션 한정 비교값'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('4. 전송하지 않는 정보'), 300);
    expect(find.textContaining('카드 IDm 원문'), findsWidgets);
    expect(find.textContaining('기기 고유 식별자'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('6. 역 코드 데이터'), 300);
    expect(find.text('5-1. Google 지도'), findsOneWidget);
    expect(
      find.textContaining('Google Maps SDK 지도를 자동으로 표시합니다'),
      findsOneWidget,
    );
    expect(
      find.textContaining('이미 발생한 지도 요청을 취소하거나 삭제하는 것은 아닙니다'),
      findsOneWidget,
    );
    expect(find.textContaining('지도 보기를 누른 경우'), findsNothing);
    expect(
      find.textContaining('인터넷 연결이 확인되지 않으면 지도를 표시하지 않으며'),
      findsOneWidget,
    );
    expect(find.textContaining('상세 화면에서 지도를 닫을 수 있지만'), findsNothing);
    expect(find.textContaining('설정의 데이터 출처 및 운임 기준 화면'), findsOneWidget);
    expect(find.textContaining('오픈소스 라이선스 화면'), findsNothing);

    await tester.scrollUntilVisible(find.text('7. 보관과 삭제'), 300);
    expect(find.textContaining('해결 후 1년간 보관'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('iccardreader10@gmail.com'),
      300,
    );
    expect(find.textContaining('iccardreader10@gmail.com'), findsOneWidget);
    expect(
      find.textContaining('https://yohan020.github.io/ic_card_reader/'),
      findsOneWidget,
    );
  });

  test(
    'public policy sources describe automatic maps, not an opt-in button',
    () {
      for (final path in ['docs/PRIVACY_POLICY.md', 'docs/index.html']) {
        final text = File(path).readAsStringSync();
        expect(text, contains('Google Maps SDK 지도를 자동으로 표시합니다'));
        expect(text, contains('이미 발생한 지도 요청을 취소하거나 삭제하는 것은 아닙니다'));
        expect(text, isNot(contains('지도 보기를 누르면')));
        expect(text, isNot(contains('`지도 보기`를 누르면')));
        expect(text, contains('연결 후 지도 새로고침으로 다시 시도할 수 있습니다'));
        expect(text, isNot(contains('상세 화면에서 지도를 닫을 수 있지만')));
      }
    },
  );
}
