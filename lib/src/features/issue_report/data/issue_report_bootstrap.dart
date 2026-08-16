import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/issue_report_repository.dart';
import 'supabase_issue_report_repository.dart';

class IssueReportBootstrap {
  const IssueReportBootstrap._();

  static const _defaultUrl = 'https://uenyouholkxxyyaukrbz.supabase.co';
  static const _defaultPublishableKey =
      'sb_publishable_8oj_-FQFuB-fLjFsbW4rLA_Rk6HCLQV';

  static const _url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _defaultUrl,
  );
  static const _publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: _defaultPublishableKey,
  );

  static bool get isConfigured => _url.isNotEmpty && _publishableKey.isNotEmpty;

  static Future<IssueReportRepository> initialize() async {
    if (!isConfigured) {
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
