import 'package:flutter/material.dart';

const yamanoteStampAssetIds = <String>[
  'tokyo',
  'kanda',
  'akihabara',
  'okachimachi',
  'ueno',
  'uguisudani',
  'nippori',
  'nishi-nippori',
  'tabata',
  'komagome',
  'sugamo',
  'otsuka',
  'ikebukuro',
  'mejiro',
  'takadanobaba',
  'shin-okubo',
  'shinjuku',
  'yoyogi',
  'harajuku',
  'shibuya',
  'ebisu',
  'meguro',
  'gotanda',
  'osaki',
  'shinagawa',
  'takanawa-gateway',
  'tamachi',
  'hamamatsucho',
  'shimbashi',
  'yurakucho',
];

/// Original line drawings, not railway logos or official station stamps.
/// Each entry corresponds to the existing Tokyo-first Yamanote station order.
const yamanoteStampMotifs = <({String ko, String en, String path})>[
  (
    ko: '붉은 벽돌 역사',
    en: 'Station facade',
    path:
        'M4 36 L4 20 L20 20 L20 14 L44 14 L44 20 L60 20 L60 36 M2 36 L62 36 M26 14 Q26 2 32 2 Q38 2 38 14 M28 36 L28 26 L36 26 L36 36 M10 25 L15 25 M10 30 L15 30 M49 25 L54 25 M49 30 L54 30',
  ),
  (
    ko: '전통 지붕',
    en: 'Traditional roof',
    path:
        'M4 17 Q20 16 32 5 Q44 16 60 17 M9 21 L55 21 M16 21 L16 37 M48 21 L48 37 M12 28 L52 28 M25 28 L25 37 M39 28 L39 37 M12 37 L52 37',
  ),
  (
    ko: '게임과 전자문화',
    en: 'Games and electronics',
    path:
        'M17 15 L47 15 Q52 15 55 23 L59 34 Q59 42 52 37 L44 30 L20 30 L12 37 Q5 42 5 34 L9 23 Q12 15 17 15 M17 20 L17 29 M12 24 L22 24 M43 21 L46 21 M49 26 L52 26 M32 3 L32 10',
  ),
  (
    ko: '보석 공예',
    en: 'Jewelry craft',
    path:
        'M20 6 L44 6 L55 18 L32 39 L9 18 Z M9 18 L55 18 M20 6 L32 39 L44 6 M20 6 L32 18 L44 6 M3 30 L8 35 M56 30 L61 35',
  ),
  (
    ko: '연꽃',
    en: 'Lotus',
    path:
        'M32 34 Q15 34 9 18 Q25 16 32 34 Q39 16 55 18 Q49 34 32 34 M32 34 Q20 17 32 4 Q44 17 32 34 M4 39 Q13 35 23 39 Q32 42 42 38 Q51 35 60 39',
  ),
  (
    ko: '새와 나뭇가지',
    en: 'Bird and branch',
    path:
        'M6 34 L57 34 M20 28 Q6 24 9 12 L22 20 Q22 7 33 8 Q43 9 43 18 L54 21 L42 25 Q31 33 20 28 M25 28 L24 34 M32 29 L31 34 M29 17 L35 24 M36 13 L37 13 M49 34 Q49 24 59 25 Q59 32 49 34',
  ),
  (
    ko: '직물과 바느질',
    en: 'Fabric and stitching',
    path:
        'M12 8 L48 8 L54 35 L18 35 Z M18 35 L18 40 L55 40 M20 13 L22 13 M27 13 L29 13 M34 13 L36 13 M41 13 L43 13 M25 20 L39 29 M39 20 L25 29 M8 5 L12 16',
  ),
  (
    ko: '언덕길',
    en: 'Hillside steps',
    path:
        'M5 38 L17 38 L17 31 L28 31 L28 24 L39 24 L39 17 L50 17 L50 10 L60 10 M8 29 L8 7 M3 13 L8 6 L13 13 M53 24 L53 38 M48 30 L53 23 L58 30',
  ),
  (
    ko: '문학 수첩과 펜',
    en: 'Literary notebook',
    path:
        'M6 11 Q20 5 32 12 Q44 5 58 11 L58 36 Q44 30 32 37 Q20 30 6 36 Z M32 12 L32 37 M12 17 L24 17 M12 23 L24 23 M42 26 L54 3 L58 5 L46 28 L41 31 Z',
  ),
  (
    ko: '정원과 돌다리',
    en: 'Garden bridge',
    path:
        'M5 32 Q32 10 59 32 M5 36 Q32 18 59 36 M12 27 L12 15 M22 20 L22 10 M42 20 L42 10 M52 27 L52 15 M12 15 Q32 2 52 15 M3 40 Q14 36 25 40 Q40 44 61 39',
  ),
  (
    ko: '상점가',
    en: 'Shopping street',
    path:
        'M8 18 L13 7 L51 7 L56 18 Z M8 18 Q12 26 18 18 Q24 26 30 18 Q36 26 42 18 Q49 26 56 18 M12 22 L12 38 L52 38 L52 22 M23 38 L23 27 L39 27 L39 38 M22 8 L20 18 M34 8 L34 18 M44 8 L47 18',
  ),
  (
    ko: '거리의 전차',
    en: 'Street tram',
    path:
        'M18 9 L46 9 L48 34 L16 34 Z M21 14 L43 14 L43 25 L21 25 Z M21 30 L24 30 M40 30 L43 30 M22 35 L18 40 M42 35 L46 40 M32 2 L27 6 L37 6 Z',
  ),
  (
    ko: '도시와 부엉이',
    en: 'City owl',
    path:
        'M20 12 L20 5 L28 11 L36 11 L44 5 L44 12 Q54 25 43 35 Q32 43 21 35 Q10 25 20 12 M23 20 Q27 15 31 20 Q27 25 23 20 M33 20 Q37 15 41 20 Q37 25 33 20 M30 27 L32 30 L34 27 M5 36 L5 18 L11 18 L11 36 M54 36 L54 13 L60 13 L60 36',
  ),
  (
    ko: '정원 창문',
    en: 'Garden window',
    path:
        'M12 36 L12 10 Q32 0 52 10 L52 36 Z M32 7 L32 36 M12 22 L52 22 M20 36 L20 31 Q26 25 32 31 Q38 25 44 31 L44 36 M20 15 L22 15 M42 15 L44 15',
  ),
  (
    ko: '학생가의 책',
    en: 'Student books',
    path:
        'M10 12 L30 5 L55 14 L34 22 Z M15 16 L15 30 Q33 41 49 30 L49 17 M55 14 L55 30 M8 38 L42 38 M9 33 L9 40',
  ),
  (
    ko: '음악과 음식 거리',
    en: 'Music and food street',
    path:
        'M13 36 Q3 36 5 31 Q7 26 15 29 L15 9 L39 4 L39 29 Q40 36 30 35 Q22 34 27 29 Q30 26 37 28 M15 16 L39 11 M47 18 L54 18 L58 38 L43 38 Z M46 26 L55 26',
  ),
  (
    ko: '고층 도시',
    en: 'High-rise city',
    path:
        'M5 39 L5 17 L19 17 L19 39 M23 39 L23 4 L40 4 L40 39 M44 39 L44 12 L59 12 L59 39 M9 23 L15 23 M9 29 L15 29 M28 10 L35 10 M28 17 L35 17 M28 24 L35 24 M49 19 L54 19 M49 26 L54 26 M2 40 L62 40',
  ),
  (
    ko: '공원의 큰 나무',
    en: 'Park tree',
    path:
        'M28 38 L28 25 Q10 28 10 18 Q8 8 21 9 Q23 0 33 5 Q43 0 47 11 Q60 14 51 24 Q45 29 36 25 L36 38 M32 15 L32 37 M22 20 L32 27 L44 17 M18 39 L46 39',
  ),
  (
    ko: '패션과 크레페',
    en: 'Fashion and crepe',
    path:
        'M9 9 L19 4 L25 8 L31 4 L41 9 L36 19 L31 16 L31 38 L19 38 L19 16 L14 19 Z M43 20 Q51 10 60 21 L51 40 Z M44 23 L58 23 M49 15 L49 12',
  ),
  (
    ko: '스크램블 교차로',
    en: 'Scramble crossing',
    path:
        'M5 10 L20 10 L20 2 M44 2 L44 10 L59 10 M5 33 L20 33 L20 41 M44 41 L44 33 L59 33 M15 30 L19 34 L49 13 L45 9 Z M15 13 L19 9 L49 30 L45 34 Z M27 3 L36 3 M27 40 L36 40',
  ),
  (
    ko: '벽돌 아치와 정원',
    en: 'Brick arch and garden',
    path:
        'M10 38 L10 18 Q32 -2 54 18 L54 38 M20 38 L20 23 Q32 10 44 23 L44 38 M10 24 L19 24 M45 24 L54 24 M10 31 L19 31 M45 31 L54 31 M27 4 L27 12 M38 4 L38 12 M26 39 L38 39',
  ),
  (
    ko: '벚꽃과 강',
    en: 'Cherry blossom river',
    path:
        'M10 12 Q3 2 17 5 Q23 -2 26 9 Q37 11 28 19 Q30 30 19 24 Q8 29 10 18 Z M17 10 L19 20 M12 15 L24 14 M36 4 Q24 22 37 38 M47 5 Q35 22 48 39 M5 36 Q13 32 21 36 M47 24 L60 24 M50 29 L61 29',
  ),
  (
    ko: '강 위의 보트',
    en: 'River boat',
    path:
        'M5 25 L57 25 L49 35 L14 35 Z M19 25 L19 16 L38 16 L44 25 M30 16 L30 5 M30 6 L43 13 L30 13 M3 39 Q12 35 22 39 Q32 43 42 39 Q53 35 61 39',
  ),
  (
    ko: '빌딩과 산책로',
    en: 'Buildings and promenade',
    path:
        'M5 29 L5 10 L19 10 L19 29 M23 29 L23 3 L39 3 L39 29 M44 29 L44 14 L57 14 L57 29 M9 16 L14 16 M28 9 L34 9 M28 16 L34 16 M3 39 Q32 23 61 39 M17 40 Q32 31 47 40',
  ),
  (
    ko: '여행의 출발',
    en: 'Travel departure',
    path:
        'M8 33 L8 12 L34 12 L34 33 Z M15 12 L15 5 L27 5 L27 12 M13 34 L13 38 M29 34 L29 38 M15 18 L15 28 M27 18 L27 28 M40 22 L60 22 M53 15 L60 22 L53 29',
  ),
  (
    ko: '새로운 관문',
    en: 'New gateway',
    path:
        'M5 14 L21 5 L34 14 L48 4 L60 14 M8 17 L21 10 L34 18 L48 9 L57 17 M12 18 L12 37 M52 18 L52 37 M23 21 L23 37 M42 21 L42 37 M8 38 L57 38',
  ),
  (
    ko: '운하와 다리',
    en: 'Canal bridge',
    path:
        'M3 25 L61 25 M9 25 L9 13 M55 25 L55 13 M9 13 Q32 32 55 13 M19 22 L19 15 M32 24 L32 18 M45 22 L45 15 M5 36 Q15 31 26 36 Q36 41 47 36 Q56 31 62 36',
  ),
  (
    ko: '전망탑',
    en: 'Observation tower',
    path:
        'M17 40 L31 3 L33 3 L47 40 M21 30 L43 30 M25 20 L39 20 M27 14 L37 14 M22 30 L41 40 M42 30 L23 40 M27 21 L38 30 M37 21 L26 30 M12 40 L52 40',
  ),
  (
    ko: '옛 증기기관차',
    en: 'Historic steam train',
    path:
        'M7 30 L7 18 L33 18 L33 8 L52 8 L52 30 Z M11 18 L11 10 L18 10 L18 18 M38 13 L47 13 L47 22 L38 22 Z M3 31 L58 31 M12 37 Q12 30 18 30 Q24 30 24 37 Q18 43 12 37 M35 37 Q35 30 41 30 Q47 30 47 37 Q41 43 35 37 M12 5 Q17 0 22 5',
  ),
  (
    ko: '고가 아치와 극장',
    en: 'Viaduct and theater',
    path:
        'M4 39 L4 13 L60 13 L60 39 M10 38 L10 28 Q18 16 26 28 L26 38 M37 38 L37 28 Q45 16 53 28 L53 38 M3 8 L61 8 M14 3 L14 8 M32 3 L32 8 M50 3 L50 8',
  ),
];

