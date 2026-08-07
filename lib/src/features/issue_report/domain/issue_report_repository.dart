import 'issue_report.dart';

abstract interface class IssueReportRepository {
  Future<void> enqueue(IssueReport report);

  Future<void> retryPending();

  Stream<List<IssueReport>> watchPending();
}
