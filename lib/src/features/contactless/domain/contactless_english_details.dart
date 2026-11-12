const contactlessEnglishAttribution =
    'Rail data: MLIT National Land Numerical Information (2025), as of Dec 31, 2025, adapted under CC BY 4.0. Name data: Wikidata (CC0). Tap-to-ride conditions were independently compiled from official guidance.';

String contactlessEnglishReason(String status) => switch (status) {
  'supported' =>
    'Based on the coverage described in the official tap-to-ride guide.',
  'partial' =>
    'The official list of eligible stations was checked against this operator and line.',
  'unsupported' =>
    'The official payment guide confirms that direct bank-card boarding is not supported.',
  'inferred' =>
    'The published payment methods do not list direct bank-card boarding. Non-support is inferred, not explicitly confirmed.',
  _ =>
    'The available official information does not confirm whether tap-to-ride is supported.',
};

String contactlessEnglishGate(String gate) => switch (gate) {
  '改札口' => 'Ticket gate',
  '中央改札口' || '中央改札口（入口専用）' || '中央改札口（出口専用）' => 'Central gate',
  '北改札口' => 'North gate',
  '南改札口' => 'South gate',
  '西改札口' => 'West gate',
  '東改札口' => 'East gate',
  '地下改札口' => 'Underground gate',
  '橋上改札口' => 'Over-track concourse gate',
  _ => gate,
};

String contactlessEnglishUnresolved(String item) => switch (item) {
  '역별 단말/개찰구 고유명칭' => 'Reader and gate names at each station',
  '지갑별 브랜드/발급사 호환표' || '지갑별 브랜드·발급사 호환표 미확인' =>
    'Card brand and issuer compatibility by mobile wallet',
  '역별 대응 개찰구 고유명칭' || '대응 개찰구 고유명칭' => 'Names of compatible gates',
  '케이블카/철도 접속 처리의 상세' =>
    'Transfer procedures between cable cars and rail services',
  '현재10역 범위 시행일' => 'Start date for the current ten-station coverage',
  '역별 직원 부재 시간·창구 명칭' =>
    'Unstaffed hours and ticket counter names at each station',
  '일부역 미설치 개찰구의 전체 명단' => 'Full list of gates without readers at some stations',
  '현재 범위 시행일' => 'Start date for current coverage',
  '일반 개찰구별 고유명칭' => 'Names of individual regular gates',
  '현재 범위의 역별 시행일' || '현재 페이지에서 각 지정역/개찰구의 시행일 미확인' =>
    'Start dates for individual stations or gates',
  '2023 FAQ의 지갑별 호환 현재성' =>
    'Whether the 2023 wallet compatibility information is still current',
  _ => 'Some payment details have not been confirmed.',
};

String contactlessEnglishSection(String alias) =>
    _sections[alias] ?? 'This alias applies to only part of the route.';

const _sections = {
  '다테야마 케이블카': 'Tateyama Cable Car: used on the Tateyama–Bijodaira section.',
  '구로베 케이블카': 'Kurobe Cable Car: used on the Kurobedaira–Kurobeko section.',
  '우쓰노미야선': 'Utsunomiya Line: used on the Tokyo–Kuroiso section.',
  '숲과 물과 로망의 철도':
      'Forest, Water and Romance Railway: used on the Niitsu–Aizu-Wakamatsu section.',
  '아이아루 이요나다선':
      'Ai Aru Iyonada Line: used on the Mukaibara–Iyo-Ozu via Iyo-Nagahama section.',
  '조반선 각역정차': 'Joban Line Local: used on the Ayase–Toride section.',
  '주오선 쾌속': 'Chuo Line Rapid: used on the Tokyo–Otsuki section.',
  '도부 스카이트리라인':
      'Tobu Skytree Line: used on the Asakusa/Oshiage–Tobu-Dobutsu-Koen section.',
  '하나사키선': 'Hanasaki Line: used on the Kushiro–Nemuro section.',
  'JR 교토선': 'JR Kyoto Line: used on the Kyoto–Osaka section.',
  '야마토지선': 'Yamatoji Line: used on the Kamo–JR Namba section.',
  '기노쿠니선': 'Kinokuni Line: used on the Shingu–Wakayama section.',
  '하루다선': 'Haruda Line: used on the Keisen–Haruda section.',
  '와카마쓰선': 'Wakamatsu Line: used on the Wakamatsu–Orio section.',
  '미야마이선': 'Miyamai Line: used on the Nishi-Maizuru–Miyazu section.',
  '미야토요선': 'Miyatoyo Line: used on the Miyazu–Toyooka section.',
  '야마가타선': 'Yamagata Line: used on the Fukushima–Shinjo section.',
  '사가노선': 'Sagano Line: used on the Kyoto–Sonobe section.',
};

String contactlessEnglishCondition(String condition) =>
    _conditions[condition] ?? 'Check the operator’s guide for this condition.';

String contactlessEnglishSource(Map<String, dynamic> source) {
  final title = source['title'] as String;
  const prefix = '공식 터치결제 안내 · ';
  final url = title.startsWith(prefix)
      ? 'https://${title.substring(prefix.length)}'
      : _sourceUrls[title];
  if (url != null) return 'Source: $url\nChecked on ${source['date']}';
  return 'Source document checked on ${source['date']}';
}

