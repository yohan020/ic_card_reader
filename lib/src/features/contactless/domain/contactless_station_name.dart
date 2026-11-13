import '../../station_resolver/domain/station_name_display.dart';

part 'contactless_station_names.g.dart';
part 'contactless_station_names_en.g.dart';

String? contactlessStationEnglishName(
  String lineId,
  String stationId,
  String japanese,
) {
  final entry = _englishStationNames['$lineId/$stationId'];
  return entry != null && entry[0] == japanese ? entry[1] : null;
}

String? contactlessStationKoreanName(
  String lineId,
  String stationId,
  String japanese,
) {
  final entry = _stationNames['$lineId/$stationId'];
  return entry?.ja == japanese ? entry?.ko : null;
}

String displayContactlessStationName({
  required String lineId,
  required String stationId,
  required String japanese,
  required StationNameDisplayMode mode,
}) {
  return displayStationName(
    japanese: japanese,
    // Guard against stale IDs/renamed stations. Never guess by name at runtime.
    korean: contactlessStationKoreanName(lineId, stationId, japanese),
    english: contactlessStationEnglishName(lineId, stationId, japanese),
    mode: mode,
  );
}
