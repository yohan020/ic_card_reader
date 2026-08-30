import '../data/kyoto_subway_bus_pass_data.dart';

enum KyotoPassVerdict { beneficial, breakEven, notBeneficial, insufficientData }

class KyotoPlannedSegment {
  const KyotoPlannedSegment({
    required this.from,
    required this.to,
    required this.fare,
  });
  final KyotoSubwayStation from;
  final KyotoSubwayStation to;
  final int fare;
}

class KyotoPassComparisonResult {
  const KyotoPassComparisonResult({
    required this.segments,
    required this.cityBusRides,
    required this.sightseeingExpressRides,
    required this.railFareTotal,
    required this.busFareTotal,
    required this.regularFareTotal,
    required this.savings,
    required this.verdict,
  });
  final List<KyotoPlannedSegment> segments;
  final int cityBusRides;
  final int sightseeingExpressRides;
  final int railFareTotal;
  final int busFareTotal;
  final int regularFareTotal;
  final int savings;
  final KyotoPassVerdict verdict;
}

abstract final class KyotoSubwayBusPassEvaluator {
  static KyotoPassComparisonResult evaluate({
    required List<KyotoPlannedSegment> segments,
    required int cityBusRides,
    required int sightseeingExpressRides,
    required KyotoSubwayBusPassData data,
  }) {
    final valid = segments
        .where((segment) => segment.fare > 0)
        .toList(growable: false);
    final city = cityBusRides < 0 ? 0 : cityBusRides;
    final sightseeing = sightseeingExpressRides < 0
        ? 0
        : sightseeingExpressRides;
    final rail = valid.fold<int>(0, (total, segment) => total + segment.fare);
    final bus =
        city * data.cityBusFare + sightseeing * data.sightseeingExpressFare;
    final total = rail + bus;
    final savings = total - data.passPrice;
    return KyotoPassComparisonResult(
      segments: valid,
      cityBusRides: city,
      sightseeingExpressRides: sightseeing,
      railFareTotal: rail,
      busFareTotal: bus,
      regularFareTotal: total,
      savings: savings,
      verdict: total == 0
          ? KyotoPassVerdict.insufficientData
          : savings > 0
          ? KyotoPassVerdict.beneficial
          : savings == 0
          ? KyotoPassVerdict.breakEven
          : KyotoPassVerdict.notBeneficial,
    );
  }
}