const _sourceUrls = {
  '東京地下鉄 공식 EMV 승차 안내':
      'https://www.tokyometro.jp/ticket/types/tap-to-ride/index.html',
  '東京都 공식 EMV 승차 안내':
      'https://www.kotsu.metro.tokyo.jp/subway/fare/contactless.html',
  '東急電鉄 공식 EMV 승차 안내': 'https://www.tokyu.co.jp/railway/ticket/tap-to-ride/',
  '小田急電鉄 공식 EMV 승차 안내': 'https://www.odakyu.jp/ticket/credit_touch/',
  '京浜急行電鉄 공식 EMV 승차 안내': 'https://www.keikyu.co.jp/ride/ticket/taptoride.html',
  '江ノ島電鉄 공식 EMV 승차 안내': 'https://www.enoden.co.jp/train/please/',
  '大阪市高速電気軌道 공식 EMV 승차 안내':
      'https://subway.osakametro.co.jp/guide/page/contactless_payment.php',
  '阪急電鉄 공식 EMV 승차 안내':
      'https://faq.hankyu.co.jp/faq/show/2793?site_domain=default',
  '한큐 브랜드 FAQ': 'https://faq.hankyu.co.jp/faq/show/2791?site_domain=default',
  '阪神電気鉄道 공식 EMV 승차 안내': 'https://www.hanshin.co.jp/ticket/tap_to_ride/',
  '한신 브랜드 FAQ':
      'https://faq.hanshin.co.jp/faq/show/590?category_id=22&site_domain=default',
  '近畿日本鉄道 공식 EMV 승차 안내': 'https://www.kintetsu.co.jp/gyoumu/contactless/',
  '福岡市 공식 EMV 승차 안내':
      'https://subway.city.fukuoka.lg.jp/topics/detail.php?id=1895',
  '西日本鉄道 공식 EMV 승차 안내': 'https://www.nishitetsu.jp/train/kippu/tattikessai/',
  '沖縄都市モノレール 공식 EMV 승차 안내':
      'https://www.yui-rail.co.jp/ticketinfo-ticket/ticketinfo/%E3%82%BF%E3%83%83%E3%83%81%E6%B1%BA%E6%B8%88%E4%B9%97%E8%BB%8A%E3%82%B5%E3%83%BC%E3%83%93%E3%82%B9%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6/',
  'JR규슈 터치 승차 대상': 'https://www.jrkyushu.co.jp/railway/touch/',
  'JR규슈 2026-09-18 확대':
      'https://www.jrkyushu.co.jp/railway/touch/pdf/news260908_1.pdf',
  'JR홋카이도 루모이선 최종 운행 안내':
      'https://www.jrhokkaido.co.jp/CM/Info/press/pdf/20260209_HP_AS_rumoiline.pdf',
  'ゆりかもめ 공식 안내': 'https://www.yurikamome.co.jp/ticket/touch-payment.html',
  '京王電鉄 공식 안내': 'https://www.keio.co.jp/train/ticket/touch/credit/',
  '伊豆箱根鉄道 공식 안내':
      'https://www.izuhakone.co.jp/sunzudaiyu/sunzudaiyu-info/p010379.html',
  '遠州鉄道 공식 안내': 'https://akaden.lekumo.biz/information/2025/01/post-2647.html',
  '横浜市 공식 안내':
      'https://www.city.yokohama.lg.jp/kotsu/sub/unchin/subwaytouch.html',
  '札幌市 공식 안내': 'https://www.city.sapporo.jp/st/josyaken/topics/202504.html',
  '一般社団法人札幌市交通事業振興公社 공식 안내':
      'https://www.global.jcb/ja/press/2026/202604221400_merchants.pdf',
  '仙台市 공식 안내': 'https://www.kotsu.city.sendai.jp/fare/contactless/',
  '福島交通 공식 안내':
      'https://www.michinori.co.jp/pdf/20230823_PR_fukushima_aizu.pdf',
  '相模鉄道 공식 안내': 'https://www.sotetsu.co.jp/train/tickets/touch/',
  '神戸市 공식 안내':
      'https://kotsu.city.kobe.lg.jp/subway/ryokin-teiki/touch-kessai/faq/',
  '神戸電鉄 공식 안내':
      'https://www.shintetsu.co.jp/railway/fare/info/img/stera_transit.pdf',
  '能勢電鉄 공식 안내': 'https://noseden.hankyu.co.jp/ticket/touch.html',
  'WILLER　TRAINS 공식 안내': 'https://trains.willer.co.jp/guide/touch-payment/',
  'WILLER TRAINS 2025-06-09 7브랜드 확대 발표': 'https://digitalpr.jp/r/111035',
  '山陽電気鉄道 공식 안내': 'https://www.sanyo-railway.co.jp/railway/touch/index.html',
  '北大阪急行電鉄 공식 안내':
      'https://www.kita-kyu.co.jp/wp/wp-content/uploads/2025/02/235.pdf',
  '南阿蘇鉄道 공식 안내':
      'https://www.mt-torokko.com/wp-content/uploads/2025/01/0af55314e358bdadd1b4d961cfd185fe.pdf',
  '静岡鉄道 공식 안내':
      'https://www.shizutetsu.co.jp/media/pages/news/2025/hp20260218/89cde19b8c-1771380171/hp20260218.pdf',
  '京阪電気鉄道 공식 안내': 'https://faq.keihan.co.jp/answer/67f1de6acc6ea44d7d225b8a/',
  '首都圏新都市鉄道 공식 범위 안내': 'https://www.mir.co.jp/service/tap-to-ride/',
  '熊本電気鉄道 공식 범위 안내':
      'https://www.kumamotodentetsu.co.jp/news/202502132325.html',
  '熊本市 공식 범위 안내':
      'https://www.kotsu-kumamoto.jp/one_html3/pub/Default.aspx?c_id=62',
  '北陸鉄道 공식 범위 안내': 'https://www.hokutetsu.co.jp/faq/',
  '鹿児島市 공식 범위 안내':
      'https://www.kotsu-city-kagoshima.jp/ticket-summary/%E3%82%AF%E3%83%AC%E3%82%B8%E3%83%83%E3%83%88%E3%82%AB%E3%83%BC%E3%83%89%E3%82%BF%E3%83%83%E3%83%81%E6%B1%BA%E6%B8%88%E3%81%AE%E3%81%94%E6%A1%88%E5%86%85/',
  '高尾登山電鉄 공식 범위 안내':
      'https://www.takaotozan.co.jp/sp/info/detail.php?id=info67ff334e6586e',
  '大山観光電鉄 공식 범위 안내': 'https://www.ooyama-cable.co.jp/timetable/',
  'のと鉄道 공식 범위 안내': 'https://nototetsu.jp/faq/faq002/',
  '伊勢鉄道 공식 범위 안내': 'https://isetetu.co.jp/faq/',
  'わたらせ渓谷鐵道 공식 범위 안내': 'https://www.watetsu.com/qa/qa.php',
  '東日本旅客鉄道 공식 범위 안내':
      'https://jreastfaq.jreast.co.jp/faq/show/3954?site_domain=default',
  '西武鉄道 공식 범위 안내': 'https://www.seiburailway.jp/railway/ticket/pasmo/tap/',
  '東武鉄道 공식 범위 안내': 'https://www.tobu.co.jp/campaign/touch-payment/',
  '南海電気鉄道 공식 범위 안내': 'https://www.nankai.co.jp/contents/contactless/map/',
  '名古屋鉄道 공식 범위 안내':
      'https://www.meitetsu.co.jp/train/ticket_fare/touch_payment/howto/index.html',
  '名古屋市 공식 서비스 범위': 'https://kotsu.city.nagoya.jp/rp/ticket/TRP0005579.htm',
  '長崎電気軌道 공식 서비스 범위': 'https://www.city.nagasaki.lg.jp/page/64856.html',
  '나가사키 전차 공동 발표 EMV 7브랜드 및 사전 구매 상품 구분':
      'https://www.naga-den.com/files/libs/6141/202507151530226647.pdf',
  '大阪モノレール 공식 서비스 범위': 'https://www.osaka-monorail.co.jp/ticket/touch/',
  '오사카 모노레일 전 역 도입 시행 안내':
      'https://www.osaka-monorail.co.jp/upload/company/press/attach/20240319_pressrelease.pdf',
  '湘南モノレール 공식 서비스 범위': 'https://www.shonan-monorail.co.jp/howtoride/touch.html',
  '쇼난 모노레일 전 역 도입 발표':
      'https://www.shonan-monorail.co.jp/news/upload/c85d22eae8d9dd4171de123e691fdd40fafc93bc.pdf',
  '神戸新交通 공식 서비스 범위':
      'https://koberope.jp/wordpress/wp-content/uploads/2024/03/20240413_press_-touch-payment.pdf',
  '간토 11개사 2026-03-25 공동 시행 범위':
      'https://www.keio.co.jp/news/update/news_release/news_release2025/pdf/nr20260128_creditcardtouch.pdf',
  '長良川鉄道 공식 서비스 범위': 'https://www.nagatetsu.co.jp/guide/one-man/',
  '나가라가와 2025-09-02 Mastercard 추가': 'https://www.nagatetsu.co.jp/info/5757/',
  '나가라가와 JCB·American Express 도입 발표':
      'https://www.global.jcb/ja/press/2023/202307181400_merchants.pdf',
  'IRいしかわ鉄道 공식 지불수단·승차 안내 재검토':
      'https://www.ishikawa-railway.jp/ticket/howto/index.html',
  'あいの風とやま鉄道 공식 지불수단·승차 안내 재검토': 'https://ainokaze.co.jp/tips/faq',
  'えちごトキめき鉄道 공식 지불수단·승차 안내 재검토': 'https://www.echigo-tokimeki.co.jp/faq/',
  'えちぜん鉄道 공식 지불수단·승차 안내 재검토': 'https://www.echizen-tetudo.co.jp/guide/buy.html',
  'くま川鉄道 공식 지불수단·승차 안내 재검토': 'https://kumagawa-rail.com/time-fare/',
  'しなの鉄道 공식 지불수단·승차 안내 재검토':
      'https://www.shinanorailway.co.jp/user/cat1/?page=1',
  'ハピラインふくい 공식 지불수단·승차 안내 재검토':
      'https://www.hapi-line.co.jp/guide/faq/archives/category/ticket',
  'ひたちなか海浜鉄道 공식 지불수단·승차 안내 재검토':
      'https://www.hitachinaka-rail.co.jp/blog/2024/03/28/8777.html',
  '愛知環状鉄道 공식 지불수단·승차 안내 재검토': 'https://www.aikanrailway.co.jp/train/faq.html',
  '伊豆箱根鉄道 공식 지불수단·승차 안내 재검토':
      'https://www.izuhakone.co.jp/sunzudaiyu/sunzudaiyu-enquiry/p000657.html',
  '伊予鉄道 공식 지불수단·승차 안내 재검토':
      'https://www.iyotetsu.co.jp/information/manner/?vm=r',
  '井原鉄道 공식 지불수단·승차 안내 재검토': 'https://www.ibara-railway.co.jp/info/',
  '岡山電気軌道 공식 지불수단·승차 안내 재검토': 'https://okayama-kido.co.jp/tram/faq/',
  '会津鉄道 공식 지불수단·승차 안내 재검토': 'https://aizutetsudo.jp/train/ride/',
  '岳南電車 공식 지불수단·승차 안내 재검토': 'https://www.gakutetsu.jp/faq/',
  '京成電鉄 공식 지불수단·승차 안내 재검토':
      'https://www.keisei.co.jp/keisei/tetudou/accessj/goriyo.php',
  '御岳登山鉄道 공식 지불수단·승차 안내 재검토': 'https://www.mitaketozan.co.jp/timetable.html',
  '広島高速交通 공식 지불수단·승차 안내 재검토': 'https://www.astramline.co.jp/qa/',
  '広島電鉄 공식 지불수단·승차 안내 재검토': 'https://www.hiroden.co.jp/train/use/index.html',
  '弘南鉄道 공식 지불수단·승차 안내 재검토': 'https://konantetsudo.jp/guide-first/',
  '黒部峡谷鉄道 공식 지불수단·승차 안내 재검토': 'https://www.kurotetu.co.jp/qa/',
  '嵯峨野観光鉄道 공식 지불수단·승차 안내 재검토': 'https://www.sagano-kanko.co.jp/faq/',
  '埼玉新都市交通 공식 지불수단·승차 안내 재검토': 'https://www.new-shuttle.jp/ticket/howto_use/',
  '三岐鉄道 공식 지불수단·승차 안내 재검토': 'https://sangirail.co.jp/faq/',
  '芝山鉄道 공식 지불수단·승차 안내 재검토': 'https://www.sibatetu.co.jp/user_guide.html',
  '上信電鉄 공식 지불수단·승차 안내 재검토': 'https://www.joshin-dentetsu.co.jp/railway/guide/',
  '信楽高原鐵道 공식 지불수단·승차 안내 재검토':
      'https://koka-skr.co.jp/img/content/timetable/one-man.pdf',
  '水島臨海鉄道 공식 지불수단·승차 안내 재검토': 'https://mizurin.co.jp/passenger/ticket.html',
  '仙台空港鉄道 공식 지불수단·승차 안내 재검토': 'https://www.senat.co.jp/question',
  '千葉都市モノレール 공식 지불수단·승차 안내 재검토': 'https://chiba-monorail.co.jp/index.php/faq/',
  '大井川鐵道 공식 지불수단·승차 안내 재검토': 'https://daitetsu.jp/faq/serviceinfo-30',
  '樽見鉄道 공식 지불수단·승차 안내 재검토': 'https://tarumi-railway.com/fare/',
  '筑豊電気鉄道 공식 지불수단·승차 안내 재검토': 'https://www.chikutetsu.co.jp/help/',
  '長野電鉄 공식 지불수단·승차 안내 재검토': 'https://www.nagaden-net.co.jp/info/ticket',
  '東京モノレール 공식 지불수단·승차 안내 재검토':
      'https://www.tokyo-monorail.co.jp/support/faq.html',
  '函館市 공식 지불수단·승차 안내 재검토':
      'https://www.city.hakodate.hokkaido.jp/docs/2014012100953/',
  '福井鉄道 공식 지불수단·승차 안내 재검토': 'https://fukutetsu.jp/train/guide.php',
  '豊橋鉄道 공식 지불수단·승차 안내 재검토': 'https://toyotetsu.com/faq/shinaisen.html',
  '北越急行 공식 지불수단·승차 안내 재검토': 'https://www.hokuhoku.co.jp/kenbaiki.html',
  '北海道旅客鉄道 공식 지불수단·승차 안내 재검토': 'https://www.jrhokkaido.co.jp/faq/qa0138.html',
  '万葉線 공식 지불수단·승차 안내 재검토': 'https://www.manyosen.co.jp/timetable/iccard01/',
  '名古屋臨海高速鉄道 공식 지불수단·승차 안내 재검토': 'https://www.aonamiline.co.jp/contact/faq',
  '明知鉄道 공식 지불수단·승차 안내 재검토': 'https://www.aketetsu.co.jp/qa/',
  '野岩鉄道 공식 지불수단·승차 안내 재검토': 'https://www.yagan.co.jp/howto/',
  '養老鉄道 공식 지불수단·승차 안내 재검토': 'https://www.yororailway.co.jp/use/',
  '和歌山電鐵 공식 지불수단·승차 안내 재검토':
      'https://wakayama-dentetsu.co.jp/boarding-and-alighting/',
  'アイジーアールいわて銀河鉄道 공식 지불수단·승차 안내 재검토': 'https://igr.jp/help/qanda/',
  'アルピコ交通 공식 지불수단·승차 안내 재검토': 'https://www.alpico.co.jp/traffic/rail/howto/',
  '愛知高速交通 공식 지불수단·승차 안내 재검토':
      'https://www.linimo.jp/language/en/ride/ticket.php',
  '叡山電鉄 공식 지불수단·승차 안내 재검토':
      'https://eizandensha.co.jp/guide/tickets/normal.html',
  '甘木鉄道 공식 지불수단·승차 안내 재검토': 'https://www.amatetsu.jp/question/',
  '京都市 공식 지불수단·승차 안내 재검토':
      'https://www2.city.kyoto.lg.jp/kotsu/webguide/ja/tika/howtoride_tika.html',
  '京福電気鉄道 공식 지불수단·승차 안내 재검토': 'https://www.keifuku.co.jp/cms/randen_howto/',
  '錦川鉄道 공식 지불수단·승차 안내 재검토':
      'https://nishikigawa.com/information/how-to-use-seiryusenfare/',
  '山万 공식 지불수단·승차 안내 재검토':
      'https://town.yukarigaoka.jp/yukariline_post/yukariline_post-11685/',
  '四国旅客鉄道 공식 지불수단·승차 안내 재검토':
      'https://www.jr-shikoku.co.jp/icoca/icoca04-howto.html',
  '松浦鉄道 공식 지불수단·승차 안내 재검토':
      'https://faq.city.sasebo.lg.jp/faqfa2/public/web/knowledge1930.html',
  '智頭急行 공식 지불수단·승차 안내 재검토': 'https://www.chizukyu.co.jp/chizukyu/faq/v584/',
  '東海旅客鉄道 공식 지불수단·승차 안내 재검토':
      'https://global.jr-central.co.jp/en/tickets/buy/toica/',
  '東京臨海高速鉄道 공식 지불수단·승차 안내 재검토': 'https://www.twr.co.jp/Default.aspx?TabId=123',
  '北条鉄道 공식 지불수단·승차 안내 재검토':
      'https://kasaipublictrans.jp/service/how-to-hojorailway/',
  'とさでん交通 공식 지불수단·승차 안내 재검토':
      'https://www.tosaden.co.jp/multilingual/electric/use.html',
  '伊豆急行 공식 지불수단·승차 안내 재검토': 'https://www.izukyu.co.jp/faq/index.php',
  '宇都宮ライトレール 공식 지불수단·승차 안내 재검토': 'https://www.miyarail.co.jp/qa',
  '三陸鉄道 공식 지불수단·승차 안내 재검토': 'https://www.sanrikutetsudou.com/en/ride.html',
  '西日本旅客鉄道 공식 지불수단·승차 안내 재검토':
      'https://www.westjr.co.jp/travel-information/en/train-usage-guide/howto/basics/',
  '東京都 공식 지불수단·승차 안내 재검토':
      'https://www.kotsu.metro.tokyo.jp/subway/fare/contactless.html',
  '道南いさりび鉄道 공식 지불수단·승차 안내 재검토':
      'https://www.shr-isaribi.jp/ticket-guide/guide/ticket-machine/',
  '富山地方鉄道 공식 지불수단·승차 안내 재검토': 'https://www.chitetsu.co.jp/?page_id=25278',
  '舞浜リゾートライン 공식 지불수단·승차 안내 재검토':
      'https://www.tokyodisneyresort.jp/tdr/resortline/fare.html',
  'JR東海交通事業 공식 지불수단·승차 안내 재검토': 'https://tkj-i.co.jp/johoku-line/guide/',
  'いすみ鉄道 공식 지불수단·승차 안내 재검토': 'https://isumirail.co.jp/qanswers',
  '阿佐海岸鉄道 공식 지불수단·승차 안내 재검토': 'https://asatetu.com/utilization/',
  '埼玉高速鉄道 공식 지불수단·승차 안내 재검토': 'https://www.s-rail.co.jp/ticket/faq/about/',
  '秩父鉄道 공식 지불수단·승차 안내 재검토': 'https://www.chichibu-railway.co.jp/en/ticket.html',
  '北九州高速鉄道 공식 지불수단·승차 안내 재검토':
      'https://www.kitakyushu-monorail.co.jp/fare/ic-card.php',
  '北総鉄道 공식 지불수단·승차 안내 재검토':
      'https://www.hokuso-railway.co.jp/railway/information.html',
  '平成筑豊鉄道 공식 지불수단·승차 안내 재검토': 'https://www.retro-line.net/blog/4826/',
  '九州旅客鉄道 공식 지불수단·승차 안내 재검토': 'https://www.jrkyushu.co.jp/railway/touch/',
  'JR九州 2026年9月18日タッチ決済92駅拡大':
      'https://www.jrkyushu.co.jp/railway/touch/pdf/news260908_1.pdf',
  '東武 現行タッチ決済利用可能駅と対象外駅注意': 'https://www.tobu.co.jp/campaign/touch-payment/',
  '名鉄 現行利用可能16駅（howto）':
      'https://www.meitetsu.co.jp/train/ticket_fare/touch_payment/howto/',
  '叡山ケーブル ご利用方法FAQ': 'https://www.keifuku.co.jp/cms/eizan_howto/',
  '天浜線 一般ワンマン乗車・車両案内': 'https://www.tenhama.co.jp/about/geton/',
  '阿武隈急行 現行サイト掲載2026年7月ワンマン乗降案内':
      'https://www.abukyu.co.jp/wp-content/uploads/2026/07/%E3%83%AF%E3%83%B3%E3%83%9E%E3%83%B3%E4%B9%97%E9%99%8D%E6%A1%88%E5%86%85.pdf',
  '肥薩おれんじ鉄道 マルチ決済端末導入注意事項':
      'https://www.hs-orange.com/common/UploadFileOutput.ashx?c_id=3&flid=3189&id=982&sub_id=2',
  '近江鉄道 2026-03-01以後の普通乗車方法・現金整理券・ICOCA':
      'https://www.ohmitetudo.co.jp/railway/icoca-2025/',
  '阪堺 電車の乗り方・利用可能な支払い方法': 'https://www.hankai.co.jp/guide/howto/',
  '山形鉄道 現行乗り方案内からリンクされた一般乗車ガイドPDF':
      'https://flower-liner.jp/wp/wp-content/uploads/2025/01/norikata.pdf',
  '青い森鉄道 現行一般ワンマン乗降案内': 'https://aoimorirailway.com/lang_jp/wanman/',
  '横浜シーサイドライン 旅客営業規則2026-06-14':
      'https://www.seasideline.co.jp/fare_ticket/document/pass_rule.pdf',
  '立山黒部全区間の当日きっぷ購入・支払案内': 'https://www.kurobe-dam.com/whatis/qa.html',
  '東葉高速 全線普通乗車券案内': 'https://www.toyokosoku.co.jp/ticket/regular',
  'ことでん 2026-09-01一般乗車方式変更・IC継続追記':
      'https://www.kotoden.co.jp/publichtm/kotoden/new/2026/press20260819.pdf',
  '前橋市交通政策課 上毛電鉄現行乗降・支払い案内':
      'https://maebashimobility.jp/traffic/railroad/jomorailway_howtoride',
  '阿武隈急行 FAQ': 'https://www.abukyu.co.jp/quest/',
  '青い森 2026年3月14日各駅窓口決済制限':
      'https://aoimorirailway.com/archives/top-side/eigyou?q=archives%2Ftop-side%2Feigyou',
  '立山黒部貫光 乗車券購入および乗車時の注意':
      'https://www.alpen-route.com/access_new/fare/ticket.html',
  '東葉高速 ICカード': 'https://www.toyokosoku.co.jp/ticket/iccard',
  '前橋市交通ポータル運営主体': 'https://maebashimobility.jp/contact',
  '肥薩おれんじ鉄道 一般利用方法':
      'https://www.hs-orange.com/hpkiji/pub/List.aspx?c_id=3&class_id=52&class_set_id=1',
  '東葉高速 現行その他案内・運送約款リンク': 'https://www.toyokosoku.co.jp/ticket/other',
  '東葉高速 旅客営業規則2025-04-01 第4条':
      'https://www.toyokosoku.co.jp/wp/images/ryokaku_eigyou_20250401-1.pdf',
  '名古屋市 ガイドウェイバスの一般乗降・現金/manaca':
      'https://faq.city.nagoya.jp/faq/detail.aspx?id=917',
  '真岡鐵道 普通列車・SLのIC/クレジット不可': 'https://www.moka-railway.co.jp/fare/',
  '鹿島臨海鉄道 2026-03-11 一般乗車の現金案内': 'https://www.rintetsu.co.jp/14010.html',
  '上田電鉄 別所線一般乗車案内': 'https://www.uedadentetsu.com/guidance.html',
  '上田電鉄 別所線 きっぷQR・現金の乗降図':
      'https://www.uedadentetsu.com/assets/themes/uedadentetsu_202003/imgs/lower/guidance_img02_2412.png',
  '水間鉄道 現行ご利用案内の添付': 'https://www.suitetsu.com/train/infomation/index.html',
  '水間鉄道 全駅ワンマン乗降・PiTaPa/現金/回数券/定期券':
      'https://www.suitetsu.com/train/infomation/image/train_infomation.pdf',
  '京成 現行ご利用案内と運送約款リンク':
      'https://www.keisei.co.jp/keisei/tetudou/accessj/goriyo.php',
  '京成 2026-03-14旅客営業規則 松戸線適用と第4条':
      'https://www.keisei.co.jp/keisei/tetudou/goriyo/pdf/keisei_260314.pdf',
  '皿倉山ケーブル 一般運賃のお支払い・キャッシュレスは窓口のみ':
      'https://www.sarakurayama-cablecar.co.jp/fare/',
  '皿倉山 北九州周遊パス タッチ後も乗車券受領必要':
      'https://www.sarakurayama-cablecar.co.jp/news/2025-7-23%E3%80%8C%E5%8C%97%E4%B9%9D%E5%B7%9E%E5%91%A8%E9%81%8A%E3%83%91%E3%82%B9%E3%80%8D%E8%B2%A9%E5%A3%B2%E9%96%8B%E5%A7%8B/',
  '土佐くろしお 現行のる 一般乗車・特急乗継・スマえき':
      'https://www.tosakuro.com/schedules-and-stations',
  '土佐くろしお 一両ワンマン一般乗降図':
      'https://static.wixstatic.com/media/310f5f_896f3bccf2094c7a84f4f6752e30f794~mv2.jpg/v1/fill/w_743%2Ch_725%2Cal_c%2Cq_85%2Cenc_avif%2Cquality_auto/oneman_001.jpg',
  '一畑電車 現行英語一般乗車・紙券/整理券と運賃箱精算': 'https://railway.ichibata.co.jp/lang/en/',
  '多摩モノレール 旅客営業規則 260314 第2・4・5・12条':
      'https://www.tama-monorail.co.jp/monorail/ticket/260314_Passenger_business_rules.pdf',
  '東北観光推進機構 津軽鉄道 通年の購入・車内精算 現金のみ':
      'https://www.tohokukanko.jp/transport/detail_1001133.html',
  '津軽鉄道 2026年12月ストーブ列車 支払説明（特別列車範囲のみ）': 'https://tsutetsu.com/lp',
  '由利高原鉄道 現行通常切符の販売駅案内':
      'https://www.obako5.com/%E3%83%81%E3%82%B1%E3%83%83%E3%83%88/%E5%90%84%E7%A8%AE%E4%B9%97%E8%BB%8A%E5%88%B8%E3%81%AE%E3%81%94%E6%A1%88%E5%86%85/',
  '由利高原鉄道 車両紹介の乗降案内・有人駅紙券/無人駅運賃箱':
      'https://www.obako5.com/%E9%B3%A5%E6%B5%B7%E3%81%8A%E3%82%82%E3%81%A1%E3%82%83%E5%88%97%E8%BB%8A%EF%BD%A2%E3%81%AA%E3%81%8B%E3%82%88%E3%81%97%E3%81%93%E3%82%88%E3%81%97%EF%BD%A3%E3%81%AE%E9%AD%85%E5%8A%9B/',
  '由利高原鉄道 2020-04-09 羽後本荘駅通常乗降・現金運賃箱案内':
      'https://www.obako5.com/info/5%E6%9C%881%E6%97%A5%E9%87%91%E3%82%88%E3%82%8A%E7%BE%BD%E5%BE%8C%E6%9C%AC%E8%8D%98%E9%A7%85%E3%81%AE%E5%96%B6%E6%A5%AD%E6%99%82%E9%96%93%E3%81%8C%E5%A4%89%E3%82%8F%E3%82%8A%E3%81%BE%E3%81%99/',
  'ラクテンチ 一般ゲートでのクレジット決済FAQ': 'https://rakutenchi.jp/guidance/faq/',
  'ラクテンチ メインゲート一般入園券のケーブル往復同梱': 'https://rakutenchi.jp/guidance/price/',
  '丹後海陸交通 ケーブル普通乗車券の購入・支払場所': 'https://www.tankai.jp/trip/cable/',
  '丹後海陸交通 ケーブルFAQのチケット購入決済手段': 'https://www.tankai.jp/trip/faq/',
  '大井川鐵道 2026井川線観光商品決済と402/405一般車両例外': 'https://daitetsu.jp/abt',
  '関東鉄道 2022-03-10 窓口カード導入・普通券/回数券/チャージの除外条項':
      'https://www.kantetsu.co.jp/img/news/2022/22030801_train/info.pdf',
  '関東鉄道 現行の一般普通乗車券購入・乗越し精算案内': 'https://www.kantetsu.co.jp/train/ticket',
  '関東鉄道 鉄道PASMOの入出場・残額不足精算/両線駅一覧': 'https://www.kantetsu.co.jp/train/iccard',
  '若桜鉄道 沿線ガイド2025ファイル・表紙記載2024-09の内容範囲':
      'https://wakatetsu.co.jp/wp/wp-content/uploads/2025/03/wakatetsu-ensen-guidebook_2025.pdf',
  '伊賀市 伊賀鉄道地域活性化R8-R10計画・VISAタッチ決済機の導入計画':
      'https://www.city.iga.lg.jp/cmsfiles/contents/0000013/13966/igatetu.pdf',
  '伊賀市 地域未来交付金事業公開・2026-04-22と予算成立の前提':
      'https://www.city.iga.lg.jp/0000013966.html',
  '富士急行線 2026-03-14一般駅窓口・カード購入・紙券回収案内':
      'https://www.fujikyu-railway.jp/news/info.php?no=425',
  '富士急行線 一般Suica/紙券の入出場・残高不足精算':
      'https://www.fujikyu-railway.jp/column/suica.php',
  '富士急行 2015-04-20会社発表・普通乗車券等の窓口カード購入':
      'https://prtimes.jp/main/html/rd/p/000000441.000001110.html',
  '富士山麓電気鉄道 2026-06-01下吉田グッズ販売機のタッチ決済範囲':
      'https://www.fujikyu-railway.jp/news/info.php?no=1154',
  '富士急行線 2026-03-01特急予約と別途必要な一般乗車券の区別':
      'https://www.fujikyu-railway.jp/news/info.php?no=1091',
  '秋田内陸線社員ブログ 2010-10-02一般乗車・整理券/運賃箱の旧案内':
      'https://nairikutetu.livedoor.blog/archives/50469563.html',
  '十国峠 現行一般FAQは所要時間・景観・軌間のみ': 'https://www.jukkoku-cable.jp/qanda/index.html',
  '伊賀鉄道 2025-02-01一般乗車券・全国交通系IC案内の範囲':
      'https://www.igatetsu.co.jp/igatetsu/wp-content/uploads/2025/01/20250201goannai.pdf',
};

