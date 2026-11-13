import '../data/sapporo_subway_pass_data.dart';

enum SapporoSubwayPassType { standardDay, donichika }

extension SapporoSubwayPassTypeDetails on SapporoSubwayPassType {
  String get displayName => switch (this) {
    SapporoSubwayPassType.standardDay => '삿포로 지하철 1일권',
    SapporoSubwayPassType.donichika => '도니치카 킵',
  };

  String get optionName => switch (this) {
    SapporoSubwayPassType.standardDay => '일반 1일권',
    SapporoSubwayPassType.donichika => '도니치카 킵',
  };

  int get price => switch (this) {
    SapporoSubwayPassType.standardDay => 830,
    SapporoSubwayPassType.donichika => 520,
  };
}

enum SapporoSubwayPassVerdict {
  beneficial,
  breakEven,
  notBeneficial,
  insufficientData,
}

class SapporoSubwayPlannedSegment {
  const SapporoSubwayPlannedSegment({
    required this.from,
    required this.to,
    required this.fare,
  });
  final SapporoSubwayStation from;
  final SapporoSubwayStation to;
  final int fare;
}

class SapporoSubwayPassComparisonResult {
  const SapporoSubwayPassComparisonResult({
    required this.passType,
    required this.segments,
    required this.regularFareTotal,
    required this.savings,
    required this.verdict,
  });
  final SapporoSubwayPassType passType;
  final List<SapporoSubwayPlannedSegment> segments;
  final int regularFareTotal;
  final int savings;
  final SapporoSubwayPassVerdict verdict;
}

abstract final class SapporoSubwayPassEvaluator {
  static SapporoSubwayPassComparisonResult evaluate(
    List<SapporoSubwayPlannedSegment> segments, {
    SapporoSubwayPassType passType = SapporoSubwayPassType.standardDay,
  }) {
    final valid = segments.where((item) => item.fare > 0).toList();
    final total = valid.fold(0, (sum, item) => sum + item.fare);
    final savings = total - passType.price;
    return SapporoSubwayPassComparisonResult(
      passType: passType,
      segments: valid,
      regularFareTotal: total,
      savings: savings,
      verdict: valid.isEmpty
          ? SapporoSubwayPassVerdict.insufficientData
          : savings > 0
          ? SapporoSubwayPassVerdict.beneficial
          : savings == 0
          ? SapporoSubwayPassVerdict.breakEven
          : SapporoSubwayPassVerdict.notBeneficial,
    );
  }
}
