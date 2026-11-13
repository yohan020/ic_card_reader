import '../../station_resolver/domain/english_station_search.dart';

part 'coin_locker_station_names_en.g.dart';

/// Independently curated external links, not a locker inventory or vacancy feed.
class CoinLockerCatalog {
  CoinLockerCatalog({required this.places});

  factory CoinLockerCatalog.fromJson(Map<String, dynamic> json) {
    if (json['schema'] != 1) {
      throw const FormatException('Unsupported coin locker catalog');
    }
    final places = (json['places'] as List)
        .map((value) => CoinLockerPlace.fromJson(value as Map<String, dynamic>))
        .toList(growable: false);
    final ids = <String>{};
    for (final place in places) {
      // A line/area article can legitimately cover more than one distinct
      // station. Deduplicate within a place, not across unrelated search hits.
      final urls = <String>{};
      if (!ids.add(place.id) || place.sources.isEmpty) {
        throw const FormatException('Duplicate or empty coin locker place');
      }
      var previous = -1;
      for (final source in place.sources) {
        final order = CoinLockerSource.hosts.keys.toList().indexOf(source.id);
        if (order <= previous || source.links.isEmpty) {
          throw const FormatException('Invalid coin locker source order');
        }
        previous = order;
        for (final link in source.links) {
          if (!isAllowedCoinLockerUri(link.uri, sourceId: source.id) ||
              !urls.add(link.uri.toString())) {
            throw const FormatException('Invalid or duplicate external link');
          }
        }
      }
    }
    return CoinLockerCatalog(places: List.unmodifiable(places));
  }

  final List<CoinLockerPlace> places;

  List<String> get regions => places.map((p) => p.region).toSet().toList();

  List<CoinLockerPlace> search(String query, {String? region}) {
    final key = _normalize(query);
    final englishKey = englishStationSearchKey(query);
    if (query.trim().isNotEmpty && key.isEmpty) return const [];
    return places
        .where((place) {
          if (region != null && place.region != region) return false;
          return key.isEmpty ||
              [
                place.nameKo,
                place.nameJa,
                ...place.aliases,
              ].any((name) => _normalize(name).contains(key)) ||
              (englishKey.isNotEmpty &&
                  place.englishSearchNames.any(
                    (name) =>
                        englishStationSearchKey(name).contains(englishKey),
                  ));
        })
        .toList(growable: false);
  }
}

String _normalize(String text) => text
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[\s・·()（）]'), '')
    .replaceFirst(RegExp(r'(역|駅)$'), '');

class CoinLockerPlace {
  const CoinLockerPlace({
    required this.id,
    required this.region,
    required this.nameKo,
    required this.nameJa,
    required this.kind,
    required this.aliases,
    required this.sources,
  });

  factory CoinLockerPlace.fromJson(Map<String, dynamic> json) =>
      CoinLockerPlace(
        id: json['id'] as String,
        region: json['region'] as String,
        nameKo: json['nameKo'] as String,
        nameJa: json['nameJa'] as String,
        kind: json['kind'] as String,
        aliases: List<String>.from(json['aliases'] as List),
        sources: (json['sources'] as List)
            .map(
              (value) =>
                  CoinLockerSource.fromJson(value as Map<String, dynamic>),
            )
            .toList(growable: false),
      );

  final String id;
  final String region;
  final String nameKo;
  final String nameJa;
  final String kind;
  final List<String> aliases;
  final List<CoinLockerSource> sources;

  List<String>? get _englishEntry {
    final entry = _englishPlaceNames[id];
    return entry != null && entry[0] == nameJa ? entry : null;
  }

  String? get nameEn {
    final name = _englishEntry?[1];
    return name == null || name.isEmpty ? null : name;
  }

  Iterable<String> get englishSearchNames =>
      _englishEntry?.skip(1).where((name) => name.isNotEmpty) ?? const [];
}

class CoinLockerSource {
  const CoinLockerSource({required this.id, required this.links});

  factory CoinLockerSource.fromJson(Map<String, dynamic> json) =>
      CoinLockerSource(
        id: json['id'] as String,
        links: (json['links'] as List)
            .map(
              (value) => CoinLockerLink.fromJson(value as Map<String, dynamic>),
            )
            .toList(growable: false),
      );

