enum OsakaAmazingPassProduct {
  oneDay(label: '오사카 주유패스 1일권', price: 3500, dayCount: 1),
  twoDay(label: '오사카 주유패스 2일권', price: 5000, dayCount: 2);

  const OsakaAmazingPassProduct({
    required this.label,
    required this.price,
    required this.dayCount,
  });

  final String label;
  final int price;
  final int dayCount;
}

class OsakaPlannedSegment {
  const OsakaPlannedSegment({
    required this.dayIndex,
    required this.operator,
    required this.fromStation,
    required this.toStation,
    required this.regularFare,
    this.journeyIndex = 0,
  });

  final int dayIndex;
  final String operator;
  final String fromStation;
  final String toStation;
  final int regularFare;
  final int journeyIndex;
}

enum OsakaPassVerdict { beneficial, breakEven, notBeneficial, insufficientData }

class OsakaPassComparisonResult {
  const OsakaPassComparisonResult({
    required this.product,
    required this.segments,
    required this.busRidesByDay,
    required this.railFareTotal,
    required this.busFareTotal,
    required this.regularFareTotal,
    required this.savings,
    required this.verdict,
  });

  final OsakaAmazingPassProduct product;
  final List<OsakaPlannedSegment> segments;
  final List<int> busRidesByDay;
  final int railFareTotal;
  final int busFareTotal;
  final int regularFareTotal;
  final int savings;
  final OsakaPassVerdict verdict;
}

abstract final class OsakaAmazingPassEvaluator {
  static OsakaPassComparisonResult evaluate({
    required OsakaAmazingPassProduct product,
    required List<OsakaPlannedSegment> segments,
    List<int> busRidesByDay = const [],
    int busAdultFare = 210,
  }) {
    final validSegments = segments
        .where(
          (segment) =>
              segment.dayIndex >= 0 &&
              segment.dayIndex < product.dayCount &&
              segment.regularFare > 0,
        )
        .toList(growable: false);
    final railFareTotal = validSegments.fold<int>(
      0,
      (sum, segment) => sum + segment.regularFare,
    );
    final validBusRides = List<int>.generate(
      product.dayCount,
      (index) => index < busRidesByDay.length && busRidesByDay[index] > 0
          ? busRidesByDay[index]
          : 0,
      growable: false,
    );
    final busFareTotal =
        validBusRides.fold<int>(0, (sum, rides) => sum + rides) * busAdultFare;
    final regularFareTotal = railFareTotal + busFareTotal;
    final savings = regularFareTotal - product.price;
    final verdict = validSegments.isEmpty && busFareTotal == 0
        ? OsakaPassVerdict.insufficientData
        : savings > 0
        ? OsakaPassVerdict.beneficial
        : savings == 0
        ? OsakaPassVerdict.breakEven
        : OsakaPassVerdict.notBeneficial;
    return OsakaPassComparisonResult(
      product: product,
      segments: validSegments,
      busRidesByDay: validBusRides,
      railFareTotal: railFareTotal,
      busFareTotal: busFareTotal,
      regularFareTotal: regularFareTotal,
      savings: savings,
      verdict: verdict,
    );
  }
}
