import '../data/nagasaki_electric_tramway_pass_data.dart';

enum NagasakiElectricTramwayPassType { oneDay, twentyFourHours }

extension NagasakiElectricTramwayPassTypeDetails
    on NagasakiElectricTramwayPassType {
  String get displayName => switch (this) {
    NagasakiElectricTramwayPassType.oneDay => '나가사키 전기궤도 1일권',
    NagasakiElectricTramwayPassType.twentyFourHours => '나가사키 전기궤도 24시간권',
  };

  String get optionName => switch (this) {
    NagasakiElectricTramwayPassType.oneDay => '1일권',
    NagasakiElectricTramwayPassType.twentyFourHours => '24시간권',
  };

  int get price => switch (this) {
    NagasakiElectricTramwayPassType.oneDay => 600,
    NagasakiElectricTramwayPassType.twentyFourHours => 700,
  };
}

enum NagasakiElectricTramwayPassVerdict {
  beneficial,
  breakEven,
  notBeneficial,
  insufficientData,
}

class NagasakiElectricTramwayPlannedSegment {
  const NagasakiElectricTramwayPlannedSegment({
    required this.from,
    required this.to,
    required this.fare,
  });

  final NagasakiElectricTramwayStation from;
  final NagasakiElectricTramwayStation to;
  final int fare;
}

class NagasakiElectricTramwayPassComparisonResult {
  const NagasakiElectricTramwayPassComparisonResult({
    required this.passType,
    required this.segments,
    required this.regularFareTotal,
    required this.savings,
    required this.verdict,
  });

  final NagasakiElectricTramwayPassType passType;
  final List<NagasakiElectricTramwayPlannedSegment> segments;
  final int regularFareTotal;
  final int savings;
  final NagasakiElectricTramwayPassVerdict verdict;
}

abstract final class NagasakiElectricTramwayPassEvaluator {
  static NagasakiElectricTramwayPassComparisonResult evaluate(
    List<NagasakiElectricTramwayPlannedSegment> segments, {
    NagasakiElectricTramwayPassType passType =
        NagasakiElectricTramwayPassType.oneDay,
  }) {
    final valid = segments.where((item) => item.fare > 0).toList();
    final total = valid.fold(0, (sum, item) => sum + item.fare);
    final savings = total - passType.price;
    return NagasakiElectricTramwayPassComparisonResult(
      passType: passType,
      segments: valid,
      regularFareTotal: total,
      savings: savings,
      verdict: valid.isEmpty
          ? NagasakiElectricTramwayPassVerdict.insufficientData
          : savings > 0
          ? NagasakiElectricTramwayPassVerdict.beneficial
          : savings == 0
          ? NagasakiElectricTramwayPassVerdict.breakEven
          : NagasakiElectricTramwayPassVerdict.notBeneficial,
    );
  }
}