  static const hosts = {
    'miitsuketa': 'coin-locker.net',
    'shiori': 'coinlocker-shiori.com',
    'guide': 'coinlocker.click',
  };
  static const names = {
    'miitsuketa': '코인락커 미이츠케타',
    'shiori': '코인락커 시오리',
    'guide': '코인락커 가이드',
  };

  final String id;
  final List<CoinLockerLink> links;
  String get name => names[id]!;
  String get englishName => switch (id) {
    'miitsuketa' => 'Coin Locker Miitsuketa',
    'shiori' => 'Coin Locker Shiori',
    'guide' => 'Coin Locker Guide',
    _ => 'Locker guide',
  };
}

class CoinLockerLink {
  const CoinLockerLink({required this.label, required this.uri, this.caution});

  factory CoinLockerLink.fromJson(Map<String, dynamic> json) => CoinLockerLink(
    label: json['label'] as String,
    uri: Uri.parse(json['url'] as String),
    caution: json['caution'] as String?,
  );

  final String label;
  final Uri uri;
  final String? caution;

  String englishLabel(CoinLockerPlace place) {
    final curated = _englishLinkLabels[label];
    if (curated != null) return curated;
    // The source slug identifies the article’s actual scope (e.g. JR vs.
    // subway or a terminal), even when several links share a search hub.
    final slug = uri.pathSegments
        .lastWhere((part) => part.isNotEmpty, orElse: () => '')
        .replaceFirst(RegExp(r'\.(?:php|html)$', caseSensitive: false), '');
    final words = slug.split(RegExp(r'[-_]+')).where((word) => word.isNotEmpty);
    if (!RegExp(r'^[a-z0-9_-]+$', caseSensitive: false).hasMatch(slug)) {
      return place.nameEn ?? 'Locker location guide';
    }
    final title = words
        .map(
          (word) => switch (word.toLowerCase()) {
            'jr' => 'JR',
            'osakametro' => 'Osaka Metro',
            'tokyometro' => 'Tokyo Metro',
            'and' => 'and',
            _ => word[0].toUpperCase() + word.substring(1),
          },
        )
        .join(' ');
    final operator = RegExp(r' · ([^·]+) 안내$').firstMatch(label)?.group(1);
    final qualifier = _englishLinkOperators[operator];
    if (qualifier == null ||
        title.toLowerCase().contains(qualifier.toLowerCase())) {
      return title;
    }
    return '$title · $qualifier';
  }

  String? get englishCaution => caution == null
      ? null
      : _englishCautions[caution] ??
            'Check the guide for its exact scope and current locker information.';
}

const _englishLinkLabels = {
  'JR 도쿄 중심': 'JR Tokyo Station',
  'JR 도쿄 및 관련 보관 안내': 'JR Tokyo Station and nearby storage',
  '시나가와 일대': 'Shinagawa area',
  'JR 시나가와': 'JR Shinagawa Station',
  'JR·게이큐 시나가와': 'JR and Keikyu Shinagawa',
  'JR 시부야': 'JR Shibuya Station',
  'JR·게이오·메트로·도큐 시부야 일대': 'Shibuya area (JR, Keio, Tokyo Metro and Tokyu)',
  'JR 신주쿠': 'JR Shinjuku Station',
  'JR 신주쿠 중심·주변 보관 안내(사철 전역 보장 아님)':
      'JR Shinjuku Station and nearby storage; other operators may not be covered',
  '메트로·도에이·도부·TX 아사쿠사 일대':
      'Asakusa area (Tokyo Metro, Toei, Tobu and Tsukuba Express)',
  '도부·메트로·도에이·TX 아사쿠사(별개 역 포함)':
      'Asakusa area, including the separate Tsukuba Express station',
  '아사쿠사 메트로·도에이 중심(표제 도부 포함·TX 별도)':
      'Asakusa (Tokyo Metro and Toei focus; Tsukuba Express is separate)',
  '도에이 아사쿠사 · 이전 안내': 'Toei Asakusa (older guide)',
  '아키하바라 일대': 'Akihabara area',
  'JR·메트로·TX 아키하바라': 'Akihabara (JR, Tokyo Metro and Tsukuba Express)',
  'JR·메트로·TX 아키하바라·전기상가 주변': 'Akihabara stations and the electronics district',
  '우에노 일대': 'Ueno area',
  'JR 우에노': 'JR Ueno Station',
  'JR·메트로·게이세이 우에노 일대': 'Ueno area (JR, Tokyo Metro and Keisei)',
  '도쿄메트로 이케부쿠로': 'Tokyo Metro Ikebukuro Station',
  'JR 이케부쿠로 중심': 'JR Ikebukuro Station',
  '진보초·주변': 'Jimbocho area',
  '진보초': 'Jimbocho',
  '메트로·도에이 진보초': 'Jimbocho (Tokyo Metro and Toei)',
};

