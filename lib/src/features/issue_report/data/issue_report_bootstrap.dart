import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/issue_report_repository.dart';
import 'supabase_issue_report_repository.dart';

class IssueReportBootstrap {
  const IssueReportBootstrap._();

  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static Future<IssueReportRepository> initialize() async {
    if (_url.isEmpty || _publishableKey.isEmpty) {
      return const UnavailableIssueReportRepository();
    }
    try {
      await Supabase.initialize(url: _url, publishableKey: _publishableKey);
      return SupabaseIssueReportRepository(Supabase.instance.client);
    } catch (_) {
      return const UnavailableIssueReportRepository();
    }
  }
}
