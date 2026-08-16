enum IssueType {
  wrongStationName,
  wrongBoardingStation,
  wrongAlightingStation,
  wrongBothStations,
  stationNotResolved,
  busCompanyNotResolved,
  koreanStationNameRequest,
  wrongTransactionType,
  wrongAmountOrBalance,
  other,
}

enum StationIssueScope { boarding, alighting, both }

class StationCorrection {
  const StationCorrection({required this.name, required this.city, this.line});

  final String name;
  final String city;
  final String? line;

  Map<String, String?> toJson() => {'name': name, 'city': city, 'line': line};
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
    this.stationIssueScope,
    this.correctedBoardingStation,
    this.correctedAlightingStation,
    this.suggestedBusCompanyName,
    this.suggestedBusCompanyCity,
    this.suggestedKoreanBoardingStationName,
    this.suggestedKoreanAlightingStationName,
    this.suggestedTransactionType,
    this.customSuggestedTransactionType,
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
  final StationIssueScope? stationIssueScope;
  final StationCorrection? correctedBoardingStation;
  final StationCorrection? correctedAlightingStation;
  final String? suggestedBusCompanyName;
  final String? suggestedBusCompanyCity;
  final String? suggestedKoreanBoardingStationName;
  final String? suggestedKoreanAlightingStationName;
  final String currentTransactionType;
  final String? suggestedTransactionType;
  final String? customSuggestedTransactionType;
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
    'stationIssueScope': stationIssueScope?.wireName,
    'correctedBoardingStation': correctedBoardingStation?.toJson(),
    'correctedAlightingStation': correctedAlightingStation?.toJson(),
    'suggestedBusCompanyName': suggestedBusCompanyName,
    'suggestedBusCompanyCity': suggestedBusCompanyCity,
    'suggestedKoreanBoardingStationName': suggestedKoreanBoardingStationName,
    'suggestedKoreanAlightingStationName': suggestedKoreanAlightingStationName,
    'currentTransactionType': currentTransactionType,
    'suggestedTransactionType': suggestedTransactionType,
    'customSuggestedTransactionType': customSuggestedTransactionType,
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
    IssueType.wrongStationName => 'WRONG_STATION_NAME',
    IssueType.wrongBoardingStation => 'WRONG_BOARDING_STATION',
    IssueType.wrongAlightingStation => 'WRONG_ALIGHTING_STATION',
    IssueType.wrongBothStations => 'WRONG_BOTH_STATIONS',
    IssueType.stationNotResolved => 'STATION_NOT_RESOLVED',
    IssueType.busCompanyNotResolved => 'BUS_COMPANY_NOT_RESOLVED',
    IssueType.koreanStationNameRequest => 'KOREAN_STATION_NAME_REQUEST',
    IssueType.wrongTransactionType => 'WRONG_TRANSACTION_TYPE',
    IssueType.wrongAmountOrBalance => 'WRONG_AMOUNT_OR_BALANCE',
    IssueType.other => 'OTHER',
  };
}

extension on StationIssueScope {
  String get wireName => switch (this) {
    StationIssueScope.boarding => 'BOARDING',
    StationIssueScope.alighting => 'ALIGHTING',
    StationIssueScope.both => 'BOTH',
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
