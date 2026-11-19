import 'station_stamp_session.dart';

part 'stamp_book_chuo_sobu.g.dart';
part 'stamp_book_midosuji.g.dart';
part 'stamp_book_osaka_loop.g.dart';

/// Curated book scope, separate from the offline nationwide research archive.
/// These are existing eligible passenger line IDs, not new station identities.
// A small projection of the verified catalog: do not construct all national
// passenger lines merely to draw the home ticket or the illustrated book.
const chuoSobuBookLine = StampLine(
  id: 'service:jr-east:chuo-sobu-local',
  japanese: '中央・総武線各駅停車',
  korean: '주오·소부선 각역정차',
  english: 'Chuo-Sobu Line (Local)',
  operator: '東日本旅客鉄道',
  operatorKorean: 'JR동일본',
  operatorEnglish: 'JR East',
  regions: ['kanto'],
  stations: chuoSobuBookStations,
  source: 'https://timetables.jreast.co.jp/2611/timetable-v/659u1.html',
);
const midosujiBookLine = StampLine(
  id: 'N02-7693ee9aa33e',
  japanese: '御堂筋線',
  korean: '미도스지선',
  english: 'Midosuji Line',
  operator: '大阪市高速電気軌道',
  operatorKorean: '오사카 메트로',
  operatorEnglish: 'Osaka Metro',
  regions: ['kansai'],
  stations: midosujiBookStations,
  source: 'https://subway.osakametro.co.jp/station_guide/index.php',
);
const osakaLoopBookLine = StampLine(
  id: 'N02-239d98587238',
  japanese: '大阪環状線',
  korean: '오사카 순환선',
  english: 'Osaka Loop Line',
  operator: '西日本旅客鉄道',
  operatorKorean: 'JR 서일본',
  operatorEnglish: 'JR West',
  regions: ['kansai'],
  stations: osakaLoopBookStations,
  source: 'https://www.westjr.co.jp/global/en/timetable/pdf/ubn_en.pdf',
);
final stampBookLines = List<StampLine>.unmodifiable([
  yamanoteStampLine,
  chuoSobuBookLine,
  midosujiBookLine,
  osakaLoopBookLine,
]);

String stampBookOperatorKorean(StampLine line) =>
    line.operator == yamanoteStampLine.operator
    ? 'JR 동일본'
    : line.operatorKorean;

final stampBookStations = List<StampStation>.unmodifiable(
  {
    for (final line in stampBookLines)
      for (final station in line.stations) station.id: station,
  }.values,
);
final stampBookStationIds = Set<String>.unmodifiable(
  stampBookStations.map((station) => station.id),
);

/// Infer a region only when the book's line metadata narrows it to one.
/// A shared station still has one entry; an unresolved one goes in Other.
final stampBookRegionByStationId = Map<String, String>.unmodifiable(() {
  final possible = <String, Set<String>>{};
  for (final line in stampBookLines.where((line) => line.regions.isNotEmpty)) {
    final regions = line.regions.toSet();
    for (final station in line.stations) {
      possible.update(
        station.id,
        (known) => known.intersection(regions),
        ifAbsent: () => regions,
      );
    }
  }
  return {
    for (final entry in possible.entries)
      if (entry.value.length == 1) entry.key: entry.value.single,
  };
}());

int stampBookCollectedCount(StationStampSession session) =>
    stampBookStationIds.where(session.collected.contains).length;
int stampBookCompletedCount(StationStampSession session) =>
    stampBookLines.where(session.completeFor).length;

String stampBookLineKorean(StampLine line) =>
    line.id == chuoSobuBookLine.id ? '주오·소부선' : line.korean;
String stampBookLineEnglish(StampLine line) =>
    line.id == chuoSobuBookLine.id ? 'Chuo-Sobu Line' : line.english;

final chuoSobuBookArtByStation = {
  for (final art in chuoSobuBookArt) art.id: art,
};
final stampBookArtByStation = {
  ...chuoSobuBookArtByStation,
  for (final art in midosujiBookArt) art.id: art,
  for (final art in osakaLoopBookArt) art.id: art,
};

/// Display-only cleanup; station identity and the source catalog are unchanged.
String stampBookStationKorean(StampStation station) =>
    station.korean.replaceFirst(RegExp(r'\s+역\s*\([^)]*\)$'), '');
