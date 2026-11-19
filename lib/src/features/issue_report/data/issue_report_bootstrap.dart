import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/card_support_report.dart';
import '../domain/issue_report.dart';
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

  static IssueReportRepository repository() => isConfigured
      ? LazyIssueReportRepository(initialize)
      : const UnavailableIssueReportRepository();

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

/// Both report screens stay offline until the user explicitly submits.
class LazyIssueReportRepository
    implements IssueReportRepository, CardSupportRepository {
  LazyIssueReportRepository(this._initialize);

  final Future<IssueReportRepository> Function() _initialize;
  Future<IssueReportRepository>? _initialization;

  Future<IssueReportRepository> _getRepository() =>
      _initialization ??= _loadRepository();

  Future<IssueReportRepository> _loadRepository() async {
    try {
      final repository = await Future.sync(_initialize);
      if (repository is UnavailableIssueReportRepository) {
        _initialization = null;
      }
      return repository;
    } catch (_) {
      _initialization = null;
      return const UnavailableIssueReportRepository();
    }
  }

  @override
  Future<IssueReportReceipt> submit(IssueReport report) async =>
      (await _getRepository()).submit(report);

  @override
  Future<String> submitCardSupport(CardSupportReport report) async {
    final repository = await _getRepository();
    if (repository is CardSupportRepository) {
      return (repository as CardSupportRepository).submitCardSupport(report);
    }
    throw const IssueReportSubmissionException(
      '문의 서버에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.',
    );
  }
}
