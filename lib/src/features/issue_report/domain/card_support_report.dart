import '../../card_reader/domain/card_diagnostics.dart';
import '../../card_reader/domain/card_scan_result.dart';

const cardSupportConsentVersion = '2026-10-26-v1';

enum CardSupportCategory {
  unreadable('UNREADABLE', '카드를 읽을 수 없어요'),
  brandUnknown('BRAND_UNKNOWN', '카드 브랜드가 표시되지 않거나 달라요');

  const CardSupportCategory(this.code, this.label);
  final String code;
  final String label;
}

/// Explicit allowlist only. No tag/raw response, IDm, history, balance or token.
class CardSupportDiagnostic {
  const CardSupportDiagnostic._(this.report, this.failure);

  factory CardSupportDiagnostic.fromReport(CardDiagnosticReport report) =>
      CardSupportDiagnostic._(report, null);

  factory CardSupportDiagnostic.fromFailure(CardScanFailureKind failure) =>
      CardSupportDiagnostic._(null, failure);

  final CardDiagnosticReport? report;
  final CardScanFailureKind? failure;

  Map<String, Object?> toJson() => {
    'technology': report == null ? 'unknown' : 'NFC-F',
    'initial_system_code': report?.initialSystemCode,
    'pmm': report?.pmm,
    'system_code_status': report?.systemCodeStatus ?? 'unavailable',
    'system_code_issue': report?.systemCodeIssue?.code,
    'system_codes': report?.systemCodes.take(32).toList() ?? <String>[],
    'service_probe': report?.serviceProbe?.toLogFields(),
    'scan_failure': failure?.name,
  };
}

class CardSupportReport {
  const CardSupportReport({
    required this.reportId,
    required this.category,
    required this.expectedBrand,
    required this.description,
    required this.diagnostic,
    required this.appVersion,
    required this.platform,
    required this.osVersion,
  });

  final String reportId;
  final CardSupportCategory category;
  final String expectedBrand;
  final String description;
  final CardSupportDiagnostic diagnostic;
  final String appVersion;
  final String platform;
  final String osVersion;

  Map<String, Object?> toJson() => {
    'schema': 1,
    'anonymousReportId': reportId,
    'category': category.code,
    'expectedBrand': expectedBrand.trim(),
    'description': description.trim(),
    'diagnostics': diagnostic.toJson(),
    'appVersion': appVersion,
    'platform': platform,
    'osVersion': osVersion,
    'consentVersion': cardSupportConsentVersion,
  };
}

abstract interface class CardSupportRepository {
  Future<String> submitCardSupport(CardSupportReport report);
}