const _englishLinkOperators = {
  '東日本旅客鉄道': 'JR East',
  '東京地下鉄': 'Tokyo Metro',
  '名古屋市': 'Nagoya Municipal Subway',
  '東急電鉄': 'Tokyu Railways',
  '東京都': 'Toei',
  '大阪市高速電気軌道': 'Osaka Metro',
  '京王電鉄': 'Keio',
  '福岡市': 'Fukuoka City Subway',
  '西日本旅客鉄道': 'JR West',
  '京浜急行電鉄': 'Keikyu',
  '京都市': 'Kyoto Municipal Subway',
  '横浜市': 'Yokohama Municipal Subway',
  '小田急電鉄': 'Odakyu',
  '九州旅客鉄道': 'JR Kyushu',
  '阪急電鉄': 'Hankyu',
  '札幌市': 'Sapporo Municipal Subway',
  '西武鉄道': 'Seibu',
  '京阪電気鉄道': 'Keihan',
  'ゆりかもめ': 'Yurikamome',
  '北海道旅客鉄道': 'JR Hokkaido',
  '南海電気鉄道': 'Nankai',
  '名古屋鉄道': 'Meitetsu',
  '沖縄都市モノレール': 'Yui Rail',
  '近畿日本鉄道': 'Kintetsu',
  '相模鉄道': 'Sotetsu',
  '横浜高速鉄道': 'Yokohama Minatomirai Railway',
  '東武鉄道': 'Tobu',
  '京成電鉄': 'Keisei',
  '東京臨海高速鉄道': 'Rinkai Line',
  '北九州高速鉄道': 'Kitakyushu Monorail',
  '阪神電気鉄道': 'Hanshin',
  '小田急箱根': 'Odakyu Hakone',
  '首都圏新都市鉄道': 'Tsukuba Express',
  '江ノ島電鉄': 'Enoden',
  '東京モノレール': 'Tokyo Monorail',
  '大阪モノレール': 'Osaka Monorail',
  '西日本鉄道': 'Nishitetsu',
  '北大阪急行電鉄': 'Kita-Osaka Kyuko',
  '多摩都市モノレール': 'Tama Monorail',
  '芝山鉄道': 'Shibayama Railway',
  '京福電気鉄道': 'Randen',
  'WILLER　TRAINS': 'Willer Trains',
  '東海旅客鉄道': 'JR Central',
  '名古屋臨海高速鉄道': 'Aonami Line',
  '湘南モノレール': 'Shonan Monorail',
};

