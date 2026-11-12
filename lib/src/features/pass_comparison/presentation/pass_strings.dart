import 'package:flutter/widgets.dart';

import '../../../core/localization/app_strings.dart';
export '../../../core/localization/app_strings.dart';
export 'pass_name_scope.dart';

part 'pass_flow_strings.g.dart';

/// Display-only adapter for legacy product labels. Never use this on lookup
/// IDs, fare-table keys, or user input. Parameters belong in ARB messages.
String passText(BuildContext context, String source) {
  final l10n = strings(context);
  return switch (source) {
    "홋카이도" => l10n.passRegionHokkaido,
    "도호쿠" => l10n.passRegionTohoku,
    "도쿄·간토" => l10n.passRegionKanto,
    "주부" => l10n.passRegionChubu,
    "간사이" => l10n.passRegionKansai,
    "주고쿠" => l10n.passRegionChugoku,
    "시코쿠" => l10n.passRegionShikoku,
    "규슈" => l10n.passRegionKyushu,
    "오키나와" => l10n.passRegionOkinawa,
    "삿포로·하코다테 등" => l10n.passRegionHokkaidoHint,
    "센다이·아오모리 등" => l10n.passRegionTohokuHint,
    "도쿄·가나가와 지역 패스" => l10n.passRegionKantoHint,
    "나고야·호쿠리쿠 등" => l10n.passRegionChubuHint,
    "오사카·교토·나라 지역 패스" => l10n.passRegionKansaiHint,
    "히로시마·오카야마 등" => l10n.passRegionChugokuHint,
    "마쓰야마·다카마쓰 등" => l10n.passRegionShikokuHint,
    "후쿠오카 지역 패스" => l10n.passRegionKyushuHint,
    "나하·오키나와 지역" => l10n.passRegionOkinawaHint,
    "교통패스 비교" => l10n.passTitle,
    "입력한 이동 계획을 기준으로 일반 운임과 패스 가격을 비교합니다." => l10n.passIntro,
    "계산 기준" => l10n.passCalculationBasis,
    "지원 데이터로 확인되는 이동만 계산합니다. 확인할 수 없는 운임은 합산하지 않으며, 구매 전 공식 상품 조건과 운임을 확인해 주세요." =>
      l10n.passCalculationNotice,
    "삿포로 지하철 1일권" => l10n.passSapporo,
    "삿포로시 지하철 · 전 구간" => l10n.passSapporoScope,
    "지하철 전 구간의 일반 운임과 비교합니다." => l10n.passSubwayDescription,
    "1일권 · ¥830" => l10n.passSapporoPeriod,
    "홋카이도 레일패스" => l10n.passHokkaido,
    "JR 홋카이도선 · 보통차 지정석" => l10n.passHokkaidoScope,
    "5·7·10일권과 철도·버스 이동 예상 운임을 비교합니다." => l10n.passHokkaidoDescription,
    "5일권 · ¥23,000" => l10n.passHokkaidoFive,
    "7일권 · ¥29,000" => l10n.passHokkaidoSeven,
    "10일권 · ¥38,000" => l10n.passHokkaidoTen,
    "Tokyo Metro · 도에이 지하철" => l10n.passTokyoScope,
    "24·48·72시간권의 손익을 비교합니다." => l10n.passTokyoDescription,
    "24시간" => l10n.passHours24,
    "48시간" => l10n.passHours48,
    "72시간" => l10n.passHours72,
    "에노시마·가마쿠라 프리패스" => l10n.passEnokama,
    "에노덴 · 오다큐 전철" => l10n.passEnokamaScope,
    "출발역별 가격과 프리구간 운임을 비교합니다." => l10n.passEnokamaDescription,
    "1일권 · 발역별 가격" => l10n.passEnokamaPeriod,
    "에노덴 1일 승차권" => l10n.passEnoden,
    "에노시마 전철 · 에노덴 전선" => l10n.passEnodenScope,
    "에노덴 내부 이동의 일반 운임과 비교합니다." => l10n.passEnodenDescription,
    "1일권 · ¥800" => l10n.passEnodenPeriod,
    "하코네 프리패스" => l10n.passHakone,
    "오다큐 70개 출발역 · 하코네 교통수단" => l10n.passHakoneScope,
    "출발역별 성인 가격과 하코네 현지 운임을 비교합니다." => l10n.passHakoneDescription,
    "2일권" => l10n.passDaysTwo,
    "3일권" => l10n.passDaysThree,
    "도쿠나이 패스" => l10n.passTokunai,
    "도쿄 23구 내 지정 JR 구간" => l10n.passTokunaiScope,
    "1일권과 적용 JR 구간의 일반 운임을 비교합니다." => l10n.passTokunaiDescription,
    "1일권 · ¥870" => l10n.passTokunaiPeriod,
    "교토 지하철 1일권" => l10n.passKyotoSubway,
    "교토시영 지하철 · 전 구간" => l10n.passKyotoSubwayScope,
    "오사카 주유패스" => l10n.passOsaka,
    "오사카 메트로 · 사철 · 시티버스" => l10n.passOsakaScope,
    "1·2일권과 환승 경로의 일반 운임을 비교합니다." => l10n.passOsakaDescription,
    "1일권 · ¥3,500" => l10n.passOsakaOne,
    "2일권 · ¥5,000" => l10n.passOsakaTwo,
    "교토 지하철·버스 1일권" => l10n.passKyotoBus,
    "교토시영 지하철 · 버스 예상 운임" => l10n.passKyotoBusScope,
    "지하철 자동 운임과 버스 이용 추정을 비교합니다." => l10n.passKyotoBusDescription,
    "1일권 · ¥1,100" => l10n.passKyotoBusPeriod,
    "한큐패스 1일권" => l10n.passHankyu,
    "한큐 전철 전 노선" => l10n.passHankyuScope,
    "한큐 전철 내부 이동의 일반 운임과 비교합니다." => l10n.passHankyuDescription,
    "1일권 · ¥1,300" => l10n.passHankyuPeriod,
    "긴테쓰 레일 패스" => l10n.passKintetsu,
    "긴테쓰 전철 · 이가철도 · 케이블카" => l10n.passKintetsuScope,
    "권종별 적용 구간과 일반 운임을 비교합니다." => l10n.passKintetsuDescription,
    "1일권" => l10n.passDaysOne,
    "5일권" => l10n.passDaysFive,
    "5일권 Plus" => l10n.passDaysFivePlus,
    "오카야마·구라시키 tabiwa 구루링 패스" => l10n.passOkayama,
    "JR 서일본 · 오카야마 전기궤도 · 시모덴 버스" => l10n.passOkayamaScope,
    "3일권과 철도·노면전차·버스 이동 운임을 비교합니다." => l10n.passOkayamaDescription,
    "3일권 · ¥3,800" => l10n.passOkayamaPeriod,
    "히로덴 전차 패스" => l10n.passHiroden,
    "히로시마 전철 · 전차 전 노선" => l10n.passHirodenScope,
    "일반 운임과 1일·8시간·24시간권을 비교합니다." => l10n.passHirodenDescription,
    "1일권 · ¥700" => l10n.passHirodenOne,
    "8시간권 · ¥600" => l10n.passHirodenEight,
    "24시간권 · ¥700" => l10n.passHirodenTwentyFour,
    "나가사키 전기궤도 패스" => l10n.passNagasaki,
    "나가사키 전기궤도 · 노면전차 전 노선" => l10n.passNagasakiScope,
    "IC·터치 기준 일반 운임과 1일·24시간권을 비교합니다." => l10n.passNagasakiDescription,
    "1일권 · ¥600" => l10n.passNagasakiOne,
    "후쿠오카 지하철 1일권" => l10n.passFukuoka,
    "후쿠오카시 지하철 · 3개 노선" => l10n.passFukuokaScope,
    "1일권 · ¥640" => l10n.passFukuokaPeriod,
    "유이레일 패스" => l10n.passYui,
    "오키나와 도시 모노레일 · 전 노선" => l10n.passYuiScope,
    "24·48시간권과 유이레일 일반 운임을 비교합니다." => l10n.passYuiDescription,
    "24시간 · ¥1,000" => l10n.passYuiOne,
    "48시간 · ¥1,800" => l10n.passYuiTwo,
    "비교할 지역을\n선택해 주세요" => l10n.passChooseRegion,
    "여행할 지역을 먼저 선택하면 해당 지역의 교통패스를 볼 수 있습니다." => l10n.passChooseRegionHint,
    "준비 중" => l10n.passComingSoon,
    "패스 선택" => l10n.passStepSelect,
    "이용 계획" => l10n.passStepPlan,
    "비교 결과" => l10n.passStepResult,
    "역 선택" => l10n.passSelectStation,
    "구간 삭제" => l10n.passRemoveSegment,
    "입력한 교통 이용 기준의 예상 비교입니다." => l10n.passEstimateNote,
    '출발' => l10n.passDeparture,
    '도착' => l10n.passArrival,
    _ => _passCompositeText(context, source),
  };
}

String _passCompositeText(BuildContext context, String source) {
  final translated = _passFlowText(context, source);
  if (translated != source || !usesEnglish(context)) return translated;
  // Only display metadata is split. Lookup keys and user input never enter here.
  if (source.contains(' · ')) {
    return source
        .split(' · ')
        .map((part) => passText(context, part))
        .join(' · ');
  }
  return source;
}
