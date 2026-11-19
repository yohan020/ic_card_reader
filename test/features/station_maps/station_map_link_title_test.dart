import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/station_maps/domain/station_map_catalog.dart';
import 'package:ic_card_reader/src/features/station_maps/presentation/station_map_link_title.dart';

Map<String, dynamic> raw({
  String id = 'one',
  String station = '新宿',
  String? lineKo,
  String? lineEn,
  String kind = 'webpage',
  bool shinkansen = false,
}) => {
  'id': id,
  'operatorJa': '東日本旅客鉄道',
  'operatorKo': 'JR 동일본',
  'operatorEn': 'JR East',
  'stationJa': station,
  'stationKo': station == '新宿' ? '신주쿠' : '신주쿠산초메',
  'stationEn': station == '新宿' ? 'Shinjuku' : 'Shinjuku-sanchome',
  'url': 'https://www.jreast.co.jp/test/$id',
  'kind': kind,
  'language': 'unknown',
  'scope': shinkansen
      ? 'operator_shinkansen_station_area'
      : 'operator_station_map_not_entire_interchange',
  'lineKo': lineKo,
  'lineEn': lineEn,
};
String label(
  StationMapLink link,
  List<StationMapLink> all, {
  bool english = false,
}) => stationMapLinkTitle(
  link: link,
  links: all,
  placeStationJa: '新宿',
  stationName: (row) => english ? row.stationEn! : row.stationKo!,
  english: english,
);

void main() {
  test(
    'verified line preferred, unreviewed map uses operator without repeated station',
    () {
      final line = StationMapLink.fromJson(
        raw(lineKo: '테스트 노선', lineEn: 'Test Line'),
      );
      expect(label(line, [line]), '테스트 노선');
      expect(label(line, [line], english: true), 'Test Line');
      final op = StationMapLink.fromJson(raw());
      expect(label(op, [op]), 'JR 동일본');
      expect(label(op, [op], english: true), 'JR East');
    },
  );
  test(
    'different stations from one operator stay distinguishable in each app language',
    () {
      final a = StationMapLink.fromJson(raw()),
          b = StationMapLink.fromJson(raw(id: 'two', station: '新宿三丁目'));
      expect(label(a, [a, b]), 'JR 동일본 · 신주쿠');
      expect(label(b, [a, b]), 'JR 동일본 · 신주쿠산초메');
      expect(label(b, [a, b], english: true), 'JR East · Shinjuku-sanchome');
      expect(label(b, [b]), 'JR 동일본 · 신주쿠산초메');
    },
  );
  test('scope and PDF are kept in compact actionable title', () {
    final m = StationMapLink.fromJson(raw(kind: 'pdf', shinkansen: true));
    expect(label(m, [m]), 'JR 동일본 · 신칸센 · PDF');
    expect(label(m, [m], english: true), 'JR East · Shinkansen · PDF');
  });
  test(
    'same-named documents get stable distinct titles instead of merging',
    () {
      final a = StationMapLink.fromJson(raw()),
          b = StationMapLink.fromJson(raw(id: 'two'));
      expect(label(a, [a, b]), 'JR 동일본 (1)');
      expect(label(b, [a, b]), 'JR 동일본 (2)');
    },
  );
  test(
    'station qualifier uses supplied name display independently of app language',
    () {
      final m = StationMapLink.fromJson(raw(station: '新宿三丁目'));
      expect(
        stationMapLinkTitle(
          link: m,
          links: [m],
          placeStationJa: '新宿',
          stationName: (_) => '新宿三丁目 (Shinjuku-sanchome)',
          english: false,
        ),
        'JR 동일본 · 新宿三丁目 (Shinjuku-sanchome)',
      );
    },
  );
  test(
    'partial or empty translated line metadata rejected; old metadata supported',
    () {
      expect(
        () => StationMapLink.fromJson(raw(lineKo: '노선')),
        throwsFormatException,
      );
      expect(
        () => StationMapLink.fromJson(raw(lineKo: '', lineEn: 'Line')),
        throwsFormatException,
      );
      expect(
        () => StationMapLink.fromJson(raw(lineKo: '노선', lineEn: ' ')),
        throwsFormatException,
      );
      expect(StationMapLink.fromJson(raw()).lineKo, isNull);
    },
  );
}
