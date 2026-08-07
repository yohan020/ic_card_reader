enum IssueType {
  wrongBoardingStation,
  wrongAlightingStation,
  stationNotResolved,
  wrongTransactionType,
  wrongAmountOrBalance,
  other,
}

enum IssueReportStatus { pending, submitted, failed }

/// Draft contract only. The report feature is not wired to Phase 1 UI.
/// [anonymousRawRecord] is exactly one 16-byte record and must never include IDm.
class IssueReport {
  const IssueReport({
    required this.anonymousReportId,
    required this.anonymousRawRecord,
    required this.issueType,
    required this.regionCode,
    required this.boardingLineCode,
    required this.boardingStationCode,
    required this.alightingLineCode,
    required this.alightingStationCode,
    required this.currentTransactionType,
    required this.usageDate,
    required this.balance,
    required this.parserVersion,
    required this.stationDatabaseVersion,
    required this.appVersion,
    required this.platform,
    required this.osVersion,
    required this.deduplicationKey,
    this.currentBoardingStation,
    this.currentAlightingStation,
    this.suggestedBoardingStation,
    this.suggestedAlightingStation,
    this.suggestedTransactionType,
    this.calculatedAmount,
    this.additionalDescription,
    this.status = IssueReportStatus.pending,
  });

  final String anonymousReportId;
  final String anonymousRawRecord;
  final IssueType issueType;
  final int regionCode;
  final int boardingLineCode;
  final int boardingStationCode;
  final int alightingLineCode;
  final int alightingStationCode;
  final String? currentBoardingStation;
  final String? currentAlightingStation;
  final String? suggestedBoardingStation;
  final String? suggestedAlightingStation;
  final String currentTransactionType;
  final String? suggestedTransactionType;
  final DateTime usageDate;
  final int balance;
  final int? calculatedAmount;
  final String? additionalDescription;
  final String parserVersion;
  final String stationDatabaseVersion;
  final String appVersion;
  final String platform;
  final String osVersion;
  final String deduplicationKey;
  final IssueReportStatus status;
}
