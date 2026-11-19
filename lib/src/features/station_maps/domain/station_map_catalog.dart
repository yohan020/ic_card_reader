import '../../coin_locker/domain/coin_locker_catalog.dart';

const stationMapHosts = <String>{
  'cdn.sotetsu.co.jp',
  'chiba-monorail.co.jp',
  'eki.jr-odekake.net',
  'navi.hamabus.city.yokohama.lg.jp',
  'railway.jr-central.co.jp',
  'subway.city.fukuoka.lg.jp',
  'subway.osakametro.co.jp',
  'trains.willer.co.jp',
  'www.city.sapporo.jp',
  'www.enoden.co.jp',
  'www.hankyu.co.jp',
  'www.hanshin.co.jp',
  'www.jreast.co.jp',
  'www.jrhokkaido.co.jp',
  'www.jrkyushu.co.jp',
  'www.keihan.co.jp',
  'www.keio.co.jp',
  'www.keisei.co.jp',
  'www.kotsu.city.nagoya.jp',
  'www.meitetsu.co.jp',
  'www.mir.co.jp',
  'www.mm21railway.co.jp',
  'www.nankai.co.jp',
  'www.odakyu.jp',
  'www.osaka-monorail.co.jp',
  'www.seasideline.co.jp',
  'www.seiburailway.jp',
  'www.shonan-monorail.co.jp',
  'www.shr-isaribi.jp',
  'www.tobu.co.jp',
  'www.tokyo-monorail.co.jp',
  'www.tokyometro.jp',
  'www.tokyu.co.jp',
  'www.twr.co.jp',
  'www.yui-rail.co.jp',
  'www.yurikamome.co.jp',
  'www2.city.kyoto.lg.jp',
};

bool isAllowedStationMapUri(Uri uri) =>
    uri.scheme == 'https' &&
    uri.userInfo.isEmpty &&
    (!uri.hasPort || uri.port == 443) &&
    stationMapHosts.contains(uri.host) &&
    uri.path.isNotEmpty;

class StationMapLink {
  StationMapLink.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      operatorJa = json['operatorJa'] as String,
      operatorKo = json['operatorKo'] as String,
      operatorEn = json['operatorEn'] as String,
      lineKo = json['lineKo'] as String?,
      lineEn = json['lineEn'] as String?,
      stationJa = json['stationJa'] as String,
      stationKo = json['stationKo'] as String?,
      stationEn = json['stationEn'] as String?,
      uri = Uri.parse(json['url'] as String),
      kind = json['kind'] as String,
      language = json['language'] as String,
      scope = json['scope'] as String {
    if (id.isEmpty ||
        stationJa.isEmpty ||
        operatorJa.isEmpty ||
        operatorKo.isEmpty ||
        operatorEn.isEmpty ||
        (lineKo == null) != (lineEn == null) ||
        (lineKo?.trim().isEmpty ?? false) ||
        (lineEn?.trim().isEmpty ?? false) ||
        !isAllowedStationMapUri(uri) ||
        !{'webpage', 'image', 'pdf'}.contains(kind) ||
        !{'ja', 'en', 'unknown'}.contains(language) ||
        !{
          'operator_shinkansen_station_area',
          'operator_station_map_not_entire_interchange',
        }.contains(scope)) {
      throw const FormatException('Invalid station map link');
    }
  }
  final String id,
      operatorJa,
      operatorKo,
      operatorEn,
      stationJa,
      kind,
      language,
      scope;
  final String? stationKo, stationEn, lineKo, lineEn;
  final Uri uri;
}

class StationMapCatalog {
  StationMapCatalog.fromJson(
    Map<String, dynamic> json,
    CoinLockerCatalog names,
  ) {
    if (json['schema'] != 1) {
      throw const FormatException('Unsupported station maps');
    }
    final entries = <String, List<StationMapLink>>{};
    final known = {for (final p in names.places) p.id: p};
    final ids = <String>{};
    for (final raw in json['places'] as List) {
      final row = raw as Map<String, dynamic>, id = row['placeId'] as String;
      if (!known.containsKey(id) || entries.containsKey(id)) {
        throw const FormatException('Unknown or duplicate station map place');
      }
      final parsed = (row['maps'] as List)
          .map((m) => StationMapLink.fromJson(m as Map<String, dynamic>))
          .toList();
      if (parsed.isEmpty || parsed.any((m) => !ids.add(m.id))) {
        throw const FormatException('Empty or duplicate station maps');
      }
      entries[id] = List.unmodifiable(parsed);
    }
    links = Map.unmodifiable(entries);
    browserCatalog = CoinLockerCatalog(
      places: List.unmodifiable(
        names.places.where((p) => links.containsKey(p.id)),
      ),
    );
  }
  late final Map<String, List<StationMapLink>> links;
  late final CoinLockerCatalog browserCatalog;
}
