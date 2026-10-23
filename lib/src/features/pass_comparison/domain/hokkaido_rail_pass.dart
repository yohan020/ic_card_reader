import '../data/hokkaido_rail_pass_data.dart';

enum HokkaidoRailTravelMode { localRapid, limitedExpress }

class HokkaidoRailPassPlannedSegment {
  const HokkaidoRailPassPlannedSegment({
    required this.from,
    required this.to,
    required this.fare,
    required this.mode,
  });

  final HokkaidoRailPassStation from;
  final HokkaidoRailPassStation to;
  final int fare;
  final HokkaidoRailTravelMode mode;
}

enum HokkaidoRailPassVerdict {
  beneficial,
  breakEven,
  notBeneficial,
  insufficientData,
}

class HokkaidoRailPassComparisonResult {
  const HokkaidoRailPassComparisonResult({
    required this.segments,
    required this.railFareTotal,
    required this.estimatedBusValue,
    required this.passPrice,
    required this.savings,
    required this.verdict,
  });

  final List<HokkaidoRailPassPlannedSegment> segments;
  final int railFareTotal;
  final int estimatedBusValue;
  final int passPrice;
  final int savings;
  final HokkaidoRailPassVerdict verdict;
}

abstract final class HokkaidoRailPassEvaluator {
  static HokkaidoRailPassComparisonResult evaluate({
    required List<HokkaidoRailPassPlannedSegment> segments,
    required int estimatedBusRides,
    required int passPrice,
  }) {
    final valid = segments.where((segment) => segment.fare > 0).toList();
    final railFareTotal = valid.fold(0, (sum, segment) => sum + segment.fare);
    const estimatedBusFarePerRide = 300;
    final estimatedBusValue = estimatedBusRides * estimatedBusFarePerRide;
    final total = railFareTotal + estimatedBusValue;
    final savings = total - passPrice;
    return HokkaidoRailPassComparisonResult(
      segments: valid,
      railFareTotal: railFareTotal,
      estimatedBusValue: estimatedBusValue,
      passPrice: passPrice,
      savings: savings,
      verdict: total == 0
          ? HokkaidoRailPassVerdict.insufficientData
          : savings > 0
          ? HokkaidoRailPassVerdict.beneficial
          : savings == 0
          ? HokkaidoRailPassVerdict.breakEven
          : HokkaidoRailPassVerdict.notBeneficial,
    );
  }
}