const _englishCautions = {
  '오래된 별도 안내예요. 다른 안내와 범위가 겹칠 수 있어요.':
      'This is an older, separate guide and may overlap with other guides.',
  '목차와 기사 본문의 역·운영사 범위 대조. 개수·운영시간의 현행성은 보증하지 않음.':
      'The station and operator were cross-checked against the article. Locker counts and hours may have changed.',
  '이전 조사 정보가 포함되어 있어요. 현재 배치·요금은 다를 수 있어요.':
      'This guide includes older information. Locker locations and prices may have changed.',
  '공개 도쿄 노선 목차에서 괄호 읽기가 붙은 역명 제목을 재대조하여 누락 링크 보강. JR 해당역 기사 본문 확인; 시설 최신성 보증 아님.':
      'The JR station is covered in the article. Locker information may have changed.',
  '제1·2·3 공항 터미널 시설 안내. 해당 철도 운영사 역구내 설치를 보장하지 않음; 터미널별 구간만 연결':
      'Covers airport Terminals 1, 2 and 3, not necessarily lockers inside the railway station.',
  '제2터미널 건물1·2층 안내. 모노레일 역구내 기사가 아니며 제1·3터미널에 확대하지 않음':
      'Covers floors 1 and 2 of Terminal 2 only, not the monorail station or Terminals 1 and 3.',
  '본문 긴테쓰·한신 오사카난바/JR난바/남해난바/지하철난바 구역을 명시한 종합 기사':
      'Covers Kintetsu/Hanshin Osaka-Namba, JR Namba, Nankai Namba and the subway station.',
  'JR오사카역 북쪽의 그랜드프런트 상업시설. 철도역구내 기사가 아님':
      'Covers Grand Front Osaka, north of JR Osaka Station, not lockers inside the station.',
  '본문에 지하철 우메다/니시우메다/히가시우메다 및 한신우메다를 함께 다룬다고 명시. 한큐와 JR은 이 기사범위로 확대하지 않음':
      'Covers Umeda, Nishi-Umeda and Higashi-Umeda subway stations and Hanshin Osaka-Umeda, not Hankyu or JR.',
  '한큐 나카쓰 시설없음 명시, 실제 위치안내는 지하철 미도스지선 나카쓰. 두 원천 시설운영중으로 표시하지 않음':
      'The article lists no lockers at Hankyu Nakatsu. The locker directions are for Nakatsu on the Midosuji Line.',
  '본문에 지하철 ドーム前千代崎와 阪神ドーム前 모두 명시.\n목차와 기사 본문의 역·운영사 범위 대조. 개수·운영시간의 현행성은 보증하지 않음.':
      'Covers both Dome-mae Chiyozaki (subway) and Dome-mae (Hanshin). Locker counts and hours may have changed.',
  '노선별 안내의 あびこ(M27) 항목에 역 구내 락커 없음 명시. 역 주변 전체의 시설 부재 보증이 아니며 현행 현장 확인 아님.':
      'The guide lists no lockers inside Abiko Station (M27). It does not rule out lockers nearby or confirm current conditions.',
  '본문에서 지하철 노다한신·한신노다를 공동 안내. 별도 JR노다에 확대하지 않음':
      'Covers subway Nodahanshin and Hanshin Noda, not the separate JR Noda Station.',
  '도입 지도설명에 京橋 오기, 본문 시설안내/역목차/요약은 大阪城公園으로 일치. 지도 실제설치점 시각 검증 별도':
      'The opening map mentions Kyobashi by mistake. The guide covers Osakajokoen; the map pin has not been independently checked.',
  '夢洲(C09) 항목에 역 구내 코인락커 없음 명시. 노선 안내 기준이며 주변 전체 부재 또는 현행 현장 상태 보증 아님.':
      'The guide lists no lockers inside Yumeshima Station (C09). This does not rule out lockers nearby or confirm current conditions.',
  'JR고쿠라·모노레일 고쿠라 종합 기사; 교토 오구라와 구분.':
      'Covers JR Kokura and monorail Kokura, not Ogura in Kyoto.',
  '국내선 터미널 시설 기사; 별도의 지하철역 구내 기사와 구분하여 인접 공항 범위로 보관.':
      'Covers the domestic terminal, not lockers inside the subway station.',
  '국내선·국제선 공항 및 지하철 종합 기사. 지하철역은 국내선 지하이며 국제선 시설이 역 구내인 것은 아님.':
      'Covers the domestic and international terminals and the subway. The subway station is beneath the domestic terminal.',
  '공항 제1·제2·제3터미널 종합 기사. 나리타공항역(T1)과 공항제2빌딩역(T2/3) 연결 범위는 분리하며 역 구내 시설로 일반화하지 않음.':
      'Covers Terminals 1–3. Narita Airport Station serves Terminal 1, and Airport Terminal 2 Station serves Terminals 2 and 3. Terminal lockers are not necessarily inside either station.',
  '한큐 가와라마치 옛 표기; 현재 교토가와라마치와 동일 역 범위.':
      'Hankyu Kawaramachi is the former name of Kyoto-Kawaramachi Station.',
  '본문 JR사가아라시야마 절을 확인한 지역 종합 기사; 란덴/한큐 역 원천과 분리.\nJR사가아라시야마·란덴아라시야마·한큐아라시야마별 본문 항목을 포함한 지역 종합 기사. 원천역은 별도 유지.':
      'Covers JR Saga-Arashiyama, Randen Arashiyama and Hankyu Arashiyama separately.',
  'JR·게이한·지하철을 구분하고 JR/게이한 구내에는 없고 지하철에만 있다는 본문 설명. 주변시설 전체 부재 확정 아님.':
      'The article lists lockers only in the subway station, not in the JR or Keihan stations. It does not rule out lockers nearby.',
  '게이한 산조와 지하철 산조케이한 본문 구역을 포함한 종합 기사. 원천역은 별도 유지.':
      'Covers Keihan Sanjo and subway Sanjo Keihan separately.',
  'JR우지와 게이한우지를 별도 본문 구역으로 다룬 종합 기사. 서로 약900m 떨어진 별도역으로 원천 식별 유지.':
      'Covers JR Uji and Keihan Uji separately. The two stations are about 900 metres apart.',
  '종료감사 보강: 기존URL/별칭/종합기사의 해당 역·운영사 본문 확인. 시설현행성/전운영사 보증 아님.':
      'The article covers this station or operator, but current availability and coverage of other operators are not guaranteed.',
  '신치토세공항 터미널 시설; JR역 구내 기사와 구분.':
      'Covers the New Chitose Airport terminal, not lockers inside the JR station.',
  '비에이 역 앞 관광안내소 시키노조호칸 시설 기사. 철도역 구내와 구분해서 인접 안내소 범위로 보관.':
      'Covers the Shiki no Johokan tourist information centre in front of Biei Station, not the station interior.',
  '제목 및 도입부는 JR유후인 주변 안내이나 영업시간 문장에 日田역 표기가 남아 있음. 그 문장/시간은 신뢰하지 않으며 현행 현장상태 보증 아님.':
      'The article covers JR Yufuin, but its hours section mentions Hita by mistake. Do not rely on those hours.',
  '이전 조사 정보가 포함되어 있어요. 현재 배치·요금은 다를 수 있어요.\n나하공항 터미널 시설 기사. 유이레일 역 구내 기사 naha-airport-station과 구분하여 인접 공항 범위로 보관.':
      'Locations and prices may have changed. Covers Naha Airport’s terminal, not the Yui Rail station.',
  '아사히바시 역 앞 나하버스터미널 시설; 유이레일 역 구내와 구분.':
      'Covers Naha Bus Terminal in front of Asahibashi, not the Yui Rail station.',
  '역 전용 기사가 아닌 주변 기사예요. 이전 조사 정보가 포함되어 있어요.\n나고야돔 주변 기사 중 메이테쓰/지하철 오조네 절. 돔 내부와 역 구역 구분.':
      'This older area guide includes Meitetsu and subway Ozone. Dome facilities and station lockers are separate.',
  '해당 역별 절에서 역 구내 락커 없음 안내 확인. 기사확보는 시설 있음 의미 아님.':
      'The article lists no lockers inside this station. A linked guide does not mean lockers are available.',
  '본문의 지하철 나고야돔마에야다 절. 가이드웨이버스 정류장 구내까지 포함하지 않음.':
      'Covers subway Nagoya Dome-mae Yada, not the guideway bus stop.',
  '善師野 절의 역 구내 락커 없음 안내. 시설존재로 해석하지 않음.':
      'The article lists no lockers inside Zenjino Station.',
  '센트레아 공항 터미널 시설 기사; 메이테쓰 역 구내 기사 central-japan-international-airport-station과 구분하여 인접 공항 범위로만 보관.':
      'Covers the Centrair airport terminal, not lockers inside the Meitetsu station.',
  '요코하마 역·주변 종합 기사. 도입부 南区 및 JR타워 동쪽 표기는 오기로 보이며 해당 행정구/방향 설명은 근거로 사용하지 않음.':
      'Covers Yokohama Station and the surrounding area. The article’s opening district and JR tower directions may be incorrect.',
  '운영사별 요코하마 구내 본문을 확인. 공통 도입부 南区/JR타워 방향 오기는 근거로 사용하지 않음.':
      'Covers the operators listed in the Yokohama Station article. The opening district and JR tower directions may be incorrect.',
  '에노덴 에노시마/쇼난모노레일 쇼난에노시마/오다큐 가타세에노시마를 각각 다루는 지역 기사. 모노레일 역은 설치 없음 명시, 다른 두 역과 원천 식별 분리.':
      'Covers Enoden Enoshima, Shonan Monorail Shonan-Enoshima and Odakyu Katase-Enoshima separately. The article lists no lockers at the monorail station.',
};

bool isAllowedCoinLockerUri(Uri uri, {String? sourceId}) =>
    uri.scheme == 'https' &&
    uri.userInfo.isEmpty &&
    !uri.hasPort &&
    !uri.hasQuery &&
    !uri.hasFragment &&
    uri.path.isNotEmpty &&
    (sourceId == null
        ? CoinLockerSource.hosts.values.contains(uri.host)
        : CoinLockerSource.hosts[sourceId] == uri.host);