// English summaries of the exact Korean research notes. Ticket purchases,
// direct boarding, and inferred vs. explicit non-support remain distinct.
const _conditions = {
  '공식 승차권/ICOCA 이용 안내에서 신용카드는 창구 승차권·일부 정기권 구매 수단으로만 안내한다. 직접 EMV 승차 안내는 없으므로 미지원 추정.':
      'The official ticket and ICOCA guide lists credit cards only for ticket-counter purchases and some commuter passes. No direct bank-card boarding is listed.',
  '브랜드별 전체 목록: 이번 대장에서 미확정. 원문 도안/후속 공지 확인 필요.':
      'The full list of card brands has not been confirmed. Check the operator’s artwork or later announcements.',
  '공식 일반 승차 안내와 FAQ는 종이표·정리권·차내 운임 지불을 안내하며 교통IC 승차도 불가라고 설명한다. EMV 직접 승차는 없어 미지원 추정. 단체열차 현금 규정만으로 판정하지 않음.':
      'The regular boarding guide lists paper tickets, boarding slips and on-board fare payment, and excludes transit IC cards. It does not list direct bank-card boarding. The decision is not based solely on charter-train cash rules.',
  '宮津線/宮福線의 보통·쾌속 대상. 특급은 자유석도 불가, 일부 보통·쾌속 제외. 宮津 남구에는 단말 없어 북구로 이동. 시간표 대상 열차 확인 필수.':
      'Eligible local and rapid trains on the Miyazu and Miyafuku lines only. Limited express trains and some local or rapid services are excluded. Use Miyazu’s north entrance; the south entrance has no reader. Check the timetable.',
  '공식 결제수단 FAQ는 종이표/차내 정산을 안내하고 신용카드는 일부 역의 회수권·정기권 구매에만 허용한다고 설명한다. 직접 EMV 승차는 없어 미지원 추정.':
      'The payment FAQ lists paper tickets and on-board settlement. Credit cards are accepted only for some multi-ride and commuter passes at selected stations.',
  '공식 FAQ는 교통IC 승차와 현금 정산을 안내하며 신용카드는 일부 창구 정기권/JR 승차권 구매에 한정한다고 설명한다. EMV 직접 승차 미지원 추정.':
      'The FAQ lists transit IC cards and cash settlement; bank cards are limited to certain commuter pass and JR ticket purchases at counters.',
  '上高地線 공식 승차 안내는 운임을 현금으로 내고 新島々 창구에서만 일부 카드 구매가 가능하다고 설명한다. 버스의 EMV 도입과 분리해 철도는 미지원 추정.':
      'The Kamikochi Line guide lists cash fares and some card purchases at Shin-Shimashima ticket office. The bus tap-to-pay rollout does not apply to the railway.',
  '공식 FAQ의 일반 승차권 구입 안내는 정리권·차내 운임함 정산 또는 두 역 발권기 구매를 열거하고 잔돈을 준비하도록 설명한다. 직접 EMV 승차는 안내하지 않아 미지원 추정.':
      'The FAQ lists boarding slips and on-board payment or ticket machines at two stations. Bring change. Direct bank-card boarding is not listed.',
  '공식 FAQ는 승차권 구매·IC 취급·예약 승차권 수령과 신용카드 취급 역을 안내한다. 카드 자체로 승하차하는 서비스 안내가 없어 미지원 추정. 관광열차 웹 결제와 구분.':
      'The FAQ lists ticket purchases, transit IC handling, reserved ticket pickup and stations that accept credit cards. Online sightseeing ticket purchases are not direct boarding.',
  '공식 구매·지불수단 종합 안내는 현금·교통IC 승차, 창구/발권기/앱의 카드·QR 구매를 구분한다. 직접 EMV 승차는 열거하지 않아 미지원 추정.':
      'The guide separates cash and transit IC fares from bank-card or QR purchases at counters, machines or in the app.',
  '공식 운임·승차권 안내는 창구/발권기 구매·차내 정산과 QUICK RIDE 앱의 카드/PayPay 사전구매를 안내한다. 직접 EMV 승차는 안내하지 않아 미지원 추정.':
      'The fare guide lists ticket counters, machines, on-board payment and advance purchases via QUICK RIDE with cards or PayPay.',
  '摩耶ケーブル의 摩耶ケーブル〜虹 두 역. 같은 회사의 로프웨이는 철도 기준 집계 밖. 현재 카드회사 철도 목록과 도입 공식 자료를 대조. 브랜드의 후속 추가는 미확정.':
      'Both stations on the Maya Cable line, Maya Cable and Niji, are covered. The ropeway is separate. Later additions to accepted card brands have not been confirmed.',
  '적용일/자료의 시행일: 2024-04-11': 'Announcement effective date: April 11, 2024.',
  '현행 공식 FAQ는 KURURU 및 전국 상호이용 교통IC 승차를 안내한다. 별도의 카드 직접 터치 승차 도입 근거는 없으므로 미지원 추정. 2026년 이전 IC 미도입 공지는 현행 근거로 사용하지 않음.':
      'The current FAQ lists KURURU and interoperable transit IC cards. No separate bank-card rollout was confirmed. Older notices about IC cards are not used as current evidence.',
  '공식 전차 승차 안내는 정리권·현금 운임함·일일권·교통IC로 지불하는 절차를 안내한다. 직접 EMV 승차는 열거하지 않아 미지원 추정. 버스 캐시리스 도입과 분리.':
      'The tram guide lists boarding slips, cash fare boxes, day passes and transit IC cards. The bus cashless service is separate.',
  '공식 FAQ가 승차 시 현금만 가능하며 IC·신용카드·캐시리스 불가라고 명시. 온라인 승차권 결제는 별도.':
      'The FAQ says only cash is accepted when boarding. Transit IC, credit cards and other cashless payments are not accepted on board. Online purchases are separate.',
  '공식 FAQ가 교통IC 이용과 신용카드 사용 가능한 판매기기/승차권을 구체적으로 구분한다. EMV 직접 승차는 안내하지 않아 미지원 추정.':
      'The FAQ distinguishes transit IC travel from credit-card ticket purchases at specific machines. Direct bank-card boarding is not listed.',
  '공식 2024-04-01 시행 공지는 신용카드 터치를 두 창구의 승차권/상품 구매에만 안내하고 발권기·차내 취급은 없다고 설명한다. 직접 터치 승차와 구분해 미지원 추정. 웹 검색 원문은 확인, 직접 HTTPS는 타임아웃.':
      'The April 1, 2024 notice limits card taps to purchases at two counters, not ticket machines or on board. This does not constitute direct tap-to-ride.',
  '전 16역. 대응 개찰 통로 이용, 성인 보통운임·동일 매체, 사전 표 구매 불필요.':
      'All 16 stations. Use the designated gate and the same card or device. Adult regular fare applies; no advance ticket is needed.',
  '정상 HTTPS 원문 HTML에서 일반 FAQ의 7브랜드·일시불·각 게이트 한정 카드 결제를 확인했다. 현행 요금 안내의 메인 게이트 일반 입장권은 케이블 왕복승차권을 포함한다. 창구/입장권 구매형 지불수단에 근거해 직접 EMV 승차 미지원으로 추정하며, 공식 불가 확정은 아니다. 이전 \'FAQ 카드 문구 미확인\'은 검색 추출 누락이었으므로 정정한다. 매점 결제를 일반 승차로 확대하지 않았다.':
      'The FAQ lists seven card brands and one-time payments at admission gates. A standard main-gate admission ticket includes a cable-car round trip. Paying for admission is not direct tap-to-ride; non-support is inferred, not confirmed.',
  '공식 FAQ가 승차권·운임 지불은 현금만 가능하다고 명시. JR/도부 간이 IC 출구를 이 회사의 승차 터치로 오해하지 않음.':
      'The FAQ says tickets and fares are cash only. JR and Tobu transit IC readers do not apply to this operator.',
  '공식 DMV 일반 승차 가이드북은 예약 전 카드 온라인 결제와 당일 현금/회수권 운임 지불을 구분하며 차내 신용카드·전자화폐·교통IC 불가를 명시한다.':
      'The DMV guide separates online card payment for advance bookings from same-day cash or multi-ride tickets. Credit cards, e-money and transit IC are not accepted on board.',
  '정리권과 운임함 납부를 설명한 일반 승차 안내 및 공식 FAQ의 표 구매 절차를 대조했다. EMV 직접 승차 안내는 없어 지불수단 기준 추정이다. 교통IC 불가 문구만의 판정은 아니다.':
      'The regular boarding guide and FAQ explain boarding slips, fare boxes and ticket purchases. Non-support is inferred from these payment instructions, not just from transit IC being unavailable.',
  '공식 FAQ의 운임 지불 질문은 신용카드를 사용할 수 없으므로 현금으로 지불하라고 명시한다. 별도 직접 EMV 승차 도입 근거도 확보되지 않음.':
      'The FAQ explicitly says to pay in cash because credit cards are not accepted. No separate direct tap-to-ride rollout was confirmed.',
  '공식 영문 승차권 안내는 현금으로 표를 구매하고 교통IC 10종으로 승차하는 방식을 열거한다. 카드 구매 불가 문구를 EMV 불가 명시문으로 확대하지 않고 직접 EMV 미지원 추정으로 구분.':
      'The official English guide lists cash ticket purchases and ten transit IC card types. Direct bank-card boarding is not listed; the ticket purchase restriction alone is not an explicit ban.',
  '공식 입산 안내는 케이블 이용을 기부금의 답례로 설명하지만 기부/승차의 실제 지불수단은 명시하지 않는다. 현금이라는 제3자 체험담이나 운임이 아닌 기부라는 법적 성격만으로 EMV를 부정하지 않는다.':
      'The official guide describes the cable ride as a benefit of the admission donation but does not list payment methods. Tap-to-ride remains unverified.',
  '이가시2026-04-22 공고에 연결된R8-R10(2026~2028) 사업계획1면을 시각 판독해 VISA 터치결제기 도입 계획을 확인했다. 그러나 운영 개시일·일반 철도 개찰 적용역/승하차 방식은 기재하지 않았고 공고에는 예산 성립 전제도 있다. 2025-02-01 운영사 일반표/교통IC 안내는 종이표 구매·차장/출구 정산과IC입출장을 설명하나 지불수단 전체가 아니다. 계획을 현행 지원이나 현재 명시적 미지원으로 바꾸지 않고 유보한다. 추가 지역교통계획P.pdf 검색 색인은 도입 검토를 언급했지만 직접404여서 확정 본문으로 쓰지 않는다.':
      'Iga City’s April 22, 2026 plan proposes Visa tap readers for 2026–2028, subject to funding. It gives no start date or station and gate details. The operator’s 2025 guide describes paper tickets and transit IC, so current bank-card support remains unverified.',
  '河原田〜津에서 교통 IC 및 신용카드 터치 결제 불가를 명시. 직통 승차라도 현금 정산·기존 카드 출입장 기록 처리가 필요.':
      'Between Kawarada and Tsu, transit IC and bank-card taps are not accepted. Through passengers must settle in cash and may need to clear their existing card entry record.',
  '공식 FAQ는 신용카드를 승차권·정기권·특급권 구매 수단으로 설명하고 Suica/PASMO 직접 승차를 별도 안내한다. EMV 직접 승차는 안내하지 않아 미지원 추정.':
      'The FAQ lists credit cards for ticket, commuter pass and limited express purchases. Suica and PASMO are listed separately for direct boarding.',
  '駿豆線 전 역. Mastercard는 2025-05-27 추가. 大雄山線까지 확대하지 않음.':
      'All stations on the Sunzu Line. Mastercard was added May 27, 2025. The Daiyuzan Line is not included.',
  '적용일/자료의 시행일: 2024-12-18': 'Announcement effective date: December 18, 2024.',
  '공식 FAQ는 駿豆線의 EMV 직접 승차를 설명한 뒤 大雄山線은 신용카드에 대응하지 않는다고 명시한다. 대상은 大雄山線에 한정.':
      'The FAQ confirms tap-to-ride on the Sunzu Line and explicitly excludes credit cards on the Daiyuzan Line.',
  '공식 종합 승차 안내/승차권 안내는 현금·전국 교통IC·미컁 QR 앱을 안내한다. 신용카드는 승차권 구매처의 결제와 구분하며 직접 EMV 승차는 없어 미지원 추정.':
      'The railway guide lists cash, nationwide transit IC and the Mican QR app. Bank-card ticket purchases are separate.',
  '공식 철도 정보의 운임 지불 항목은 IC카드와 신용카드 등으로 정산할 수 없으며 현금 취급이라고 명시한다. 정기권 구매의 캐시리스와 구분.':
      'The railway fare guide says cash settlement only; transit IC and credit cards are not accepted. Cashless commuter-pass purchases are separate.',
  '정상 메뉴의 실제 영어 링크(/lang/en/)에서 일반 승차 안내를 확보했다. 유인5역 종이표 구입·출구 반납, 무인역 정리권·하차 시 운임함 정산과 사용 불가 고액권을 설명한다. 사전구매 캐시리스 패스는 직접 EMV가 아니며 현행 EMV 도입을 찾지 못했다는 사실만을 근거로 삼지 않고, 이 일반 지불 절차를 근거로 미지원 추정한다.':
      'The English guide describes paper tickets at five staffed stations and cash fare boxes with boarding slips at unstaffed stations. Prepaid cashless passes are separate.',
  '아오모리 공식 관광 안내의 실제 링크는 www 없는 seikan-tunnel-museum.jp였다. 해당 정상 HTTPS도 시간초과/TLS 오류였다. 관광기관의 입장료/체험권 가격만으로 직접 EMV 여부를 판단하지 않는다.':
      'The operator’s site could not be verified. Admission and experience prices alone do not establish tap-to-ride support.',
  '시전 전 정류장·전 차량. 하차 시 터치. 복수인/어린이/복지할인은 먼저 운전사에게 요청. 타 교통기관 합산·환승할인과 구분.':
      'All tram stops and vehicles. Tap when getting off. Ask the driver first for multiple riders, child fares or welfare discounts. Other operators and transfer discounts are separate.',
  '적용일/자료의 시행일: 2026-04-27': 'Announcement effective date: April 27, 2026.',
  '공식 FAQ가 운임을 신용카드·QR·VISA 터치로 지불할 수 없다고 명시하며 현금 또는 교통IC로 한정한다.':
      'The FAQ explicitly excludes credit cards, QR and Visa tap for fares; it lists cash and transit IC.',
  '공식 보통 승차권/IC 안내는 종이표·승차역증명서·하차 정산 및 교통IC 사용을 안내한다. EMV 직접 승차는 안내하지 않아 미지원 추정.':
      'The ordinary ticket guide describes paper tickets, proof of boarding station, fare adjustment and transit IC, but does not list direct bank-card boarding.',
  '철도선 전 역 도입 안내. 2025-01 자료의 6브랜드를 확인; 현행 Mastercard 추가 여부는 별도 확인 필요. 모바일 안내 있음.':
      'All stations on the Railway Line. The January 2025 notice lists six brands and mobile payments. Later Mastercard support remains unverified.',
  '적용일/자료의 시행일: 2025-03-01': 'Announcement effective date: March 1, 2025.',
  '현행 일반 운송 규정 제4조는 현금·특인 결제 및 별도 PASMO 규칙을 정한다. 일반 승차권 안내와 대조해 직접 EMV 미지원으로 추정한다. 현금만이라고 단정하지 않는다.':
      'The general conditions list cash, authorized alternatives and separate PASMO rules. No direct bank-card boarding is listed; this is not a cash-only finding.',
  'みなとみらい線 전 역. 다른 회사의 미지원 구간/전용 환승 개찰 제한은 별도.':
      'All stations on the Minatomirai Line. Other operators and designated transfer gates have separate conditions.',
  '적용일/자료의 시행일: 2026-03-25': 'Announcement effective date: March 25, 2026.',
  '블루라인·그린라인 전 40역. N02 법정 노선은 1호선/3호선/4호선으로 구분. 대응 전용 개찰 이용.':
      'All 40 Blue and Green Line stations (legal lines 1, 3 and 4). Use designated gates.',
  '공식 FAQ는 Hareca·전국 교통IC 승차와 정기권 구매용 신용카드를 구분한다. EMV 직접 승차는 안내하지 않아 미지원 추정.':
      'The FAQ separates Hareca and nationwide transit IC travel from credit-card purchases of commuter passes.',
  '전 19역. 전용 개찰 통로 수는 역별 상이. 800엔 상한은 2026-08-31 종료; 승차 지원 종료가 아님.':
      'All 19 stations. The number of compatible gates varies. The ¥800 cap ended August 31, 2026; tap-to-ride did not end.',
  '공식 会津線 승차 안내가 신용카드·각종 IC카드로 운임 정산할 수 없다고 명시한다. 종이 승차권/현금 이용.':
      'The Aizu Line guide explicitly excludes credit and IC cards for fare settlement. Use paper tickets or cash.',
  '공식 FAQ는 신용카드·교통IC를 吉原역 발권기에서 승차권을 사는 수단으로만 설명하고 직접 IC 승차/정산은 불가로 구분한다. 직접 EMV 승차 미지원 추정.':
      'Credit cards and transit IC are listed only for purchases at the Yoshiwara ticket machine. Direct IC boarding or settlement is not accepted, and direct bank-card boarding is not listed.',
  '공식 FAQ는 신용카드를 사용할 수 없고 전부 현금 취급이라고 명시한다. 단순히 교통IC 미지원 문구만으로 판정하지 않음.':
      'The FAQ explicitly says credit cards are not accepted and payments are cash only.',
  '2022-03-10 창구 카드 도입 PDF를 시각 판독해 제3항이 정기/기획권만이 아니라 보통승차권·회수권·IC 충전의 카드 결제 제외도 명시함을 확인했다. 이를 현행 철도 일반표 구매·승차/잔액부족 정산 및 PASMO 양선 역별 안내와 결합해 조소·류가사키선 직접 EMV 미지원으로 추정한다. 오래된 구매 제한을 최신 직접승차 불가 확정으로 부르지 않으며 카드 창구 구매와 EMV 검표를 구별한다. 검색 부재나 정기권 전용 문구만으로 판정하지 않았다.':
      'The March 10, 2022 counter-payment notice excludes ordinary tickets, multi-ride tickets and IC top-ups. Current ordinary ticket, fare adjustment and PASMO guides do not list direct tap-to-ride on the Joso or Ryugasaki lines. The older purchase restriction is not a current explicit tap-to-ride ban.',
  '고보시 공식 링크로 운영사 실제 도메인이 www.kitetsu.co.jp/railway/index.html임을 확인했다. 앞선 kitetsu.jp 후보는 올바른 공식 경로가 아니었다. 정상 HTTPS 수신은 TLS 오류/웹 캐시 미수신이어서 우회하지 않았고 지불 안내 확보가 필요하다.':
      'The operator’s official site was identified through Gobo City, but its payment guide could not be retrieved.',
  '게이오·이노카시라 계통 전 역. 임시 출입구 및 新宿/分倍河原/高尾 JR 연결 개찰 제외. QR 전용 소개 페이지와 구분.':
      'All stations on the Keio and Inokashira networks. Temporary entrances and JR transfer gates at Shinjuku, Bubaigawara and Takao are excluded. QR-only information is separate.',
  '공식 FAQ에서 신용카드 터치 결제로 운임을 지불할 수 없다고 명시. PiTaPa와 은행카드 EMV를 구분.':
      'The FAQ explicitly says bank-card tap payments cannot be used for fares. PiTaPa is a separate transit IC service.',
  '공식 이용 안내는 종이/IC 승차, 운임과 카드 구매·변경 절차를 안내하지만 EMV 직접 승차는 안내하지 않는다. 현행 별도 도입 공지도 확보되지 않아 미지원 추정. 스카이라이너 온라인 카드 결제와 구분.':
      'The guide lists paper tickets, transit IC and ticket purchasing or changes. No direct bank-card boarding rollout was confirmed. Online Skyliner purchases are separate.',
  '현행 안내에 실제 연결된 2026-03-14 약관을 확보했다. 제2·3조가 마쓰도선을 명시적으로 포함하고, 제4조는 현금·SF 및 정기/특급 관련 카드 구매 예외, 제13조는 유효 승차권 소지를 규정한다. 2026년 도입 검색과 대조해 마쓰도선도 EMV 직접 승차 미지원으로 추정한다. 본선 규정을 근거 없이 확대하거나 404 구형 PDF를 현행본으로 사용하지 않았다.':
      'The March 14, 2026 conditions expressly cover the Matsudo Line and list cash, stored fare and card exceptions for commuter or limited express purchases. Current direct tap-to-ride was not found.',
  '교토시 공식 지하철 승차 안내가 사용할 수 있는 표/교통IC와 함께 신용카드·캐시카드는 사용할 수 없다고 명시한다. 향후 도입 예정과 현재를 구분.':
      'Kyoto’s subway guide explicitly excludes credit and bank cards and lists accepted tickets and transit IC. Announced future changes are separate.',
  '5개 노선 전 역 기본 지원. 品川/天空橋/八丁畷/横浜 환승 개찰구, 神奈川新町西口/上大岡京急百貨店口 제외.':
      'All stations on the five lines by default, excluding transfer gates at Shinagawa, Tenkubashi, Hatchonawate and Yokohama, the Kanagawa-Shimmachi west gate and the Kami-Ooka Keikyu department store gate.',
  '케이블·로프웨이는 현금만 결제 가능하다는 FAQ 답변을 확인했다. 교통IC 불가만을 확대 해석한 판정이 아니다.':
      'The FAQ says the cable car and ropeway accept cash only.',
  '본문 일부 운임은 구형이므로 운임 금액을 사용하지 않는다. 嵐電 및 별도 회사 叡山電鉄와 구분한다.':
      'Some fares in the source are outdated. Randen and Eizan Electric Railway are separate operators.',
  '嵐電 공식 이용 방법은 현금 또는 전국 교통IC로 운임을 지불한다고 열거한다. 北野線·嵐山本線만 미지원 추정하며 별도 鋼索線에는 전파하지 않음.':
      'Randen lists cash and nationwide transit IC. This finding applies to the Kitano and Arashiyama Main lines, not the cable car.',
  '2026-06-24 공식 지불 안내가 錦川鉄道 및 JR岩徳線의 교통IC/신용카드 이용 불가와 현금 정산을 명시한다.':
      'The June 24, 2026 official guide lists cash settlement and excludes transit IC and credit cards on Nishikigawa Railway and the JR Gantoku Line.',
  '이코마 케이블 제외 전 노선. 柏原 2025-03-04 추가. 鶴橋/JR·近鉄名古屋 타사 환승 개찰 제외.':
      'All lines except Ikoma Cable. Kashiwara was added March 4, 2025. JR transfer gates at Tsuruhashi and other operators’ gates at Kintetsu-Nagoya are excluded.',
  '공식 현행 안내의 이코마 케이블 제외. 일반 승차권 구매와 구분.':
      'The current guide excludes Ikoma Cable. Paying for a regular ticket is separate.',
  '2026-03-01 개정 일반 승차 안내에서 ICOCA 잔액·현금 정리권 방식 및 일반 종이표 종료를 확인했다. 직접 EMV는 안내되지 않아 미지원 추정이다. iCONPASS 온라인 카드 구매를 직접 승차로 보지 않는다.':
      'The March 1, 2026 guide lists ICOCA or cash with boarding slips and says ordinary paper tickets ended. Buying iCONPASS online is not direct tap-to-ride.',
  '2026-09-18 시행 대상 92역 폐쇄 목록에 이 법정 노선의 대상 역이 없다. 직접 승하차 대상 역 없음 기준이며 통과 경로 금지 판단이 아니다.':
      'None of the 92 stations in the official September 18, 2026 list belong to this legal line. This does not determine whether through journeys are allowed.',
  '적용일/자료의 시행일: 2026-09-18': 'Announcement effective date: September 18, 2026.',
  '신칸센 제외': 'Shinkansen services are excluded.',
  '고쿠라·하카타 신칸센 환승개찰구 제외':
      'Shinkansen transfer gates at Kokura and Hakata are excluded.',
  '시모노세키 포함 산요본선·산인본선 제외':
      'The Sanyo Main Line (including Shimonoseki) and San-in Main Line are excluded.',
  '역별 전용 단말 사용; 다른회사 단말을 JR역 대상으로 확대하지 않음':
      'Use designated readers. A reader operated by another company does not make a JR station eligible.',
  '동일 카드/단말로 입장·퇴장; 타 승차권 병용 불가':
      'Use the same card or device to enter and exit. Do not combine with other tickets.',
  '비대상역 터치 퇴장 불가': 'You cannot tap out at a station that is not covered.',
  '공식 현행 직접 카드 승차 안내가 모든 신칸센과 시모노세키 포함 山陽本線을 제외한다고 명시한다. 나머지 법정 노선은 별도 매핑 미확정.':
      'The current guide excludes all Shinkansen services and the Sanyo Main Line, including Shimonoseki. Coverage of other legal lines is assessed separately.',
  '西戸崎〜宇美 16역. 전체 대상 92역 중 한 계통.':
      'All 16 stations from Saitozaki to Umi, within the 92-station network.',
  '시전 차량의 하차구 리더에서 터치, 승차 시 터치 불필요. 辛島町 환승은 하차 전 승무원에게 요청. 소아·복지할인/복수인 사전 요청 가능.':
      'Tap the tram reader when getting off, not when boarding. Ask the driver before getting off to transfer at Karashimacho or to request child, welfare or group fares.',
  '전철 두 노선 전선. 2025-02-24 개시. 카드/모바일·데빗/선불 안내, UnionPay 데빗 제외.':
      'Both railway lines from February 24, 2025. Cards and mobile, debit and prepaid payments are described. UnionPay debit is excluded.',
  '적용일/자료의 시행일: 2025-02-24': 'Announcement effective date: February 24, 2025.',
  '공식 시간표·운임 안내가 개찰구에서 1인1매 교통IC를 이용하는 방식을 안내한다. 직접 EMV 승차는 안내하지 않아 미지원 추정. 리프트·매점 결제와 구분.':
      'The official timetable and fare guide lists one transit IC card per person at the gate. Lift and shop payments do not establish tap-to-ride.',
  '공식 FAQ는 교통IC 승차를 안내하며 신용카드는 정기권 구입에 한정한다고 설명한다. 직접 EMV 승차 미지원 추정.':
      'The FAQ lists transit IC travel and limits credit cards to commuter-pass purchases.',
  '공식 전차 승차·지불수단 안내는 현금·승차권·MOBIRY DAYS·교통IC·WAON을 열거하며 EMV는 없다. 직접 EMV 승차 미지원 추정. 버스의 별도 결제 안내와 혼동하지 않음.':
      'The tram guide lists cash, tickets, MOBIRY DAYS, transit IC and WAON, but no direct bank-card boarding. Bus payment instructions are separate.',
  '공식 양 노선 승하차 안내는 승차권·정리권을 받고 역무원/운전사에게 운임을 내는 절차를 안내한다. 직접 EMV 승차는 없어 미지원 추정.':
      'Both lines’ boarding guides explain tickets, boarding slips and payment to staff or the driver. Direct bank-card boarding is not listed.',
  '藤沢〜鎌倉 전 역. 입출장은 동일 카드/매체; 간토 11개사 공동 계산으로 자동 병합하지 않음.':
      'All stations from Fujisawa to Kamakura. Use the same card or device at entry and exit. Separate fares may apply when transferring to another operator.',
  '2026-08-26 추기가 있는 일반 승차 개정은 현금 정산·디지털 화면 제시표·계속 제공하는 IruCa/전국 교통IC를 설명한다. 직접 EMV는 없어 미지원 추정이다. QR로 표를 사서 보여주는 방식은 직접 터치와 다르다.':
      'The August 26, 2026 update describes cash settlement, showing a digital ticket and using IruCa or nationwide transit IC. Buying or showing a QR ticket is not a direct bank-card tap.',
  '케이블카 탑승 개찰 전용 리더. 2025-04-18 Mastercard 추가, 7브랜드. 리프트도 지원하지만 이번 N02 철도 집계에서는 제외.':
      'Use the designated cable-car reader. Mastercard was added April 18, 2025, bringing the total to seven brands. The lift is separate from this rail listing.',
  '공식 FAQ는 현금/카드/전자화폐/QR의 창구 승차권 구매와 웹 사전구매를 안내한다. 표를 사지 않고 은행카드로 직접 승하차하는 방식은 없어 미지원 추정.':
      'The FAQ lists cash, cards, e-money and QR for counter purchases and advance web purchases. It does not list direct bank-card boarding.',
  '공식 FAQ는 지정 열차 승차권의 온라인 예약/역 창구 현금·카드·교통IC 구매를 안내한다. 직접 EMV 승차는 안내하지 않아 미지원 추정.':
      'The FAQ lists online reservations and cash, cards or transit IC for buying designated train tickets at station counters. Direct bank-card boarding is not listed.',
  '고베고속 포함 전 역. 타사 연결 경로 제한은 별도. G7은 브랜드 FAQ에서 확인.':
      'All stations including the Kobe Kosoku Line. Other operators’ connections may be restricted. The brand FAQ confirms seven brands.',
  '공식 승차 안내 검색 색인은 가능한 지불수단을 현금·교통계 IC카드로 열거한다. 직접 EMV 안내가 없어 미지원 추정이다. 본문 직접 요청은 503이므로 직접 열람과 구분한다.':
      'The official boarding guide’s indexed text lists cash and transit IC but not direct bank-card boarding. The page could not be opened directly.',
  '본선/난바/무코가와/고베고속. 西代 현행 포함, 東鳴尾/洲先 전용 리더.':
      'Main, Namba, Mukogawa and Kobe Kosoku lines. Nishidai is included. Use designated readers at Higashi-Naruo and Susaki.',
  '공식 승차권 FAQ는 표 구매시 현금만 취급한다고 안내하고 PASMO 승차를 별도로 설명한다. 직접 EMV 불가를 명시한 답변은 아니므로 지불수단 안내 기준 미지원 추정.':
      'The FAQ lists cash for ticket purchases and separately explains PASMO boarding. It does not explicitly address bank-card taps; non-support is inferred.',
  '공식 승차권 이용·신용카드 지불 종합 안내는 종이표·교통IC 승차와 大宮역 등 구매용 카드 결제를 구분한다. 직접 EMV 승차는 없어 미지원 추정.':
      'The guide separates paper tickets and transit IC for travel from credit-card purchases at Omiya and other locations.',
  '지하철 3노선 전 49역. 실증 실시 중이며 전용 리더 사용. 스마트폰/웨어러블 안내 있음.':
      'All 49 stations on the three subway lines under the trial. Use designated readers. Phones and wearables are covered by the guide.',
  '적용일/자료의 시행일: 2025-04-26': 'Announcement effective date: April 26, 2025.',
  '일반 운임 페이지의 지불수단은 현금 및 산로쿠역 창구에 한정된 캐시리스 승차권 구매다. 직접 EMV 승차 미지원으로 추정한다. 2025-07 발표의 사전구매 관광패스는 2026-03 이용기한 자료이며, 카드 터치 후에도 승차권을 받아야 한다고 명시하므로 직접 터치 승차 근거로 사용하지 않는다. 새해 첫차의 현금 제한을 일반선 전체로 확대하지 않았다.':
      'The regular fare guide lists cash and cashless ticket purchases only at the Sanroku counter. An older advance sightseeing pass required collecting a ticket after payment; it is not tap-to-ride.',
  '공식 FAQ는 자동개찰기 이용을 교통IC로 한정하고 종이 승차권/ICOCA 사용을 안내한다. EMV 직접 승차는 없어 미지원 추정.':
      'The FAQ lists paper tickets and ICOCA and limits automatic-gate card use to transit IC.',
  '공식 일반열차 승하차 안내는 창구/발권기 표 구매 또는 정리권과 차내 운임함 지불을 열거한다. EMV 직접 승차는 안내하지 않아 미지원 추정. 단체열차 현금 안내만으로 판정하지 않음.':
      'The regular boarding guide lists counter or machine tickets and on-board fare boxes with boarding slips. Direct bank-card boarding is not listed.',
  '일반 승차 가이드는 현금·승차권·정기권 준비와 운임함 정산을 설명한다. 현재 사이트에서 연결하는 첨부자료와 앱 표 구매 안내를 대조해 직접 EMV 미지원으로 추정한다.':
      'The ordinary boarding guide lists cash, tickets, commuter passes and fare-box payment. The linked app sells advance tickets, not direct bank-card boarding.',
  '공식 운임/승차 안내는 현금으로 표 구입·QR·유카리PASS 얼굴인식을 안내한다. 얼굴인식에 등록하는 신용카드는 직접 EMV 터치 승차가 아니므로 미지원 추정.':
      'The guide lists cash tickets, QR and Yukari PASS facial recognition. A bank card registered for facial recognition is not a direct tap at the gate.',
  '본선·아보시선 전 역. 성인 일반운임만. 통과 불가 시 창구/인터폰; 정기권·대체수송과 구분.':
      'All stations on the Main and Aboshi lines. Adult regular fare only. If the gate does not open, use the ticket office or intercom. Commuter passes and substitute transport are separate.',
  '야쿠리 케이블 현행 요금 페이지를 직접 확인했다. 일반 편도·왕복 표는 표시되지만 지불수단 안내는 없어 현금 전용으로 추정하지 않는다.':
      'The current Yakuri Cable fare page lists one-way and round-trip prices but not accepted payment methods. Support remains unverified.',
  '공식 ICOCA 승차·스마트에키 앱의 지불수단 안내와 차내 QR 승차권 구매 공지를 대조했다. 현금·교통IC·사전구매 QR를 안내하며 직접 EMV 승차는 없어 미지원 추정.':
      'The guides list cash, transit IC and prepaid QR tickets, including on-board QR ticket purchases. No direct bank-card boarding is listed.',
  '운임·교통IC·약관 및 시 철도계획을 추가 검색했다. 후보2025 PDF는 안전보고서라 지불수단 근거가 아니며 홈페이지503도 미지원 근거로 삼지 않는다.':
      'Fare, transit IC, conditions and city plans did not establish direct boarding support. A safety report and site access failure are not proof of non-support.',
  '시전 전 차량. Mastercard는 2025-08-01 추가. 버스/전차 환승 할인 자동 적용으로 해석하지 않음.':
      'All tram vehicles. Mastercard was added August 1, 2025. Bus and tram transfer discounts are not automatically included.',
  '2026-03-11 공지의 일반 승차 설명에서 대세가시마선은 현금 취급이라고 명시하고, JR 이용객의 IC 출장을 먼저 정산한 뒤 회사선 표 구매/도착역 정산을 안내한다. 행사 공지에 실렸지만 특별열차 전용 제한이 아니라 통상 노선 승차 안내다. 같은 글의 사전구매 전자표는 직접 EMV가 아니다.':
      'The March 11, 2026 notice says regular Oarai Kashima Line rides are cash based. JR riders must first settle their IC exit, then buy a ticket or settle at the destination. Prepaid digital tickets are separate.',
  '공식 이용 안내는 현금 지불과 교통IC 이용 불가/현금 정산을 안내한다. 직접 EMV 승차는 열거하지 않아 미지원 추정.':
      'The guide describes cash payment and says transit IC is not accepted. It does not list direct bank-card boarding.',
  '2025 경로의 공식 안내서18.9MB를 정상 수신했다. pypdf 텍스트는 비어 있었고 표지·목차2면을 직접 렌더 판독했다. 표지 실제 발행 표기는2024-09이며 내용은 관광/철도문화재/시설과 패스 판매 안내로, 일반 운임 지불수단 안내가 아니다. 단순 가격·행사 현금 문구는 일반 결제 근거로 쓰지 않고 유보한다.':
      'The September 2024 guide covers sightseeing, railway heritage, facilities and pass sales, not regular fare payment. Direct bank-card boarding remains unverified.',
  '전 역. 新御徒町 B3 도에이 환승 개찰·流山おおたかの森 こかげテラス 개찰 제외. 성인 보통운임.':
      'All stations. Toei transfer gates on B3 at Shin-Okachimachi and the Kokage Terrace gate at Nagareyama-Otakanomori are excluded. Adult regular fares apply.',
  '현재 jube 승차법 페이지에서 유인→무인·무인→유인·무인→무인 공식 영상 링크를 구분했으나 영상 본문은 웹 캐시 미수신, 앱내 브라우저2회 시간초과로 보지 못했다. 직원 공식 블로그2010-10-02는 보통표 발매기·정리권·유인역 직원/무인역 운임함 지불을 설명하지만16년 전 내용이라 현재 전체 수단을 증명하지 않는다. 구 운임/승차법·도시락 현금·행사 참가비를 현행 일반선 미지원으로 확대하지 않고 유보한다.':
      'The current site links boarding videos, but their payment details could not be verified. An older staff blog describes paper tickets and on-board cash; it does not establish current coverage.',
  '현재 공식 일반FAQ를 직접 읽었지만 소요시간·경관·궤간 설명뿐이며 지불수단은 없다. 운영사가 연결한2025 세이부 PASMO 캠페인은 케이블 포함 시설에서의 교통IC 결제이며 직접 EMV가 아니다. 글램핑 결제/상품·사전구매 WEB 표 역시 일반 현장 지불수단 전체 안내가 아니어서 확인 필요를 유지한다.':
      'The current FAQ does not list payment methods. A PASMO campaign, glamping payments and advance web tickets do not establish direct bank-card boarding.',
  '3개 노선 전 역. 신주쿠·아쓰기·후지사와 JR 환승 개찰구 제외.':
      'All stations on the three lines. JR transfer gates at Shinjuku, Atsugi and Fujisawa are excluded.',
  '승차·하차 때 전용 단말 사용': 'Use designated readers when entering and exiting.',
  '노란 EMot QR인증BOX와 EMV단말을 구별':
      'Use the bank-card reader, not the yellow EMot QR reader.',
  '공동 대상 외 사업자 경유·넘어 이용 및 다른 승차권 병용 불가':
      'Do not travel via or beyond a non-participating operator or combine this with another ticket.',
  '케이블카 공동 새 운임계산 제외를 터치승차 미지원으로 해석하지 않음':
      'Exclusion from the new joint cable-car fare calculation does not mean tap-to-ride itself is unsupported.',
  '공식 철도 FAQ/일반 승차권 안내 검색 색인에서 구매 위치와 IC 미지원을 확인했으나 본문은503였다. 정기권 카드 구매·QR 전자표·버스 요금표를 일반 철도 직접 EMV 판정으로 확대하지 않는다.':
      'Indexed official guides mention where to buy tickets and that transit IC is not accepted. The full guides could not be checked; commuter passes, QR tickets and bus fare information do not confirm regular rail support.',
  '사세보시 공식 교통 FAQ는 松浦鉄道 지불수단을 현금 또는 전국 교통IC로 열거한다. 직접 EMV 승차는 없어 미지원 추정.':
      'Sasebo City’s FAQ lists cash and nationwide transit IC for Matsuura Railway. Direct bank-card boarding is not listed.',
  '大船〜湘南江の島 전 역. 일반 후불 터치 승차와 Pass Case 사전 구매를 구분. 사전 구매 상품의 Google Pay 제한을 일반 승차 전체에 복사하지 않음. 최초 발표의 Mastercard 후일 추가는 이번에 현행 추가 공지까지 확정하지 못함.':
      'All stations from Ofuna to Shonan-Enoshima. Direct taps are separate from Pass Case advance purchases, so its Google Pay limits do not apply automatically. Later Mastercard support remains unverified.',
  '적용일/자료의 시행일: 2025-02-13': 'Announcement effective date: February 13, 2025.',
  '공식 철도 이용 안내가 현금만 취급하며 Suica/PASMO 등 교통IC는 이용할 수 없다고 설명한다. 직접 EMV 도입 공지 없이 현금 지불 안내 기준 미지원 추정.':
      'The railway guide lists cash only and excludes Suica and PASMO. Direct bank-card support is inferred absent from the published payment methods.',
  '현재 연결된 2024-12 표기 승차 안내 이미지를 직접 확인했다. 전 역을 표 발매기 설치역/미설치역으로 나누고 종이표 QR·TicketQR·현금·정기권 처리를 설명한다. 현금은 정리권과 운임함, 표는 QR 판독/회수이며 은행카드 직접 터치는 안내되지 않아 미지원으로 추정한다. QR 리더를 EMV 단말로 오인하지 않는다.':
      'The December 2024 boarding guide distinguishes stations with and without machines and lists paper ticket QR, TicketQR, cash and commuter passes. A QR reader is not a bank-card reader.',
  '2026년 IC 도입 이후의 시 공식 가이드는 유인·무인역별 종이표/현금·IC/MaaS 정기 승차 절차를 구분한다. 직접 EMV는 없어 미지원 추정이다. 시 교통정책과 운영 사이트임을 연락처 페이지에서 확인했다. 검색 색인 본문이며 직접 요청은 실패했다.':
      'The city’s post-IC-rollout guide lists paper tickets, cash, transit IC and MaaS passes, with different procedures at staffed and unstaffed stations. The indexed guide does not list direct bank-card boarding.',
  '공식 원맨열차 안내는 교통IC 불가와 현금 지불을 안내한다. 디지털 정기권 사전구매와 직접 EMV 승차를 구분해 미지원 추정.':
      'The one-person-train guide lists cash and excludes transit IC. Advance digital commuter passes are not direct bank-card boarding.',
  '현행 일반 운임 페이지의 승차 주의사항은 보통열차와 SL 모두 교통IC 및 신용카드를 사용할 수 없다고 명시한다. SL 전용 문구만 확인했던 이전 유보와 달리 보통열차 적용 범위도 직접 확인했다. 온라인 상품의 카드 구매와 직접 승차는 별개다.':
      'The current fare guide explicitly excludes transit IC and credit cards on regular and steam trains. Online product purchases are separate.',
  '시영 지하철 전 역, 개찰구별 1레인. 신테쓰 연결은 별도 10역만 가능.':
      'All municipal subway stations, with one lane per gate. Connections with Shintetsu cover only ten stations separately.',
  'ポートアイランド線 전 역의 직접 터치 승차 시행. 2024 공동 발표의 브랜드는 당시 6개이며 현행 Mastercard 목록은 추가 확인.':
      'Direct taps are accepted at all Port Island Line stations. The 2024 announcement listed six brands; current Mastercard support needs separate confirmation.',
  '六甲アイランド線 전 역. 성인 일반운임, 어린이·할인·정기권 설정 없음.':
      'All Rokko Island Line stations. Adult regular fare only, with no child, discounted or commuter-pass settings.',
  '적용일/자료의 시행일: 2025-04-01': 'Announcement effective date: April 1, 2025.',
  '역 창구 전용 리더로 승하차 처리':
      'Use the dedicated reader at the station counter to enter and exit.',
  '일부역 직원 부재 시간에는 이용 불가':
      'Service is unavailable when staff are absent at some stations.',
  '대응 타사선과 이용 가능하나 타사 대상 범위는 별도':
      'Travel with participating operators is possible, but their eligible stations are listed separately.',
  '비대상역 하차는 현금 등 정산 및 출발 사업자에서 입장기록 취소 필요':
      'If you exit at an ineligible station, settle in cash or another accepted method and ask the entry operator to clear the entry record.',
  '성인 운임만·다른 승차권과 병용 불가':
      'Adult regular fares only. Do not combine with other tickets.',
  '신카이치 타사 단말을 신테쓰 단말로 자동 포함하지 않음':
      'Other operators’ readers at Shinkaichi are not Shintetsu readers.',
  '현재 이용 안내에서 연결한 PDF를 렌더링해 직접 확인했다. 중간 무인역·양 끝 유인역·출근시간 예외를 포함해 PiTaPa 계열, 현금, 회수권, 정기권별 승하차/운임함 처리를 안내하여 EMV 직접 승차 미지원으로 추정한다. 문서 작성일은 미표기이고 일부 구형 자기카드 경고가 남아 있어 명시적 현행 부인으로 승격하지 않는다.':
      'The published guide covers PiTaPa, cash, multi-ride tickets and commuter passes, with separate procedures at staffed and unstaffed stations and at peak times. Direct bank-card boarding is not listed; the undated guide is not an explicit current ban.',
  '공식 승차권 안내는 종이표와 차내 운임함 정산을 안내한다. 직접 EMV 승차는 안내하지 않아 미지원 추정.':
      'The official ticket guide describes paper tickets and on-board fare boxes, not direct bank-card boarding.',
  '4개 노선 전 역. 薬院/大橋/雑餉隈/桜並木/下大利 북구, 津古/三沢/大保 서구, 久留米 북구, 太宰府 동구 미설치. 筑紫 EV구 인터폰 문의.':
      'All stations on the four lines. Readers are unavailable at the north entrances of Yakuin, Ohashi, Zasshonokuma, Sakuranamiki and Shimo-Ori; west entrances of Tsuko, Misawa and Oho; Kurume’s north entrance; and Dazaifu’s east entrance. Use the intercom at Chikushi’s elevator entrance.',
  'JR서일본 공식 회사 공통 승차 가이드는 보통권·ICOCA 및 특급/신칸센 승차권을 구입한 뒤 개찰하는 방법을 열거한다. 은행카드 자체로 직접 승차하는 EMV는 없어 미지원 추정. 특정 열차 예약 결제·교통IC 연동과 구분.':
      'JR West’s guide lists regular tickets, ICOCA and limited express or Shinkansen tickets. Booking or linking a transit IC card is not direct bank-card boarding.',
  '2026-06-24 錦川鉄道 공식 이용 안내가 JR岩徳線의 IC·신용카드 불가를 별도로 명시한다. JR서일본 일반 지불수단 안내에 따른 추정보다 우선.':
      'Nishikigawa Railway’s June 24, 2026 guide explicitly excludes transit IC and credit cards on the JR Gantoku Line.',
  '현행 본문 제외 13역 외 전 역. 일부 역 개찰구 제한은 원문 확인. 2027년 전역 확대 예고를 현재 상태에 섞지 않음.':
      'All stations except the 13 excluded in the current guide. Check gate exceptions there. The announced 2027 expansion is not yet included.',
  '동일 카드/단말로 입장·퇴장': 'Use the same card or device at entry and exit.',
  '대상역이라도 미설치 개찰구 존재': 'Some gates at eligible stations do not have a reader.',
  '상호이용 비대상 사업자를 경유/넘어 이용 불가':
      'You cannot travel via or beyond a non-participating operator.',
  '다른 승차권·정기권과 조합 불가': 'Do not combine with other tickets or commuter passes.',
  '지갑 등록/발급사별 호환은 별도':
      'Check wallet setup and issuer compatibility separately.',
  '공식 제외 목록에 다마가와선 6역 모두 포함. 현행 직접 터치 승차 불가.':
      'All six Tamagawa Line stations are on the current exclusion list.',
  '공식 일반 승차 안내는 정리권·승차권·운임함·잔돈 준비를 설명한다. 2026-03-14 역 안내는 신용카드를 창구의 정기권·회수권 구매로 한정한다. 두 안내를 대조해 직접 EMV는 미지원 추정이며 단순 IC 미지원 때문이 아니다.':
      'The ordinary guide lists boarding slips, tickets, fare boxes and change. The March 14, 2026 station guide limits credit cards to commuter and multi-ride passes at counters. This is an inference, not a finding based only on transit IC.',
  '지정5역 자동개찰기 전용 단말 사용':
      'Use the designated automatic gates at the five eligible stations.',
  '비대상역 하차는 현금 정산': 'Settle in cash if you exit at an ineligible station.',
  '공식 FAQ가 사용 가능한 교통IC 11종과 종이 승차권 이용을 안내한다. 별도 EMV 직접 승차는 안내하지 않아 미지원 추정.':
      'The FAQ lists 11 transit IC cards and paper tickets but not direct bank-card boarding.',
  '도자이선 13역 14개 유인 개찰. 仙台는 동/서 개찰만, 북/남/센세키 환승 개찰 제외. 난보쿠선 환승 불가.':
      'The Tozai Line has 14 staffed gates across 13 stations. At Sendai, use the east or west gate, not the north, south or Senseki transfer gate. Namboku Line transfers are not covered.',
  '적용일/자료의 시행일: 2026-03-17': 'Announcement effective date: March 17, 2026.',
  '현행 공식 안내는 도자이선만 대상이며 난보쿠선 환승 불가를 명시.':
      'Only the Tozai Line is covered; transfers to the Namboku Line are excluded.',
  '공식 FAQ는 현금·교통IC 승차와 카드 정기권 구매 미취급을 설명한다. 모바일 PASMO에 연결한 카드 결제와 EMV 직접 승차를 구분해 미지원 추정.':
      'The FAQ lists cash and transit IC and says credit cards are not accepted for commuter-pass purchases. Linking a card to mobile PASMO is not direct bank-card boarding.',
  '3개 노선 전 역 창구 포함. 개찰 기기 방식은 역별 다름. 横浜五番街/天王町YBP/かしわ台東口/海老名北口/ゆめが丘ソラトス 개찰 불가. 大和 환승 전용 리더 필수.':
      'All stations on the three lines, including ticket counters. Gate equipment varies. The Yokohama Gobangai, Tennōchō YBP, Kashiwadai east, Ebina north and Yumegaoka Soratos gates are excluded. Use the dedicated transfer reader at Yamato.',
  '메뉴 페이지 유지보수와 달리 공개 약관의 실제 링크 260314_Passenger_business_rules.pdf는 웹 도구에서 본문을 확보했다. 제2조 적용 범위, 제4조 현금 선불·공통이용 IC·정기권용 인정 수표, 제5·12조 증표 발행/소지를 대조해 미지원 추정한다. 후불 예외 조항이 있어 명시적 거부로 해석하지 않는다. 별도 진입/터치 서비스 도입 근거는 확보하지 못했다.':
      'The published conditions list cash in advance, compatible transit IC, authorized checks for commuter passes and ticket issuance. Exceptions exist; the rules do not constitute an explicit ban on direct taps.',
  '실제 공식 도메인 daitetsu.jp의 현행 2026-07-01 전환 안내를 확보했다. 관광상품 온라인 카드/PayPay 및 현장 현금(센즈 창구 카드 예외)은 있으나, 원문 하단에는 402·405열차의 일반차량(센즈~셋소쿄온센, 예약 불필요·일반운임) 예외가 따로 있다. 관광상품 결제 안내가 일반차량 지불수단 전체를 규정하는지 불명확하므로 전선 미지원으로 확대하지 않고 확인 필요 유지한다. 요약 \'전 열차 예약제\'만으로 일반차량 예외를 지우지 않는다.':
      'The July 1, 2026 notice describes card or PayPay for sightseeing products and cash on site, with a Senzu counter exception. Regular cars on trains 402 and 405 between Senzu and Sessokyo-Onsen do not require reservations. General tap-to-ride support remains unverified.',
  '공식 원맨전차 운임 지불 FAQ는 정리권·운임함 및 유인역 현금 정산을 안내한다. 직접 EMV는 없어 미지원 추정. SL/관광열차의 카드 사전구매와 구분.':
      'The regular tram FAQ lists boarding slips, fare boxes and cash at staffed stations. Advance card purchases for steam or sightseeing trains are separate.',
  '본선·彩都線 전 역. 청색 대응 개찰기/전용 리더를 이용. 현재 페이지는 Mastercard 포함 7브랜드. 과거 2024 도입 발표의 Mastercard 추가 예정 문구와 구분.':
      'All Main and Saito Line stations. Use the blue designated gates or readers. The current guide lists seven brands including Mastercard.',
  '지하철 8개 노선과 뉴트램. 타사 직통 구간은 별도.':
      'Eight subway lines and the New Tram. Through services on other operators’ tracks are separate.',
  '공식 운임 안내는 개찰 터치 탑승에 EMot·대응 신용카드만 사용 가능하며 교통 IC는 창구 구매용이라고 구분. 중간 大山寺 이용/운영시간은 현행 원문 확인.':
      'Use EMot or an eligible bank card at the gate. Transit IC can be used to buy tickets at the counter. Check the current guide for Oyama-dera and operating hours.',
  '공식 운임·승차권 안내는 종이 승차권 또는 차내 운임 지불과 교통IC 이용 불가를 안내한다. EMV 직접 승차 도입은 없어 미지원 추정.':
      'The official guide lists paper tickets or on-board fare payment and says transit IC is not accepted. No direct bank-card rollout was confirmed.',
  '케이블 전용 현행 원문 HTML에서 후추역 창구/발매기 승차권 구입, 취급 카드·전자머니와 가사마쓰역 캐시리스 미대응을 확인했다. 같은 시설 FAQ는 카드·교통IC를 \'티켓 구매\' 수단으로 열거한다. 이 일반 구매/지불 안내를 근거로 직접 EMV 승차 미지원으로 추정한다. 상부역 제한을 전선의 명시적 카드 불가로 확대하지 않고 2026년 버스 터치결제 도입도 케이블 지원으로 옮기지 않는다.':
      'The cable-car guide lists ticket purchases at Fuchu and says Kasamatsu does not accept cashless payments. Cards and transit IC are listed for purchases, not boarding. The 2026 bus rollout does not apply to the cable car.',
  '공식 FAQ는 카드·전자화폐를 직영역 창구에서 승차권/상품을 구매하는 수단으로 상세히 열거한다. 직접 EMV 승차는 안내하지 않아 미지원 추정.':
      'The FAQ lists cards and e-money for buying tickets or products at directly operated station counters, not direct boarding.',
  '현재 홈페이지와 케이블 요금 페이지를 확인했다. 가격만 제시돼 결제 목록을 확보하지 못했다. 제3자 글의 2026-09 운휴 주장은 현재 홈페이지의 통상운행과 다르므로 현재 상태 근거에서도 제외한다.':
      'The current website and fare page list prices but not payment methods. Direct boarding remains unverified; an unrelated suspension claim was not used.',
  '공식 승차 안내가 현금 및 nimoca 등 교통IC 두 방식으로 구분한다. 은행카드 EMV 직접 승차는 안내하지 않아 미지원 추정.':
      'The boarding guide lists cash and transit IC such as nimoca, not direct bank-card boarding.',
  '공식 일반열차 이용 가이드는 현금으로 종이표를 구입해 제시하거나 PASMO/Suica를 개찰기에 터치하는 방식을 열거한다. 직접 EMV는 없어 미지원 추정. SL 사전 예약 결제와 구분.':
      'The ordinary train guide lists cash paper tickets or PASMO and Suica taps. Advance steam-train bookings are separate.',
  '운송약관과 일반 승차 지불수단을 추가 검색했다. 표 가격/종류·온라인 상품 이외의 일반 현장 결제 범위가 아직 부족해 미지원으로 변경하지 않는다.':
      'The published terms, ticket prices and online products do not establish which payment methods are accepted for regular boarding.',
  '노면전차 전선 2025-10-01 시행. 회사 공동 발표의 EMV 7브랜드와 사전구매 Pass Case 상품의 브랜드 조건은 별개. 할인·상한의 실증기간은 승차 지원과 따로 재확인.':
      'All tram lines from October 1, 2025. Seven brands were announced for direct taps, separately from Pass Case purchases. Trial discounts and caps may have different dates.',
  '적용일/자료의 시행일: 2025-10-01': 'Announcement effective date: October 1, 2025.',
  '현행 공식 승차권 종합 안내는 카드·QR·전자화폐를 자동발권기의 표 구매 수단으로 열거한다. 카드 자체로 승하차하는 EMV와 구분해 미지원 추정.':
      'The current guide lists cards, QR and e-money for ticket-machine purchases, not direct boarding.',
  '越美南線 일반 원맨 열차 전선 안내. 승차·하차 시 운전석 옆 전용 단말에 각각 터치. 관광열차 예약/추가요금 지원을 뜻하지 않음. 확인 브랜드는 확인된 일부이며 나머지 국제 브랜드를 추정하지 않음.':
      'Regular one-person trains across the Etsumi-Nan Line. Tap the dedicated reader near the driver when boarding and exiting. Tourist bookings and surcharges are separate. Only verified brands are listed.',
  '동북관광추진기구의 일반 철도 교통 안내 본문형 검색 색인 답변에서 대상 통년·津軽鉄道線·세 유인역/차장/원맨 차내 정산과 현금만의 구매 방법을 확인했다. 최신 운영사 스토브 안내의 신용카드/전자화폐 불가는 특별열차 전용이므로 단독 일반화하지 않는다. 일반 안내의 갱신일이 없고 스토브 구요금도 남아 있어 최신 명시적 미지원이 아니라 지불수단 안내 기준 추정으로만 채택한다. 원 URL 직접 열기는503이었다.':
      'The regional tourism guide describes cash purchases at three staffed stations and fare payment to conductors or on board. The operator’s stove-train restriction does not establish current rules for all regular trains; non-support is inferred.',
  '역 승차권 구매 및 차내 운임 정산은 현금만 가능하다는 일반 승차 안내를 확인했다. 앱 승차권 사전 구매는 직접 EMV 승차와 다르다.':
      'The regular boarding guide says station ticket purchases and on-board settlement are cash only. Advance app tickets are separate.',
  '현재 회사 일반 승차 페이지와 이미지 안내를 함께 확인했다. 고멘나하리/나카무라·스쿠모 구간의 정리권·운임함·종이표/패스 제시, 특급 환승 시 표 구매·정산, 스마트폰 사전구매 표 제시를 안내한다. 한 노선의 단순 운임표나 정기권 구매만이 아니라 일반 승차 흐름을 확인해 세 법정 노선의 EMV 직접 승차 미지원으로 추정한다. 현장 확인이나 운영사의 명시적 EMV 부인은 아니다.':
      'The regular boarding guide lists slips, fare boxes, paper tickets, passes and advance digital tickets on the Gomen-Nahari, Nakamura and Sukumo lines. Limited express transfers require separate tickets or settlement. Direct bank-card non-support is inferred, not explicit.',
  '일본어 일반 승차 안내는 여전히2026-10-22 보안 점검으로 중단되어 우회하지 않았다. 별도 공식 번체중문 railway/way 검색 색인에서 현금·표·회수권을 운임함에 넣는 일반 승하차 절차를 확보했다. 다만 같은 번역 사이트 버스 안내에는2020 종료 스마트카드가 남아 있어 번역 갱신 시점을 인증할 수 없다. 따라서 현재 철도 미지원으로 변경하지 않고 재개/최신 근거 대기를 유지한다.':
      'The Japanese guide was unavailable. The indexed Chinese guide lists cash, tickets and multi-ride tickets, but its update date is uncertain. Current direct support remains unverified.',
  '공식 승차 안내는 종이표·TOICA와 사전 예약한 신칸센의 등록 교통IC/EX-IC/QR 이용을 안내한다. 신용카드의 예약 결제와 직접 EMV 승차를 구분해 미지원 추정.':
      'The guide lists paper tickets and TOICA, plus registered transit IC, EX-IC or QR for reserved Shinkansen rides. Paying by card for a reservation is not direct boarding.',
  '9개 노선 전 역. 세타가야선은 공동 후불 운임계산 별도 취급.':
      'All stations on nine lines. The Setagaya Line is handled separately for joint postpaid fares.',
  '공식 FAQ는 종이표/교통IC 승차 및 현금·IC잔액의 표 구매를 안내하고 신용카드는 일부 정기권 구매에만 허용한다. EMV 직접 승차 미지원 추정.':
      'The FAQ lists paper tickets and transit IC, with tickets bought using cash or an IC balance. Credit cards are limited to some commuter passes.',
  '전 노선 기본 지원. 도자이선 나카노 승차 제외; 하차는 창구. 타사 미지원 구역/환승 개찰구 주의.':
      'All lines are generally covered. At Nakano on the Tozai Line, tap-in is not available; ask station staff when exiting. Check other operators and transfer gates.',
  '지하철 4개 노선만 확인. 모든 타사 연결 경로를 보장하지 않음.':
      'Only the four subway lines are confirmed. Connections on other operators are not guaranteed.',
  '대상은 도덴 아라카와선·닛포리 토네리 라이너뿐이다. 각 노선의 공식 운임/승차권·교통IC 안내와 도에이 지하철 한정 EMV 서비스 범위를 대조해 직접 EMV 미지원 추정. 지하철 4개 노선의 지원 상태는 변경하지 않음.':
      'This assessment applies only to the Toden Arakawa Line and Nippori-Toneri Liner. Their fare and transit IC guides were checked against the subway-only rollout; the four subway lines are assessed separately.',
  '공식 운임·보통권/정기권 안내는 종이표·교통IC 승차와 일부 카드 구매를 구분한다. 직접 EMV 승차는 안내하지 않아 미지원 추정.':
      'The official guide distinguishes paper tickets and transit IC travel from card purchases of some tickets. Direct bank-card boarding is not listed.',
  '공식 FAQ3954가 신용카드 터치 결제 미대응을 명시. 본문 HTTP/웹 조회 시간 초과로 공식 검색 색인 답변을 대조한 근거이며 전체 본문 재접속 필요. 예약용 IC 태그/모바일 Suica와 구분.':
      'Official FAQ 3954 states that bank-card tap payment is not supported. The indexed answer was available, but the full page could not be reopened. Reserved IC tags and mobile Suica are separate.',
  '입장/퇴장 모두 대상역이어야 함': 'Both entry and exit stations must be eligible.',
  '동일 단말로 입장·퇴장': 'Use the same card or device to enter and exit.',
  '역별 개찰구마다 대응1통로 안내': 'The operator lists one designated lane per gate.',
  '신타카토쿠·도부월드스퀘어는 창구 부근 단말':
      'At Shin-Takatoku and Tobu World Square, use the reader near the counter.',
  '접속역 한정 지원을 지선 내 여행 지원으로 확대하지 않음':
      'A covered connecting station does not make rides within a branch eligible.',
  '공식77역 집계와 공유 오시아게 접속점 포함 명명 목록을 구분;78항목을 도부 소유역78개로 표현하지 않음':
      'The operator lists 77 stations. The named list also includes the shared Oshiage connection; that does not make it 78 Tobu-owned stations.',
  '공동 대상 외 사업자 경유/넘어 이용 및 다른 승차권 병용 불가':
      'Do not travel via or beyond non-participating operators or combine this with other tickets.',
  '우쓰노미야선 기점 新栃木는 대상인 栃木와 다른 역이며 대상 역 목록에 없다. 대상 외 승하차 불가라는 공식 조건을 적용한다.':
      'Shin-Tochigi, the Utsunomiya Line terminus, is not the same station as eligible Tochigi and is not on the list.',
  '현재 일반 안내가 연결하는 2025-04-01 약관 제4조의 현금·SF카드·인정 증서 지불 및 제5조 승차권 교부, 현행 교통IC 안내와 도입 검색을 함께 대조했다. 표 종류 목록만 보았던 이전 검토와 달리 실제 운임 지불 규정을 확인하여 EMV 직접 승차 미지원으로 추정한다. 예외 허용 조항이 있으므로 명시적 부인은 아니다.':
      'The April 1, 2025 terms list cash, stored-fare cards, authorized documents and ticket issuance. Together with current transit IC guidance, these support an inference of non-support, not an explicit ban.',
  '공식 FAQ와 2024년 이후 발권기 안내를 대조했다. 현금·카드·코드·전자화폐는 표 구매 수단이며 승차는 표/정리권으로 안내한다. 직접 EMV 승차는 없어 미지원 추정.':
      'The FAQ and ticket machine guide list cash, card, code and e-money purchases. Boarding uses a ticket or boarding slip, not a direct bank-card tap.',
  '高森線 立野〜高森 전 역의 일반 열차. JR규슈 직통 열차는 南鉄 구간도 제외. 관광 토롯코 제외. 최초 발표의 Mastercard 추가 예정은 현행 여부 재확인 필요.':
      'Regular trains at all Takamori Line stations from Tateno to Takamori. JR Kyushu through trains and tourist trolley trains are excluded, including on Minamiaso tracks. Later Mastercard support remains unverified.',
  '적용일/자료의 시행일: 2025-01-20': 'Announcement effective date: January 20, 2025.',
  '현재 공식 지도 노란 점 대상. 타사·개찰 조건 별도. 2026-03 발표의 97/105역 수를 현재 자동 통계로 재사용하지 않음.':
      'Use the stations marked with yellow dots on the current official map. Other operators and gates have separate rules. Older 97/105 station counts are not used as current totals.',
  '대상역 전용 개찰기를 입장·퇴장 모두 사용':
      'Use designated gates at eligible stations for both entry and exit.',
  '비대상역에서 터치 입장/퇴장 불가': 'Do not tap in or out at an ineligible station.',
  '동일 카드/단말 사용·성인 운임만': 'Use the same card or device. Adult fares only.',
  '지도 노란 점/흰 점을 구별; 회사 총 역수는 재추정하지 않음':
      'Use the current map to distinguish yellow and white markers; no company-wide count is inferred.',
  '두 노선 전 역. 카드/스마트폰 전용 개찰기. 통과 불가 시 인터폰 문의. 브랜드 이미지의 개별 목록은 후속 대조.':
      'All stations on both lines. Use gates for cards or smartphones. If the gate does not open, use the intercom. The full brand list has not been verified.',
  '시영전차 공식 종합 승차 안내는 현금·교통IC 사용을 구분한다. EMV 직접 승차는 안내하지 않아 미지원 추정. 별도 버스 서비스와 구분.':
      'The municipal tram guide lists cash and transit IC, not direct bank-card boarding. Bus services are separate.',
  '현행 일반 서비스에서 캐시리스는 굿즈 판매와 별도 제목이며 사카모토역 결제 목록임을 재확인했다. 운임 안내의 당일 승차권 창구 구입·사전구매 티켓 링크도 대조했지만 일반 상하행 전체의 표 수령/직접 검표 관계는 불명이다. 현행2026 요금으로 안내되나 한 역의 결제 목록을 전선 직접 EMV 부재로 확대하지 않고 유보한다.':
      'The payment guide lists cashless payment at Sakamoto Station and distinguishes ticket purchases from merchandise. It does not explain direct gate use across both directions; current support remains unverified.',
  '2025-01-22 창구 단말은 표 구매용이고 승하차 개찰용이 아님을 명시한다. 무인역·발매기·차내에서는 사용할 수 없다. 일반 승차 안내와 대조해 직접 EMV는 미지원 추정으로 분류한다.':
      'The January 22, 2025 notice says the counter reader is for ticket purchases, not gates. It is unavailable at unstaffed stations, ticket machines and on board. Direct support is inferred absent.',
  '단말 구매 제한을 회사 전체의 명시적 EMV 부인으로 과장하지 않는다.':
      'The limitation on purchasing terminals is not an explicit company-wide ban on bank-card boarding.',
  '공식 종합 승차 안내는 철도는 현금·종이표·에코마이카, 시내전차는 현금·일일권·에코마이카·전국 교통IC로 각각 나누어 설명한다. 직접 EMV는 없어 미지원 추정. 버스나 철도만의 제한을 전 노선에 확대하지 않음.':
      'The rail guide lists cash, paper tickets and ecomyca; city trams also list day passes and nationwide transit IC. Neither lists direct bank-card boarding. Bus conditions are separate.',
  '2026-03-14 현행 일반 창구 안내의 카드 \'구매\'·종이표 회수함·무배치 시간 차장 검표와, 현행 일반 Suica/종이표 입출장·잔액부족 정산 안내를 새로 확보했다. 2015 회사 발표는 보통승차권까지 창구 카드 구매 대상임을 확인하는 보조 근거다. 이 일반 구매/검표 절차와 현행 도입 공지를 대조해 오쓰키·가와구치코 양선을 직접 EMV 미지원으로 추정한다. Suica 페이지 일부 창구 시각은 구형이고2026 창구 안내를 우선하며, 오래된 구매 공지만으로 판단하지 않았다. 2026 시모요시다 터치결제는 굿즈 판매기, 특급 WEB결제는 별도 일반 승차권이 필요한 사전구매여서 직접 EMV 근거에서 제외한다. 명시적 불가 확정이 아니다.':
      'Current counter, Suica and paper-ticket instructions describe card purchases, entry, exit and fare adjustment. Direct boarding on the Otsuki and Kawaguchiko lines is not listed. Shimoyoshida merchandise payments and advance limited express purchases do not count.',
  '리조트라인 공식 운임·승차권 안내는 자동판매기 표 구매와 전국 교통IC 승차를 열거하며 신용카드는 승차권센터 구매에 이용한다고 구분한다. 직접 EMV 승차는 없어 미지원 추정. 테마파크 매장의 카드 터치와 분리.':
      'The Resort Line guide lists machine-issued tickets and nationwide transit IC, with credit cards for purchases at the ticket centre. Theme park shop payments are separate.',
  '공식 전차 이용 안내는 종이표·현금·교통IC 승차와 창구/발권기 카드·QR 구매를 구분한다. EMV 직접 승차는 안내하지 않아 미지원 추정.':
      'The tram guide distinguishes paper tickets, cash and transit IC boarding from card or QR purchases at machines and counters.',
  '지하철 3개 노선 36역. JR 지쿠히선 직통 제외. Mastercard 추가 2024-10-17.':
      'All 36 stations on the three subway lines. JR Chikuhi Line through services are excluded. Mastercard was added October 17, 2024.',
  '飯坂線 전 12역 대상 공식 도입 발표. 카드 회사 2026-09 현행 철도 목록에도 등재. 발표 당시 6브랜드, 현행 Mastercard 여부 미확정.':
      'The announcement covers all 12 Iizaka Line stations. The September 2026 card company list still includes the line. Six brands were announced; current Mastercard support is unverified.',
  '일반 3개 노선의 공식 승차 안내는 표·정리권·차내 운임 지불을 안내한다. 별도 모지코 관광선은 공식 공지가 카드/교통IC를 표 구매 수단으로 설명한다. 두 계통 모두 직접 EMV 승차는 없어 미지원 추정하되 자료 적용은 분리한다.':
      'The three regular lines list tickets, boarding slips and on-board fare payment. The separate Mojiko sightseeing line accepts card or transit IC for ticket purchase. Neither lists direct bank-card boarding.',
  '공식 FAQ는 渥美線/市内線 전국 교통IC 사용과 신용카드로 구매 가능한 정기권을 별도로 설명한다. 직접 EMV 승차는 없어 미지원 추정.':
      'The FAQ lists nationwide transit IC on the Atsumi Line and city tram, and separately lists credit card purchases for commuter passes.',
  '공식 발권기·승차 안내는 현금/카드삽입/코드결제로 표를 구매하는 절차와 표가 없을 때 차내 정산을 안내한다. 직접 EMV 승차와 구분해 미지원 추정.':
      'The guide lists cash, card insertion or code payments to buy tickets, and on-board settlement when you do not have a ticket. These are not direct taps.',
  '공식 회사 공통 지불수단 FAQ는 창구 카드 구매와 PIN 입력을 안내한다. 교통IC/표 이용 및 원맨 현금 정산 안내와 대조해 직접 EMV 승차 미지원 추정. 신칸센 예약연동 IC 승차는 EMV가 아님.':
      'The FAQ lists credit card purchases and PIN entry at ticket counters, as well as transit IC, tickets and on-board cash payment. Shinkansen bookings linked to transit IC are separate.',
  '공식 FAQ·IC 안내는 종이/QR 표와 mono SUGOCA·전국 교통IC 승차 및 신용카드 정기권 구매를 구분한다. 직접 EMV는 없어 미지원 추정. 공식 검색 색인 본문 확인이며 직접 사이트는 HTTP 500.':
      'The indexed FAQ lists paper and QR tickets, mono SUGOCA and nationwide transit IC. Credit cards are listed for commuter-pass purchases. Direct boarding is not listed; the original page could not be opened.',
  '가사이시 교통 안내는 北条鉄道 지불수단을 현금·종이표·정기권 및 전국 교통IC로 구분한다. 직접 EMV 승차는 없어 미지원 추정.':
      'Kasai City’s guide lists cash, paper tickets, commuter passes and nationwide transit IC for Hojo Railway. Direct bank-card boarding is not listed.',
  '공식 종합 이용 안내는 종이표·PASMO/Suica 승차와 정기권 카드 구매를 구분하며 일반표 카드 구매는 제외한다고 설명한다. 직접 EMV 승차는 없어 미지원 추정.':
      'The guide lists paper tickets and PASMO or Suica boarding. Credit cards are accepted for commuter passes, not ordinary tickets. Direct bank-card boarding is not listed.',
  '전 역 개찰 대응. Mastercard는 2025-03-04부터. 성인 일반운임만.':
      'All stations. Mastercard has been accepted since March 4, 2025. Adult regular fares only.',
  '철도 石川線·浅野川線. 무인역 승차 홈 리더, 하차 차량 전방 리더 사용. 소아/복지할인·복수인 특별 처리 제한: 승무원 동승 시, 割出 유인 시간, 野々市工大前 직원 배치 시.':
      'On the Ishikawa and Asanogawa lines, use the platform reader to enter an unstaffed station and the front-of-train reader to exit. Ask staff about child, welfare or group fares; handling is limited to staffed situations at Waridashi, Nonoichi-Kodaimae or on board.',
  '공식 안내는 전국 교통IC와 종이표/현금 이용을 설명하고 다른 IC 사용을 제외한다. 직접 EMV 승차는 안내하지 않아 미지원 추정. 교통IC 외 다른 IC 불가 문구를 EMV 명시 불가로 과장하지 않음.':
      'The official guide lists nationwide transit IC, paper tickets and cash. Other transit cards being excluded is not an explicit ban on bank-card taps.',
  '시의 가이드웨이 버스 전용 일반 승하차 FAQ는 승차·하차 모두 현금/정리권과 manaca 처리 방법을 안내한다. 2024-04-01 갱신 안내를 현재 공개본으로 확인하고 2026년 도입 자료를 대조해 EMV 직접 승차 미지원으로 추정한다. 나고야 지하철·긴테쓰의 터치 도입을 가이드웨이로 확대하지 않는다.':
      'The guideway bus FAQ lists cash with boarding slips and manaca for entry and exit. Direct bank-card boarding is not listed. Subway and Kintetsu rollouts are separate.',
  '지하철 전 역, 2026-09-03 개시. 미개조 개찰구는 직원 창구 처리. 東海通南/六番町南/東別院南/妙音通中/黒川西/志賀本通東西/平安通南/築地口中 등 개조 일정은 현행 안내 우선.':
      'All subway stations since September 3, 2026. Use staff counters at gates not yet upgraded. Check the current operator guide for gate-by-gate upgrades.',
  '적용일/자료의 시행일: 2026-09-03': 'Announcement effective date: September 3, 2026.',
  '현행 howto의 16역과 대상 8개 법정 노선의 N02 역 목록 교집합이 없다. 공식 대상 외 사용 불가 조건에 따른 직접 승하차 미지원이다.':
      'None of the 16 stations on the current official list are on these eight legal lines. Direct entry and exit are not available at unlisted stations.',
  '구형 FAQ의 13역 대신 16역 안내를 우선한다. 해당 선로를 포함하는 통과 여행의 허용/불허를 뜻하지 않는다.':
      'The current 16-station guide supersedes the older 13-station FAQ. It does not establish whether a particular through journey is allowed.',
  '대상역의 지정 개찰구만 사용': 'Use designated gates at eligible stations only.',
  '나고야시 지하철과 상호 이용 안내; 타사 대상/개찰 조건은 별도':
      'The guide describes transfers with Nagoya Municipal Subway. Other operators and gates have separate conditions.',
  'QR승차의 다른 역 목록을 EMV에 혼합하지 않음':
      'The QR ticket station list is separate from bank-card coverage.',
  '공식 FAQ의 지불수단 질문에 신용카드를 이용할 수 없으므로 현금으로 지불하라고 명시한다. 교통IC 승차는 별도 지원.':
      'The FAQ explicitly says credit cards are not accepted and to pay in cash. Transit IC is supported separately.',
  '공식 FAQ가 IC·전자화폐·신용/체크카드 등 현금 외 지불수단에 대응하지 않는다고 명시한다.':
      'The FAQ explicitly excludes transit IC, e-money, credit and debit cards and other cashless methods.',
  '공식 会津鬼怒川線 승차 안내는 IC·신용카드·전자화폐를 사용할 수 없고 현금만 취급한다고 명시한다.':
      'The Aizu Kinugawa Line guide explicitly says cash only, excluding IC cards, credit cards and e-money.',
  '현행 공개된 일반 승차권 판매3역 안내와 차량 소개의 승차 절차(해당3역 종이표, 무인역 정리권·운임함 정산)를 대조했다. 추가 확보한 2020년羽後本荘 일반 창구 영업 안내는 영업 종료 뒤 통상 열차 정리권/현금 운임함·교통IC/전자화폐 불가를 설명한다. 대절·이탈리안 패키지 결제가 아닌 일반 승하차 절차를 근거로 미지원 추정한다. 2020년 설명을 현재의 명시적 EMV 거부로 취급하지 않는다.':
      'The current guide lists paper tickets at three staffed stations and boarding slips or fare boxes at unstaffed stations. An older Ugo-Honjo notice also describes cash after the counter closes. Non-support is inferred from regular boarding, not charter or meal packages.',
  '공식 승차권 이용 안내는 종이 승차권과 무인역 정리권/차내 정산을 안내한다. 직접 EMV 승차는 안내하지 않아 미지원 추정. QR 승차권 구매와 구분.':
      'The guide lists paper tickets and boarding slips with on-board fare settlement at unstaffed stations. QR ticket purchases are separate.',
  '관계 운영사 간사이전력의 알펜루트 안내는 각 역에서 현금/카드로 표 구매·인도를 설명한다. 운영사 승차 안내와 대조해 立山·黒部 두 케이블의 직접 EMV 미지원으로 추정한다. 카드로 표 구매 가능과 구분한다.':
      'The Alpine Route guide lists cash or card for buying or collecting tickets. That does not confirm direct bank-card boarding on either the Tateyama or Kurobe cable car.',
  '공식 정기권 페이지 검색 색인에 흐름야마선 신용카드 불가 문구를 찾았지만 구매 문맥과 직접 승차 범위가 분명하지 않다. 일반표 페이지는 TLS 접속 오류여서 우회하지 않았고 일반 지불수단 안내를 추가 확보해야 한다.':
      'The indexed commuter pass page mentions a credit card restriction, but its purchase scope is unclear. The ordinary ticket guide could not be opened, so direct boarding remains unverified.',
  '공식 승하차 안내의 지불수단 표는 차내·승차권 창구를 현금으로, 일부 정기권 구매만 바코드 결제로 열거한다. EMV 직접 승차는 없어 미지원 추정.':
      'The boarding guide lists cash on board and at ticket counters; barcode payments apply only to some commuter-pass purchases. Direct bank-card boarding is not listed.',
};
