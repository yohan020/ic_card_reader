enum TransitCoverage {
  tokyoMetro('Tokyo Metro', true),
  toeiSubway('도에이 지하철', true),
  outside('패스 적용 외', false);

  const TransitCoverage(this.label, this.isCoveredByTokyoSubwayTicket);

  final String label;
  final bool isCoveredByTokyoSubwayTicket;
}

enum PassProduct {
  tokyoSubway24(
    label: 'Tokyo Subway 24시간권',
    price: 1000,
    duration: Duration(hours: 24),
  ),
  tokyoSubway48(
    label: 'Tokyo Subway 48시간권',
    price: 1500,
    duration: Duration(hours: 48),
  ),
  tokyoSubway72(
    label: 'Tokyo Subway 72시간권',
    price: 2000,
    duration: Duration(hours: 72),
  );

  const PassProduct({
    required this.label,
    required this.price,
    required this.duration,
  });

  final String label;
  final int price;
  final Duration duration;
}

class PlannedTransitSegment {
  const PlannedTransitSegment({
    required this.id,
    required this.departureAt,
    required this.fromStation,
    required this.toStation,
    required this.coverage,
    required this.regularFare,
  });

  final int id;
  final DateTime departureAt;
  final String fromStation;
  final String toStation;
  final TransitCoverage coverage;
  final int regularFare;
}

enum PassComparisonVerdict {
  beneficial,
  breakEven,
  notBeneficial,
  insufficientData,
}

class SegmentEvaluation {
  const SegmentEvaluation({
    required this.segment,
    required this.isWithinValidity,
    required this.isCovered,
  });

  final PlannedTransitSegment segment;
  final bool isWithinValidity;
  final bool isCovered;
}

class PassComparisonResult {
  const PassComparisonResult({
    required this.product,
    required this.validFrom,
    required this.validUntil,
    required this.segments,
    required this.coveredRegularFare,
    required this.excludedFare,
    required this.savings,
    required this.verdict,
  });

  final PassProduct product;
  final DateTime validFrom;
  final DateTime validUntil;
  final List<SegmentEvaluation> segments;
  final int coveredRegularFare;
  final int excludedFare;
  final int savings;
  final PassComparisonVerdict verdict;

  int get regularFareTotal => coveredRegularFare + excludedFare;
  int get costWithPass => product.price + excludedFare;
  int get coveredSegmentCount =>
      segments.where((item) => item.isCovered).length;
}

abstract final class PassComparisonEvaluator {
  static PassComparisonResult evaluate({
    required PassProduct product,
    required DateTime validFrom,
    required List<PlannedTransitSegment> segments,
  }) {
    final validUntil = validFrom.add(product.duration);
    final evaluations = segments
        .map((segment) {
          final isWithinValidity =
              !segment.departureAt.isBefore(validFrom) &&
              segment.departureAt.isBefore(validUntil);
          return SegmentEvaluation(
            segment: segment,
            isWithinValidity: isWithinValidity,
            isCovered:
                isWithinValidity &&
                segment.coverage.isCoveredByTokyoSubwayTicket,
          );
        })
        .toList(growable: false);

    final coveredRegularFare = evaluations
        .where((item) => item.isCovered)
        .fold(0, (sum, item) => sum + item.segment.regularFare);
    final excludedFare = evaluations
        .where((item) => !item.isCovered)
        .fold(0, (sum, item) => sum + item.segment.regularFare);
    final savings = coveredRegularFare - product.price;
    final verdict = segments.isEmpty || coveredRegularFare == 0
        ? PassComparisonVerdict.insufficientData
        : savings > 0
        ? PassComparisonVerdict.beneficial
        : savings == 0
        ? PassComparisonVerdict.breakEven
        : PassComparisonVerdict.notBeneficial;

    return PassComparisonResult(
      product: product,
      validFrom: validFrom,
      validUntil: validUntil,
      segments: evaluations,
      coveredRegularFare: coveredRegularFare,
      excludedFare: excludedFare,
      savings: savings,
      verdict: verdict,
    );
  }
}
