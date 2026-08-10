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
  final DateTime? usageDate;
  final int balance;
  final int? calculatedAmount;
  final String? additionalDescription;
  final String parserVersion;
  final String stationDatabaseVersion;
  final String appVersion;
  final String platform;
  final String osVersion;
  final IssueReportStatus status;

  Map<String, Object?> toJson() => {
    'anonymousReportId': anonymousReportId,
    'anonymousRawRecord': anonymousRawRecord,
    'issueType': issueType.wireName,
    'regionCode': regionCode,
    'boardingLineCode': boardingLineCode,
    'boardingStationCode': boardingStationCode,
    'alightingLineCode': alightingLineCode,
    'alightingStationCode': alightingStationCode,
    'currentBoardingStation': currentBoardingStation,
    'currentAlightingStation': currentAlightingStation,
    'suggestedBoardingStation': suggestedBoardingStation,
    'suggestedAlightingStation': suggestedAlightingStation,
    'currentTransactionType': currentTransactionType,
    'suggestedTransactionType': suggestedTransactionType,
    'usageDate': usageDate == null
        ? null
        : '${usageDate!.year.toString().padLeft(4, '0')}-'
              '${usageDate!.month.toString().padLeft(2, '0')}-'
              '${usageDate!.day.toString().padLeft(2, '0')}',
    'balance': balance,
    'calculatedAmount': calculatedAmount,
    'additionalDescription': additionalDescription,
    'parserVersion': parserVersion,
    'stationDatabaseVersion': stationDatabaseVersion,
    'appVersion': appVersion,
    'platform': platform,
    'osVersion': osVersion,
  };
}

extension on IssueType {
  String get wireName => switch (this) {
    IssueType.wrongBoardingStation => 'WRONG_BOARDING_STATION',
    IssueType.wrongAlightingStation => 'WRONG_ALIGHTING_STATION',
    IssueType.stationNotResolved => 'STATION_NOT_RESOLVED',
    IssueType.wrongTransactionType => 'WRONG_TRANSACTION_TYPE',
    IssueType.wrongAmountOrBalance => 'WRONG_AMOUNT_OR_BALANCE',
    IssueType.other => 'OTHER',
  };
}

class IssueReportReceipt {
  const IssueReportReceipt({
    required this.reportId,
    required this.reviewStatus,
  });

  final String reportId;
  final String reviewStatus;
}
