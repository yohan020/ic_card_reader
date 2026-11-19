import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/issue_report/data/issue_report_bootstrap.dart';
import 'package:ic_card_reader/src/features/issue_report/data/supabase_issue_report_repository.dart';
import 'package:ic_card_reader/src/features/issue_report/domain/card_support_report.dart';
import 'package:ic_card_reader/src/features/issue_report/domain/issue_report.dart';
import 'package:ic_card_reader/src/features/issue_report/domain/issue_report_repository.dart';

void main() {
  test('includes the production publishable Supabase configuration', () {
    expect(IssueReportBootstrap.isConfigured, isTrue);
    expect(IssueReportBootstrap.repository(), isA<CardSupportRepository>());
  });

  test('only explicit submissions initialize and share the backend', () async {
    final pending = Completer<IssueReportRepository>();
    var initializations = 0;
    final repository = LazyIssueReportRepository(() {
      initializations++;
      return pending.future;
    });
    expect(initializations, 0);

    final issue = repository.submit(_Issue());
    final support = repository.submitCardSupport(_Support());
    expect(initializations, 1);
    pending.complete(_Repository());
    expect((await issue).reportId, 'issue');
    expect(await support, 'support');
    expect((await repository.submit(_Issue())).reportId, 'issue');
    expect(initializations, 1);
  });

  test('failed initialization can be retried by either report type', () async {
    var initializations = 0;
    final repository = LazyIssueReportRepository(() {
      switch (++initializations) {
        case 1:
          throw StateError('synthetic startup error');
        case 2:
          return Future.value(const UnavailableIssueReportRepository());
        default:
          return Future.value(_Repository());
      }
    });
    await expectLater(
      repository.submitCardSupport(_Support()),
      throwsA(isA<IssueReportSubmissionException>()),
    );
    await expectLater(
      repository.submit(_Issue()),
      throwsA(isA<IssueReportSubmissionException>()),
    );
    expect(await repository.submitCardSupport(_Support()), 'support');
    expect(initializations, 3);
  });
}

class _Issue extends Fake implements IssueReport {}

class _Support extends Fake implements CardSupportReport {}

class _Repository implements IssueReportRepository, CardSupportRepository {
  @override
  Future<IssueReportReceipt> submit(IssueReport report) async =>
      IssueReportReceipt(reportId: 'issue', reviewStatus: 'received');

  @override
  Future<String> submitCardSupport(CardSupportReport report) async => 'support';
}
