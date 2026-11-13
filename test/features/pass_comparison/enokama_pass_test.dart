import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/enokama_pass_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/domain/enokama_pass.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'loads all 70 origin prices and searches Korean and Japanese names',
    () async {
      final data = await const EnokamaPassDataRepository().load();

      expect(data.origins, hasLength(70));
      expect(data.searchOrigins('신주쿠').map((origin) => origin.nameJa), [
        '新宿',
        '南新宿',
      ]);
      expect(data.searchOrigins('ㅅㅈㅋ').single.nameJa, '新宿');
      expect(data.searchOrigins('오다큐나가야마').single.nameJa, '小田急永山');
      expect(data.searchOrigins('오다큐다마센터').single.nameJa, '小田急多摩センター');
      expect(data.searchStations('가마쿠라').map((station) => station.nameJa), [
        '鎌倉',
        '鎌倉高校前',
      ]);
      expect(data.searchStations('에노덴'), isEmpty);
    },
  );

  test('adds origin round trip and free-area segment fare', () async {
    final data = await const EnokamaPassDataRepository().load();
    final origin = data
        .searchOrigins('신주쿠')
        .singleWhere((origin) => origin.nameJa == '新宿');
    final from = data
        .searchStations('후지사와')
        .singleWhere(
          (station) =>
              station.nameJa == '藤沢' &&
              station.operator == 'Enoshima Electric Railway',
        );
    final to = data
        .searchStations('가마쿠라')
        .singleWhere((station) => station.nameJa == '鎌倉');
    final fare = data.fareBetween(from, to)!;

    final result = EnokamaPassEvaluator.evaluate(
      origin: origin,
      segments: [EnokamaSegment(from, to, fare)],
    );

    expect(origin.roundTripFare, 1214);
    expect(fare, 310);
    expect(result.total, 1524);
    expect(result.savings, -116);
  });
}
