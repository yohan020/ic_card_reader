import '../data/okayama_kurashiki_gururin_pass_data.dart';

enum OkayamaKurashikiGururinPassVerdict {
  beneficial,
  breakEven,
  notBeneficial,
  insufficientData,
}

class OkayamaKurashikiGururinPlannedSegment {
  const OkayamaKurashikiGururinPlannedSegment({
    required this.from,
    required this.to,
    required this.fare,
  });

  final OkayamaKurashikiGururinStation from;
  final OkayamaKurashikiGururinStation to;
  final int fare;
}

class OkayamaKurashikiGururinPassComparisonResult {
  const OkayamaKurashikiGururinPassComparisonResult({
    required this.segments,
    required this.serviceRides,
    required this.railFareTotal,
    required this.exactServiceFareTotal,
    required this.estimatedServiceFareTotal,
    required this.regularFareTotal,
    required this.savings,
    required this.verdict,
  });

  final List<OkayamaKurashikiGururinPlannedSegment> segments;
  final Map<OkayamaKurashikiGururinRideService, int> serviceRides;
  final int railFareTotal;
  final int exactServiceFareTotal;
  final int estimatedServiceFareTotal;
  final int regularFareTotal;
  final int savings;
  final OkayamaKurashikiGururinPassVerdict verdict;
}

abstract final class OkayamaKurashikiGururinPassEvaluator {
  static OkayamaKurashikiGururinPassComparisonResult evaluate(
    List<OkayamaKurashikiGururinPlannedSegment> segments, {
    required Map<OkayamaKurashikiGururinRideService, int> serviceRides,
  }) {
    final valid = segments.where((item) => item.fare > 0).toList();
    final validServices =
        Map<OkayamaKurashikiGururinRideService, int>.fromEntries(
          serviceRides.entries.where((entry) => entry.value > 0),
        );
    final railTotal = valid.fold(0, (sum, item) => sum + item.fare);
    final exactServiceTotal = validServices.entries
        .where((entry) => !entry.key.isEstimate)
        .fold(0, (sum, entry) => sum + entry.key.fare * entry.value);
    final estimatedServiceTotal = validServices.entries
        .where((entry) => entry.key.isEstimate)
        .fold(0, (sum, entry) => sum + entry.key.fare * entry.value);
    final total = railTotal + exactServiceTotal + estimatedServiceTotal;
    final savings = total - OkayamaKurashikiGururinPassData.passPrice;
    return OkayamaKurashikiGururinPassComparisonResult(
      segments: valid,
      serviceRides: validServices,
      railFareTotal: railTotal,
      exactServiceFareTotal: exactServiceTotal,
      estimatedServiceFareTotal: estimatedServiceTotal,
      regularFareTotal: total,
      savings: savings,
      verdict: valid.isEmpty && validServices.isEmpty
          ? OkayamaKurashikiGururinPassVerdict.insufficientData
          : savings > 0
          ? OkayamaKurashikiGururinPassVerdict.beneficial
          : savings == 0
          ? OkayamaKurashikiGururinPassVerdict.breakEven
          : OkayamaKurashikiGururinPassVerdict.notBeneficial,
    );
  }
}
