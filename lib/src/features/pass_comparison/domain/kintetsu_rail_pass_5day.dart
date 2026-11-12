import '../data/kintetsu_rail_pass_5day_data.dart';

enum KintetsuPassVerdict {
  beneficial,
  breakEven,
  notBeneficial,
  insufficientData,
}

enum KintetsuPassVariant {
  oneDay('1일권', 1900, '오사카난바–긴테쓰나라, 교토–쓰쓰이, 나가타–이코마, 도리이마에–이코마산조'),
  twoDay('2일권', 3700, '오사카·나라·교토의 긴테쓰 노선 (오사카선은 산본마쓰까지)'),
  fiveDay('5일권', 4900, '긴테쓰 전 노선과 이가철도'),
  fiveDayPlus('5일권 Plus', 6700, '긴테쓰 전 노선과 이가철도');

  const KintetsuPassVariant(this.label, this.price, this.railScope);
  final String label;
  final int price;
  final String railScope;

  String? get busScope => switch (this) {
    oneDay => '나라교통: 나라공원·니시노쿄·호류지 지정 구간',
    twoDay => '나라교통: 나라공원·니시노쿄·호류지·아스카·무로·야마노베노미치 지정 구간',
    fiveDay => null,
    fiveDayPlus => '2일권과 같은 나라교통 구간 및 미에교통·도바 카모메 버스 지정 구간',
  };

  String get officialUrl =>
      'https://www.kintetsu.co.jp/foreign/english/ticket/krp_${switch (this) {
        oneDay => '1day',
        twoDay => '2day',
        fiveDay => '5day',
        fiveDayPlus => '5dayplus',
      }}.html';

  bool covers(KintetsuStation station) {
    if (this == fiveDay || this == fiveDayPlus) return true;
    final lines = station.lines.split('|');
    if (this == oneDay) {
      return lines.any(_oneDayLines.contains) ||
          _oneDayBoundaryStations.contains(station.id);
    }
    return lines.any(_twoDayLines.contains) ||
        _twoDayOsakaStations.contains(station.id);
  }
}

const _oneDayLines = {'kintetsu_namba', 'nara', 'kyoto', 'ikoma_cable'};
const _oneDayBoundaryStations = {
  'amagatsuji',
  'nishinokyo',
  'kujo_nara',
  'kintetsu_koriyama',
  'tsutsui',
  'nagata',
  'aramoto',
  'yoshita',
  'shin_ishikiri',
};
const _twoDayLines = {
  ..._oneDayLines,
  'keihanna',
  'kashihara',
  'domyoji',
  'gose',
  'ikoma',
  'minami_osaka',
  'nagano',
  'nishi_shigi_cable',
  'shigi',
  'tawaramoto',
  'tenri',
  'yoshino',
};
// Osaka Line D03–D47; the next stop (D48 Akameguchi) is in Mie.
const _twoDayOsakaStations = {
  'osaka_uehommachi',
  'tsuruhashi',
  'imazato',
  'fuse',
  'shuntokumichi',
  'nagase',
  'mito',
  'kyuhojiguchi',
  'kintetsu_yao',
  'kawachi_yamamoto',
  'takayasu',
  'onji',
  'hozenji',
  'katashimo',
  'ando',
  'kawachi_kokubu',
  'osaka_kyoikudai_mae',
  'sekiya',
  'nijo',
  'kintetsu_shimoda',
  'goido',
  'tsukiyama',
  'yamato_takada',
  'matsuzuka',
  'masuga',
  'yamato_yagi',
  'miminashi',
  'daifuku',
  'sakurai',
  'yamato_asakura',
  'hasedera',
  'haibara',
  'muroguchi_ono',
  'sambommatsu',
};

class KintetsuPlannedSegment {
  const KintetsuPlannedSegment({
    required this.from,
    required this.to,
    required this.fare,
  });
  final KintetsuStation from;
  final KintetsuStation to;
  final int fare;
}

class KintetsuPassComparisonResult {
  const KintetsuPassComparisonResult({
    required this.segments,
    required this.outsideCoverage,
    required this.railFareTotal,
    required this.busFareTotal,
    required this.passPrice,
    required this.savings,
    required this.verdict,
  });
  final List<KintetsuPlannedSegment> segments;
  final List<KintetsuPlannedSegment> outsideCoverage;
  final int railFareTotal;
  final int busFareTotal;
  final int passPrice;
  int get regularFareTotal => railFareTotal + busFareTotal;
  final int savings;
  final KintetsuPassVerdict verdict;
}

abstract final class KintetsuRailPass5DayEvaluator {
  static KintetsuPassComparisonResult evaluate({
    required List<KintetsuPlannedSegment> segments,
    required KintetsuRailPass5DayData data,
    KintetsuPassVariant variant = KintetsuPassVariant.fiveDay,
    int confirmedBusFare = 0,
  }) {
    final valid = <KintetsuPlannedSegment>[];
    final outside = <KintetsuPlannedSegment>[];
    for (final segment in segments) {
      if (!variant.covers(segment.from) || !variant.covers(segment.to)) {
        outside.add(segment);
      } else if (segment.fare > 0) {
        valid.add(segment);
      }
    }
    final rail = valid.fold(0, (sum, segment) => sum + segment.fare);
    final bus = variant.busScope != null && confirmedBusFare > 0
        ? confirmedBusFare
        : 0;
    final price = variant == KintetsuPassVariant.fiveDay
        ? data.passPrice
        : variant.price;
    final savings = rail + bus - price;
    return KintetsuPassComparisonResult(
      segments: valid,
      outsideCoverage: outside,
      railFareTotal: rail,
      busFareTotal: bus,
      passPrice: price,
      savings: savings,
      verdict: rail + bus == 0
          ? KintetsuPassVerdict.insufficientData
          : savings > 0
          ? KintetsuPassVerdict.beneficial
          : savings == 0
          ? KintetsuPassVerdict.breakEven
          : KintetsuPassVerdict.notBeneficial,
    );
  }
}