class YamanoteStampArt extends StatelessWidget {
  const YamanoteStampArt({required this.index, required this.color, super.key});
  final int index;
  final Color color;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Image.asset(
      'assets/images/stamp_book_simple/${yamanoteStampAssetIds[index]}.webp',
      key: ValueKey('stamp-generated-art-$index'),
      fit: BoxFit.contain,
      color: color,
      colorBlendMode: BlendMode.srcIn,
      cacheWidth: 384,
      filterQuality: FilterQuality.medium,
      // Retain the original line art only as a safe asset/decode error fallback.
      errorBuilder: (context, error, stack) =>
          CustomPaint(painter: _MotifPainter(index, color)),
    ),
  );
}

class _MotifPainter extends CustomPainter {
  _MotifPainter(this.index, this.color);
  final int index;
  final Color color;
  static final _paths = yamanoteStampMotifs
      .map((m) => _parse(m.path))
      .toList(growable: false);
  static Path _parse(String source) {
    final tokens = RegExp(
      r'[MLQCZ]|-?\d+(?:\.\d+)?',
    ).allMatches(source).map((m) => m.group(0)!).toList();
    final p = Path();
    var i = 0;
    double n() => double.parse(tokens[i++]);
    while (i < tokens.length) {
      switch (tokens[i++]) {
        case 'M':
          p.moveTo(n(), n());
        case 'L':
          p.lineTo(n(), n());
        case 'Q':
          p.quadraticBezierTo(n(), n(), n(), n());
        case 'C':
          p.cubicTo(n(), n(), n(), n(), n(), n());
        case 'Z':
          p.close();
      }
    }
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64, size.height / 44);
    canvas.drawPath(
      _paths[index],
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MotifPainter oldDelegate) =>
      index != oldDelegate.index || color != oldDelegate.color;
}
