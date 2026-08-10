import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
        home: IssueReportPage(history: history, repository: repository),
      ),
    );

    await tester.tap(find.text('승차역이 잘못됨'));
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
