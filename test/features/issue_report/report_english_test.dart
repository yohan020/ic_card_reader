import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/l10n/app_localizations.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_diagnostics.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_reader.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_scan_result.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/raw_history_block.dart';
import 'package:ic_card_reader/src/features/issue_report/domain/card_support_report.dart';
import 'package:ic_card_reader/src/features/issue_report/domain/issue_report.dart';
import 'package:ic_card_reader/src/features/issue_report/domain/issue_report_repository.dart';
import 'package:ic_card_reader/src/features/issue_report/presentation/card_support_page.dart';
import 'package:ic_card_reader/src/features/issue_report/presentation/issue_report_page.dart';
import 'package:ic_card_reader/src/features/issue_report/presentation/report_strings.dart';
import 'package:ic_card_reader/src/features/settings/domain/installed_app_version.dart';
import 'package:ic_card_reader/src/features/transaction_history/data/transit_history_parser.dart';

Widget app(
  Widget page, {
  bool dark = false,
  double scale = 1,
  String locale = 'en',
}) => MaterialApp(
  key: page.key,
  locale: Locale(locale),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: dark ? AppTheme.dark : AppTheme.light,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: page,
);

Future<void> tapText(WidgetTester tester, String text) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 300));
  if (find.text(text).evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      find.text(text),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  final target = find.text(text).last;
  await Scrollable.ensureVisible(tester.element(target), alignment: .5);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(target);
  if (text == 'Send anonymously') {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
  }
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          InstalledAppVersion.channel,
          (_) async => '1.0.0 (1)',
        );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(InstalledAppVersion.channel, null);
  });

  testWidgets(
    'changing app language resets the station-name draft and consent',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final history = const TransitHistoryParser().parse([
        _block('050D000F34FC0F3D00002F0700004FC0'),
      ]).single;
      final page = IssueReportPage(
        key: const ValueKey('language-change'),
        history: history,
      );
      await tester.pumpWidget(app(page));
      await tester.pumpAndSettle();
      await tapText(tester, 'Request an English station name');
      await tapText(tester, 'Next');
      await tapText(tester, 'Choose the boarding or alighting station');
      await tapText(tester, 'Both boarding and alighting stations');
      await tester.ensureVisible(find.byType(TextFormField).first);
      await tester.enterText(find.byType(TextFormField).first, 'Tenjin');
      await tapText(tester, 'Review');
      expect(find.text('Suggested boarding name in English'), findsOneWidget);
      await tapText(tester, 'I agree to send the information above.');
      await tester.pumpWidget(app(page, locale: 'ko'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('역명 한글 표기 추가 요청'),
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('1/3 단계'), findsOneWidget);
      expect(find.text('Request an English station name'), findsNothing);
      expect(find.text('Tenjin'), findsNothing);
      await tapText(tester, '다음');
      expect(find.text('승차역·하차역을 선택해 주세요'), findsOneWidget);
      await tapText(tester, '승차역·하차역을 선택해 주세요');
      await tapText(tester, '승차역과 하차역 모두');
      expect(find.text('한글 표기'), findsNWidgets(2));
      await tapText(tester, '검토하기');
      final consent = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      expect(consent.value, isFalse);
      expect(find.text('Tenjin'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final scope in ['Boarding station', 'Alighting station']) {
    testWidgets('English name request shows only the selected scope: $scope', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final history = const TransitHistoryParser().parse([
        _block('050D000F34FC0F3D00002F0700004FC0'),
      ]).single;
      await tester.pumpWidget(
        app(IssueReportPage(history: history), dark: true),
      );
      await tester.pumpAndSettle();
      await tapText(tester, 'Request an English station name');
      await tapText(tester, 'Next');
      await tapText(tester, 'Choose the boarding or alighting station');
      await tapText(tester, scope);
      expect(find.text('English name'), findsOneWidget);
      expect(find.text('$scope in English'), findsOneWidget);
      await tapText(tester, 'Review');
      expect(find.text('Review before sending'), findsOneWidget);
      expect(
        find.text(
          scope == 'Boarding station'
              ? 'Suggested boarding name in English'
              : 'Suggested alighting name in English',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          scope == 'Boarding station'
              ? 'Suggested alighting name in English'
              : 'Suggested boarding name in English',
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'all inquiry ARB copy resolves in both languages, including server errors',
    (tester) async {
      final ko =
          jsonDecode(File('lib/l10n/app_ko.arb').readAsStringSync()) as Map;
      final en =
          jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map;
      for (final locale in ['en', 'ko']) {
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                for (final key in ko.keys.whereType<String>().where(
                  (key) =>
                      key.startsWith('report') &&
                      key != 'reportTransaction' &&
                      key != 'reportStep' &&
                      key != 'reportRequiredField',
                )) {
                  expect(
                    reportText(context, ko[key] as String),
                    locale == 'en' ? en[key] : ko[key],
                    reason: key,
                  );
                }
                expect(reportText(context, 'UNCHANGED'), 'UNCHANGED');
                return const SizedBox();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'English report branches, validation, sheets and receipt preserve wire values',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final history = const TransitHistoryParser().parse([
        _block('050D000F34FC0F3D00002F0700004FC0'),
      ]).single;
      // Keep all submissions in one fake-async zone because installed version is cached.
      for (final issue in [
        'Missing or incorrect station information',
        'Request an English station name',
        'Missing or incorrect bus operator',
        'Incorrect transaction type',
        'Incorrect amount or balance',
        'Other',
      ]) {
        final repository = _Repository();
        await tester.pumpWidget(
          app(
            IssueReportPage(
              key: ValueKey(issue),
              history: history,
              repository: repository,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Step 1 of 3'), findsOneWidget);
        await tapText(tester, issue);
        await tapText(tester, 'Next');
        if (issue.contains('station')) {
          await tapText(tester, 'Review');
          expect(find.text('Choose the affected station.'), findsOneWidget);
          await tapText(tester, 'Choose the boarding or alighting station');
          await tapText(tester, 'Both boarding and alighting stations');
          if (issue.startsWith('Request')) {
            expect(find.text('Boarding station in English'), findsOneWidget);
            expect(find.text('Alighting station in English'), findsOneWidget);
            expect(find.text('English name'), findsNWidgets(2));
            await tester.ensureVisible(find.byType(TextFormField).first);
            await tester.enterText(find.byType(TextFormField).first, 'Tenjin');
          }
          if (issue.startsWith('Missing')) {
            await tapText(tester, 'Review');
            expect(find.text('Enter Station name.'), findsWidgets);
            final fields = find.byType(TextFormField);
            for (final index in [0, 1, 3, 4]) {
              await tester.ensureVisible(fields.at(index));
              await tester.enterText(fields.at(index), 'Test $index');
            }
          }
        } else if (issue.contains('bus operator')) {
          await tapText(tester, 'Review');
          expect(find.text('Enter Bus operator.'), findsOneWidget);
          final fields = find.byType(TextFormField);
          await tester.enterText(fields.at(0), '기타');
          await tester.enterText(fields.at(1), 'Test city');
        } else if (issue == 'Incorrect transaction type') {
          await tapText(tester, 'Review');
          expect(
            find.text('Choose the correct transaction type.'),
            findsOneWidget,
          );
          await tapText(tester, 'Choose a type');
          await tapText(tester, 'Not listed / enter manually');
          await tapText(tester, 'Review');
          expect(find.text('Enter Transaction type.'), findsOneWidget);
          await tester.ensureVisible(find.byType(TextFormField).first);
          await tester.enterText(find.byType(TextFormField).first, '기타');
        }
        await tapText(tester, 'Review');
        expect(find.text('Review before sending'), findsOneWidget);
        if (issue == 'Incorrect transaction type' ||
            issue.contains('bus operator')) {
          expect(
            find.text('기타'),
            findsOneWidget,
          ); // Never translate user input.
        }
        await tapText(tester, 'I agree to send the information above.');
        await tapText(tester, 'Send anonymously');
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Your report has been received'), findsOneWidget);
        expect(find.text('Report ID'), findsOneWidget);
        expect(repository.reports, hasLength(1));
        final sent = repository.reports.single;
        expect(sent.anonymousRawRecord, history.rawBlock.hexadecimal);
        if (issue.startsWith('Request')) {
          expect(sent.issueType, IssueType.englishStationNameRequest);
          expect(sent.suggestedEnglishBoardingStationName, 'Tenjin');
          expect(sent.suggestedEnglishAlightingStationName, isNull);
          expect(sent.suggestedKoreanBoardingStationName, isNull);
          expect(sent.suggestedKoreanAlightingStationName, isNull);
          expect(sent.toJson()['issueType'], 'ENGLISH_STATION_NAME_REQUEST');
          expect(
            sent.toJson()['suggestedEnglishBoardingStationName'],
            'Tenjin',
          );
          expect(sent.toJson()['suggestedEnglishAlightingStationName'], isNull);
        }
        if (issue == 'Incorrect transaction type') {
          expect(sent.suggestedTransactionType, 'OTHER');
          expect(sent.customSuggestedTransactionType, '기타');
        }
        await tapText(tester, 'Done');
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'English support has separate consent, raw preview, error, retry and receipt',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _Repository();
      final reader = _Reader();
      await tester.pumpWidget(
        app(
          CardSupportPage(reader: reader, repository: repository),
          dark: true,
          scale: 1.7,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Card recognition support'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('support-category-picker')));
      await tester.pumpAndSettle();
      expect(find.text('Choose an inquiry type'), findsOneWidget);
      await tapText(tester, 'Card brand identification');
      expect(reader.scans, 0);
      await tapText(tester, 'I agree to the minimal diagnostic check.');
      await tapText(tester, 'Scan card for diagnostics');
      expect(reader.scans, 1);
      expect(repository.support, isEmpty);
      await tapText(tester, 'Review data to be sent');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pumpAndSettle();
      await tapText(tester, 'View all data to be sent');
      expect(
        find.textContaining('Opening this screen does not send anything.'),
        findsOneWidget,
      );
      final payload = tester
          .widget<SelectableText>(
            find.byKey(const ValueKey('support-payload-json')),
          )
          .data!;
      expect(jsonDecode(payload)['category'], 'BRAND_UNKNOWN');
      expect(payload, isNot(contains('balance')));
      await tapText(tester, 'Close');
      final send = find.widgetWithText(FilledButton, 'Agree and send');
      expect(tester.widget<FilledButton>(send).onPressed, isNull);
      await tapText(tester, 'I agree to send this inquiry.');
      await tapText(tester, 'Agree and send');
      expect(
        find.text('Check your internet connection and try again.'),
        findsOneWidget,
      );
      await tapText(tester, 'Agree and send');
      expect(find.text('Your inquiry has been received'), findsOneWidget);
      expect(find.text('Report ID'), findsOneWidget);
      expect(
        find.text(
          'Your card IDm, balance and transaction history were not sent.',
        ),
        findsOneWidget,
      );
      expect(repository.support, hasLength(2));
      expect(
        repository.support.first.reportId,
        repository.support.last.reportId,
      );
      await tapText(tester, 'Done');
      expect(tester.takeException(), isNull);
    },
  );
}

RawHistoryBlock _block(String hex) => RawHistoryBlock(
  index: 0,
  bytes: Uint8List.fromList([
    for (var i = 0; i < hex.length; i += 2)
      int.parse(hex.substring(i, i + 2), radix: 16),
  ]),
);

class _Reader implements CardReader, SupportCardReader {
  int scans = 0;
  @override
  Future<CardDiagnosticReport> scanSupportDiagnostics() async {
    scans++;
    return CardDiagnosticReport(
      initialSystemCode: '0003',
      pmm: '0000000000000000',
      systemCodes: ['0003'],
      systemCodeStatus: 'ok',
    );
  }

  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<CardReaderAvailability> checkAvailability() async =>
      CardReaderAvailability.enabled;
  @override
  Future<bool> openNfcSettings() async => true;
  @override
  Future<void> cancel() async {}
  @override
  Future<CardScanResult> scan({
    Duration timeout = const Duration(seconds: 30),
  }) => throw UnimplementedError();
}

class _Repository implements CardSupportRepository, IssueReportRepository {
  final support = <CardSupportReport>[];
  final reports = <IssueReport>[];
  @override
  Future<String> submitCardSupport(CardSupportReport report) async {
    support.add(report);
    if (support.length == 1) {
      throw const IssueReportSubmissionException('인터넷 연결을 확인한 뒤 다시 시도해 주세요.');
    }
    return report.reportId;
  }

  @override
  Future<IssueReportReceipt> submit(IssueReport report) async {
    reports.add(report);
    return const IssueReportReceipt(
      reportId: 'test-receipt',
      reviewStatus: 'RECEIVED',
    );
  }
}
