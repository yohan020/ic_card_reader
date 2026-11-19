import '../data/hiroden_pass_data.dart';

enum HirodenPassType { paperOneDay, digitalEightHours, digitalTwentyFourHours }

extension HirodenPassTypeDetails on HirodenPassType {
  String get displayName => switch (this) {
    HirodenPassType.paperOneDay => '히로덴 전차 1일권',
    HirodenPassType.digitalEightHours => '히로덴 전차 8시간권',
    HirodenPassType.digitalTwentyFourHours => '히로덴 전차 24시간권',
  };

  String get optionName => switch (this) {
    HirodenPassType.paperOneDay => '1일권',
    HirodenPassType.digitalEightHours => '8시간권',
    HirodenPassType.digitalTwentyFourHours => '24시간권',
  };

  int get price => switch (this) {
    HirodenPassType.paperOneDay => 700,
    HirodenPassType.digitalEightHours => 600,
    HirodenPassType.digitalTwentyFourHours => 700,
  };
}

enum HirodenPassVerdict {
  beneficial,
  breakEven,
  notBeneficial,
  insufficientData,
}

class HirodenPlannedSegment {
  const HirodenPlannedSegment({
    required this.from,
    required this.to,
    required this.fare,
  });

  final HirodenStation from;
  final HirodenStation to;
  final int fare;
}

class HirodenPassComparisonResult {
  const HirodenPassComparisonResult({
    required this.passType,
    required this.segments,
    required this.regularFareTotal,
    required this.savings,
    required this.verdict,
  });

  final HirodenPassType passType;
  final List<HirodenPlannedSegment> segments;
  final int regularFareTotal;
  final int savings;
  final HirodenPassVerdict verdict;
}

abstract final class HirodenPassEvaluator {
  static HirodenPassComparisonResult evaluate(
    List<HirodenPlannedSegment> segments, {
    HirodenPassType passType = HirodenPassType.paperOneDay,
  }) {
    final valid = segments.where((item) => item.fare > 0).toList();
    final total = valid.fold(0, (sum, item) => sum + item.fare);
    final savings = total - passType.price;
    return HirodenPassComparisonResult(
      passType: passType,
      segments: valid,
      regularFareTotal: total,
      savings: savings,
      verdict: valid.isEmpty
          ? HirodenPassVerdict.insufficientData
          : savings > 0
          ? HirodenPassVerdict.beneficial
          : savings == 0
          ? HirodenPassVerdict.breakEven
          : HirodenPassVerdict.notBeneficial,
    );
  }
}
