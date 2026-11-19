import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ic_card_reader/src/features/settings/domain/installed_app_version.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_diagnostics.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_reader.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_scan_result.dart';
import 'package:ic_card_reader/src/features/issue_report/domain/card_support_report.dart';
import 'package:ic_card_reader/src/features/issue_report/domain/issue_report_repository.dart';
import 'package:ic_card_reader/src/features/issue_report/presentation/card_support_page.dart';
import 'package:ic_card_reader/src/features/issue_report/presentation/report_success_dialog.dart';
import 'package:ic_card_reader/src/features/transaction_history/presentation/history_pages.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/card_brand_identity.dart';
import 'package:ic_card_reader/src/features/settings/presentation/settings_page.dart';
import 'package:ic_card_reader/src/features/station_resolver/domain/station_name_display.dart';

CardDiagnosticReport metadata() => CardDiagnosticReport(
  initialSystemCode: '0003',
  pmm: '053143454682B7FF',
  systemCodes: ['0003'],
  systemCodeStatus: 'ok',
  serviceProbe: CardServiceProbeReport(
    status: 'ok',
    presence: {
      for (final code in diagnosticServiceCodes)
        code: code == 0x208B || code == 0x20CB,
    },
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const visualPreview = bool.fromEnvironment('CARD_SUPPORT_VISUAL_PREVIEW');
  if (visualPreview) {
    setUpAll(() async {
      final loader = FontLoader('SupportPreview')
        ..addFont(
          File(
            const String.fromEnvironment(
              'CARD_SUPPORT_PREVIEW_FONT',
              defaultValue: 'C:/Windows/Fonts/malgun.ttf',
            ),
          ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
      await loader.load();
      final mono = FontLoader('monospace')
        ..addFont(
          File(
            'C:/Windows/Fonts/consola.ttf',
          ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
      await mono.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          File(
            'C:/Users/yohan/Desktop/project/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
          ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
      await icons.load();
    });
  }
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
  test(
    'support serialization is a strict metadata allowlist, not a card dump',
    () {
      final diagnostic = CardSupportDiagnostic.fromReport(metadata());
      final json = diagnostic.toJson();
      expect(json.keys.toSet(), {
        'technology',
        'initial_system_code',
        'pmm',
        'system_code_status',
        'system_code_issue',
        'system_codes',
        'service_probe',
        'scan_failure',
      });
      expect((json['service_probe'] as Map)['presence'].length, 19);
      for (final forbidden in [
        'idm',
        'history',
        'balance',
        'raw',
        'key_version',
        'token',
      ]) {
        expect(jsonEncode(json).toLowerCase(), isNot(contains(forbidden)));
      }
      final error = CardSupportDiagnostic.fromFailure(
        CardScanFailureKind.unsupportedTag,
      ).toJson();
      expect(error['scan_failure'], 'unsupportedTag');
      expect(error['pmm'], isNull);
      expect(error['service_probe'], isNull);
    },
  );

  for (final dark in [false, true]) {
    testWidgets(
      'settings keeps support copy short and details in form dark=$dark',
      (tester) async {
        final reader = _Reader();
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: Scaffold(
              body: Builder(
                builder: (context) => SettingsPage(
                  themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                  onThemeModeChanged: (_) {},
                  onClearSession: () {},
                  stationNameDisplayMode: StationNameDisplayMode.japanese,
                  onStationNameDisplayModeChanged: (_) {},
                  onOpenCardSupport: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => CardSupportPage(reader: reader),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('카드 인식 문의'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('카드 읽기·브랜드 구분 문제'), findsOneWidget);
        expect(find.textContaining('동의 후 최소 진단 전송'), findsNothing);
        await tester.ensureVisible(find.text('카드 인식 문의'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('카드 인식 문의'));
        await tester.pumpAndSettle();
        expect(find.byType(CardSupportPage), findsOneWidget);
        expect(find.text('카드 브랜드 (선택)'), findsOneWidget);
        expect(find.textContaining('카드 종류'), findsNothing);
        expect(find.textContaining('일반 스캔의 이용내역은 바뀌지 않아요.'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('최소 진단 확인에 동의해요'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.textContaining('통신 오류 코드만 확인해요.'), findsOneWidget);
        expect(find.textContaining('잔액·이용내역은 수집하지 않아요.'), findsOneWidget);
        expect(reader.scans, 0);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets('card support screen preview dark=$dark', (tester) async {
      tester.view.physicalSize = const Size(432, 920);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final theme = dark ? AppTheme.dark : AppTheme.light;
      await tester.pumpWidget(
        MaterialApp(
          theme: visualPreview
              ? theme.copyWith(
                  textTheme: theme.textTheme.apply(
                    fontFamily: 'SupportPreview',
                  ),
                  filledButtonTheme: FilledButtonThemeData(
                    style: theme.filledButtonTheme.style?.merge(
                      FilledButton.styleFrom(
                        textStyle: const TextStyle(
                          fontFamily: 'SupportPreview',
                        ),
                      ),
                    ),
                  ),
                  outlinedButtonTheme: OutlinedButtonThemeData(
                    style: theme.outlinedButtonTheme.style?.merge(
                      OutlinedButton.styleFrom(
                        textStyle: const TextStyle(
                          fontFamily: 'SupportPreview',
                        ),
                      ),
                    ),
                  ),
                  textButtonTheme: TextButtonThemeData(
                    style: theme.textButtonTheme.style?.merge(
                      TextButton.styleFrom(
                        textStyle: const TextStyle(
                          fontFamily: 'SupportPreview',
                        ),
                      ),
                    ),
                  ),
                  appBarTheme: theme.appBarTheme.copyWith(
                    titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
                      fontFamily: 'SupportPreview',
                    ),
                  ),
                )
              : theme,
          home: RepaintBoundary(
            key: const ValueKey('support-preview'),
            child: CardSupportPage(reader: _Reader()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const ValueKey('support-preview')),
        matchesGoldenFile(
          visualPreview
              ? '../../../.dart_tool/card_support_preview/${dark ? 'dark' : 'light'}.png'
              : 'goldens/card_support_${dark ? 'dark' : 'light'}.png',
        ),
      );
      expect(tester.takeException(), isNull);
      if (visualPreview) {
        await tester.tap(find.byKey(const ValueKey('support-category-picker')));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(BottomSheet),
          matchesGoldenFile(
            '../../../.dart_tool/card_support_preview/category_${dark ? 'dark' : 'light'}.png',
          ),
        );
        await tester.tap(find.text('카드 브랜드 구분'));
        await tester.pumpAndSettle();
        Future<void> tapPreview(String label) async {
          final target = find.text(label);
          if (target.evaluate().isEmpty) {
            await tester.scrollUntilVisible(
              target,
              180,
              scrollable: find.byType(Scrollable).first,
            );
          }
          await tester.ensureVisible(target);
          await tester.pumpAndSettle();
          await tester.tap(target);
          await tester.pumpAndSettle();
        }

        await tapPreview('최소 진단 확인에 동의해요');
        await tapPreview('진단용 카드 스캔');
        await tapPreview('전송할 내용 확인');
        await tester.scrollUntilVisible(
          find.text('전송 항목 전체 보기'),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.text('전송 항목 전체 보기'));
        await tester.pumpAndSettle();
        await expectLater(
          find.byKey(const ValueKey('support-preview')),
          matchesGoldenFile(
            '../../../.dart_tool/card_support_preview/transmission_${dark ? 'dark' : 'light'}.png',
          ),
        );
        await tapPreview('전송 항목 전체 보기');
        await expectLater(
          find.byType(BottomSheet),
          matchesGoldenFile(
            '../../../.dart_tool/card_support_preview/payload_${dark ? 'dark' : 'light'}.png',
          ),
        );
        await tapPreview('닫기');
        for (final support in [false, true]) {
          final title = support ? '문의가 접수되었습니다' : '제보가 접수되었습니다';
          final notice = support
              ? '카드 IDm·잔액·이용내역은 전송되지 않았습니다.'
              : '카드 IDm과 다른 이용내역은 전송되지 않았습니다.';
          final closed = showReportSuccessDialog(
            tester.element(find.byType(CardSupportPage)),
            reportId: '12345678-1234-4234-8234-123456789012',
            title: title,
            privacyNotice: notice,
          );
          await tester.pumpAndSettle();
          await expectLater(
            find.byType(ReportSuccessDialog),
            matchesGoldenFile(
              '../../../.dart_tool/card_support_preview/success_${support ? 'card' : 'history'}_${dark ? 'dark' : 'light'}.png',
            ),
          );
          await tester.tap(find.text('확인'));
          await tester.pumpAndSettle();
          await closed;
        }
      }
    });
    testWidgets(
      'support requires scan consent, preview and separate send consent; dark=$dark',
      (tester) async {
        final reader = _Reader();
        final repository = _Repository();
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: Builder(
              builder: (context) => Scaffold(
                body: FilledButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => CardSupportPage(
                        reader: reader,
                        repository: repository,
                      ),
                    ),
                  ),
                  child: const Text('카드 인식 문의 열기'),
                ),
              ),
            ),
          ),
        );
        Future<void> tapText(String text) async {
          if (find.text(text).evaluate().isEmpty) {
            await tester.scrollUntilVisible(
              find.text(text),
              250,
              scrollable: find.byType(Scrollable).first,
            );
          }
          await tester.ensureVisible(find.text(text));
          await tester.pumpAndSettle();
          await tester.tap(find.text(text));
          await tester.pumpAndSettle();
        }

        await tapText('카드 인식 문의 열기');

        await tapText('진단용 카드 스캔');
        expect(reader.scans, 0);
        await tapText('최소 진단 확인에 동의해요');
        await tapText('진단용 카드 스캔');
        expect(reader.scans, 1);
        expect(repository.sent, isEmpty);
        await tapText('전송할 내용 확인');
        await tapText('동의하고 문의 보내기');
        expect(repository.sent, isEmpty);
        await tapText('문의 전송에 동의해요');
        await tapText('동의하고 문의 보내기');
        expect(repository.sent, hasLength(1));
        expect(
          repository.sent.single.toJson()['consentVersion'],
          cardSupportConsentVersion,
        );
        expect(find.byType(ReportSuccessDialog), findsOneWidget);
        expect(find.text('문의가 접수되었습니다'), findsOneWidget);
        expect(find.text(repository.sent.single.reportId), findsOneWidget);
        expect(find.text('카드 IDm·잔액·이용내역은 전송되지 않았습니다.'), findsOneWidget);
        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();
        expect(find.byType(ReportSuccessDialog), findsOneWidget);
        await tapText('확인');
        expect(find.byType(CardSupportPage), findsNothing);
        expect(find.text('카드 인식 문의 열기'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'approved brand names and icons preserve balance layout; dark=$dark',
      (tester) async {
        for (final brand in [
          CardBrandIdentity.kitaca,
          CardBrandIdentity.manaca,
          CardBrandIdentity.sugoca,
        ]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: Scaffold(
                body: HistoryListPage(
                  histories: const [],
                  currentBalance: 1200,
                  brandIdentity: brand,
                  stationPairs: const {},
                  onScan: () {},
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('현재 ${brand.label} 잔액'), findsOneWidget);
          expect(
            find.byIcon(Icons.account_balance_wallet_outlined),
            findsNothing,
          );
          expect(tester.takeException(), isNull);
        }
      },
    );
  }

  testWidgets('editing invalidates preview and consent', (tester) async {
    final repository = _Repository();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CardSupportPage(reader: _Reader(), repository: repository),
      ),
    );
    Future<void> tap(String text) async {
      if (find.text(text).evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          find.text(text),
          250,
          scrollable: find.byType(Scrollable).first,
        );
      }
      await tester.ensureVisible(find.text(text));
      await tester.pumpAndSettle();
      await tester.tap(find.text(text));
      await tester.pumpAndSettle();
    }

    await tap('최소 진단 확인에 동의해요');
    await tap('진단용 카드 스캔');
    await tap('전송할 내용 확인');
    await tap('문의 전송에 동의해요');
    final brandField = find.byKey(const ValueKey('support-expected-brand'));
    await tester.scrollUntilVisible(
      brandField,
      -250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.enterText(brandField, 'Kitaca');
    await tester.pumpAndSettle();
    expect(find.text('동의하고 문의 보내기'), findsNothing);
    expect(repository.sent, isEmpty);
  });

  testWidgets(
    'unreadable support contains only failure enum and retry keeps receipt ID',
    (tester) async {
      final repository = _Repository()..failOnce = true;
      final reader = _Reader()..failure = CardScanFailureKind.unsupportedTag;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: CardSupportPage(reader: reader, repository: repository),
        ),
      );
      Future<void> tap(String text) async {
        if (find.text(text).evaluate().isEmpty) {
          await tester.scrollUntilVisible(
            find.text(text),
            250,
            scrollable: find.byType(Scrollable).first,
          );
        }
        await tester.ensureVisible(find.text(text));
        await tester.pumpAndSettle();
        await tester.tap(find.text(text));
        await tester.pumpAndSettle();
      }

      await tap('최소 진단 확인에 동의해요');
      await tap('진단용 카드 스캔');
      await tap('전송할 내용 확인');
      await tap('문의 전송에 동의해요');
      await tap('동의하고 문의 보내기');
      expect(repository.sent, hasLength(1));
      expect(
        repository.sent.single.diagnostic.toJson()['scan_failure'],
        'unsupportedTag',
      );
      expect(repository.sent.single.diagnostic.toJson()['pmm'], isNull);
      await tap('동의하고 문의 보내기');
      expect(repository.sent, hasLength(2));
      expect(repository.sent.first.reportId, repository.sent.last.reportId);
      expect(find.byType(ReportSuccessDialog), findsOneWidget);
      expect(find.text('문의가 접수되었습니다'), findsOneWidget);
    },
  );
  testWidgets('custom category sheet, separate payload and consent reset', (
    tester,
  ) async {
    final repository = _Repository();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CardSupportPage(reader: _Reader(), repository: repository),
      ),
    );
    Future<void> tap(String label) async {
      final target = find.text(label);
      if (target.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          target,
          200,
          scrollable: find.byType(Scrollable).first,
        );
      }
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    final description = tester.widget<TextField>(
      find.byKey(const ValueKey('support-description')),
    );
    expect(description.minLines, 1);
    expect(description.maxLines, 3);
    expect(find.byType(RadioListTile<CardSupportCategory>), findsNothing);
    await tap('카드 읽기 오류');
    expect(find.text('문의 유형 선택'), findsOneWidget);
    expect(find.text('카드 브랜드가 표시되지 않거나 달라요'), findsOneWidget);
    expect(find.textContaining('카드 종류'), findsNothing);
    await tap('카드 브랜드 구분');
    expect(find.text('문의 유형 선택'), findsNothing);
    await tap('최소 진단 확인에 동의해요');
    await tap('진단용 카드 스캔');
    await tap('전송할 내용 확인');
    await tap('전송 항목 전체 보기');
    final payload = tester.widget<SelectableText>(
      find.byKey(const ValueKey('support-payload-json')),
    );
    final json = jsonDecode(payload.data!) as Map;
    expect(json['category'], 'BRAND_UNKNOWN');
    expect(repository.sent, isEmpty);
    await tap('닫기');
    final consent = find.ancestor(
      of: find.text('문의 전송에 동의해요'),
      matching: find.byType(CheckboxListTile),
    );
    expect(tester.widget<CheckboxListTile>(consent).value, isFalse);
    await tap('문의 전송에 동의해요');
    await tap('전송 항목 전체 보기');
    await tap('닫기');
    expect(tester.widget<CheckboxListTile>(consent).value, isTrue);
    final picker = find.byKey(const ValueKey('support-category-picker'));
    await tester.scrollUntilVisible(
      picker,
      -250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(picker);
    await tester.pumpAndSettle();
    await tester.tap(picker);
    await tester.pumpAndSettle();
    await tap('카드 읽기 오류');
    expect(find.text('문의 전송에 동의해요'), findsNothing);
    expect(find.byKey(const ValueKey('support-payload-json')), findsNothing);
    expect(repository.sent, isEmpty);
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 1.7]) {
    testWidgets('compact consent and sheets fit narrow screen scale=$scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: CardSupportPage(reader: _Reader()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('support-category-picker')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('카드 브랜드 구분'));
      await tester.tap(find.text('카드 브랜드 구분'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('최소 진단 확인에 동의해요'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('최소 진단 확인에 동의해요'));
      await tester.pumpAndSettle();
      final label = tester.widget<Text>(find.text('최소 진단 확인에 동의해요'));
      expect(label.style?.fontSize, 12);
      expect(label.maxLines, isNull);
      expect(label.overflow, isNull);
      await tester.tap(find.text('최소 진단 확인에 동의해요'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}

class _Reader implements CardReader, SupportCardReader {
  int scans = 0;
  CardScanFailureKind? failure;
  @override
  Future<CardDiagnosticReport> scanSupportDiagnostics() async {
    scans++;
    if (failure != null) {
      throw CardScanException(failure!, 'SECRET NATIVE RESPONSE');
    }
    return metadata();
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

class _Repository implements CardSupportRepository {
  final sent = <CardSupportReport>[];
  bool failOnce = false;
  @override
  Future<String> submitCardSupport(CardSupportReport report) async {
    sent.add(report);
    if (failOnce) {
      failOnce = false;
      throw const IssueReportSubmissionException('서버에 연결하지 못했어요.');
    }
    return report.reportId;
  }
}
