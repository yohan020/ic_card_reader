import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/hakone_freepass_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'loads adult Hakone Freepass origin prices and searches station names only',
    () async {
      final data = await const HakoneFreepassDataRepository().load();

      expect(data.departures, hasLength(70));
      expect(
        data.searchDeparture('신주쿠').map((origin) => origin.ja),
        containsAll(['新宿', '南新宿']),
      );
      expect(data.searchDeparture('ㅅㅈㅋ').single.ja, '新宿');
      expect(data.searchDeparture('오다큐').map((origin) => origin.ja), [
        '小田急相模原',
      ]);
      expect(data.searchDeparture('오다큐전철'), isEmpty);

      final shinjuku = data
          .searchDeparture('신주쿠')
          .singleWhere((origin) => origin.ja == '新宿');
      expect(data.passPrice(shinjuku, 2), 7100);
      expect(data.passPrice(shinjuku, 3), 7500);
    },
  );

  test('returns an exact fare only for a supported Hakone mode pair', () async {
    final data = await const HakoneFreepassDataRepository().load();
    final pair = [
      for (final from in data.places)
        for (final to in data.places)
          if (from.id != to.id && data.fare(from, to) != null) (from, to),
    ].first;

    expect(data.fare(pair.$1, pair.$2), greaterThan(0));
  });

  test(
    'searches Korean cable, ropeway, and cruise port names by mode',
    () async {
      final data = await const HakoneFreepassDataRepository().load();

      expect(data.searchPlace('코엔시모', 'cable').single.ja, '公園下');
      expect(
        data.searchPlace('고라', 'cable').map((place) => place.ja),
        contains('強羅'),
      );
      expect(data.searchPlace('소운잔', 'ropeway').single.ja, '早雲山');
      expect(data.searchPlace('토겐다이', 'cruise').single.ja, '桃源台港');
      expect(data.searchPlace('하코네마치', 'cruise').single.ja, '箱根町港');
      expect(data.searchPlace('모토하코네', 'cruise').single.ja, '元箱根港');
    },
  );
}
