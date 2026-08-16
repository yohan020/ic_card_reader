import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/issue_report.dart';
import '../domain/issue_report_repository.dart';

class SupabaseIssueReportRepository implements IssueReportRepository {
  SupabaseIssueReportRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<IssueReportReceipt> submit(IssueReport report) async {
    try {
      if (_client.auth.currentSession == null) {
        await _client.auth.signInAnonymously();
      }
      final response = await _client.functions.invoke(
        'ic-card-report',
        body: report.toJson(),
      );
      if (response.status != 202 || response.data is! Map) {
        throw const IssueReportSubmissionException(
          '제보를 접수하지 못했습니다. 잠시 후 다시 시도해 주세요.',
        );
      }
      final data = Map<String, dynamic>.from(response.data as Map);
      final reportId = data['reportId'];
      final reviewStatus = data['reviewStatus'];
      if (reportId is! String || reviewStatus is! String) {
        throw const IssueReportSubmissionException(
          '서버 응답을 확인할 수 없습니다. 잠시 후 다시 시도해 주세요.',
        );
      }
      return IssueReportReceipt(reportId: reportId, reviewStatus: reviewStatus);
    } on IssueReportSubmissionException {
      rethrow;
    } on AuthException {
      throw const IssueReportSubmissionException(
        '익명 연결을 시작하지 못했습니다. 인터넷 연결을 확인해 주세요.',
      );
    } on FunctionException catch (error) {
      if (error.status == 409) {
        throw const IssueReportSubmissionException('이미 접수된 제보입니다.');
      }
      if (error.status == 429) {
        throw const IssueReportSubmissionException(
          '짧은 시간에 제보가 많이 접수되었습니다. 10분 뒤 다시 시도해 주세요.',
        );
      }
      if (error.status == 403) {
        throw const IssueReportSubmissionException(
          '제보 전송이 제한되었습니다. 문의가 필요하면 앱 설정의 이메일로 연락해 주세요.',
        );
      }
      if (error.status >= 400 && error.status < 500) {
        throw const IssueReportSubmissionException(
          '제보 내용을 확인할 수 없습니다. 입력 내용을 다시 확인해 주세요.',
        );
      }
      throw const IssueReportSubmissionException(
        '서버에 연결하지 못했습니다. 잠시 후 다시 시도해 주세요.',
      );
    } catch (_) {
      throw const IssueReportSubmissionException('인터넷 연결을 확인한 뒤 다시 시도해 주세요.');
    }
  }
}

class UnavailableIssueReportRepository implements IssueReportRepository {
  const UnavailableIssueReportRepository();

  @override
  Future<IssueReportReceipt> submit(IssueReport report) {
    throw const IssueReportSubmissionException(
      '오류 제보 서버가 설정되지 않았습니다. 앱 설정을 확인해 주세요.',
    );
  }
}
