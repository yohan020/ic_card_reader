import '../data/hankyu_1day_pass_data.dart';

enum HankyuPassVerdict {
  beneficial,
  breakEven,
  notBeneficial,
  insufficientData,
}

class HankyuPlannedSegment {
  const HankyuPlannedSegment({
    required this.from,
    required this.to,
    required this.fare,
  });

  final HankyuStation from;
  final HankyuStation to;
  final int fare;
}

class HankyuPassComparisonResult {
  const HankyuPassComparisonResult({
    required this.segments,
    required this.regularFareTotal,
    required this.savings,
    required this.verdict,
  });

  final List<HankyuPlannedSegment> segments;
  final int regularFareTotal;
  final int savings;
  final HankyuPassVerdict verdict;
}

abstract final class Hankyu1DayPassEvaluator {
  static HankyuPassComparisonResult evaluate({
    required List<HankyuPlannedSegment> segments,
    required Hankyu1DayPassData data,
  }) {
    final valid = segments.where((segment) => segment.fare > 0).toList();
    final total = valid.fold(0, (sum, segment) => sum + segment.fare);
    final savings = total - data.passPrice;
    return HankyuPassComparisonResult(
      segments: valid,
      regularFareTotal: total,
      savings: savings,
      verdict: valid.isEmpty
          ? HankyuPassVerdict.insufficientData
          : savings > 0
          ? HankyuPassVerdict.beneficial
          : savings == 0
          ? HankyuPassVerdict.breakEven
          : HankyuPassVerdict.notBeneficial,
    );
  }
}
