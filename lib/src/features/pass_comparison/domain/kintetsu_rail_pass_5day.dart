import '../data/kintetsu_rail_pass_5day_data.dart';

enum KintetsuPassVerdict { beneficial, breakEven, notBeneficial, insufficientData }

class KintetsuPlannedSegment {
  const KintetsuPlannedSegment({required this.from, required this.to, required this.fare});
  final KintetsuStation from;
  final KintetsuStation to;
  final int fare;
}

class KintetsuPassComparisonResult {
  const KintetsuPassComparisonResult({required this.segments, required this.regularFareTotal, required this.savings, required this.verdict});
  final List<KintetsuPlannedSegment> segments;
  final int regularFareTotal;
  final int savings;
  final KintetsuPassVerdict verdict;
}

abstract final class KintetsuRailPass5DayEvaluator {
  static KintetsuPassComparisonResult evaluate({required List<KintetsuPlannedSegment> segments, required KintetsuRailPass5DayData data}) {
    final valid = segments.where((segment) => segment.fare > 0).toList(growable: false);
    final total = valid.fold(0, (sum, segment) => sum + segment.fare);
    final savings = total - data.passPrice;
    return KintetsuPassComparisonResult(
      segments: valid,
      regularFareTotal: total,
      savings: savings,
      verdict: valid.isEmpty ? KintetsuPassVerdict.insufficientData : savings > 0 ? KintetsuPassVerdict.beneficial : savings == 0 ? KintetsuPassVerdict.breakEven : KintetsuPassVerdict.notBeneficial,
    );
  }
}
