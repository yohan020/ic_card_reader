import 'kyoto_subway_bus_pass_data.dart';

/// Subway-only view of the Kyoto City Transportation Bureau fare dataset.
///
/// The shared repository is intentionally used so the two Kyoto passes never
/// read or parse the same asset twice.
class KyotoSubway1DayPassData {
  const KyotoSubway1DayPassData(this._subwayData);

  static const passPrice = 800;

  final KyotoSubwayBusPassData _subwayData;

  List<KyotoSubwayStation> get stations => _subwayData.stations;

  int? fareBetween(KyotoSubwayStation from, KyotoSubwayStation to) =>
      _subwayData.fareBetween(from, to);

  List<KyotoSubwayStation> search(String query, {int limit = 20}) =>
      _subwayData.search(query, limit: limit);
}

class KyotoSubway1DayPassDataRepository {
  const KyotoSubway1DayPassDataRepository();

  static Future<KyotoSubway1DayPassData>? _cachedLoad;

  Future<KyotoSubway1DayPassData> load() => _cachedLoad ??= _load();

  Future<KyotoSubway1DayPassData> _load() async => KyotoSubway1DayPassData(
    await const KyotoSubwayBusPassDataRepository().load(),
  );
}
