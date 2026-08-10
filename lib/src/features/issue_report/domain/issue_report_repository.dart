import 'issue_report.dart';

abstract interface class IssueReportRepository {
  Future<IssueReportReceipt> submit(IssueReport report);
}

class IssueReportSubmissionException implements Exception {
  const IssueReportSubmissionException(this.message);

  final String message;

  @override
  String toString() => message;
}
