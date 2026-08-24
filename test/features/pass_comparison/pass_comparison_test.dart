import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/pass_comparison/domain/pass_comparison.dart';

void main() {
  final validFrom = DateTime(2026, 8, 12, 9);

  test('compares only covered segments inside the pass validity', () {
    final result = PassComparisonEvaluator.evaluate(
      product: PassProduct.tokyoSubway24,
      validFrom: validFrom,
      segments: [
        _segment(1, 600, TransitCoverage.tokyoMetro, validFrom),
        _segment(
          2,
          550,
          TransitCoverage.toeiSubway,
          validFrom.add(const Duration(hours: 5)),
        ),
        _segment(
          3,
          300,
          TransitCoverage.outside,
          validFrom.add(const Duration(hours: 7)),
        ),
        _segment(
          4,
          200,
          TransitCoverage.tokyoMetro,
          validFrom.add(const Duration(hours: 24)),
        ),
      ],
    );

    expect(result.coveredRegularFare, 1150);
    expect(result.excludedFare, 500);
    expect(result.savings, 150);
    expect(result.costWithPass, 1500);
    expect(result.verdict, PassComparisonVerdict.beneficial);
    expect(result.coveredSegmentCount, 2);
  });

  test('marks an equal covered fare as break even', () {
    final result = PassComparisonEvaluator.evaluate(
      product: PassProduct.tokyoSubway24,
      validFrom: validFrom,
      segments: [_segment(1, 1000, TransitCoverage.toeiSubway, validFrom)],
    );

    expect(result.verdict, PassComparisonVerdict.breakEven);
    expect(result.savings, 0);
  });

  test('returns insufficient data when every segment is outside coverage', () {
    final result = PassComparisonEvaluator.evaluate(
      product: PassProduct.tokyoSubway48,
      validFrom: validFrom,
      segments: [_segment(1, 900, TransitCoverage.outside, validFrom)],
    );

    expect(result.verdict, PassComparisonVerdict.insufficientData);
    expect(result.excludedFare, 900);
  });

  test(
    'uses the calendar day and only JR Tokunai coverage for Tokunai Pass',
    () {
      final result = PassComparisonEvaluator.evaluate(
        product: PassProduct.tokunai1Day,
        validFrom: DateTime(2026, 8, 12, 15),
        segments: [
          _segment(1, 406, TransitCoverage.tokunaiJr, DateTime(2026, 8, 12, 8)),
          _segment(2, 406, TransitCoverage.tokunaiJr, DateTime(2026, 8, 13)),
          _segment(
            3,
            178,
            TransitCoverage.tokyoMetro,
            DateTime(2026, 8, 12, 10),
          ),
        ],
      );

      expect(result.validFrom, DateTime(2026, 8, 12));
      expect(result.validUntil, DateTime(2026, 8, 13));
      expect(result.coveredRegularFare, 406);
      expect(result.excludedFare, 584);
      expect(result.verdict, PassComparisonVerdict.notBeneficial);
    },
  );
}

PlannedTransitSegment _segment(
  int id,
  int fare,
  TransitCoverage coverage,
  DateTime departureAt,
) => PlannedTransitSegment(
  id: id,
  departureAt: departureAt,
  fromStation: '출발$id',
  toStation: '도착$id',
  coverage: coverage,
  regularFare: fare,
);
