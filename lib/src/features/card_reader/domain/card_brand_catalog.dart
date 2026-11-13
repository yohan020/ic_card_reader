/// Manual ground-truth labels, NOT a list of supported or detected cards.
/// Sources and generation distinctions: docs/parsing/CARD_BRAND_DIAGNOSTICS.md.
class CardBrand {
  const CardBrand(this.id, this.name, this.group, this.aliases);

  final String id;
  final String name;
  final String group;
  final String aliases;

  bool matches(String query) {
    final needle = _normalize(query);
    return _normalize('$name $aliases').contains(needle);
  }

  static String _normalize(String text) =>
      text.toLowerCase().replaceAll(RegExp(r'[\s·・_\-()]'), '');
}

/// No card numbers, personal names or multiline log injection in manual labels.
String? validateCardBrandLabel(String input) {
  final value = input.trim();
  if (value.isEmpty) return '브랜드 이름을 입력해 주세요.';
  if (value.runes.length > 40) return '40자 이내로 입력해 주세요.';
  if (RegExp(
    r'[\x00-\x1f\x7f-\x9f\u2028\u2029\u202a-\u202e\u2066-\u2069]',
  ).hasMatch(value)) {
    return '줄바꿈이나 제어 문자는 사용할 수 없어요.';
  }
  if (RegExp(r'\d{8,}|[0-9a-fA-F]{16}').hasMatch(value)) {
    return '카드 번호 대신 브랜드 이름만 입력해 주세요.';
  }
  return null;
}

