import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/core/design/app_theme.dart';
import 'package:ic_card_reader/src/core/widgets/app_ui.dart';
import 'package:ic_card_reader/src/features/card_reader/domain/raw_history_block.dart';
import 'package:ic_card_reader/src/features/issue_report/domain/issue_report.dart';
import 'package:ic_card_reader/src/features/issue_report/domain/issue_report_repository.dart';
import 'package:ic_card_reader/src/features/issue_report/presentation/issue_report_page.dart';
import 'package:ic_card_reader/src/features/transaction_history/data/transit_history_parser.dart';

void main() {
  test('serializes one anonymous record without prohibited identifiers', () {
    final report = _report();
    final json = report.toJson();

    expect(json['anonymousRawRecord'], hasLength(32));
    expect(json['usageDate'], '2026-07-04');
    expect(json['issueType'], 'WRONG_BOARDING_STATION');
    expect(json.keys.map((key) => key.toLowerCase()), isNot(contains('idm')));
    expect(json.keys, isNot(contains('deviceId')));
    expect(json.keys, isNot(contains('allHistories')));
  });

  test('serializes both corrected stations with city and optional line', () {
    final json = IssueReport(
      anonymousReportId: '550e8400-e29b-41d4-a716-446655440000',
      anonymousRawRecord: '1601000234E4A578AC38E20300012950',
      issueType: IssueType.wrongStationName,
      regionCode: 0x50,
      boardingLineCode: 0xA5,
      boardingStationCode: 0x78,
      alightingLineCode: 0xAC,
      alightingStationCode: 0x38,
      currentTransactionType: 'RAIL',
      usageDate: DateTime(2026, 7, 4),
      balance: 994,
      parserVersion: TransitHistoryParser.version,
      stationDatabaseVersion: 'test-stations-v1',
      appVersion: '1.0.0+1',
      platform: 'android',
      osVersion: 'test',
      stationIssueScope: StationIssueScope.both,
      correctedBoardingStation: const StationCorrection(
        name: '渋谷',
        city: '東京都渋谷区',
        line: '銀座線',
      ),
      correctedAlightingStation: const StationCorrection(
        name: '浅草',
        city: '東京都台東区',
      ),
    ).toJson();

    expect(json['issueType'], 'WRONG_STATION_NAME');
    expect(json['stationIssueScope'], 'BOTH');
    expect(json['correctedBoardingStation'], {
      'name': '渋谷',
      'city': '東京都渋谷区',
      'line': '銀座線',
    });
    expect(json['correctedAlightingStation'], {
      'name': '浅草',
      'city': '東京都台東区',
      'line': null,
    });
  });

  test(
    'serializes the required bus company correction without a route number',
    () {
      final json = IssueReport(
        anonymousReportId: '550e8400-e29b-41d4-a716-446655440000',
        anonymousRawRecord: '050D000F34FC0F3D00002F0700004FC0',
        issueType: IssueType.busCompanyNotResolved,
        regionCode: 0x05,
        boardingLineCode: 0x0D,
        boardingStationCode: 0x00,
        alightingLineCode: 0x0F,
        alightingStationCode: 0x34,
        currentTransactionType: 'BUS',
        usageDate: DateTime(2026, 7, 4),
        balance: 994,
        parserVersion: TransitHistoryParser.version,
        stationDatabaseVersion: 'test-stations-v1',
        appVersion: '1.0.0+1',
        platform: 'android',
        osVersion: 'test',
        suggestedBusCompanyName: '伊予鉄バス',
        suggestedBusCompanyCity: '愛媛県松山市',
      ).toJson();

      expect(json['issueType'], 'BUS_COMPANY_NOT_RESOLVED');
      expect(json['suggestedBusCompanyName'], '伊予鉄バス');
      expect(json['suggestedBusCompanyCity'], '愛媛県松山市');
      expect(json.keys, isNot(contains('busRouteNumber')));
    },
  );

  testWidgets('submits the selected history through the repository', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _RecordingRepository();
    final history = const TransitHistoryParser().parse([
      _block(0, '1601000234E4A578AC38E20300012950'),
      _block(1, '050D000F34E30D2A0000B60700012740'),
    ]).first;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: IssueReportPage(history: history, repository: repository),
      ),
    );

    final reportSafeArea = find.ancestor(
      of: find.byType(AppPage),
      matching: find.byType(SafeArea),
    );
    final safeArea = tester.widget<SafeArea>(reportSafeArea);
    expect(safeArea.top, isFalse);
    expect(safeArea.bottom, isTrue);
    expect(find.text('버스 회사 정보가 없거나 잘못됨'), findsNothing);

    await tester.tap(find.text('금액 또는 잔액이 잘못됨'));
    await tester.pump();
    await tester.dragUntilVisible(
      find.text('다음'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('검토하기'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('위 정보의 전송에 동의합니다.'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('위 정보의 전송에 동의합니다.'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('익명으로 제보하기'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('익명으로 제보하기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.submitted, hasLength(1));
    expect(
      repository.submitted.single.anonymousRawRecord,
      history.rawBlock.hexadecimal,
    );
    expect(find.text('제보가 접수되었습니다'), findsOneWidget);
    expect(find.text('접수 번호'), findsOneWidget);
    expect(find.text('server-report-id'), findsOneWidget);
    expect(find.text('카드 IDm과 다른 이용내역은 전송되지 않았습니다.'), findsOneWidget);
    expect(find.text('확인'), findsOneWidget);
  });

  testWidgets(
    'asks for both station corrections when both stations are wrong',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final history = const TransitHistoryParser().parse([
        _block(0, '1601000234E4A578AC38E20300012950'),
        _block(1, '050D000F34E30D2A0000B60700012740'),
      ]).first;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: IssueReportPage(history: history),
        ),
      );
      await tester.tap(find.text('역 정보가 없거나 잘못됨'));
      await tester.pump();
      await tester.dragUntilVisible(
        find.text('다음'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('승차역·하차역을 선택해 주세요'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('승차역과 하차역 모두').last);
      await tester.pumpAndSettle();

      expect(find.text('올바른 승차역'), findsOneWidget);
      expect(find.text('올바른 하차역'), findsOneWidget);
      expect(find.text('노선명 (선택)'), findsNWidgets(2));
    },
  );

  testWidgets('shows the bus company report type only for bus history', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final busHistory = const TransitHistoryParser().parse([
      _block(0, '050D000F34FC0F3D00002F0700004FC0'),
    ]).single;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: IssueReportPage(history: busHistory),
      ),
    );

    expect(find.text('버스 회사 정보가 없거나 잘못됨'), findsOneWidget);
    await tester.tap(find.text('버스 회사 정보가 없거나 잘못됨'));
    await tester.pump();
    await tester.dragUntilVisible(
      find.text('다음'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    expect(find.text('실제 버스 회사명'), findsOneWidget);
    expect(find.text('운행 도시·지역'), findsOneWidget);
    expect(find.text('노선 번호'), findsNothing);
  });

  testWidgets('chooses a suggested transaction type from a bottom sheet', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final history = const TransitHistoryParser().parse([
      _block(0, '1601000234E4A578AC38E20300012950'),
    ]).single;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: IssueReportPage(history: history),
      ),
    );
    await tester.tap(find.text('거래 유형이 잘못됨'));
    await tester.pump();
    await tester.dragUntilVisible(
      find.text('다음'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('유형을 선택해 주세요'));
    await tester.pumpAndSettle();
    expect(find.text('올바른 거래 유형을 선택해 주세요'), findsOneWidget);
    await tester.tap(find.text('물품 구매'));
    await tester.pumpAndSettle();

    expect(find.text('물품 구매'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
  });
}

IssueReport _report() => IssueReport(
  anonymousReportId: '550e8400-e29b-41d4-a716-446655440000',
  anonymousRawRecord: '1601000234E4A578AC38E20300012950',
  issueType: IssueType.wrongBoardingStation,
  regionCode: 0x50,
  boardingLineCode: 0xA5,
  boardingStationCode: 0x78,
  alightingLineCode: 0xAC,
  alightingStationCode: 0x38,
  currentTransactionType: 'RAIL',
  usageDate: DateTime(2026, 7, 4),
  balance: 994,
  calculatedAmount: 980,
  parserVersion: TransitHistoryParser.version,
  stationDatabaseVersion: 'test-stations-v1',
  appVersion: '1.0.0+1',
  platform: 'android',
  osVersion: 'test',
);

RawHistoryBlock _block(int index, String hexadecimal) => RawHistoryBlock(
  index: index,
  bytes: Uint8List.fromList([
    for (var offset = 0; offset < hexadecimal.length; offset += 2)
      int.parse(hexadecimal.substring(offset, offset + 2), radix: 16),
  ]),
);

class _RecordingRepository implements IssueReportRepository {
  final List<IssueReport> submitted = [];

  @override
  Future<IssueReportReceipt> submit(IssueReport report) async {
    submitted.add(report);
    return const IssueReportReceipt(
      reportId: 'server-report-id',
      reviewStatus: 'RECEIVED',
    );
  }
}
