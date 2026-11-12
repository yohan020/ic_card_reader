import 'package:flutter/material.dart';

import '../../pass_comparison/presentation/pass_strings.dart';

import '../../../core/design/app_theme.dart';
import '../../../core/widgets/app_ui.dart';

class PassDataSourcesPage extends StatelessWidget {
  const PassDataSourcesPage({super.key});

  static const _entries = [
    _PassDataSource(
      icon: Icons.subway_outlined,
      title: '삿포로 지하철 1일권',
      subtitle: '地下鉄専用1日乗車券 · ドニチカキップ · 삿포로시 지하철 전 구간',
      calculation:
          '46개 물리 역의 인접 영업거리와 공식 거리 구간 규칙으로 성인 일반 운임을 계산합니다. 삿포로와 오도리는 환승 노선이 있어도 각각 하나의 물리 역으로 계산합니다.',
      sources: [
        _SourceLink(
          '삿포로시 지하철 1일 승차권 공식 안내',
          'https://www.city.sapporo.jp/st/josyaken/card.html',
        ),
        _SourceLink(
          '삿포로시 지하철 운임 안내',
          'https://www.city.sapporo.jp/st/josyaken/ryokin/ryoukin.html',
        ),
        _SourceLink(
          '삿포로시 지하철 운임 공개 데이터셋',
          'https://ckan.pf-sapporo.jp/dataset/st_ryoukin',
        ),
      ],
      note:
          '성인 지하철 전용 1일 승차권(¥830)과 도니치카 킵(¥520)을 비교합니다. 도니치카 킵은 토·일·공휴일 및 12/29~1/3에만 이용할 수 있습니다. 운임 구간은 삿포로시 공개 데이터(CC BY 4.0)와 공식 안내를 대조했으며, 역 순서·인접 영업거리 파생 데이터는 Wikipedia contributors의 CC BY-SA 4.0 조건을 따릅니다. 다른 회사 환승·할인과 소아요금은 포함하지 않습니다.',
    ),
    _PassDataSource(
      icon: Icons.confirmation_number_outlined,
      title: '오카야마·구라시키 tabiwa 구루링 패스',
      subtitle: 'JR 서일본 · 오카야마 전기궤도 · 시모덴 버스',
      calculation:
          'JR 서일본 대상 35개 역의 성인 일반 운임 1,190건을 조회합니다. 오카야마 전기궤도는 1회 ¥160을 정확히 합산하고, 시모덴 버스는 선택한 서비스별 입력 횟수와 대표 운임을 합산합니다.',
      sources: [
        _SourceLink(
          '오카야마·구라시키 tabiwa 구루링 패스 공식 안내',
          'https://www.jr-odekake.net/ticket/tabiwa/pass/',
        ),
        _SourceLink(
          'tabiwa 상품 상세',
          'https://app.tabi-wester.westjr.co.jp/eticketDetails?ticket_id=J0002400',
        ),
        _SourceLink(
          '오카야마 전기궤도 운임 안내',
          'https://okayama-kido.co.jp/tram/route-map/',
        ),
        _SourceLink(
          '시모덴 버스 운임 개정 안내',
          'https://shimoden.net/rosen/rosen_news/entry-277.html',
        ),
      ],
      note:
          'JR 역간 거리 파생 데이터는 Wikipedia contributors의 CC BY-SA 4.0을 따릅니다. 시모덴 버스의 고지마–구라시키·도코하이호는 대표 운임이므로 실제 정류장별 운임과 다를 수 있습니다. 관광시설·렌터사이클 혜택, 특급·할인과 다른 회사 환승은 계산하지 않습니다.',
    ),
    _PassDataSource(
      icon: Icons.tram_outlined,
      title: '히로덴 전차 패스',
      subtitle: '電車一日乗車券 · 디지털 8시간권 · 24시간권',
      calculation:
          '77개 정류장 중 서로 다른 두 정류장을 선택하면 성인 일반 운임 ¥240을 적용합니다. 입력한 이동 구간 하나를 별도로 운임이 청구되는 1회 이용으로 합산합니다.',
      sources: [
        _SourceLink(
          '히로시마 전철 전차 승차권 공식 안내',
          'https://www.hiroden.co.jp/ticket-pass/bargain-tickets/oneday.html',
        ),
        _SourceLink(
          '히로시마 전철 운임 개정 자료',
          'https://www.hiroden.co.jp/topics/2024/pdf/1023-release/release.pdf',
        ),
        _SourceLink(
          'MOBIRY DAYS 운임 안내',
          'https://www.hiroden.co.jp/discount/days-fare.html',
        ),
        _SourceLink('Wikidata', 'https://www.wikidata.org/'),
      ],
      note:
          '종이 전차 1일 승차권(¥700), 디지털 8시간권(¥600), 24시간권(¥700)을 비교합니다. 정류장 식별 정보는 Wikidata CC0, 정규화한 역 코드·운임·상품 사실값은 Wikimedia 기반 CC BY-SA 4.0 조건을 유지합니다. MOBIRY DAYS의 거리별 할인, 자동 환승·재승차 판정, 버스·선박·소아요금은 포함하지 않습니다.',
    ),
    _PassDataSource(
      icon: Icons.train_outlined,
      title: '홋카이도 레일패스',
      subtitle: 'JR 홋카이도선 · 5·7·10일권',
      calculation:
          '310개 JR홋카이도 역의 성인 기본 운임을 조회합니다. 검증된 특급 역쌍은 보통차 지정석 포함 운임을 선택할 수 있고, JR홋카이도 버스는 1회 ¥300 예상값을 입력 횟수만큼 합산합니다.',
      sources: [
        _SourceLink(
          '홋카이도 레일패스 공식 안내',
          'https://www.jrhokkaido.co.jp/global/Korean/ticket/railpass/index.html',
        ),
        _SourceLink('JR 홋카이도 열차 안내', 'https://www.jrhokkaido.co.jp/train/'),
      ],
      note:
          '역·운임·정차역 순서 파생 데이터는 CC BY-SA 4.0 조건과 원 출처 고지를 유지합니다. 특급은 검증된 정규 열차 공통 정차역쌍에서만 선택할 수 있으며, 버스는 정확 운임이 아닌 예상값입니다. 그린차와 관광·계절·SL 열차는 포함하지 않습니다.',
    ),
    _PassDataSource(
      icon: Icons.landscape_outlined,
      title: '하코네 프리패스',
      subtitle: '오다큐 출발역별 가격 · 하코네 지정 교통수단',
      calculation:
          '성인 기준으로 오다큐 70개 출발역의 2·3일권 가격을 조회합니다. 등산전차·케이블카·로프웨이·해적선은 정확 운임, 버스는 사업자별 평균 운임과 입력 횟수의 예상값으로 합산합니다.',
      sources: [
        _SourceLink('하코네 프리패스 공식 안내', 'https://www.odakyu-freepass.jp/hakone/'),
        _SourceLink(
          '하코네 프리패스 공식 가격표',
          'https://www.odakyu-freepass.jp/assets/files/prices/hakone.pdf',
        ),
        _SourceLink(
          '하코네 나비: 로프웨이·해적선 운임',
          'https://www.hakonenavi.jp/transportation/ticket/ropeway/',
        ),
      ],
      note:
          '오다큐선은 출발역↔오다와라 왕복 1회만 포함하며 로망스카 특급권은 별도입니다. 역·거리 파생 데이터는 Wikipedia contributors의 CC BY-SA 4.0, 구조화 식별 정보는 Wikidata CC0을 따릅니다. 버스 결과는 예상값입니다.',
    ),
    _PassDataSource(
      icon: Icons.subway_outlined,
      title: 'Tokyo Subway Ticket',
      subtitle: 'Tokyo Metro · 도에이 지하철',
      calculation: 'ODPT 역·성인 IC 운임 데이터로 도쿄메트로와 도에이 지하철의 적용 구간 운임을 계산합니다.',
      sources: [
        _SourceLink('ODPT 공개 교통 데이터 센터', 'https://developer.odpt.org/'),
        _SourceLink(
          'Tokyo Subway Ticket 공식 안내',
          'https://www.tokyometro.jp/tst/ko/',
        ),
      ],
      note: '운임과 패스 조건은 개정될 수 있으므로 구매 전 공식 안내를 확인해 주세요.',
    ),
    _PassDataSource(
      icon: Icons.confirmation_number_outlined,
      title: '에노시마·가마쿠라 프리패스',
      subtitle: '에노덴 전선 · 오다큐 후지사와–가타세에노시마',
      calculation:
          '선택한 오다큐 발역별 패스 가격과 발역↔후지사와 왕복 성인 IC 운임, 에노덴·오다큐 프리구간의 실제 입력 운임을 합산해 비교합니다.',
      sources: [
        _SourceLink(
          '에노시마·가마쿠라 프리패스 공식 안내',
          'https://www.odakyu-freepass.jp/enokama/',
        ),
        _SourceLink('Wikidata', 'https://www.wikidata.org/'),
        _SourceLink('일본어 위키백과: 오다큐·에노덴 노선 정보', 'https://ja.wikipedia.org/'),
      ],
      note:
          '오다큐 영업거리와 운임 거리대, 에노덴 영업거리 자료를 가공해 만들었습니다. 해당 파생 데이터는 Wikipedia contributors의 CC BY-SA 4.0을 따릅니다. 특급·좌석요금, 할인과 프리구간 밖 추가 이동은 포함하지 않습니다.',
    ),
    _PassDataSource(
      icon: Icons.train_outlined,
      title: '도쿠나이 패스',
      subtitle: 'JR 동일본 도쿄 23구 내 지정 구간',
      calculation:
          '도쿠나이 적용 77개 역의 영업거리와 JR 동일본 성인 IC 운임표를 바탕으로 만든 오프라인 운임표를 사용합니다.',
      sources: [
        _SourceLink(
          'JR 동일본 도쿠나이 패스 공식 안내',
          'https://www.jreast.co.jp/multi/ko/pass/tokunai_pass.html',
        ),
        _SourceLink('JR 동일본 운임·요금 안내', 'https://www.jreast.co.jp/ko/kippu/'),
        _SourceLink('Wikidata', 'https://www.wikidata.org/'),
      ],
      note: '참고용 계산 결과이므로 실제 이용 전 적용 구간과 최신 운임을 확인해 주세요.',
    ),
    _PassDataSource(
      icon: Icons.train_outlined,
      title: '에노덴 1일 승차권',
      subtitle: '江ノ電1日乗車券「のりおりくん」 · 에노덴 전선',
      calculation: '에노덴 15개 역의 영업거리와 성인 일반 운임 거리대 규칙을 바탕으로 두 역 사이의 운임을 계산합니다.',
      sources: [
        _SourceLink(
          '에노덴 1일 승차권 「のりおりくん」 공식 안내',
          'https://www.enoden.co.jp/tourism/ticket/noriorikun/',
        ),
        _SourceLink('Wikidata', 'https://www.wikidata.org/'),
        _SourceLink('일본어 위키백과: 에노시마 전철선·에노시마 전철', 'https://ja.wikipedia.org/'),
      ],
      note:
          '에노덴 역·영업거리와 운임 거리대 자료를 가공해 만들었습니다. 해당 파생 운임 데이터는 Wikipedia contributors의 CC BY-SA 4.0을 따릅니다. 특전·할인과 다른 회사 환승은 포함하지 않습니다.',
    ),
    _PassDataSource(
      icon: Icons.confirmation_number_outlined,
      title: '오사카 주유패스',
      subtitle: '오사카 메트로 · 사철 · 시티버스',
      calculation: '철도 사업자별 공개 운임 자료, 역간 거리와 환승 연결을 바탕으로 일반 운임을 계산합니다.',
      sources: [
        _SourceLink(
          '오사카 주유패스 공식 안내',
          'https://osaka-amazing-pass.com/en/howto_about_1day.html',
        ),
        _SourceLink(
          'Osaka Metro 운임 안내',
          'https://subway.osakametro.co.jp/guide/fare/conditions_carriage/unsoyakan.php',
        ),
        _SourceLink('오사카 시티버스 이용 안내', 'https://citybus-osaka.co.jp/howto/'),
      ],
      note:
          '시간표 기반 최속 경로, 관광시설 혜택, 제외 버스, 특급·좌석요금은 포함하지 않습니다. 일부 게이한 영업거리 자료는 Wikipedia contributors의 CC BY-SA 4.0을 따릅니다.',
    ),
    _PassDataSource(
      icon: Icons.subway_outlined,
      title: '교토 지하철 1일권',
      subtitle: '교토시영 지하철 · 전 구간',
      calculation:
          '교토시영 지하철 역간 거리와 성인 운임대로 일반 운임을 계산하고, 입력한 모든 이동의 합계를 성인 ¥800 1일권과 비교합니다.',
      sources: [
        _SourceLink(
          '교토 지하철 1일권 공식 안내',
          'https://www.city.kyoto.lg.jp/kotsu/page/0000028376.html',
        ),
        _SourceLink(
          '교토시 오픈데이터: 京都市営地下鉄 駅間距離・運賃',
          'https://data.city.kyoto.lg.jp/dataset/00024/',
        ),
        _SourceLink(
          '교토시 교통국 지하철 운임',
          'https://www2.city.kyoto.lg.jp/kotsu/webguide/ja/fare/fare_tika.html',
        ),
      ],
      note:
          '「京都市営地下鉄 駅間距離・運賃」(京都市)을 가공해 만들었습니다. CC BY 4.0. 1일권은 이용일 당일 영업 종료까지 유효하며, 다른 회사 환승·할인과 소아요금은 포함하지 않습니다.',
    ),
    _PassDataSource(
      icon: Icons.directions_bus_filled_outlined,
      title: '교토 지하철·버스 1일권',
      subtitle: '교토시영 지하철 · 사용자 입력 버스 예상 운임',
      calculation:
          '교토시영 지하철은 역간 거리와 성인 운임대로 계산합니다. 버스는 일반 시내버스 ¥230·관광특급버스 ¥500의 입력 횟수만 예상 운임으로 합산합니다.',
      sources: [
        _SourceLink(
          '교토시 오픈데이터: 京都市営地下鉄 駅間距離・運賃',
          'https://data.city.kyoto.lg.jp/dataset/00024/',
        ),
        _SourceLink(
          '교토시 교통국 지하철 운임',
          'https://www2.city.kyoto.lg.jp/kotsu/webguide/ja/fare/fare_tika.html',
        ),
        _SourceLink(
          '교토 지하철·버스 1일권 공식 안내',
          'https://www.city.kyoto.lg.jp/kotsu/page/0000028378.html',
        ),
      ],
      note:
          '「京都市営地下鉄 駅間距離・運賃」(京都市)을 가공해 만들었습니다. CC BY 4.0. 버스 노선·사업자·조정 운임 구간·심야 할증·제외 노선은 자동 판정하지 않습니다.',
    ),
    _PassDataSource(
      icon: Icons.tram_outlined,
      title: '나가사키 전기궤도 패스',
      subtitle: '長崎電気軌道 一日乗車券 · 24時間乗車券 · 노면전차 전 노선',
      calculation:
          '38개 정류장의 방향별 성인 IC·터치 운임 1,406건을 기기 내 운임표로 조회합니다. 昭和町通은 赤迫 방면만 정차하므로 출발·도착 방향을 구분합니다.',
      sources: [
        _SourceLink(
          '나가사키 전기궤도 2026 노선·운임 안내',
          'https://www.naga-den.com/relays/download/9/1789/155//?file=/files/libs/6996//202603271529469650.pdf',
        ),
        _SourceLink(
          '나가사키 전기궤도 여객운송규칙',
          'https://www.naga-den.com/relays/download/382/1540/41//?file=/files/libs/6413//202510010100435309.pdf',
        ),
        _SourceLink('일본어 위키백과: 長崎電気軌道', 'https://ja.wikipedia.org/wiki/長崎電気軌道'),
      ],
      note:
          '성인 1일권(¥600)과 24시간권(¥700)을 비교합니다. 운임은 IC·터치 결제 기준이며, 지정 정류장에서 동일 카드로 30분 안에 환승한 경우의 할인값을 포함합니다. 역·노선 및 운임 규칙 파생 데이터는 Wikipedia contributors의 CC BY-SA 4.0 조건을 따르며, 공식 PDF 원문은 앱에 포함하지 않습니다. 현금·버스·소아요금은 계산하지 않습니다.',
    ),
    _PassDataSource(
      icon: Icons.subway_outlined,
      title: '후쿠오카 지하철 1일권',
      subtitle: '후쿠오카시 지하철',
      calculation:
          '36개 물리 역의 방향별 성인 일반 운임 1,260건을 기기 내 운임표로 조회합니다. 나카스카와바타와 하카타의 환승 노선 코드는 하나의 물리 역으로 묶어 중복 계산하지 않습니다.',
      sources: [
        _SourceLink(
          '후쿠오카시 지하철 1일 승차권 공식 안내',
          'https://subway.city.fukuoka.lg.jp/fare/card/oneday.php',
        ),
        _SourceLink(
          '후쿠오카시 지하철 운임 안내',
          'https://subway.city.fukuoka.lg.jp/fare/futuken/',
        ),
        _SourceLink(
          '후쿠오카시 역 데이터 공개 데이터셋',
          'https://www.geospatial.jp/ckan/dataset/40130-009',
        ),
      ],
      note:
          '역 정보는 후쿠오카시 공개 데이터(CC BY)와 현재 공식 안내를 대조해 구성했으며, 2026-09-03 기준 성인 운임만 사용합니다. 1일권은 개찰 당일 첫차부터 막차까지 유효합니다. 다른 회사 환승·할인과 소아요금은 포함하지 않습니다.',
    ),
    _PassDataSource(
      icon: Icons.train_outlined,
      title: '유이레일 패스',
      subtitle: '오키나와 도시 모노레일 · 전 노선',
      calculation:
          '유이레일 19개 역의 방향별 성인 일반 운임 342건을 기기 내 운임표로 조회합니다. 24시간권 또는 48시간권 가격과 입력한 모든 이동의 합계를 비교합니다.',
      sources: [
        _SourceLink(
          '유이레일 프리 승차권 공식 안내',
          'https://www.yui-rail.co.jp/ticketinfo-ticket/ticketinfo/1day-pass/',
        ),
        _SourceLink(
          '유이레일 운임 공식 안내',
          'https://www.yui-rail.co.jp/ticketinfo-ticket/ticketinfo/ticket/',
        ),
        _SourceLink(
          '일본어 위키백과: 오키나와 도시 모노레일선',
          'https://ja.wikipedia.org/wiki/沖縄都市モノレール線',
        ),
      ],
      note:
          '역 순서와 영업거리 기반 파생 데이터는 Wikipedia contributors의 CC BY-SA 4.0을 따릅니다. 공식 역별 운임과 전 구간을 대조했습니다. OKICA 등 결제수단별 할인, 다른 회사 환승과 소아요금은 포함하지 않습니다.',
    ),
    _PassDataSource(
      icon: Icons.train_outlined,
      title: '한큐패스 1일권',
      subtitle: '阪急1dayパス · 한큐 전철 전 노선(고베고속선 제외)',
      calculation:
          '한큐 전철 87개 역의 인접 역간 영업거리와 성인 보통 운임 거리대 규칙으로 계산한 일반 운임을 사용합니다.',
      sources: [
        _SourceLink(
          '阪急1dayパス 공식 안내',
          'https://www.hankyu.co.jp/ticket/otoku/013812.html',
        ),
        _SourceLink(
          '한큐 여객영업규칙',
          'https://www.hankyu.co.jp/traveler/01_ryoryaku.pdf',
        ),
        _SourceLink('일본어 위키백과: 한큐 각 노선 역·영업거리', 'https://ja.wikipedia.org/'),
      ],
      note:
          '한큐 각 노선의 역간 영업거리 데이터를 가공해 만들었습니다. 해당 파생 운임 데이터는 Wikipedia contributors의 CC BY-SA 4.0을 따릅니다. 고베고속선, 특급·좌석요금, 할인·IC 특례와 다른 회사 환승은 포함하지 않습니다.',
    ),
    _PassDataSource(
      icon: Icons.confirmation_number_outlined,
      title: '긴테쓰 레일 패스',
      subtitle: 'KINTETSU RAIL PASS · 1일권·2일권·5일권·5일권 Plus',
      calculation:
          '301개 역, 45,150개 역쌍의 성인 기본 운임 중 권종에 적용되는 구간만 합산합니다. 지정 버스는 적용을 확인한 뒤 직접 입력한 운임만 반영합니다.',
      sources: [
        _SourceLink(
          'KINTETSU RAIL PASS 권종별 공식 안내',
          'https://www.kintetsu.co.jp/foreign/guidebook/korean/',
        ),
        _SourceLink('Wikidata', 'https://www.wikidata.org/'),
        _SourceLink('일본어 위키백과: 긴테쓰·이가철도 노선 정보', 'https://ja.wikipedia.org/'),
      ],
      note:
          'Wikidata(CC0)와 Wikipedia/Wikimedia의 영업거리 사실값(CC BY-SA 4.0)을 가공해 만든 파생 데이터입니다. 특급은 별도 특급권이 필요하며, 로프웨이·할인·특전은 계산하지 않습니다.',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(passText(context, '데이터 출처 및 운임 기준'))),
    body: AppPage(
      children: [
        Text(
          passText(context, '역 위치 지도'),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 6),
        Text(
          passText(
            context,
            '이용내역 상세의 역 좌표는 Wikidata P625(CC0)에서 생성했습니다. 역 코드·역명·사업자·노선을 대조하며 미확인 위치는 표시하지 않습니다. 실제 이동 경로가 아닌 역 위치 참고용입니다. 지도 배경은 Google Maps가 제공하며 지도 안의 저작권 표기를 따릅니다.\nhttps://www.wikidata.org/wiki/Wikidata:Licensing',
          ),
          style: TextStyle(color: AppColors.mutedText(context), height: 1.4),
        ),
        SizedBox(height: 24),
        Text(
          passText(context, '교통패스별 데이터 출처'),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 6),
        Text(
          passText(context, '비교할 패스를 선택하면 운임 계산 기준, 출처와 제한사항을 확인할 수 있습니다.'),
          style: TextStyle(color: AppColors.mutedText(context), height: 1.4),
        ),
        SizedBox(height: 18),
        AppSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var index = 0; index < _entries.length; index++) ...[
                _PassSourceTile(source: _entries[index]),
                if (index != _entries.length - 1) Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _PassSourceTile extends StatelessWidget {
  const _PassSourceTile({required this.source});
  final _PassDataSource source;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.symmetric(horizontal: 17, vertical: 5),
    leading: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.skySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(source.icon, color: AppColors.skyDark, size: 21),
    ),
    title: Text(
      passText(context, source.title),
      style: TextStyle(fontWeight: FontWeight.w800),
    ),
    subtitle: Text(passText(context, source.subtitle)),
    trailing: Icon(Icons.chevron_right_rounded),
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _PassSourceDetailPage(source: source),
      ),
    ),
  );
}

