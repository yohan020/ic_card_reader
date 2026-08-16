import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/issue_report/data/issue_report_bootstrap.dart';

void main() {
  test('includes the production publishable Supabase configuration', () {
    expect(IssueReportBootstrap.isConfigured, isTrue);
  });
}
