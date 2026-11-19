import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/sapporo_subway_pass_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/domain/sapporo_subway_pass.dart';

void main() {
  test('46개 물리 역과 환승역을 로드하고 한국어·초성·일본어로 검색한다', () async {
    final data = await const SapporoSubwayPassDataRepository().load();
    expect(data.stations, hasLength(46));
    expect(data.search('삿포로').first.nameJa, 'さっぽろ');
    expect(data.search('ㅅㅍㄹ').first.nameJa, 'さっぽろ');
    expect(data.search('大通').single.nameKo, '오도리');
    expect(data.search('삿포로시'), isEmpty);
  });

  test('공식 거리 구간 운임과 선택한 1일권 손익을 계산한다', () async {
    final data = await const SapporoSubwayPassDataRepository().load();
    final asabu = data.search('아사부').single;
    final makomanai = data.search('마코마나이').single;
    expect(data.fareBetween(asabu, makomanai), 330);
    final result = SapporoSubwayPassEvaluator.evaluate([
      for (var index = 0; index < 3; index++)
        SapporoSubwayPlannedSegment(from: asabu, to: makomanai, fare: 330),
    ]);
    expect(result.regularFareTotal, 990);
    expect(result.savings, 160);
    expect(result.verdict, SapporoSubwayPassVerdict.beneficial);

    final donichikaResult = SapporoSubwayPassEvaluator.evaluate([
      SapporoSubwayPlannedSegment(from: asabu, to: makomanai, fare: 330),
      SapporoSubwayPlannedSegment(from: makomanai, to: asabu, fare: 330),
    ], passType: SapporoSubwayPassType.donichika);
    expect(donichikaResult.passType, SapporoSubwayPassType.donichika);
    expect(donichikaResult.savings, 140);
    expect(donichikaResult.verdict, SapporoSubwayPassVerdict.beneficial);
  });
}