class _PassSourceDetailPage extends StatelessWidget {
  const _PassSourceDetailPage({required this.source});
  final _PassDataSource source;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(passText(context, source.title))),
    body: SelectionArea(
      child: AppPage(
        children: [
          AppSurface(
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.softSurface(context),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(source.icon, color: AppColors.accent(context)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        passText(context, source.title),
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 2),
                      Text(
                        passText(context, source.subtitle),
                        style: TextStyle(color: AppColors.mutedText(context)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          SectionLabel(passText(context, '운임 계산 기준')),
          AppSurface(
            child: Text(
              passText(context, source.calculation),
              style: TextStyle(height: 1.45),
            ),
          ),
          SizedBox(height: 20),
          SectionLabel(passText(context, '데이터 출처')),
          AppSurface(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < source.sources.length; index++) ...[
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 5,
                    ),
                    leading: Icon(Icons.link_rounded),
                    title: Text(
                      passText(context, source.sources[index].label),
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: SelectableText(source.sources[index].url),
                  ),
                  if (index != source.sources.length - 1) Divider(height: 1),
                ],
              ],
            ),
          ),
          SizedBox(height: 20),
          NoticeBanner(
            title: passText(context, '확인할 점'),
            text: passText(context, source.note),
            tone: NoticeTone.info,
          ),
        ],
      ),
    ),
  );
}

class _PassDataSource {
  const _PassDataSource({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.calculation,
    required this.sources,
    required this.note,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String calculation;
  final List<_SourceLink> sources;
  final String note;
}

class _SourceLink {
  const _SourceLink(this.label, this.url);
  final String label;
  final String url;
}
