import '../data/enoden_noriorikun_pass_data.dart';

enum EnodenPassVerdict { beneficial, breakEven, notBeneficial, insufficientData }

class EnodenPlannedSegment {
  const EnodenPlannedSegment({required this.from, required this.to, required this.fare});
  final EnodenStation from;
  final EnodenStation to;
  final int fare;
}

class EnodenPassComparisonResult {
  const EnodenPassComparisonResult({
    required this.segments,
    required this.regularFareTotal,
    required this.savings,
    required this.verdict,
  });
  final List<EnodenPlannedSegment> segments;
  final int regularFareTotal;
  final int savings;
  final EnodenPassVerdict verdict;
}

abstract final class EnodenNoriorikunPassEvaluator {
  static EnodenPassComparisonResult evaluate({
    required List<EnodenPlannedSegment> segments,
    required EnodenNoriorikunPassData data,
  }) {
    final valid = segments.where((item) => item.fare > 0).toList();
    final total = valid.fold(0, (sum, item) => sum + item.fare);
    final savings = total - data.passPrice;
    return EnodenPassComparisonResult(
      segments: valid,
      regularFareTotal: total,
      savings: savings,
      verdict: valid.isEmpty
          ? EnodenPassVerdict.insufficientData
          : savings > 0
          ? EnodenPassVerdict.beneficial
          : savings == 0
          ? EnodenPassVerdict.breakEven
          : EnodenPassVerdict.notBeneficial,
    );
  }
}
