import '../domain/station_map_catalog.dart';

/// Display only: never merge distinct URLs in a grouped interchange area.
String stationMapLinkTitle({
  required StationMapLink link,
  required List<StationMapLink> links,
  required String placeStationJa,
  required String Function(StationMapLink) stationName,
  required bool english,
}) {
  String title(StationMapLink row) {
    final operatorLinks = links.where((m) => m.operatorJa == row.operatorJa);
    final distinguishStation =
        row.stationJa != placeStationJa ||
        operatorLinks.map((m) => m.stationJa).toSet().length > 1;
    return [
      if (english)
        row.lineEn ?? row.operatorEn
      else
        row.lineKo ?? row.operatorKo,
      if (distinguishStation) stationName(row),
      if (row.scope == 'operator_shinkansen_station_area')
        english ? 'Shinkansen' : '신칸센',
      if (row.kind == 'pdf') 'PDF',
    ].join(' · ');
  }

  final label = title(link);
  final same = links.where((row) => title(row) == label).toList();
  // Same-name documents remain individually selectable, in catalog order.
  return same.length > 1 ? '$label (${same.indexOf(link) + 1})' : label;
}
