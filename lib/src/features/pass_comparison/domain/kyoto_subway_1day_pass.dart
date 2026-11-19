import '../data/kyoto_subway_1day_pass_data.dart';
import '../data/kyoto_subway_bus_pass_data.dart';

enum KyotoSubway1DayPassVerdict {
  beneficial,
  breakEven,
  notBeneficial,
  insufficientData,
}

class KyotoSubway1DayPlannedSegment {
  const KyotoSubway1DayPlannedSegment({
    required this.from,
    required this.to,
    required this.fare,
  });

  final KyotoSubwayStation from;
  final KyotoSubwayStation to;
  final int fare;
}

class KyotoSubway1DayPassComparisonResult {
  const KyotoSubway1DayPassComparisonResult({
    required this.segments,
    required this.regularFareTotal,
    required this.savings,
    required this.verdict,
  });

  final List<KyotoSubway1DayPlannedSegment> segments;
  final int regularFareTotal;
  final int savings;
  final KyotoSubway1DayPassVerdict verdict;
}

abstract final class KyotoSubway1DayPassEvaluator {
  static KyotoSubway1DayPassComparisonResult evaluate(
    List<KyotoSubway1DayPlannedSegment> segments,
  ) {
    final valid = segments.where((segment) => segment.fare > 0).toList();
    final total = valid.fold<int>(0, (sum, segment) => sum + segment.fare);
    final savings = total - KyotoSubway1DayPassData.passPrice;
    return KyotoSubway1DayPassComparisonResult(
      segments: valid,
      regularFareTotal: total,
      savings: savings,
      verdict: valid.isEmpty
          ? KyotoSubway1DayPassVerdict.insufficientData
          : savings > 0
          ? KyotoSubway1DayPassVerdict.beneficial
          : savings == 0
          ? KyotoSubway1DayPassVerdict.breakEven
          : KyotoSubway1DayPassVerdict.notBeneficial,
    );
  }
}
