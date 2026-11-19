import '../data/enokama_pass_data.dart';

class EnokamaSegment {
  const EnokamaSegment(this.from, this.to, this.fare);
  final EnokamaStation from;
  final EnokamaStation to;
  final int fare;
}

class EnokamaResult {
  const EnokamaResult({
    required this.segments,
    required this.origin,
    required this.total,
    required this.savings,
  });
  final List<EnokamaSegment> segments;
  final EnokamaOrigin? origin;
  final int total;
  final int savings;
  bool get insufficient => origin == null || segments.isEmpty;
}

abstract final class EnokamaPassEvaluator {
  static EnokamaResult evaluate({
    required EnokamaOrigin? origin,
    required List<EnokamaSegment> segments,
  }) {
    final valid = segments.where((segment) => segment.fare > 0).toList();
    final total =
        (origin?.roundTripApplicable == true ? origin!.roundTripFare : 0) +
        valid.fold<int>(0, (sum, segment) => sum + segment.fare);
    return EnokamaResult(
      origin: origin,
      segments: valid,
      total: total,
      savings: origin == null ? 0 : total - origin.passPrice,
    );
  }
}
