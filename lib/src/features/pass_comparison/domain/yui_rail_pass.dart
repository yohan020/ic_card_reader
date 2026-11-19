import '../data/yui_rail_pass_data.dart';

enum YuiRailPassVerdict {
  beneficial,
  breakEven,
  notBeneficial,
  insufficientData,
}

class YuiRailPlannedSegment {
  const YuiRailPlannedSegment({
    required this.from,
    required this.to,
    required this.fare,
  });

  final YuiRailStation from;
  final YuiRailStation to;
  final int fare;
}

class YuiRailPassComparisonResult {
  const YuiRailPassComparisonResult({
    required this.segments,
    required this.regularFareTotal,
    required this.savings,
    required this.verdict,
    required this.passHours,
  });

  final List<YuiRailPlannedSegment> segments;
  final int regularFareTotal;
  final int savings;
  final YuiRailPassVerdict verdict;
  final int passHours;
}

abstract final class YuiRailPassEvaluator {
  static YuiRailPassComparisonResult evaluate(
    List<YuiRailPlannedSegment> segments, {
    required int passHours,
  }) {
    final valid = segments.where((item) => item.fare > 0).toList();
    final total = valid.fold(0, (sum, item) => sum + item.fare);
    final savings = total - YuiRailPassData.passPrices[passHours]!;
    return YuiRailPassComparisonResult(
      segments: valid,
      regularFareTotal: total,
      savings: savings,
      verdict: valid.isEmpty
          ? YuiRailPassVerdict.insufficientData
          : savings > 0
          ? YuiRailPassVerdict.beneficial
          : savings == 0
          ? YuiRailPassVerdict.breakEven
          : YuiRailPassVerdict.notBeneficial,
      passHours: passHours,
    );
  }
}
