import '../data/fukuoka_city_subway_pass_data.dart';

enum FukuokaCitySubwayPassVerdict {
  beneficial,
  breakEven,
  notBeneficial,
  insufficientData,
}

class FukuokaCitySubwayPlannedSegment {
  const FukuokaCitySubwayPlannedSegment({
    required this.from,
    required this.to,
    required this.fare,
  });

  final FukuokaSubwayStation from;
  final FukuokaSubwayStation to;
  final int fare;
}

class FukuokaCitySubwayPassComparisonResult {
  const FukuokaCitySubwayPassComparisonResult({
    required this.segments,
    required this.regularFareTotal,
    required this.savings,
    required this.verdict,
  });

  final List<FukuokaCitySubwayPlannedSegment> segments;
  final int regularFareTotal;
  final int savings;
  final FukuokaCitySubwayPassVerdict verdict;
}

abstract final class FukuokaCitySubwayPassEvaluator {
  static FukuokaCitySubwayPassComparisonResult evaluate(
    List<FukuokaCitySubwayPlannedSegment> segments,
  ) {
    final valid = segments.where((item) => item.fare > 0).toList();
    final total = valid.fold(0, (sum, item) => sum + item.fare);
    final savings = total - FukuokaCitySubwayPassData.passPrice;
    return FukuokaCitySubwayPassComparisonResult(
      segments: valid,
      regularFareTotal: total,
      savings: savings,
      verdict: valid.isEmpty
          ? FukuokaCitySubwayPassVerdict.insufficientData
          : savings > 0
          ? FukuokaCitySubwayPassVerdict.beneficial
          : savings == 0
          ? FukuokaCitySubwayPassVerdict.breakEven
          : FukuokaCitySubwayPassVerdict.notBeneficial,
    );
  }
}