const cardBrandCatalog = <CardBrand>[
  CardBrand('suica', 'Suica', '전국 상호이용', '스이카 スイカ'),
  CardBrand('pasmo', 'PASMO', '전국 상호이용', '파스모 パスモ'),
  CardBrand('icoca', 'ICOCA', '전국 상호이용', '이코카 イコカ'),
  CardBrand('toica', 'TOICA', '전국 상호이용', '토이카 トイカ'),
  CardBrand('kitaca', 'Kitaca', '전국 상호이용', '키타카 キタカ'),
  CardBrand('manaca', 'manaca', '전국 상호이용', '마나카 マナカ'),
  CardBrand('pitapa', 'PiTaPa', '전국 상호이용', '피타파 ピタパ'),
  CardBrand('sugoca', 'SUGOCA', '전국 상호이용', '스고카 スゴカ'),
  CardBrand('nimoca', 'nimoca', '전국 상호이용', '니모카 ニモカ'),
  CardBrand('hayakaken', '하야카켄', '전국 상호이용', 'はやかけん hayakaken'),
  CardBrand('welcome-suica', 'Welcome Suica', '파생 상품·모바일 참고', '웰컴 스이카 ウェルカム'),
  CardBrand(
    'monorail-suica',
    '모노레일 Suica',
    '파생 상품·모바일 참고',
    'モノレール スイカ monorail',
  ),
  CardBrand('rinkai-suica', '린카이 Suica', '파생 상품·모바일 참고', 'りんかい スイカ rinkai'),
  CardBrand('smart-icoca', 'SMART ICOCA', '파생 상품·모바일 참고', '스마트 이코카 スマート'),
  CardBrand('mobile-suica', '모바일 Suica', '파생 상품·모바일 참고', 'モバイル スイカ mobile'),
  CardBrand('mobile-pasmo', '모바일 PASMO', '파생 상품·모바일 참고', 'モバイル パスモ mobile'),
  CardBrand('mobile-icoca', '모바일 ICOCA', '파생 상품·모바일 참고', 'モバイル イコカ mobile'),
  CardBrand('sapica', 'SAPICA', '홋카이도', '사피카 サピカ'),
  CardBrand('docard', 'DoCARD', '홋카이도', '도카드 道北バス'),
  CardBrand('asaca', 'Asaca', '홋카이도', '아사카 アサカ'),
  CardBrand('icsca', 'icsca', '도호쿠', '이쿠스카 イクスカ'),
  CardBrand('noruca', 'NORUCA', '도호쿠', '노루카 ノルカ'),
  CardBrand('aopass', 'AOPASS', '도호쿠', '아오패스 アオパス'),
  CardBrand('megoica', 'MegoICa', '도호쿠', '메고이카 メゴイカ'),
  CardBrand('hachica', '하치카', '도호쿠', 'ハチカ hachica'),
  CardBrand('towada', 'Towada SkyBlue Pass', '도호쿠', '도와다 十和田'),
  CardBrand('iwate', 'Iwate Green Pass', '도호쿠', '이와테 岩手'),
  CardBrand('iguca', 'iGUCA', '도호쿠', '이구카 イグカ'),
  CardBrand('shuhoku', 'Shuhoku Orange Pass', '도호쿠', '슈호쿠 秋北'),
  CardBrand('akica', 'AkiCA', '도호쿠', '아키카 アキカ'),
  CardBrand('yamako', 'yamako cherica', '도호쿠', '야마코 체리카 ヤマコウ チェリカ'),
  CardBrand('shoko', 'shoko cherica', '도호쿠', '쇼코 체리카 ショウコウ チェリカ'),
  CardBrand('odeca-new', 'odeca (지역연계형)', '도호쿠', '오데카 オデカ Suica 2023'),
  CardBrand('lococa', 'LOCOCA', '도호쿠', '로코카 ロコカ'),
  CardBrand('ibappi', '이밧피', '간토·고신에쓰', 'いばっピ ibappi'),
  CardBrand('totra', 'totra', '간토·고신에쓰', '토트라 トトラ'),
  CardBrand('nolbe', 'nolbé', '간토·고신에쓰', '놀베 ノルベ norube'),
  CardBrand('ryuto', '류토', '간토·고신에쓰', 'りゅーと ryuto'),
  CardBrand('kururu-new', 'KURURU (지역연계형)', '간토·고신에쓰', '쿠루루 くるる Suica 2025'),
  CardBrand('ica', 'ICa (가나자와)', '도카이·호쿠리쿠', '아이카 アイカ 北陸鉄道 호쿠테쓰 kanazawa'),
  CardBrand('ecomyca', 'ecomyca', '도카이·호쿠리쿠', '에코마이카 えこまいか'),
  CardBrand('passca', 'passca', '도카이·호쿠리쿠', '파스카 パスカ'),
  CardBrand('ayuca', 'ayuca', '도카이·호쿠리쿠', '아유카 アユカ'),
  CardBrand('nicepass', 'nicepass', '도카이·호쿠리쿠', '나이스패스 ナイスパス'),
  CardBrand('luluca', 'LuLuCa', '도카이·호쿠리쿠', '루루카 ルルカ'),
  CardBrand('emica', 'emica', '긴키', '에미카 エミカ'),
  CardBrand('randen', '란덴 카드', '긴키', 'らんでんカード randen'),
  CardBrand('hanica', 'hanica', '긴키', '하니카 ハニカ'),
  CardBrand('cica', 'CI-CA', '긴키', '시카 シーカ cica'),
  CardBrand('tsukica', 'Tsukica', '긴키', '츠키카 ツキカ'),
  CardBrand('kinoca', 'kinoca', '긴키', '키노카 キノカ'),
  CardBrand('itappy', 'itappy', '긴키', '이탓피 イタッピー'),
  CardBrand('nicopa', 'NicoPa', '긴키', '니코파 ニコパ'),
  CardBrand('hareca', 'Hareca', '주고쿠·시코쿠', '하레카 ハレカ'),
  CardBrand('iruca', 'IruCa', '주고쿠·시코쿠', '이루카 イルカ'),
  CardBrand('desuca', '데스카', '주고쿠·시코쿠', 'ですか desuca'),
  CardBrand('mobiry', 'MOBIRY DAYS', '주고쿠·시코쿠', '모비리 モビリー デイズ'),
  CardBrand('ntasu', 'N+ (엔타스 카드)', '규슈·오키나와', 'エヌタスカード ntasu'),
  CardBrand('kumamon', '쿠마몬의 IC CARD', '규슈·오키나와', 'くまモンのIC CARD kumamon'),
  CardBrand('rapica', 'Rapica', '규슈·오키나와', '라피카 ラピカ'),
  CardBrand('iwasaki', '이와사키 IC 카드', '규슈·오키나와', 'いわさきICカード iwasaki'),
  CardBrand('okica', 'OKICA', '규슈·오키나와', '오키카 オキカ'),
  CardBrand('odeca-old', 'odeca (구형)', '구형·종료 카드 참고', '오데카 オデカ 旧'),
  CardBrand('kururu-old', 'KURURU (구형)', '구형·종료 카드 참고', '쿠루루 くるる 旧'),
  CardBrand('setamaru', '세타마루', '구형·종료 카드 참고', 'せたまる setamaru'),
  CardBrand(
    'yamanashi',
    '야마나시교통 버스 IC 카드',
    '구형·종료 카드 참고',
    '山梨交通 バスICカード yamanashi',
  ),
  CardBrand('kitami', '기타미 버스 IC 카드', '구형·종료 카드 참고', '北海道北見バス kitami'),
  CardBrand('icousa', 'ICOUSA', '구형·종료 카드 참고', '이코우사 イコウサ'),
  CardBrand('omi', '오미철도 버스 IC 카드', '구형·종료 카드 참고', '近江鉄道バス omi'),
  CardBrand('natch', '낫치', '구형·종료 카드 참고', 'なっち natch'),
  CardBrand('paspy', 'PASPY', '구형·종료 카드 참고', '파스피 パスピー'),
  CardBrand('skyrail', '스카이레일 패스', '구형·종료 카드 참고', 'スカイレールパス skyrail'),
  CardBrand('icecard', 'IC 이~카드', '구형·종료 카드 참고', 'ICい〜カード 이요테츠 이카드 e-card'),
  CardBrand('himawari', '히마와리 버스 카드', '구형·종료 카드 참고', 'ひまわりバスカード himawari'),
  CardBrand('nagasaki', '나가사키 스마트카드', '구형·종료 카드 참고', '長崎スマートカード nagasaki'),
  CardBrand('miyako', '미야코 버스카', '구형·종료 카드 참고', '宮交バスカ miyako'),
];
