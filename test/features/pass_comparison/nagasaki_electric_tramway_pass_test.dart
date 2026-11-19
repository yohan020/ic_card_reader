import 'package:flutter_test/flutter_test.dart';
import 'package:ic_card_reader/src/features/pass_comparison/data/nagasaki_electric_tramway_pass_data.dart';
import 'package:ic_card_reader/src/features/pass_comparison/domain/nagasaki_electric_tramway_pass.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('38개 정류장과 방향별 IC 운임을 로드하고 역명 표기로 검색한다', () async {
    final data = await const NagasakiElectricTramwayPassDataRepository().load();

    expect(data.stations, hasLength(38));
    expect(data.search('아카사코').single.nameJa, '赤迫');
    expect(data.search('ㅎㅌㄹ').single.nameJa, '蛍茶屋');
    expect(data.search('昭和町').single.nameKo, '쇼와마치도리');
    expect(data.search('전기궤도'), isEmpty);

    final akasako = data.search('아카사코').single;
    final sumiyoshi = data.search('스미요시').single;
    final showamachi = data.search('쇼와마치').single;
    expect(data.fareBetween(akasako, sumiyoshi), 110);
    expect(data.fareBetween(akasako, showamachi), 220);
  });

  test('선택한 1일·24시간권 가격으로 IC 운임 손익을 계산한다', () async {
    final data = await const NagasakiElectricTramwayPassDataRepository().load();
    final akasako = data.search('아카사코').single;
    final peacePark = data.search('평화공원').single;
    final fare = data.fareBetween(akasako, peacePark)!;
    expect(fare, 150);

    final oneDay = NagasakiElectricTramwayPassEvaluator.evaluate([
      for (var index = 0; index < 4; index++)
        NagasakiElectricTramwayPlannedSegment(
          from: akasako,
          to: peacePark,
          fare: fare,
        ),
    ]);
    expect(oneDay.passType, NagasakiElectricTramwayPassType.oneDay);
    expect(oneDay.regularFareTotal, 600);
    expect(oneDay.verdict, NagasakiElectricTramwayPassVerdict.breakEven);

    final twentyFourHours = NagasakiElectricTramwayPassEvaluator.evaluate([
      for (var index = 0; index < 5; index++)
        NagasakiElectricTramwayPlannedSegment(
          from: akasako,
          to: peacePark,
          fare: fare,
        ),
    ], passType: NagasakiElectricTramwayPassType.twentyFourHours);
    expect(twentyFourHours.savings, 50);
    expect(
      twentyFourHours.verdict,
      NagasakiElectricTramwayPassVerdict.beneficial,
    );
  });
}
